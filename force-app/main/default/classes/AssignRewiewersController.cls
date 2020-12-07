public with sharing class AssignRewiewersController {

    @AuraEnabled
    public static List<String> getTopics(){
        List<String> topics = new List<String>();

        Schema.sObjectType objType = Abstract__c.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<Schema.PicklistEntry> values = fieldMap.get('Abstract_Topic__c').getDescribe().getPickListValues();

        for (Schema.PicklistEntry v : values){
            topics.add(v.getLabel());
        }

        return topics;
    }
    
    @AuraEnabled
    public static List<Abstract__c> getAbstracts(String abstractTopic){
        List<Abstract__c> abstracts = new List<Abstract__c>();

        if(abstractTopic.length() == 0){
            abstracts = [
                SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Topics__c, Abstract_Presenter__c, Abstract_Presenter__r.Email
                FROM Abstract__c 
                WHERE 
                    RecordType.Name = 'Public Submission'
                    AND 
                    Stage__c = 'Submitted'
                    AND 
                    Status__c = 'Pending'
            ];
        }else{
            abstracts = [
                SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Topics__c, Abstract_Presenter__c, Abstract_Presenter__r.Email
                FROM Abstract__c 
                WHERE 
                    RecordType.Name = 'Public Submission'
                    AND 
                    Stage__c = 'Submitted'
                    AND 
                    Status__c = 'Pending' 
                    AND 
                    Abstract_Topic__c =: abstractTopic
            ];
        }
        
        return abstracts;
    }

    @AuraEnabled
    public static List<Reviewer__c> getReviewers(Id abstractId){
        List<Reviewer__c> reviewers = new List<Reviewer__c>();

        Abstract__c abstractItem = [ 
            SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c, Event__c, Topics__c 
            FROM Abstract__c WHERE Id =: abstractId
        ].get(0);
        
        String queryString = 
            'SELECT Id, Name, Remaining_Capacity__c, Assigned_Abstracts__c, Event__c, Topics__c, Contact__c, Contact__r.Email ' + 
            'FROM Reviewer__c ' + 
            'WHERE ' +
                'Id NOT IN (SELECT Reviewer__c FROM Abstract_Review__c WHERE Abstract__c = \'' + abstractId + '\') AND ' +
                'Remaining_Capacity__c > 0 ' + 
                'AND ' + 
                'Event__c = \'' + abstractItem.Event__c + '\' ';
                
                
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