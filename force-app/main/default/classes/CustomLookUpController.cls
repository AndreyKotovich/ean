public class CustomLookUpController {
    @AuraEnabled
    public static List<Contact> fetchLookUpValues(String searchKeyWord) {
        String searchKey = '%' + searchKeyWord + '%';
        
        List<Contact> returnList = new List<Contact>();
        List<Id> ids = new List<Id>();

        String sQuery;
        if(searchKeyWord == ''){
            // get recent contacts 
            sQuery = 'SELECT Id FROM RecentlyViewed WHERE  Type = \'Contact\' ORDER BY LastViewedDate DESC Limit 5';
            List<SObject> objects = Database.query(sQuery);
            List<Id> conIds = new List<Id>();
            for(SObject obj : objects){
                conIds.add(obj.Id);
            }
            sQuery = 'SELECT Id, Name, Account.Name, Email, Department_Name__c, MailingAddress, deleted1__c FROM Contact WHERE Id IN: conIds';
        }else{
            // get contacts by searchKeyWord
            sQuery =  'SELECT Id, Name, Account.Name, Email, Department_Name__c, MailingAddress, deleted1__c FROM Contact WHERE Email LIKE: searchKey ORDER BY createdDate DESC limit 5';
        }
      
        List<Contact> lstOfRecords = (List<Contact>)Database.query(sQuery);
        
        for (Contact obj: lstOfRecords) {
            obj.deleted1__c = true; // flag to presenter submission count check - if count >= 3, false
            returnList.add(obj);
            ids.add(obj.Id);
        }

        if(ids.size() > 0){
            AggregateResult[] groupedResults = [
                SELECT 
                    COUNT(Id), Abstract_Presenter__c 
                FROM 
                    Abstract__c 
                WHERE 
                    Abstract_Presenter__c IN :ids 
                    AND 
                    RecordType.Name = 'Public Submission' 
                GROUP BY 
                    Abstract_Presenter__c
            ];
            if(groupedResults.size() > 0){
                updateList(returnList, groupedResults);
            }
        }

        return returnList;
    }

    private static void updateList(List<Contact> conList, AggregateResult[] groupedResults){
        if(groupedResults != null){
            for(Contact con : conList){
                boolean finded = false;
                for (AggregateResult ar : groupedResults){
                    if(con.Id == ar.get('Abstract_Presenter__c')){
                        boolean checked = ((Integer)ar.get('expr0')) < 3;
                        con.deleted1__c = checked;
                        finded = true;
                    }
                }
    
                if(finded){
                    finded = false;
                }else{
                    con.deleted1__c = true;
                }
            }
        }
    }
}