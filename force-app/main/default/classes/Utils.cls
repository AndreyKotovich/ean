// public without sharing class Utils {
public with sharing class Utils {

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getUserMemberships(){

        User currentUser = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];

        return getContactMemberships(currentUser.ContactId);

    }

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getContactMemberships(String contactId){

        List<MembershipContactAssotiation__c> contactsMemberships = [
                SELECT Id, Membership__r.Name, Membership__r.API__c, CreatedDate
                FROM MembershipContactAssotiation__c
                WHERE Contact__c = :contactId
                AND IsActive__c = TRUE
                ORDER BY CreatedDate DESC
        ];

        return contactsMemberships;
    }

    @AuraEnabled
    public static List<Map<String, String>> picklistValues(String objectName, String fieldName) {
        return picklistValues(objectName, fieldName, new Set<String>());
    }

    public static List<Map<String, String>> picklistValues(String objectName, String fieldName, Set<String> disabledValues) {
        List<Map<String, String>> values = new List<Map<String, String>>();
        List<String> types = new List<String>{objectName};
        List<Schema.DescribeSObjectResult> results = Schema.describeSObjects(types);
        for(Schema.DescribeSObjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {

                    String picklistValue = '' + entry.getValue();
                    String picklistLabel = '' + entry.getLabel();
                    if (disabledValues.contains(picklistValue) || disabledValues.contains(picklistLabel)) continue;

                    values.add(new Map<String, String>{'value' => picklistValue, 'label' => picklistLabel});
                }
            }
        }
        return values;
    }

    public static void insertSObjectsWithoutSharing(List<SObject> sbojects) {
        insert sbojects;
    }

    public static void startOrderReminder() {
        String jobName = 'Order Reminder';
        List<CronTrigger> waitingJobs = [SELECT Id, CronJobDetail.Name, NextFireTime, State
                                FROM CronTrigger
                                WHERE CronJobDetail.Name = :jobName];
        Boolean isBatchWorking = false;
        for (CronTrigger waitingJob : waitingJobs) {
            if (waitingJob.NextFireTime < System.now().addDays(1) 
            && waitingJob.NextFireTime > System.now().addSeconds(-30)
            && waitingJob.CronJobDetail.Name == jobName){
                isBatchWorking = true;
            } else if (waitingJob.CronJobDetail.Name == jobName){
                System.abortJob(waitingJob.Id);
            }
        }
        if (isBatchWorking == false) {
            System.scheduleBatch(new OrderReminderBatch(), jobName, 1400);
        }
    }

}