public with sharing class RejectionLetterEmailController {
    public Application_form__c appForm {get{
        return appForm.Id==null? new Application_form__c():
                [
                        SELECT Id, Name, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Title,
                                Membership__r.Name, Membership__r.API__c, Membership__r.Reviewer__r.Salutation,
                                Membership__r.Reviewer__r.Name, Membership__r.Reviewer__r.Reviewer_Title__c, Order__r.Name
                        FROM Application_form__c
                        WHERE Id = :appForm.Id
                ];
    }set;}
    public Contact defaultSecretaryGeneral {get{
        List<GroupChatterGroupAssotiation__c>  groupMemberships = [
                SELECT Id, Contact__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Role__c = 'Secretary general' AND
                Group__r.RecordType.Name = 'Level 1 Board (EAN Board)'
        ];
        Contact contact = new Contact();
        if(!groupMemberships.isEmpty()){
            contact = [SELECT Id, Salutation, Name, Title, Reviewer_Title__c FROM Contact WHERE Id = :groupMemberships[0].Contact__c];
        }
        return contact;
    } set;}
}