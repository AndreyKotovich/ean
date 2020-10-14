public with sharing class JournalBuyController {
    @AuraEnabled public static List<Product2> getProduct2s(){
        List<Product2> product2s = [SELECT Id, Name, Product_use__c, IsActive, Description, (SELECT Id, Name, UnitPrice, Pricebook2.Name FROM PricebookEntries WHERE Pricebook2.IsActive=true) FROM Product2 WHERE Product_use__c INCLUDES ('Membership Application') AND IsActive = true];
        return product2s;
    }
    @AuraEnabled public static Contact getContact(){
        User user = [SELECT ContactId FROM User WHERE Id=:UserInfo.getUserId()];
        List<Contact> contact = [SELECT Id FROM Contact WHERE Id = :user.ContactId];
        if(!contact.isEmpty()){
            return contact[0];
        }else{
            throw new AuraException('You do not have a contact');
        }
    }
}