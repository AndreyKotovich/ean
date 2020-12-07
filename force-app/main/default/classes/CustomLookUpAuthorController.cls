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
            sQuery =  'SELECT Id, Name, Account.Name, Email, Department_Name__c, MailingAddress FROM Contact WHERE Id NOT IN: selectedIds AND (Email LIKE: searchKey OR Name LIKE: searchKey) ORDER BY createdDate DESC limit 5';
        }

        return (List<Contact>)Database.query(sQuery);
    }

    @AuraEnabled
    public static Contact createContact(String FirstNameString, String LastNameString, String EmailString, String Department, String City, String Country){
        try{
            Contact con = new Contact(
                    FirstName = FirstNameString,
                    LastName = LastNameString,
                    Email = EmailString,
                    Department_Name__c = Department,
                    MailingCity = City,
                    MailingCountry = Country
            );

            insert con;

            con = [SELECT Id, Name FROM Contact WHERE Id =: con.Id].get(0);

            return con;
        } catch (Exception e) {
            String message = 'Something went wrong, please contact your system administrator';
            System.debug('The following exception has occurred: ' + e.getMessage() +' on line number: ' + e.getLineNumber() + e.getStackTraceString() + e.getCause());

            if(e.getMessage().contains('DUPLICATES_DETECTED')){
                message = 'Please review inserted data, looks like contact with similar data already exist';
            }

            AuraHandledException auraError = new AuraHandledException(message);
            auraError.setMessage(message);

            throw auraError;
        }
    }

    @AuraEnabled
    public static List<Contact> getContacts(String abstractId){
        List<Abstract_Author__c> abstractAuthors = [SELECT Abstract_Author__c FROM Abstract_Author__c WHERE Abstract__c =: abstractId];
        List<Id> ids = new List<Id>();

        for(Abstract_Author__c junction : abstractAuthors){
            ids.add(junction.Abstract_Author__c);
        }

        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id IN : ids];

        return contacts;
    }

    @AuraEnabled
    public static List<String> getMailingCountries(){
        List<String> countries = new List<String>();

        Schema.sObjectType objType = Contact.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<Schema.PicklistEntry> values = fieldMap.get('MailingCountryCode').getDescribe().getPickListValues();

        for (Schema.PicklistEntry v : values){
            countries.add(v.getLabel());
        }

        System.debug('countries: ' + countries);

        return countries;
    }
}