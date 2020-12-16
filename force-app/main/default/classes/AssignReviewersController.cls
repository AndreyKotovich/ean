public with sharing class AssignReviewersController {

    // @AuraEnabled
    // public static List<String> getTopics(){
    //     List<String> topics = new List<String>();

    //     Schema.sObjectType objType = Abstract__c.getSObjectType();
    //     Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
    //     Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
    //     List<Schema.PicklistEntry> values = fieldMap.get('Abstract_Topic__c').getDescribe().getPickListValues();

    //     for (Schema.PicklistEntry v : values){
    //         topics.add(v.getLabel());
    //     }

    //     return topics;
    // }
    
    @AuraEnabled
    public static Map<String, Map<String, List<String>>> getPickListValues(Map<String, List<String>> objectApiNameTofieldApiNameMap){
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Map<String, Map<String, List<String>>> resultsMap= new Map<String, Map<String, List<String>>>();
        for (String objectApiName : objectApiNameTofieldApiNameMap.keySet()) {
            if (globalDescribeMap.containsKey(objectApiName)) {
                Map<String, List<String>> pickListValuesMap= new Map<String, List<String>>();
                Map<String, Schema.SObjectField> objectFieldsMap = globalDescribeMap.get(objectApiName).getDescribe().fields.getMap();
                for (String fieldApiName : objectApiNameTofieldApiNameMap.get(objectApiName)) {
                    if (objectFieldsMap.containsKey(fieldApiName.toLowerCase())) {
                        List<String> pickListValues = new List<String>();
                        List<Schema.PicklistEntry> fieldResults = objectFieldsMap.get(fieldApiName.toLowerCase()).getDescribe().getPicklistValues();
                        for( Schema.PicklistEntry pickListValue : fieldResults){
                            pickListValues.add(pickListValue.getLabel());
                        }
                        pickListValuesMap.put(fieldApiName, pickListValues);
                    }
                }
                resultsMap.put(objectApiName, pickListValuesMap);
            }
        }
        return resultsMap;
    }

    @AuraEnabled
    public static List<Abstract__c> getAbstracts(String abstractTopic, String abstractType){
        List<Abstract__c> abstracts = new List<Abstract__c>();

        if(abstractTopic.length() == 0
            && abstractType.length() == 0){
            abstracts = [
                SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Abstract_Presenter__c, Abstract_Presenter__r.Email,  (SELECT Id FROM Abstract_Reviews__r)
                FROM Abstract__c 
                WHERE 
                    RecordType.Name = 'Public Submission'
                    AND 
                    Stage__c = 'Submitted'
                    AND 
                    Status__c = 'Pending'
            ];
        }else{
            String recordType = 'Public Submission';
            String stage = 'Submitted';
            String status = 'Pending';
            String query = 'SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Abstract_Presenter__c, Abstract_Presenter__r.Email,  (SELECT Id FROM Abstract_Reviews__r) FROM Abstract__c WHERE RecordType.Name = :recordType AND Stage__c = :stage AND Status__c = :status';
            if (String.isNotBlank(abstractTopic)) {
                query = query + ' AND Abstract_Topic__c = :abstractTopic';
            }
            if (String.isNotBlank(abstractType)) {
                query = query + ' AND Type__c = :abstractType';
            }
            abstracts = Database.query(query);
        }
        
        return abstracts;
    }

    @AuraEnabled
    public static List<Reviewer__c> getReviewers(Id abstractId){
        List<Reviewer__c> reviewers = new List<Reviewer__c>();

        Abstract__c abstractItem = [ 
            SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Abstract_Presenter__c,
                    Submitter__c,
            (
                    SELECT Id, Abstract_Author__c FROM Abstract_Authors__r
            )
            FROM Abstract__c WHERE Id =: abstractId
        ].get(0);

        Set<Id> excludedReviewerContacts = new Set<Id>();

        //Reviewer.Contact != Abstract.AbstractPresenter
        excludedReviewerContacts.add(abstractItem.Abstract_Presenter__c);
        //submitter cannot be a reviewer
        excludedReviewerContacts.add(abstractItem.Submitter__c);
        //Reviewer.Contact != Check all Abstract Authors.Contact for Abstract
        for(Abstract_Author__c author : abstractItem.Abstract_Authors__r){
            excludedReviewerContacts.add(author.Abstract_Author__c);
        }

        System.debug('excludedReviewerContacts: ' + excludedReviewerContacts);

        String queryString = 
            'SELECT Id, Name, Remaining_Capacity__c, Assigned_Abstracts__c, Event__c, Topics__c, Contact__c, Contact__r.Email, Contact__r.Name ' + 
            'FROM Reviewer__c ' + 
            'WHERE ' +
                'Id NOT IN (SELECT Reviewer__c FROM Abstract_Review__c WHERE Abstract__c = :abstractId) ' +
                'AND Remaining_Capacity__c > 0 ' +
                'AND Event__c = \'' + abstractItem.Event__c + '\' ' +
                'AND Contact__c NOT IN :excludedReviewerContacts ' +
                'AND Status__c = \'Accepted\' ';

        System.debug('abstractItem.Abstract_Topic__c ' + abstractItem.Abstract_Topic__c);
        if(abstractItem.Abstract_Topic__c != null){
            String[] topicsArray = abstractItem.Abstract_Topic__c.split(';');
            queryString += 'AND Topics__c INCLUDES(';

            for(String item : topicsArray){
                queryString += '\'' + item + '\',';
            }
            queryString = queryString.removeEnd(',') +')';
        }else{
            return reviewers;
        }
        System.debug('queryString ' + queryString);
        reviewers = (List<Reviewer__c>)Database.query(queryString);
        return reviewers;
    }

    @AuraEnabled
    public static List<Abstract_Author__c> getAuthorsData(String abstractId, String reviewerContactId, String reviewerContactEmail){
        List<Abstract_Author__c> authorsData = new List<Abstract_Author__c>();

        authorsData = [
            SELECT Id, Abstract_Author__c, Abstract_Author__r.Email
            FROM Abstract_Author__c
            WHERE
                Abstract__c =: abstractId
                AND (
                    Abstract_Author__c =: reviewerContactId 
                    OR 
                    Abstract_Author__r.Email =: reviewerContactEmail
                )
        ];

        return authorsData;
    }

    @AuraEnabled
    public static Map<String,Object> setAbstractRev(Map<String,String> generalData){
        System.debug('setAbstractRev generalData ' + generalData);
        try {
            List<Abstract_Review__c> ars = new List<Abstract_Review__c>();
            for (String key : generalData.keySet()) {
                ars.add(
                    new Abstract_Review__c(
                        Abstract__c = generalData.get(key),
                        Reviewer__c = key,
                        Stage__c = 'Assigned'
                    )
                );
            }
            
            insert ars;

            return new Map<String,Object> {
                'status' => 'Success',
                'message' => 'Reviewers appointed'
            };

        } catch (Exception e) {
            return new Map<String,Object> {
                'status' => 'Error',
                'message' => e.getMessage()
            };
        }
    }
}