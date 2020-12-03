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
                SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c
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
                SELECT Id, Name, Title__c, Abstract_Topic__c, Type__c, Stage__c, Status__c
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
}