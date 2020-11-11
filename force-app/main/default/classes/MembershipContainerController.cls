public with sharing class MembershipContainerController {
    @AuraEnabled public static String getCurrentContactMemberships(){
        List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        List<MembershipContactAssotiation__c> contactsMemberships = [SELECT Id, Expiration_date__c, Membership__r.Name, Membership__r.API__c, Renewal_Application_Form__c FROM MembershipContactAssotiation__c WHERE Contact__c=:currentUser[0].ContactId AND IsActive__c=true];
        List<Application_form__c> contactAppForms = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Contact__c=:currentUser[0].ContactId];

        // return JSON.serialize(new Map<String, List<Object>>{'app-forms'=>contactAppForms, 'memberships'=>contactsMemberships});

        Map<String, Object> renewalSettings = MembershipRenewalController.collectRenewalInfo(contactsMemberships);
        return JSON.serialize(new Map<String, Object>{'app-forms'=>contactAppForms, 'memberships'=>contactsMemberships, 'renewalSettings' => renewalSettings});
    }
}