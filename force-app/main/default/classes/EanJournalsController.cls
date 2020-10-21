public with sharing class EanJournalsController {
    @AuraEnabled public static List<Product2> getProduct2s() {
        List<Product2> product2s = [
                SELECT Id, Name, Product_use__c, IsActive, Description,
                (
                        SELECT Id, Name, UnitPrice, Pricebook2.Name
                        FROM PricebookEntries
                        WHERE Pricebook2.IsActive = TRUE
                )
                FROM Product2
                WHERE Product_use__c INCLUDES ('Membership Application')
                AND IsActive = TRUE
        ];
        return product2s;
    }
}