public with sharing class membershipApplicationWrapper {
    @AuraEnabled public List<Membership__c> memberships { get; set; }
    @AuraEnabled public List<Country_Price__c> countryPrices { get; set; }
    @AuraEnabled public Contact contact { get; set; }
    @AuraEnabled public List<Contact_Form__mdt> fieldMap { get; set; }
    @AuraEnabled public List<Product2> availableProduct2s { get; set; }

    public membershipApplicationWrapper(
            List<Membership__c> memberships,
            List<Country_Price__c> countryPrices,
            Contact contact,
            List<Contact_Form__mdt> fieldMap,
            List<Product2> availableProduct2s) {
        this.memberships = memberships;
        this.countryPrices = countryPrices;
        this.contact = contact;
        this.fieldMap = fieldMap;
        this.availableProduct2s = availableProduct2s;
    }
}