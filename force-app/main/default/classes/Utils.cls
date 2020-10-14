public with sharing class Utils {

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getUserMemberships(){

        User currentUser = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];

        return getContactMemberships(currentUser.ContactId);

    }

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getContactMemberships(String contactId){

        List<MembershipContactAssotiation__c> contactsMemberships = [
                SELECT Id, Membership__r.Name, Membership__r.API__c, CreatedDate
                FROM MembershipContactAssotiation__c
                WHERE Contact__c = :contactId
                AND IsActive__c = TRUE
                ORDER BY CreatedDate DESC
        ];

        return contactsMemberships;
    }

}