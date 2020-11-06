public class InvoicePDFGenerator {
    @Future(Callout = true)
    public static void generateInvoicePDFs(List<Id> orderIds) {
        List<ContentVersion> attachments = new List<ContentVersion>();
        List<ContentVersion> newAttachments = new List<ContentVersion>();
        Map<String, ContentVersion> attachmentMap = new Map<String, ContentVersion>();
        Map<String, String> fileOrderMap = new Map<String, String>();
        Set<String> attachmentNames = new Set<String>();
        List<Order__c> orders = new List<Order__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<BCC_email__mdt> bccEmail = [SELECT Id, Email__c FROM BCC_email__mdt LIMIT 1];
        // Collect Orders
        orders = [
                SELECT Id, Name, Contact__r.Email, Contact__r.MailingAddress, Invoice_Number__c, Purchase_Type__c,
                (SELECT Id, Product__c, Membership__c FROM Order_Items__r), (SELECT Id, Name FROM Applications_Forms__r ORDER BY CreatedDate DESC)
                FROM Order__c
                WHERE Id IN :orderIds AND Contact__c != null AND Contact__r.Email != null
                ORDER BY CreatedDate ASC
        ];
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
                    fileOrderMap.put(att.Title, o.Id);
                    // else if PDF exists
                } else {
                    att = attachmentMap.get('Invoice_' + o.Name + '.pdf');
                }
                
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(et.Id, o.Contact__c, whatId);
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setBody(att.VersionData);
                attach.setFileName(att.Title);
                attach.setContentType('application/pdf');
                String emailTextBody = message.getPlainTextBody();
                message.setTargetObjectId(o.Contact__c);
                message.setPlainTextBody(emailTextBody);
                message.saveAsActivity = false;
                message.setOrgWideEmailAddressId(address.Id);

                if(!bccEmail.isEmpty()){
                    message.setBccAddresses(new List<String>{bccEmail[0].Email__c});
                }

                message.setFileAttachments(new Messaging.EmailFileAttachment[]{
                        attach
                });
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
                        Id orderId = fileOrderMap.get(cd.Title);
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
        String orderTemplateREIMF = 'REIMF ' + String.valueOf(Date.today().year()) + '/%';
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
//                if (o.Purchase_Type__c == 'Update') {
//                    newOrdersREIMF.add(o);
//                } else {
                    newOrdersEIMF.add(o);
//                }
            }
        }

        // Generate Invoice Numbers for EIMF
        if (!newOrdersEIMF.isEmpty()) {
            lastEIMFNumber = 625;

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
                String invoiceNumb = o.Invoice_Number__c.replace('REIMF ' + String.valueOf(Date.today().year()) + '/','');
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
                o.Invoice_Number__c = 'REIMF ' + String.valueOf(Date.today().year()) + '/' + newInvoiceNumber;
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
        List<Order__c> ordersWithParticipationItems = [
                SELECT Id, Status__c,
                (
                        SELECT Id, Session_Participation__r.Status__c, Event_Participation__r.Status__c
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
                if(oi.Event_Participation__c != null && oi.Event_Participation__r.Status__c == 'Pending'){
                   eventParticipants.add(new Participant__c(Id = oi.Event_Participation__c, Status__c = 'Registered'));
                }
                if(oi.Session_Participation__c != null && oi.Session_Participation__r.Status__c == 'Pending'){
                    sessionParticipants.add(new Session_Participation__c(Id = oi.Session_Participation__c, Status__c = 'Registered'));
                }
            }
        }

        update eventParticipants;
        update sessionParticipants;
    }

    @Future(Callout = true)
     public static void insertEmailActivity(List<Id> orderIds) {
         List<Order__c> orders = [
             SELECT Id, Contact__r.Email, Event_custom__c, Type__c FROM Order__c WHERE Id IN :orderIds
         ];
         List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
         for (Order__c order : orders) {
             Email_Activity__c emailActivity = new Email_Activity__c(
                 Contact__c = order.Contact__c,
                 Event_Custom__c = order.Event_custom__c,
                 Order__c = order.Id,
                 Send_To_Email__c = order.Contact__r.Email,
                 Type__c = order.Type__c
             );
             emailActivities.add(emailActivity);
         }
         if (emailActivities.size() > 0) {
             insert emailActivities;
         }
     }
}