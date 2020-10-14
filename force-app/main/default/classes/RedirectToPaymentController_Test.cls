@IsTest
public with sharing class RedirectToPaymentController_Test {
    @IsTest public static void getOrderTest(){
        Order__c orderResult = RedirectToPaymentController.getOrder('id');
        System.assertEquals(null, orderResult);

        Membership__c membership = new Membership__c(Name='Test', API__c = 'test');
        insert membership;
        Contact contact = new Contact(LastName='Test');
        insert contact;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today(),
                Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = membership.Id,
                Profession__c = 'Other', Street__c = '123Street', Form_Status__c = 'Draft');
        insert appForm;
        orderResult = RedirectToPaymentController.getOrder(appForm.Id);
        System.assertEquals(null, orderResult);

        Order__c newOrder = new Order__c(Contact__c = contact.Id);
        insert newOrder;
        appForm.Order__c = newOrder.Id;
        update appForm;

        orderResult = RedirectToPaymentController.getOrder(appForm.Id);
        System.assertEquals(newOrder.Id, orderResult.Id);
    }

}