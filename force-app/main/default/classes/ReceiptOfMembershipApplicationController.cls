public with sharing class ReceiptOfMembershipApplicationController {
    public Application_form__c appForm {get{
        return appForm.Id==null? new Application_form__c():[SELECT Id, Name, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Title FROM Application_form__c WHERE Id = :appForm.Id];
    }set;}
}