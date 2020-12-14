public class CertificatePDFGenerator {
    @Future(Callout = true)
    public static void generateCertificatePDFs(Set<Id> mStatusIds) {
        String secretaryName = '';
        String presidentName = '';
        Boolean hasError = false;
        List<ContentVersion> newCertificates = new List<ContentVersion>();
        List<BCC_email__mdt> bccEmail = [SELECT Id, Email__c FROM BCC_email__mdt LIMIT 1];
        List<String> singleEmailMemberships = new List<String>{'resident_and_research_membership', 'full_membership', 'corresponding_membership', 'fellow_membership'};

        // Get Membership status records by Ids ===>
        List<MembershipContactAssotiation__c> mStatuses = [
                SELECT Id, Name, Contact__c, Application_form__c, Membership__r.API__c,
                    Application_form__r.Order__c, Application_form__r.Order__r.Type__c, Application_form__r.Order__r.Total_amount__c, Application_form__r.Renewal_End_Date__c
                FROM  MembershipContactAssotiation__c
                WHERE Id IN :mStatusIds
        ];
        //<===

//        PARSE RENEWAL MEMBERSHIPS (Certificate sent in InvoicePDFGenerator.generateInvoicePDFs) =======>
        List<MembershipContactAssotiation__c> mStatuses_temp = new List<MembershipContactAssotiation__c>();

        for(MembershipContactAssotiation__c m : mStatuses){
            if(singleEmailMemberships.contains(m.Membership__r.API__c) && m.Application_form__r.Order__r.Type__c == 'Renewal'){
                continue;
            } else {
                mStatuses_temp.add(m);
            }
        }

        mStatuses = mStatuses_temp;
//      <======= PARSE RENEWAL MEMBERSHIPS (Certificate sent in InvoicePDFGenerator.generateInvoicePDFs)

        //GET Attached Certificates for related Contacts ===>
        Set<Id> contactIds = new Set<Id>();
        Set<String> certificateNames = new Set<String>();
        Map<Id, ContentVersion> AttachemntMap = new Map<Id, ContentVersion>();
        for (MembershipContactAssotiation__c m : mStatuses) {
            contactIds.add(m.Contact__c);
            certificateNames.add('Certificate_' + m.Name + '.pdf');
        }

        List<ContentVersion> attachments = [
                SELECT Title, VersionData
                FROM ContentVersion
                WHERE Title IN :certificateNames
        ];

        //<===

        // Get president and Secretary names ===>
        List<GroupChatterGroupAssotiation__c>  groupMemberships = [
                SELECT Id, Contact__r.Name, Contact__r.Salutation, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE (Role__c = 'President' OR Role__c = 'Secretary general') AND
                      Group__r.RecordType.Name = 'Level 1 Board (EAN Board)'
        ];

        for (GroupChatterGroupAssotiation__c g : groupMemberships) {
            if (g.Role__c == 'President') {
                presidentName = g.Contact__r.Salutation + ' ' + g.Contact__r.Name;
            } else if (g.Role__c == 'Secretary general') {
                secretaryName = g.Contact__r.Salutation + ' ' + g.Contact__r.Name;
            }

            if (secretaryName != '' && presidentName != ''){
                break;
            }
        }
        //<===

        // Create new Certificates ===>
        List<MStatusAttachmentAssociation> associatedStatuses = new List<MStatusAttachmentAssociation>();
        Map<String, String> fileContactMap = new Map<String, String>();
        if (secretaryName != null && presidentName != null) {
            MStatusAttachmentGenerator generator = new MStatusAttachmentGenerator(attachments, mStatuses);
            associatedStatuses = generator.generateAssociations();
            for (MStatusAttachmentAssociation a : associatedStatuses) {
                if (a.hasCertificate == false) {
                    PageReference defaultPage = new PageReference('/apex/CertificatePage');
                    defaultPage.getParameters().put('ms', a.mStatus.Id);
                    defaultPage.getParameters().put('sn', secretaryName);
                    defaultPage.getParameters().put('pn', presidentName);
                    Blob pageData;
                    if (Test.isRunningTest()) {
                        pageData = Blob.valueOf('Unit.Test');
                    } else {
                        pageData = defaultPage.getContent();

                    }
                    ContentVersion newCertificate = new ContentVersion(
                            VersionData = pageData,
                            Title = 'Certificate_' + a.mStatus.Name + '.pdf',
                            PathOnClient = '/Certificate_' + a.mStatus.Name + '.pdf',
                            IsMajorVersion = true,
                            SharingPrivacy = 'N',
                            ContentLocation = 'S'
                    );

                    //  required for Membership Renewal
                    if (!Test.isRunningTest()) newCertificate.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;

                    newCertificates.add(newCertificate);
                    a.certificate = newCertificate;
                    fileContactMap.put(newCertificate.Title, a.mStatus.Contact__c);

                }
            }
        }
        //<===

        // Insert Attachments ===>
        try {
            if (!newCertificates.isEmpty()) {
                insert newCertificates;

                List<ContentVersion> cds = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN : newCertificates];
                List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
                for (ContentVersion cd : cds) {
                    Id orderId = fileContactMap.get(cd.Title);
                    ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = orderId,
                            ShareType = 'V', Visibility = 'AllUsers', ContentDocumentId = cd.ContentDocumentId);
                    cdLinks.add(link);
                }

                if (!cdLinks.isEmpty()) {
                    insert cdLinks;
                }
            }

            // Error simulation
            if (Test.isRunningTest()) {
                Integer i = 1/0;
            }
        } catch (Exception e) {
            hasError = true;
            sendErrorEmail(e);
        }
        //<===

        // Create emails ===>
        List<Messaging.SingleEmailMessage> listToSend = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> ets = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName LIKE '%Welcome_Email%' LIMIT 2];
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();

        for (EmailTemplate et : ets){
            emailTemplateMap.put(et.DeveloperName, et);
        }

        //  costyl
        List<EmailTemplate> renewalApproved = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName ='MRenewal_Student_Final_Approval' LIMIT 1];
        if (!renewalApproved.isEmpty()) emailTemplateMap.put(renewalApproved[0].DeveloperName, renewalApproved[0]);

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'membership@ean.org' LIMIT 1];
        for (MStatusAttachmentAssociation a : associatedStatuses) {
            String contactId = a.mStatus.Contact__c;
            String whatId = a.mStatus.Id;
            Messaging.SingleEmailMessage message;

            if (a.mStatus.Application_form__r.Renewal_End_Date__c == null) {
                if(a.mStatus.Membership__r.API__c == 'fellow_membership'){
                    message = Messaging.renderStoredEmailTemplate(emailTemplateMap.get('New_Welcome_Email_FEAN').Id, contactId, whatId);
                } else {
                    message = Messaging.renderStoredEmailTemplate(emailTemplateMap.get('New_Welcome_Email').Id, contactId, whatId);
                }
            }
            // if (a.mStatus.Application_form__r.Renewal_End_Date__c != null && a.mStatus.Application_form__r.Order__r.Total_amount__c == 0) {
            if (a.mStatus.Application_form__r.Renewal_End_Date__c != null) {
                message = Messaging.renderStoredEmailTemplate(emailTemplateMap.get('MRenewal_Student_Final_Approval').Id, contactId, a.mStatus.Application_form__c);
            }

            String emailTextBody = message.getPlainTextBody();
            message.setTargetObjectId(contactId);
            message.setPlainTextBody(emailTextBody);
            message.saveAsActivity = false;
            message.setOrgWideEmailAddressId(address.Id);

            if(!bccEmail.isEmpty()){
                message.setBccAddresses(new List<String>{bccEmail[0].Email__c});
            }

            //attach certificate to email
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setBody(a.certificate.VersionData);
            attachment.setFileName(a.certificate.Title);
            attachment.setContentType('application/pdf');
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{
                    attachment
            });


            listToSend.add(message);
        }
        //<===

        // Send emails ===>
        try {
            if (!listToSend.isEmpty() && !hasError) {
                Messaging.sendEmail(listToSend);
            }

            // Error simulation
            if (Test.isRunningTest()) {
                Integer i = 1/0;
            }
        } catch (Exception e) {
            sendErrorEmail(e);
        }
        //<===

    }

    public class MStatusAttachmentGenerator {
        List <ContentVersion> certificates;
        List<MembershipContactAssotiation__c> mStatuses;
        public MStatusAttachmentGenerator(List<ContentVersion> atts, List<MembershipContactAssotiation__c> mSts) {
            this.certificates = atts;
            this.mStatuses = mSts;
        }

        public List<MStatusAttachmentAssociation> generateAssociations () {
            List<MStatusAttachmentAssociation> associations = new List<MStatusAttachmentAssociation>();
            for (MembershipContactAssotiation__c m : mStatuses) {
                Boolean matchFound = false;
                for (ContentVersion a : certificates ) {
                    if (a.Title.contains(m.Name)) {
                        associations.add(new MStatusAttachmentAssociation(a, m));
                        matchFound = true;
                        break;
                    }
                }

                if (matchFound == false) {
                    associations.add(new MStatusAttachmentAssociation(m));
                }
            }
            return associations;
        }
    }

    public class MStatusAttachmentAssociation {
        ContentVersion certificate;
        MembershipContactAssotiation__c mStatus;
        Boolean hasCertificate = false;

        public MStatusAttachmentAssociation (MembershipContactAssotiation__c mStatus) {
            this.mStatus = mStatus;
        }

        public MStatusAttachmentAssociation (ContentVersion att, MembershipContactAssotiation__c mStatus) {
            this(mStatus);
            this.hasCertificate = true;
            this.certificate = att;
        }
    }

    private static void sendErrorEmail (Exception e) {
        Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
        errorEmail.setSubject('New Certificate sending error');
        String[] emailIds = new String[]{
                'ilya.litovchik@succraft.com'
        };
        errorEmail.setToAddresses(emailIds);
        errorEmail.setPlainTextBody('Error Description: \n Message:' + e.getMessage() + '\n Line Number: ' + e.getLineNumber() + '\n Stack Trace: ' + e.getStackTraceString());
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                errorEmail
        });
    }

    @Future
    public static void setNewProfileForUser(Set<Id> contactIds) {
        List<Profile> newProfileList = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'];
        if (!newProfileList.isEmpty()) {
            Profile profileToSet = newProfileList[0];
            List<User> users = [SELECT ProfileId, Profile.Name FROM User WHERE ContactId IN : contactIds];
            List<User> usersToUpdate = new List<User>();
            for (User u : users) {
                if (u.ProfileId != profileToSet.Id && u.Profile.Name == 'Non-Member Community User Profile') {
                    u.ProfileId = profileToSet.Id;
                    usersToUpdate.add(u);
                }
            }

            if (!usersToUpdate.isEmpty()) {
                update usersToUpdate;
            }
        }

    }
}