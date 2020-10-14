public with sharing class RedirectToPaymentController {
    @AuraEnabled public static Order__c getOrder(String applicationFormId){
        List<Application_form__c> applicationForm = [SELECT Id, Order__c FROM Application_form__c WHERE Id = :applicationFormId];
        if(!applicationForm.isEmpty()){
            List<Order__c> order = [SELECT Id, Status__c FROM Order__c WHERE Id = :applicationForm[0].Order__c];
            if(!order.isEmpty()){
                return order[0];
            } else {
                return null;
            }
        }
        return null;
    }
}