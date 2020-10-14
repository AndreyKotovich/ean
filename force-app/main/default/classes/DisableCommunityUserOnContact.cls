public class DisableCommunityUserOnContact {
    @InvocableMethod public static void checkUncheckCommunityUser(List<Id> ContactIds) {
        checkUncheckCommunityUserFuture(ContactIds);
    }
    @future(callout=true) public static void checkUncheckCommunityUserFuture(List<Id> ContactIds) {
        List<Contact> cs = [SELECT IsCommunityUser__c FROM Contact WHERE Id IN :ContactIds];
        for (Contact c : cs) {
            c.IsCommunityUser__c = !c.IsCommunityUser__c;
        }
        update cs;
    }
}