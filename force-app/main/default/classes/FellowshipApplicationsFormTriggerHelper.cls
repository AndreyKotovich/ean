public with sharing class FellowshipApplicationsFormTriggerHelper {
    public static void unlockRecords(List<Fellowship_Applications_Form__c> oldForms, List<Fellowship_Applications_Form__c> newForms){
        List<String> formsIdsToUnlock = new List<String>();
        for(Integer i=0; i<newForms.size(); i++){
            if(newForms[i].Approval_Status__c != oldForms[i].Approval_Status__c && newForms[i].Approval_Status__c == 'Further Information Required' && newForms[i].Id == oldForms[i].Id){
                formsIdsToUnlock.add(newForms[i].Id);
            }
        }
        if(!formsIdsToUnlock.isEmpty()){
            unlockInFuture(JSON.serialize(formsIdsToUnlock));
        }
    }
    @future public static void unlockInFuture(String ids){
        List<String> idsList = (List<String>) JSON.deserialize(ids, List<String>.class);
        Map<Id, Boolean> checkResult = Approval.isLocked(idsList);
        List<String> idsToUnlock = new List<String>();
        for(Id id : checkResult.keySet()){
            if(checkResult.get(id)){
                idsToUnlock.add(id);
            }
        }
        List<Approval.UnlockResult> lrList = Approval.unlock(idsToUnlock);
    }
}