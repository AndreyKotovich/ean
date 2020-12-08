public without sharing class CustomLookUpController {
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

    @AuraEnabled
    public static Contact createContact(String FirstNameString, String LastNameString, String EmailString, String Department, String City, String Country){
        User u;

        if([SELECT Id, IsSandbox, Name FROM Organization LIMIT 1].IsSandbox){
            u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        } else {
            List<User> users = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE];

            for(User user : users){
                if(user.Name == 'EAN System Administrator'){
                    u = user;
                }
            }

            if(u == null){
                u = users[0];
            }
        }

        Contact con = new Contact(
            FirstName = FirstNameString, 
            LastName = LastNameString, 
            Email = EmailString, 
            Department_Name__c = Department, 
            MailingCity = City, 
            MailingCountry = Country,
            deleted1__c = true,
            OwnerId = u.Id
        );

        insert con;

        con = [SELECT Id, Name, deleted1__c FROM Contact WHERE Id =: con.Id].get(0);

        return con;
    }

    @AuraEnabled
    public static List<String> getMailingCountries(){
        List<String> countries = new List<String>();
        try{
            Schema.sObjectType objType = Contact.getSObjectType();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            List<Schema.PicklistEntry> values = fieldMap.get('MailingCountryCode').getDescribe().getPickListValues();

            for (Schema.PicklistEntry v : values){
                countries.add(v.getLabel());
            }
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        

        return countries;
    }

    @AuraEnabled
    public static Contact getContact(String abstractId){
        Abstract__c abstractRec = [SELECT Abstract_Presenter__c FROM Abstract__c WHERE Id =: abstractId].get(0);

        List<Contact> contacts = [SELECT Id, Name FROM COntact WHERE Id =: abstractRec.Abstract_Presenter__c];
        
        if(contacts.size() > 0){
            return contacts.get(0);
        }else{
            return null;
        }
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