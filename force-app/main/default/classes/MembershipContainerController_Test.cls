@IsTest
public with sharing class MembershipContainerController_Test {
    @IsTest public static void getCurrentContactMembershipsTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account acc = new Account(Name = 'Individuals (Contacts)');
        insert acc;
        Contact c = new Contact(LastName='Test', AccountId= acc.Id);
        insert c;
        Id cclu = [SELECT Id FROM profile WHERE Name = 'Customer Community Login User'].Id;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'Belarus', IsActive = true,
                ContactId = c.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        Membership__c m = new Membership__c(Name='Test', API__c='Test');
        insert m;
        MembershipContactAssotiation__c mca = new MembershipContactAssotiation__c(Membership__c = m.Id, Contact__c=c.Id, Expiration_date__c= Datetime.now().addDays(15));
        insert mca;
        System.runAs(user) {
            String result = MembershipContainerController.getCurrentContactMemberships();
            Map<String, Object> mapResult = (Map<String, Object>) JSON.deserializeUntyped(result);
            List<Object> memberships= (List<Object>) JSON.deserializeUntyped(JSON.serialize(mapResult.get('memberships')));
            MembershipContactAssotiation__c mapObject  = (MembershipContactAssotiation__c) JSON.deserialize(JSON.serialize(memberships[0]), MembershipContactAssotiation__c.class);
            System.assertEquals(mapObject.Membership__r.Name, m.Name);
            System.assertEquals(mapObject.Id, mca.Id);
            System.assertEquals('[]',JSON.serialize(mapResult.get('app-forms')));
        }
    }

}