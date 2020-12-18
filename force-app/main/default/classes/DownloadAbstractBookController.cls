public with sharing class DownloadAbstractBookController {

    private ApexPages.StandardSetController standardController;
    public List<String> selectedIds {get; set;}
    public String redirectUrl {get{
        String url = Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooks?type=AbstractStaff';
        if (this.selectedIds.size() > 0) {
            url += '?id=' + String.join(selectedIds, ',');
        }
        
        return url;
    }set;}

    public DownloadAbstractBookController (ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        List<Abstract__c> selectedAbstract = (List<Abstract__c>) standardController.getSelected();
        List<String> selectedIds = new List<String>();
        for (Abstract__c a : selectedAbstract) {
            selectedIds.add('' + a.Id);
        }
        this.selectedIds = selectedIds;
    }
}