public with sharing class DownloadAbstractBookController {

    private ApexPages.StandardSetController standardController;
    public List<String> selectedIds {get; set;}
    public String redirectUrl {get; set;}
    public Boolean isRedirect {get; set;}

    public DownloadAbstractBookController (ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        List<Abstract__c> selectedAbstract = (List<Abstract__c>) standardController.getSelected();
        List<String> selectedIds = new List<String>();
        for (Abstract__c a : selectedAbstract) {
            selectedIds.add('' + a.Id);
        }
        this.selectedIds = selectedIds;
    }
    //AbstractBooksWord AbstractBooks AbstractBooksHtml
    public PageReference doWord() {
        String url = Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooksWord?type=AbstractStaff';
        if (this.selectedIds.size() > 0) {
            url += '?id=' + String.join(selectedIds, ',');
        }
        this.redirectUrl=url;
        this.isRedirect = true;
        return null;
    }

    public PageReference doPDF() {
        String url = Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooks?type=AbstractStaff';
        if (this.selectedIds.size() > 0) {
            url += '?id=' + String.join(selectedIds, ',');
        }
        this.redirectUrl=url;
        this.isRedirect = true;
        return null;
    }

    public PageReference doHTML() { 
        String url = Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooksHtml?type=AbstractStaff';
        if (this.selectedIds.size() > 0) {
            url += '?id=' + String.join(selectedIds, ',');
        }
        this.redirectUrl=url;
        this.isRedirect = true;
        return null;
    }
    

      // String url = Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooks?type=AbstractStaff';
        // if (this.selectedIds.size() > 0) {
        //     url += '?id=' + String.join(selectedIds, ',');
        // }
        
        // return url;
}