public with sharing class AssignMembershipHelper {
    public static void assignMembership(List<Application_form__c> updatedForms){

        //  part of 'Membership Renewal'
        List<Membership__c> studentMemberhip = [SELECT Id FROM Membership__c WHERE API__c ='student_membership' LIMIT 1];
        Id studentMemberhipId = !studentMemberhip.isEmpty() ? studentMemberhip[0].Id : null;

        List<MembershipContactAssotiation__c> mca = new List<MembershipContactAssotiation__c>();
        Date expDate;

        for(Application_form__c af:updatedForms){

            Datetime renewalStartDateTime; //  part of 'Membership Renewal'
            Datetime renewalExpDateTime;   //  part of 'Membership Renewal'

            if(!Test.isRunningTest()){
                if(Date.today().month() >= 10){
                    expDate = Date.newInstance(Date.today().year()+1,12,31);
                }else{
                    expDate = Date.newInstance(Date.today().year(),12,31);
                }

                //  part of 'Membership Renewal'
                renewalExpDateTime = af.Renewal_End_Date__c;
                renewalStartDateTime = af.Renewal_Start_Date__c;
                //  part of 'Membership Renewal': if it is not 'Student' then 'Membership_Status' record will be created from a Lightning Flow
                if (af.Membership__c != studentMemberhipId && (renewalExpDateTime != null || renewalStartDateTime != null)) continue;

            } else {
                expDate = Date.newInstance(Date.today().year()+1,12,31);
            }
            if(af.Form_Status__c == 'Approved'){
                mca.add(new MembershipContactAssotiation__c(
                    Contact__c = af.Contact__c, Membership__c = af.Membership__c, Application_form__c = af.Id,
                    Start_Date__c = renewalStartDateTime != null ? renewalStartDateTime : Date.today(),   //  part of 'Membership Renewal'
                    Expiration_date__c = renewalExpDateTime != null ? renewalExpDateTime : expDate,       //  changed for 'Membership Renewal'
                    Assignment_date__c = Date.today())
                );
            }
        }
        if(!mca.isEmpty()){
            insert mca;
        }
    }
    public static void documentsMissingEmailCheck(List<Application_form__c> updatedFormsOld, List<Application_form__c> updatedFormsNew){
        List<String> sendEmailRecords = new List<String>();
        for(Integer i = 0; i<updatedFormsNew.size(); i++){
            if(updatedFormsNew[i].Form_Status__c == 'Further Information Required' && updatedFormsNew[i].Form_Status__c != updatedFormsOld[i].Form_Status__c){
                if(Approval.isLocked(updatedFormsNew[i].Id)){
                    sendEmailRecords.add(updatedFormsNew[i].Id);
                }
            }
        }
        System.debug('sendEmailRecords:: '+!sendEmailRecords.isEmpty());
        if(!sendEmailRecords.isEmpty()){
            sendEmail(sendEmailRecords, 'Documents_are_missing');
        }
    }
    @Future public static void sendEmail(List<String> ids, String templateDeveloperName){
        try{
            List<Application_form__c> appsForms = [SELECT Id, Contact__c FROM Application_form__c WHERE Id IN : ids];
            List<EmailTemplate> ets = [
                    SELECT Id, Name, DeveloperName
                    FROM EmailTemplate
                    WHERE DeveloperName = :templateDeveloperName
            ];
            System.debug('ETS:: '+ets);
            OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'membership@ean.org' LIMIT 1];
            System.debug('address!!!: '+address);
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for(Application_form__c af : appsForms){
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(ets[0].Id, af.Contact__c, af.Id);
                String emailTextBody = message.getPlainTextBody();
                message.setTargetObjectId(af.Contact__c);
                message.setPlainTextBody(emailTextBody);
                message.saveAsActivity = false;
                message.setOrgWideEmailAddressId(address.Id);
                emails.add(message);
            }
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        } catch (Exception e) {
            System.debug('FUTURE_ERROR: '+e.getMessage());
            Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
            errorEmail.setSubject('Documents Missing Error Email');
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
    public static void rejectionLetterEmailCheck(List<Application_form__c> updatedFormsOld, List<Application_form__c> updatedFormsNew){
        List<String> sendEmailRecords = new List<String>();
        List<String> sendFEANEmailRecords = new List<String>();
        List<Id> membershipIds = new List<Id>();

        for(Application_form__c appForm : updatedFormsNew){
            membershipIds.add(appForm.Membership__c);
        }

        Map<Id, Membership__c> memberships = new Map<Id, Membership__c>([SELECT Id, API__c FROM Membership__c WHERE Id IN : membershipIds]);

        for(Integer i = 0; i<updatedFormsNew.size(); i++){
            if(updatedFormsNew[i].Form_Status__c == 'Declined' && updatedFormsNew[i].Form_Status__c != updatedFormsOld[i].Form_Status__c){
                if(Approval.isLocked(updatedFormsNew[i].Id)){
                    if(memberships.get(updatedFormsNew[i].Membership__c).API__c == 'fellow_membership'){
                        sendFEANEmailRecords.add(updatedFormsNew[i].Id);
                    } else {
                        sendEmailRecords.add(updatedFormsNew[i].Id);
                    }
                }
            }
        }

        if(!sendEmailRecords.isEmpty()){
            System.debug('sendEmailRecords: '+sendEmailRecords);
            sendEmail(sendEmailRecords, 'Rejection_Letter');
        }

        if(!sendFEANEmailRecords.isEmpty()){
            System.debug('sendFEANEmailRecords: '+sendFEANEmailRecords);
            sendEmail(sendFEANEmailRecords, 'Rejection_Letter_FEAN');
        }
    }
}