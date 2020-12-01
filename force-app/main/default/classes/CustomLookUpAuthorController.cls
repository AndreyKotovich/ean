public with sharing class CustomLookUpAuthorController {
    @AuraEnabled
    public static List<Contact> fetchLookUpValues(String searchKeyWord, String[] selectedIds) {
        String searchKey = '%' + searchKeyWord + '%';
        
        List<Id> ids = new List<Id>();

        String sQuery;
        if(searchKeyWord == ''){
            // get recent contacts 
            sQuery = 'SELECT Id FROM RecentlyViewed WHERE Type = \'Contact\' AND Id NOT IN: selectedIds ORDER BY LastViewedDate DESC Limit 5';
            List<SObject> objects = Database.query(sQuery);
            List<Id> conIds = new List<Id>();
            for(SObject obj : objects){
                conIds.add(obj.Id);
            }
            sQuery = 'SELECT Id, Name, Account.Name, Email, Department_Name__c, MailingAddress FROM Contact WHERE Id IN: conIds';
        }else{
            // get contacts by searchKeyWord
            sQuery =  'SELECT Id, Name, Account.Name, Email, Department_Name__c, MailingAddress FROM Contact WHERE Id NOT IN: selectedIds AND Email LIKE: searchKey ORDER BY createdDate DESC limit 5';
        }

        return (List<Contact>)Database.query(sQuery);
    }
}