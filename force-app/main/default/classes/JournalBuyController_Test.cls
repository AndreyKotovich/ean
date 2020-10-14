@IsTest
public with sharing class JournalBuyController_Test {
    @IsTest public static void getProduct2sTest() {
        // Create a Pricebook
        Pricebook2 priceBook = new Pricebook2(
                Name = 'Membership Application',
                Description = 'This pricebook used by membership application.',
                IsActive = true
        );
        insert priceBook;
        // Create a Product
        Product2 product = new Product2(
                Name = 'European Journal of Neurology',
                Description = 'This year\'s complete printed volume of the European Journal of Neurology will be sent to the address above. The Journal cannot be delivered to addresses that are incomplete.',
                Product_use__c = 'Membership Application',
                IsActive = true
        );
        insert product;
        // Get the Standard Price Book ID
        Pricebook2 standardPriceBook = new Pricebook2(Id = Test.getStandardPricebookId());
        // Insert the Product in the Standard Price Book (if necessary)
        PricebookEntry standardPriceBookEntry = new PricebookEntry(
                Pricebook2Id = standardPriceBook.Id,
                Product2Id = product.Id,
                UnitPrice = 75.00,
                UseStandardPrice = false,
                IsActive = true
        );
        insert standardPriceBookEntry;
        // Insert the Product in the New Price Book
        PricebookEntry priceBookEntry = new PricebookEntry(
                Pricebook2Id = priceBook.Id,
                Product2Id = product.Id,
                UnitPrice = 75.00,
                UseStandardPrice = false,
                IsActive = true
        );
        insert priceBookEntry;

        List<Product2> product2s = JournalBuyController.getProduct2s();
        System.assertEquals(1, product2s.size());
        System.assertEquals(product.Id, product2s[0].Id);
    }
    @IsTest public static void getContactExceptionTest() {
        try {
            JournalBuyController.getContact();
        } catch (Exception e) {
            System.assertEquals('You do not have a contact', e.getMessage());
        }
    }
    @IsTest public static void getContactTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account account = new Account(Name = 'Individuals (Contacts)');
        insert account;
        Contact contact = new Contact(Lastname = 'Test Contact', AccountId = account.Id);
        insert contact;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'].Id;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        System.runAs(user) {
            Contact contact2 = JournalBuyController.getContact();
            System.assertEquals(contact2.Id, contact.Id);
        }
    }
}