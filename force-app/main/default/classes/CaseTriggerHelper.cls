public with sharing class CaseTriggerHelper {
    public static void postRecordsTo45kBrains(List<Case> newCases, List<Case> oldCases){
        List<Id> parsedCases = get45kBrainsApprovedCases(newCases, oldCases);
        List<Network> community = [SELECT Id FROM Network WHERE Name = 'ean' LIMIT 1];
        if(!community.isEmpty()) {
            List<CollaborationGroup> chatterGroup = new List<CollaborationGroup>();
            if(Test.isRunningTest()){
                chatterGroup = [
                        SELECT Id
                        FROM CollaborationGroup
                        WHERE Name = '45,000 Brains - Neurology Case Forum_1'
                        LIMIT 1
                ]; //find chatter group to do post
            } else {
                chatterGroup = [
                        SELECT Id
                        FROM CollaborationGroup
                        WHERE Name = '45,000 Brains - Neurology Case Forum'
                        AND NetworkId = :community[0].Id
                        LIMIT 1
                ]; //find chatter group to do post
            }

            if (!chatterGroup.isEmpty()) {
                List<List<Id>> lists = new List<List<Id>>();
                List<Id> subList = new List<Id>();
                Decimal parsedCasesSize = parsedCases.size();

                for (Integer i = 0; i < parsedCasesSize; i++) {
                    subList.add(parsedCases[i]);

                    if (subList.size() == 30 || i == parsedCasesSize - 1) {
                        lists.add(subList);
                        subList = new List<Id>();
                    }

                }

                for (Integer i = 0; i < lists.size(); i++) {
                    ChatterGroupPoster.postChatterQuestionFromCase(lists[i], chatterGroup[0].Id, community[0].Id);
                }

            }
        }
    }

    public static List<Id> get45kBrainsApprovedCases(List<Case> newCases, List<Case> oldCases){
        RecordType challengingSubmissionRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'Challenging_Case_Submission'];
        List<Id> submittedCases = new List<Id>();

        for(Integer i = 0; i<newCases.size(); i++){
            if(oldCases[i].Status != 'Accepted' && newCases[i].Status == 'Accepted' && newCases[i].RecordTypeId == challengingSubmissionRecordType.Id){
                submittedCases.add(newCases[i].Id);
            }
        }

        return submittedCases;
    }
}