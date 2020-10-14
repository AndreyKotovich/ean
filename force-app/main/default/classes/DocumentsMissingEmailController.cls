public with sharing class DocumentsMissingEmailController {
    public Application_form__c appForm {get{
        return appForm.Id==null? new Application_form__c():[SELECT Id, Name, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Title, Membership__r.Name FROM Application_form__c WHERE Id = :appForm.Id];
    } set;}
    public String approvalComment {get{
        if(appForm.Id!=null){
            List<ProcessInstance> recordInstances = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =:appForm.Id ORDER BY CreatedDate DESC];
            List<ProcessInstanceStep> instancesSteps = [SELECT Comments, ProcessInstanceId, CreatedDate, OriginalActorId FROM ProcessInstanceStep WHERE ProcessInstanceId =:recordInstances[0].Id ORDER BY CreatedDate DESC];
            return instancesSteps[0].Comments;
        } else {
            return null;
        }
    }set;}
    public String communityUrl{get{
        if(Test.isRunningTest()) return 'community.com';
        List<Network> myNetwork = [SELECT Id FROM Network WHERE Name = 'ean'];
        if(!myNetwork.isEmpty() && appForm.Id!=null){
            ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork[0].Id);
            return myCommunity.siteUrl + '/s/detail/'+appForm.Id;
        } else {
            return 'ean.org';
        }
    } set;}
}