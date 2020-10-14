public with sharing class ClinicalFellowshipApplicationController {
    @AuraEnabled public static Map<String, String> init(){
        Contact contact = new Contact();
        contact = getContact();
        Map<String, String> result = new Map<String, String>();
        result.put('contact', JSON.serialize(contact));
        result.put('record-type-id', getClinicalApplicationRTId());
        return result;
    }
    public static Contact getContact(){
        User user = [SELECT Contact.Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Contact> contact = [SELECT Id FROM Contact WHERE Id = :user.Contact.Id];
        if(!contact.isEmpty()){
            return contact[0];
        }else{
            throw new AuraException('User do not have a contact');
        }
    }
    public static String getClinicalApplicationRTId(){
        List<RecordType> recType = [SELECT Id
                                    FROM RecordType
                                    WHERE SObjectType = 'Fellowship_Applications_Form__c'
                                    AND DeveloperName = 'Clinical_Fellowship_Application_Form'];
        if(!recType.isEmpty()){
            return recType[0].Id;
        }else{
            throw new AuraException('ERROR_Record type not exist');
        }
    }
    @AuraEnabled public static Fellowship_Applications_Form__c createAppForm(Fellowship_Applications_Form__c fellForm){
        insert fellForm;
        return fellForm;
    }
    @AuraEnabled public static Boolean submitRecordForApproval(String recordId){
        String userId = UserInfo.getUserId();
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(recordId);
        req1.setSubmitterId(userId);
        Approval.ProcessResult result = Approval.process(req1);
        return result.isSuccess();
    }
}