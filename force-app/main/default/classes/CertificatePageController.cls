public class CertificatePageController {
    public String salutation { get; set; }
    public String memberName { get; set; }
    public String memberTitle { get; set; }
    public String nationality { get; set; }
    public String membershipName { get; set; }
    public String currentDate { get; set; }
    public String secretaryName { get; set; }
    public String secretaryPosition { get; set; }
    public String presidentName { get; set; }
    public Boolean isFellowMembership { get; set; }

    public String membershipDurationString { get; set; } // added with 'Membership Renewal'

    public CertificatePageController() {
        salutation = '';
        memberName = '';
        memberTitle = '';
        nationality = '';
        membershipName = '';
        currentDate = '';
        secretaryName = '';
        secretaryPosition = '';
        presidentName = '';
        isFellowMembership = false;

        String paramId =  ApexPages.currentPage().getParameters().get('ms');
        presidentName =  ApexPages.currentPage().getParameters().get('pn');
        presidentName = !String.isBlank(presidentName) ? presidentName : 'Prof. Claudio Bassetti';
        secretaryName =  ApexPages.currentPage().getParameters().get('sn');
        this.mergeAllInfo(paramId);
    }

    private void mergeAllInfo(String membershipStatusId) {
        MembershipContactAssotiation__c currentMS;

        List<MembershipContactAssotiation__c>  msList = [
                SELECT Id, Contact__r.Name, Contact__r.Salutation, Contact__r.Title, Contact__r.Residency__c,
                        Membership__r.Name, Membership__r.API__c,
                        Start_Date__c, Expiration_date__c   // added with 'Membership Renewal'
                FROM MembershipContactAssotiation__c
                WHERE Id = :membershipStatusId
        ];

        if (!msList.isEmpty()) {
            currentMS = msList[0];
            salutation = currentMS.Contact__r.Salutation;
            memberName = currentMS.Contact__r.Name;
            memberTitle = currentMS.Contact__r.Title;
            nationality = currentMS.Contact__r.Residency__c;
            membershipName = currentMS.Membership__r.Name;
            currentDate = Datetime.now().format('MMMM') + ' ' + Datetime.now().year();

            // added with 'Membership Renewal
            Datetime startDate = currentMS.Start_Date__c != null ? currentMS.Start_Date__c : Datetime.now();
            Datetime endDate = currentMS.Expiration_date__c != null ? currentMS.Expiration_date__c : Datetime.newInstance(startDate.year(), 12, 31, 23, 59, 69);
            membershipDurationString = startDate.format('MMMM') + ' ' + startDate.year() + ' - ' + endDate.format('MMMM') + ' ' + endDate.year();

            if (currentMS.Membership__r.API__c.containsIgnoreCase('fellow_membership')) {
                isFellowMembership = true;
            }
        }
    }
}