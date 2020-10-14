public class JournalOrderConfirmationController {
    public Id contactId {get; set;}
    public Order__c order {get{
        return order.Id == null?new Order__c():[SELECT Id, Name, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Title FROM Order__c WHERE Id = :order.Id];
    } set;}
    public List<String> mailingAddress {get{
        List<Contact> contact = [SELECT Id, Selected_Mailing_Address__c FROM Contact WHERE Id = :order.Contact__c];
        return contact.isEmpty()?new List<String>{'none'}:contact[0].Selected_Mailing_Address__c.split('<br>');
    } set;}
    public String myEANProfileUrl {get{
        if(Test.isRunningTest()) return 'link.com';
        Network myNetwork = [SELECT Id FROM Network WHERE Name ='ean'];
        ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork.Id);
        return myCommunity.siteUrl + '/s/profile/' + UserInfo.getUserId();
    } set;}
}