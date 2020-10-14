public without sharing class ApprovalCommentsController {
    @AuraEnabled public static Boolean sObjectCheck(Id recordId){
        if(recordId.getSobjectType().getDescribe().getName() == 'Application_form__c'){
            List<Application_form__c> appForm = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Id =:recordId];
            if(appForm[0].Form_Status__c == 'Further Information Required'){
                return true;
            }else {
                return false;
            }
        } else if(recordId.getSobjectType().getDescribe().getName() == 'Fellowship_Applications_Form__c'){
            List<Fellowship_Applications_Form__c> appForm = [SELECT Id, Approval_Status__c FROM Fellowship_Applications_Form__c WHERE Id =:recordId];
            if(appForm[0].Approval_Status__c == 'Further Information Required'){
                return true;
            }else {
                return false;
            }
        } else {
            return false;
        }
    }
    @AuraEnabled public static String getApprovalComments(Id recordId){
        List<ProcessInstance> recordInstances = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =:recordId ORDER BY CreatedDate DESC];
        List<ProcessInstanceStep> instancesSteps = [SELECT Comments, ProcessInstanceId, CreatedDate, OriginalActorId FROM ProcessInstanceStep WHERE ProcessInstanceId =:recordInstances[0].Id ORDER BY CreatedDate DESC];
        if(instancesSteps[0].Comments!=null){
            TimeZone tz = UserInfo.getTimeZone();
            List<User> approver = [SELECT Id, Name, SmallPhotoUrl FROM User WHERE Id=:instancesSteps[0].OriginalActorId];
            System.debug('instancesSteps:: '+instancesSteps[0]);
            Map<String, Object> approvalPost = new Map<String, Object>();
            approvalPost.put('comment', instancesSteps[0].Comments);
            approvalPost.put('approver', approver[0]);
            approvalPost.put('date', instancesSteps[0].CreatedDate.format('MM-dd-yyyy HH:mm:ss'));
            return JSON.serialize(approvalPost);
        } else {
            return 'none';
        }
    }

}