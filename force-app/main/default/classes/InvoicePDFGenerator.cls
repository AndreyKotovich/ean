public class InvoicePDFGenerator {

    public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';
    public static final String MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE = 'Membership_Renewal_Payment_Confirmation';
    public static final String MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE_STUDENTS = 'MRenewal_Payment_Confirmation_Students';

    @Future(Callout = true)
    public static void generateInvoicePDFs(List<Id> orderIds) {
        Boolean isSandbox = [SELECT Id, IsSandbox, Name FROM Organization LIMIT 1].IsSandbox;
        List<ContentVersion> attachments = new List<ContentVersion>();
        List<ContentVersion> newAttachments = new List<ContentVersion>();
        Map<String, ContentVersion> attachmentMap = new Map<String, ContentVersion>();
        Map<String, String> fileTitleEntityIdMap = new Map<String, String>();
        Set<String> attachmentNames = new Set<String>();
        List<Order__c> orders = new List<Order__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<BCC_email__mdt> bccEmail = [SELECT Id, Email__c FROM BCC_email__mdt LIMIT 1];
        // Collect Orders
        orders = [
                SELECT Id, Name, Contact__r.Email, Contact__r.MailingAddress, Invoice_Number__c, Purchase_Type__c, Type__c, Total_amount__c,
                (SELECT Id, Product__c, Membership__c FROM Order_Items__r), (SELECT Id, Name, Renewal_End_Date__c, Membership__r.API__c FROM Applications_Forms__r ORDER BY CreatedDate DESC)
                FROM Order__c
                WHERE Id IN :orderIds AND Contact__c != null AND Contact__r.Email != null
                ORDER BY CreatedDate ASC
        ];

//        RENEWAL CERTIFICATE GENERATION PART =================>
        String secretaryName = '';
        String presidentName = '';
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
        List<String> singleEmailMemberships = new List<String>{'resident_and_research_membership', 'full_membership', 'corresponding_membership', 'fellow_membership'};
        // List<String> singleEmailMemberships = new List<String>{'resident_and_research_membership', 'full_membership', 'corresponding_membership', 'fellow_membership', 'student_membership'};

        List<MembershipContactAssotiation__c> certificateRequired = [
                SELECT Id, Name, Application_form__r.Form_Status__c, Application_form__r.Order__c, Membership__r.API__c,
                        Application_form__r.Order__r.Type__c, Contact__c
                FROM MembershipContactAssotiation__c
                WHERE Application_form__r.Form_Status__c = 'Approved'
                AND Application_form__r.Order__c IN :orderIds
                AND Membership__r.API__c IN :singleEmailMemberships
                AND Application_form__r.Order__r.Type__c = 'Renewal'
                AND Application_form__r.Order__r.Total_amount__c > 0
                ORDER BY CreatedDate DESC
        ];

        system.debug('certificateRequired: '+certificateRequired);

        List<ContentVersion> existedCertificates = getRenewalExistedCertificates(certificateRequired);
//        <================= RENEWAL CERTIFICATE GENERATION PART

        // Generate new Invoice Numbers
        Boolean generated =  InvoicePDFGenerator.generateInvoiceNumber(orders);
        if (generated) {
            // Collect all Attachment Names
            for (Order__c o : orders) {
                attachmentNames.add('Invoice_' + o.Name + '.pdf');
            }
            // Collect all related Attachments
            attachments = [SELECT Title, VersionData FROM ContentVersion WHERE Title IN :attachmentNames];

            for (ContentVersion at : attachments) {
                attachmentMap.put(at.Title, at);
            }
            // Send an email with new or existing PDF
            List<EmailTemplate> ets = [
                    SELECT Id, Name, DeveloperName
                    FROM EmailTemplate
                    WHERE DeveloperName = 'Confirmation_of_Journal_order_invoice'
                    OR DeveloperName = 'New_Invoice_Email'
                    OR DeveloperName =:MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE
                    OR DeveloperName =:MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE_STUDENTS
            ];
            EmailTemplate et = new EmailTemplate();
            OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'membership@ean.org' LIMIT 1];
            for (Order__c o : orders) {
                ContentVersion att;

                //check if order has membership
                Boolean hasMembership = false;
                for(Order_Item__c oi : o.Order_Items__r){
                    if(oi.Membership__c != null){
                        hasMembership = true;
                    }
                }
                //find required email template
                String emailTemplateDevName = hasMembership?'New_Invoice_Email':'Confirmation_of_Journal_order_invoice';

                // part of 'Membership Renewal'
                if (hasMembership && o.Applications_Forms__r[0].Renewal_End_Date__c != null) {
                    emailTemplateDevName = o.Applications_Forms__r[0].Membership__r.API__c == 'student_membership' ? MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE_STUDENTS : MEMBERSHIP_RENEWAL_EMAIL_TEMPLATE;
                }

                for(EmailTemplate emTemp : ets){
                    if(emTemp.DeveloperName == emailTemplateDevName){
                        et = emTemp;
                    }
                }
                //choose whoId and whatId for email template
                Id whatId = hasMembership?o.Applications_Forms__r[0].Id:o.Id;


                // if PDF doesn't exist
                if (!attachmentMap.keySet().contains('Invoice_' + o.Name + '.pdf')) {
                    PageReference defaultPage = new PageReference('/apex/InvoicePage');
                    defaultPage.getParameters().put('co', o.Id);
                    defaultPage.getParameters().put('in', o.Invoice_Number__c);
                    Blob pageData;

                    if (Test.isRunningTest()) {
                        pageData = Blob.valueOf('Unit.Test');
                    } else {
                        pageData = defaultPage.getContent();
                    }
                    att = new ContentVersion(
                            VersionData = pageData,
                            Title = 'Invoice_' + o.Name + '.pdf',
                            PathOnClient = 'Invoice_' + o.Name + '.pdf',
                            IsMajorVersion = true,
                            ContentLocation = 'S',
                            NetworkId = ConnectApi.Communities.getCommunities().communities[0].id
                    );
                    newAttachments.add(att);
                    fileTitleEntityIdMap.put(att.Title, o.Id);
                    // else if PDF exists
                } else {
                    att = attachmentMap.get('Invoice_' + o.Name + '.pdf');
                }
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();

//                RENEWAL CERTIFICATE GENERATION PART =================>
                MembershipContactAssotiation__c membershipStatusForCertificate;

                for(MembershipContactAssotiation__c mca : certificateRequired){
                    if(mca.Application_form__r.Order__c == o.Id){
                        membershipStatusForCertificate = mca;
                    }
                }

                if(membershipStatusForCertificate != null){
                    ContentVersion certificate;

                    for(ContentVersion cv : existedCertificates){
                        if(cv.Title.contains(membershipStatusForCertificate.Name)){
                            certificate = cv;
                            break;
                        }
                    }

                    if(certificate == null){
                        certificate = generateMembershipCertificate(secretaryName, presidentName, membershipStatusForCertificate);
                        newAttachments.add(certificate);
                        fileTitleEntityIdMap.put(certificate.Title, membershipStatusForCertificate.Contact__c);
                    }


                    Messaging.EmailFileAttachment renewalCertificate = new Messaging.EmailFileAttachment();
                    renewalCertificate.setBody(certificate.VersionData);
                    renewalCertificate.setFileName(certificate.Title);
                    renewalCertificate.setContentType('application/pdf');
                    emailAttachments.add(renewalCertificate);

                }
//                <================= RENEWAL CERTIFICATE GENERATION PART

                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(et.Id, o.Contact__c, whatId);
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setBody(att.VersionData);
                attach.setFileName(att.Title);
                attach.setContentType('application/pdf');
                emailAttachments.add(attach);

                String emailTextBody = message.getPlainTextBody();
                message.setTargetObjectId(o.Contact__c);
                message.setPlainTextBody(emailTextBody);
                message.saveAsActivity = false;
                message.setOrgWideEmailAddressId(address.Id);

                if(!bccEmail.isEmpty() && membershipStatusForCertificate == null){
                    if(isSandbox) message.setBccAddresses(new List<String>{'ilya.litovchik@succraft.com'});
                    if(!isSandbox) message.setBccAddresses(new List<String>{bccEmail[0].Email__c});
                }

                if(membershipStatusForCertificate != null){
                    if(isSandbox) message.setBccAddresses(new List<String>{'ilya.litovchik@succraft.com'});
                    if(!isSandbox) message.setBccAddresses(new List<String>{'membership@ean.org'});
                }

                message.setFileAttachments(emailAttachments);
                emails.add(message);
            }

            try {
                // Insert new PDF Invoices as Attachments
                if (!newAttachments.isEmpty()) {
                    System.debug(newAttachments);
                    insert newAttachments;

                    List<ContentVersion> cds = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN : newAttachments];
                    List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
                    for (ContentVersion cd : cds) {
                        Id orderId = fileTitleEntityIdMap.get(cd.Title);
                        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = orderId,
                        ShareType = 'V', ContentDocumentId = cd.ContentDocumentId);
                        cdLinks.add(link);
                    }

                    if (!cdLinks.isEmpty()) {
                        insert cdLinks;
                    }
                }
                // Send Emails with attached PDF Invoices
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                }
            } catch (Exception e) {
                Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
                errorEmail.setSubject('New Invoice sending error');
                String[] emailIds = new String[]{
                        'ilya.litovchik@succraft.com'
                };
                errorEmail.setToAddresses(emailIds);
                errorEmail.setPlainTextBody('Error Description: \n Message:' + e.getMessage() + '\n Line Number: ' + e.getLineNumber() + '\n Stack Trace: ' + e.getStackTraceString());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                        errorEmail
                });
            }
        }
    }

    public static Boolean generateInvoiceNumber(List<Order__c> orders) {
        Boolean isOk = true;
        List<Order__c> newOrdersEIMF = new List<Order__c>();
        List<Order__c> newOrdersREIMF = new List<Order__c>();
        String orderTemplateEIMF = 'EIMF ' + String.valueOf(Date.today().year()) + '/%';
        String orderTemplateREIMF = 'REIMF ' + String.valueOf((Date.today().addYears(1)).year()) + '/%';
        Integer lastEIMFNumber;
        Integer lastREIMFNumber;

        // Collect the last Orders to find the last Invoice Number for EIMF
        List<Order__c> ordersEIMF = [
                SELECT Invoice_Number__c
                FROM Order__c
                WHERE Invoice_Number__c != NULL AND Invoice_Number__c LIKE :orderTemplateEIMF
                ORDER BY Invoice_Number__c DESC
                LIMIT 10
        ];

        // Collect the last Orders to find the last Invoice Number for REIMF
        List<Order__c> ordersREIMF = [
                SELECT Invoice_Number__c
                FROM Order__c
                WHERE Invoice_Number__c != null AND Invoice_Number__c LIKE :orderTemplateREIMF
                ORDER BY Invoice_Number__c DESC
                LIMIT 10
        ];

        for (Order__c o : orders) {
            if (o.Invoice_Number__c == null || !o.Invoice_Number__c.contains('EIMF')) {

                //  part of 'Membership Renewal'
                if (o.Type__c == 'Renewal') {
                    newOrdersREIMF.add(o);
                    continue;
                }

                //  old logic
//                if (o.Purchase_Type__c == 'Update') {
//                    newOrdersREIMF.add(o);
//                } else {
                    newOrdersEIMF.add(o);
//                }
            }
        }

        // Generate Invoice Numbers for EIMF
        if (!newOrdersEIMF.isEmpty()) {
            lastEIMFNumber = 0;

            // Find the last correct Invoice Number for EIMF
            for (Order__c o : ordersEIMF) {
                String invoiceNumb = o.Invoice_Number__c.replace('EIMF ' + String.valueOf(Date.today().year()) + '/','');
                if (invoiceNumb.isNumeric()) {
                    lastEIMFNumber = Integer.valueOf(invoiceNumb);
                    break;
                }
            }

            // Set new Invoice Numbers to EIMF Orders
            for (Order__c o : newOrdersEIMF) {
                lastEIMFNumber += 1;
                String newInvoiceNumber = String.valueOf(lastEIMFNumber);
                if (lastEIMFNumber < 1000) {
                    newInvoiceNumber  = ('0000' + lastEIMFNumber).right(4);
                }
                o.Invoice_Number__c = 'EIMF ' + String.valueOf(Date.today().year()) + '/' + newInvoiceNumber;
            }
        }

        // Generate Invoice Numbers for REIMF
        if (!newOrdersREIMF.isEmpty()) {
            lastREIMFNumber = 0;

            // Find the last correct Invoice Number for REIMF
            for (Order__c o : ordersREIMF) {
                String invoiceNumb = o.Invoice_Number__c.replace('REIMF ' + String.valueOf((Date.today().addYears(1)).year()) + '/','');
                if (invoiceNumb.isNumeric()) {
                    lastREIMFNumber = Integer.valueOf(invoiceNumb);
                    break;
                }
            }

            // Set new Invoice Numbers to REIMF Orders
            for (Order__c o : newOrdersREIMF) {
                lastREIMFNumber += 1;
                String newInvoiceNumber = String.valueOf(lastREIMFNumber);
                if (lastREIMFNumber < 1000) {
                    newInvoiceNumber  = ('0000' + lastREIMFNumber).right(4);
                }
                o.Invoice_Number__c = 'REIMF ' + String.valueOf((Date.today().addYears(1)).year()) + '/' + newInvoiceNumber;
            }

        }

        try {
            // Update Orders with new Invoice Numbers
            if (!orders.isEmpty()) {
                update orders;
            }
        } catch (Exception e) {
            isOk = false;
            Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
            errorEmail.setSubject('New Invoice Number creation error');
            String[] emailIds = new String[]{
                    'ezhi.sarosek@succraft.com'
            };
            errorEmail.setToAddresses(emailIds);
            errorEmail.setPlainTextBody('Error Description: \n Message:' + e.getMessage() + '\n Line Number: ' + e.getLineNumber() + '\n Stack Trace: ' + e.getStackTraceString());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    errorEmail
            });
        }

        return isOk;
    }

    public static void updateParticipantsStatus(List<Id> orderIds){

        List<Contact> undefinedParticipant = [SELECT Id FROM Contact WHERE Name =:SYSTEM_GROUP_CONTACT_NAME LIMIT 1];
        Id undefinedParticipantId = undefinedParticipant.isEmpty() ? null : undefinedParticipant[0].Id;

        List<Order__c> ordersWithParticipationItems = [
                SELECT Id, Status__c,
                (
                        SELECT Id, Session_Participation__r.Status__c, Event_Participation__r.Status__c, Event_Participation__r.Contact__c
                        FROM Order_Items__r
                        WHERE Session_Participation__c != NULL
                        OR Event_Participation__c != NULL
                )
                FROM Order__c
                WHERE Id IN :orderIds
        ];

        List<Participant__c> eventParticipants = new List<Participant__c>();
        List<Session_Participation__c> sessionParticipants = new List<Session_Participation__c>();

        for(Order__c o : ordersWithParticipationItems){
            for(Order_Item__c oi : o.Order_Items__r){

                //  OLD LOGIC
                // if(oi.Event_Participation__c != null && oi.Event_Participation__r.Status__c == 'Pending'){
                //    eventParticipants.add(new Participant__c(Id = oi.Event_Participation__c, Status__c = 'Registered'));
                // }

                //  NEW LOGIC
                if(oi.Event_Participation__c != null && oi.Event_Participation__r.Status__c == 'Pending') {
                    String newStatus = oi.Event_Participation__r.Contact__c != undefinedParticipantId ? 'Registered' : 'Registered Draft';
                    eventParticipants.add(new Participant__c(Id = oi.Event_Participation__c, Status__c = newStatus));
                }

                if(oi.Session_Participation__c != null && oi.Session_Participation__r.Status__c == 'Pending'){
                    sessionParticipants.add(new Session_Participation__c(Id = oi.Session_Participation__c, Status__c = 'Registered'));
                }
            }
        }

        update eventParticipants;
        update sessionParticipants;
    }

    public static void sendEmailOrderPaidSoloReg(List<Id> orderIds) {
        List<Order__c> orders = [
            SELECT Id, Contact__r.Email, Event_custom__c, Type__c, Payment_Method__c FROM Order__c WHERE Id IN :orderIds
        ];
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Order__c order : orders) {
            if (order.Payment_Method__c == 	'Bank Transfer') {
                Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = order.Contact__c,
                Event_Custom__c = order.Event_custom__c,
                Order__c = order.Id,
                Send_To_Email__c = order.Contact__r.Email,
                Type__c = 'Solo event registration order paid BT'
            );
            emailActivities.add(emailActivity);
            } else if (order.Payment_Method__c == 	'paypal'
                        || order.Payment_Method__c == 	'creditcard') {
                Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = order.Contact__c,
                Event_Custom__c = order.Event_custom__c,
                Order__c = order.Id,
                Send_To_Email__c = order.Contact__r.Email,
                Type__c = 'Event registration ' + order.Payment_Method__c
            );
            emailActivities.add(emailActivity);
            }
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
            List<String> emailActivityIds = new List<String>();
            for (Email_Activity__c emailActivity : emailActivities) {
                emailActivityIds.add(emailActivity.Id);
            }
            saveEventInvoicePDF(emailActivityIds);
        }
    }

    public static void sendEmailOrderPaidGroupRegBT(List<Id> orderIds) {
        List<Order__c> orders = [
            SELECT Id, Contact__r.Email, Event_custom__c, Type__c, Payment_Method__c,
            (SELECT Id, Total_amount__c, Name__c, Event_Participation__r.Contact__r.Name FROM Order_Items__r)
            FROM Order__c 
            WHERE Id IN :orderIds
        ];
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Order__c order : orders) {
            Boolean isAllOrderItemsSame = true;
            Decimal orderItemAmount;
            String orderItemName;
            String orderItemContact;
            if (order.Order_Items__r.size() == 1) {
                isAllOrderItemsSame = false;
            }
            for (Order_Item__c orderItem : order.Order_Items__r) {
                if (orderItemAmount == null) {
                    orderItemAmount = orderItem.Total_amount__c;
                } else if (orderItemAmount != orderItem.Total_amount__c) {
                    isAllOrderItemsSame = false;
                }
                if (orderItemName == null) {
                    orderItemName = orderItem.Name__c;
                } else if (orderItemName != orderItem.Name__c) {
                    isAllOrderItemsSame = false;
                }
                if (String.isNotBlank(orderItem.Event_Participation__c)) {
                    if (orderItemContact == null) {
                        orderItemContact = orderItem.Event_Participation__r.Contact__c;
                    } else if (orderItemContact != orderItem.Event_Participation__r.Contact__c) {
                        isAllOrderItemsSame = false;
                    }
                }
            }
            if (isAllOrderItemsSame) {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group eventReg order paid BT with the same orderItems'
                );
                emailActivities.add(emailActivity);
            } else {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group event registration order paid BT'
                );
                emailActivities.add(emailActivity);
            }
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
            List<String> emailActivityIds = new List<String>();
            for (Email_Activity__c emailActivity : emailActivities) {
                emailActivityIds.add(emailActivity.Id);
            }
            saveEventInvoicePDF(emailActivityIds);
        }
    }

    public static void sendInvoiceSoloRegBT(List<Id> orderIds) {
        List<Order__c> orders = [
            SELECT Id, Contact__r.Email, Event_custom__c, Type__c, Payment_Method__c FROM Order__c WHERE Id IN :orderIds
        ];
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Order__c order : orders) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = order.Contact__c,
                Event_Custom__c = order.Event_custom__c,
                Order__c = order.Id,
                Send_To_Email__c = order.Contact__r.Email,
                Type__c = 'Solo event registration BT'
            );
            emailActivities.add(emailActivity);
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
        }
    }

    public static List<ContentVersion> getRenewalExistedCertificates(List<MembershipContactAssotiation__c> membershipStatuses){
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Set<String> certificateNames = new Set<String>();

        for(MembershipContactAssotiation__c mStatus : membershipStatuses){
            certificateNames.add('Certificate_' + mStatus.Name + '.pdf');
        }

        contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title IN :certificateNames];

        return contentVersions;
    }

    public static ContentVersion generateMembershipCertificate(String secretaryName, String presidentName, MembershipContactAssotiation__c membershipStatus){
        PageReference defaultPage = new PageReference('/apex/CertificatePage');
        defaultPage.getParameters().put('ms', membershipStatus.Id);
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
                Title = 'Certificate_' + membershipStatus.Name + '.pdf',
                PathOnClient = '/Certificate_' + membershipStatus.Name + '.pdf',
                IsMajorVersion = true,
                SharingPrivacy = 'N',
                ContentLocation = 'S'
        );

        if (!Test.isRunningTest()) newCertificate.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;

        return newCertificate;
//        newCertificates.add(newCertificate);
//        fileContactMap.put(newCertificate.Title, membershipStatus.Contact__c);
    }

    @Future(callout=true)
    public static void saveEventInvoicePDF(List<String> emailActivityIds){
        List<Email_Activity__c> emailActivities = [
            SELECT Id, Order__c, Contact__c, Event_Custom__c, Type__c
            FROM Email_Activity__c
            WHERE Id IN :emailActivityIds
        ];
        Set<String> orderIdsSet = new Set<String>();
        for (Email_Activity__c emailActivity : emailActivities) {
            if (String.isNotBlank(emailActivity.Order__c)) {
                orderIdsSet.add(emailActivity.Order__c);
            }            
        }
        Map<Id, Order__c> orderMap = new  Map<Id, Order__c>([
            SELECT Id, Invoice_Number__c
            FROM Order__c
            WHERE Id IN :orderIdsSet
        ]);
        Map<String, ContentVersion> orderIdToConVerMap = new Map<String, ContentVersion>();
        for (Email_Activity__c emailActivity :emailActivities) {
            PageReference invoicePage = new PageReference('/apex/EventInvoice');
            invoicePage.getParameters().put('orderId', emailActivity.Order__c);
            invoicePage.getParameters().put('contactId', emailActivity.Contact__c);
            invoicePage.getParameters().put('eventId', emailActivity.Event_Custom__c);
            if (emailActivity.Type__c == 'Group eventReg order paid BT with the same orderItems') {
                invoicePage.getParameters().put('isOrderItemsSame', 'true');
            } else {
                invoicePage.getParameters().put('isOrderItemsSame', 'false');
            }
            ContentVersion conVer = new ContentVersion();
            if (Test.isRunningTest()) {
                conVer.NetworkId = null;
            } else {
                conVer.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;
            }                        
            conVer.ContentLocation = 'S';
            conVer.PathOnClient = 'Invoice - ' + orderMap.get(emailActivity.Order__c).Invoice_Number__c + '.pdf';
            conVer.Title = 'Invoice - ' + orderMap.get(emailActivity.Order__c).Invoice_Number__c + '.pdf';
            if (Test.isRunningTest()) {
                conVer.VersionData = Blob.valueOf('Unit.Test');
            } else {
                conVer.VersionData = invoicePage.getContent();
            }            
            orderIdToConVerMap.put(emailActivity.Order__c, conVer);
        }
        if (orderIdToConVerMap.size() > 0) {
            insert orderIdToConVerMap.values();

            List<String> conVerIds = new List<String>();

            for (ContentVersion conVer : orderIdToConVerMap.values()) {
                conVerIds.add(conVer.Id);
            }

            Map<ID, ContentVersion> conVersMap = new Map<ID, ContentVersion>([
                SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :conVerIds
                ]);
            List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();

            for (String orderId : orderIdToConVerMap.keySet()) {
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = orderId;
                conDocLink.ContentDocumentId = conVersMap.get(orderIdToConVerMap.get(orderId).Id).ContentDocumentId;
                conDocLink.shareType = 'V';
                conDocLink.Visibility='AllUsers';
                conDocLinks.add(conDocLink);
            }
            insert conDocLinks;
        }
    }

    public static void generateEventInvoiceNumber(List<Order__c> orders) {
        String invoiceNum = 'EAN' + String.valueOf(Date.today().year()).right(2) + '-F-%';
        Integer oIEANNumber = 0;
        List<Order__c> oIEAN = [
            SELECT Invoice_Number__c
            FROM Order__c
            WHERE Invoice_Number__c != NULL AND Invoice_Number__c LIKE :invoiceNum
            ORDER BY Invoice_Number__c DESC
            LIMIT 10
        ];

        if (oIEAN.isEmpty()) { invoiceNum = invoiceNum.substring(0,invoiceNum.length()-1) + '000001'; }
        if (!oIEAN.isEmpty()) {
            for (Order__c o : oIEAN) {
                String invoiceNumb = o.Invoice_Number__c.right(6);
                if (invoiceNumb.isNumeric()) {
                    oIEANNumber = Integer.valueOf(invoiceNumb);
                    break;
                }
            }

            oIEANNumber++;

			String oIEANStr = String.valueOf(oIEANNumber);
			while (oIEANStr.length() < 6) {
				oIEANStr = '0' + oIEANStr;
			}
              
			invoiceNum = invoiceNum.substring(0,invoiceNum.length()-1) + oIEANStr;
        }
        for (Order__c order : orders) {
            order.Invoice_Number__c = invoiceNum;
            List<String> invoiceNumParts = invoiceNum.split('-');
            String serialNumber = String.valueOf(Integer.valueof(invoiceNumParts[invoiceNumParts.size()-1]) + 1);
            while (serialNumber.length() < 6) {
				serialNumber = '0' + serialNumber;
            }
            invoiceNum = invoiceNum.left(invoiceNum.length() - 6) + serialNumber;
        }
    }
}