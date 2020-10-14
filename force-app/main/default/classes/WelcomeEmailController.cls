public class WelcomeEmailController {
    public String membershipId { get; set; }
    public String membershipName { get; set ;}
    public String mStatusContactId { get; set; }
    public String userName;
    public Boolean showGeneralSecretary { get; set; }
    public Membership__c benefits { get; set; }
    public MembershipContactAssotiation__c memStatus { get{
        return memStatus.Id==null?new MembershipContactAssotiation__c():
                [SELECT Id, Contact__c, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Title,
                Membership__r.API__c, Membership__r.Name, Membership__r.Membership_Benefits__c, Membership__r.Reviewer__c, Membership__r.Reviewer__r.Salutation,
                Membership__r.Reviewer__r.Name, Membership__r.Reviewer__r.Reviewer_Title__c, Membership__r.Reviewer__r.Title, Application_form__r.Order__r.Name
                FROM MembershipContactAssotiation__c WHERE Id =:memStatus.Id];
    } set; }
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

    public String getuserName() {
        String name = '';
        List<User> users = [SELECT Username FROM User WHERE ContactId = :memStatus.Contact__c];
        if (!users.isEmpty()) {
            name = users[0].Username;
        }
        return name;
    }
}