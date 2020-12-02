public with sharing class MassPrintBadgesController {

    private ApexPages.StandardSetController standardController;
    public List<String> selectedIds {get; set;}
    public String redirectUrl {get{
        return Url.getOrgDomainUrl().toExternalForm() + '/c/BadgeApp.app?id=' + String.join(selectedIds, ',');
    }set;}

    public MassPrintBadgesController (ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        List<Event_Badge__c> selectedBadges = (List<Event_Badge__c>) standardController.getSelected();
        List<String> selectedIds = new List<String>();
        for (Event_Badge__c badge : selectedBadges) selectedIds.add('' + badge.Id);
        this.selectedIds = selectedIds;
    }
}