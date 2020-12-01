public class SendInvoiceController {
	@AuraEnabled
    public static void sendInvoice(String orderId) {
        List<EmailTemplate> ets = [ SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Change_Request' ];
        EmailTemplate et = new EmailTemplate();
        et = ets.size() > 0 ? ets[0] : new EmailTemplate();
        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'membership@ean.org' LIMIT 1];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<BCC_email__mdt> bccEmail = [SELECT Id, Email__c FROM BCC_email__mdt LIMIT 1];
        List<Order__c> ords = [SELECT Id, Contact__c, Invoice_Number__c FROM Order__c WHERE Id =: orderId];

        if (String.isBlank(ords[0].Invoice_Number__c)) {

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
                    oIEANNumber++;
                    oIEANStr = '0' + oIEANStr;
                }
                
                invoiceNum = invoiceNum.substring(0,invoiceNum.length()-1) + oIEANStr;
            }

            update new Order__c(Id = ords[0].Id, Invoice_Number__c = invoiceNum);
        }

        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(et.Id, ords[0].Contact__c, ords[0].Id);
		
        String emailTextBody = message.getPlainTextBody();
        message.setTargetObjectId(ords[0].Contact__c);
        message.setPlainTextBody(emailTextBody);
        message.saveAsActivity = false;
        message.setOrgWideEmailAddressId(address.Id);

        if(!bccEmail.isEmpty()){
            message.setBccAddresses(new List<String>{bccEmail[0].Email__c});
        }

        emails.add(message);
      
        if (!emails.isEmpty()) {
		    Messaging.sendEmail(emails);
		}        
    }
    
}