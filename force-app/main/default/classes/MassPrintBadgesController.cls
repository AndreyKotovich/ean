public with sharing class MassPrintBadgesController {

    private ApexPages.StandardSetController standardController;
    public List<String> selectedIds {get; set;}

    public MassPrintBadgesController (ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        List<Event_Badge__c> selectedBadges = (List<Event_Badge__c>) standardController.getSelected();
        List<String> selectedIds = new List<String>();
        for (Event_Badge__c badge : selectedBadges) selectedIds.add('' + badge.Id);
        this.selectedIds = selectedIds;
    }

    public PageReference urlRedirection() {
        String link = '';

        if(!this.selectedIds.isEmpty()){
            link = Url.getOrgDomainUrl().toExternalForm() + '/c/BadgeApp.app?id='+String.join(selectedIds, ',');
            PageReference page = new PageReference(link);
            page.setRedirect(true);
            return page;
        } else {
            return new ApexPages.Action('{!List}').invoke();
        }
    }
}