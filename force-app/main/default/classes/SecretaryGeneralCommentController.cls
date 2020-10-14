public without sharing class SecretaryGeneralCommentController {
    @AuraEnabled public static void insertComment(Id recordId, String comment) {
        List<Profile> usersProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        System.debug(usersProfile);
        if (!usersProfile.isEmpty() && (usersProfile[0].Name == 'Secretary General' || usersProfile[0].Name == 'RRFS Reviewer')) {
            update new Application_form__c(Id = recordId, Comments__c = comment);
            try {
                 approveRecord(recordId);
            } catch (Exception e){
                System.debug(e.getMessage());
                throw new AuraException('Something went wrong, contact your system administrator');
            }
        } else {
            throw new AuraException('Something went wrong, contact your system administrator');
        }
    }
    public static void approveRecord(Id recordId){
        Id retVal = null;
        for(ProcessInstanceWorkitem workItem  : [SELECT p.Id FROM ProcessInstanceWorkitem p WHERE p.ProcessInstance.TargetObjectId =: recordId])
        {
            retVal  =  workItem.Id;
        }
        if(retVal!=null){
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setAction('Approve');
            req2.setWorkitemId(retVal);
            Approval.ProcessResult result2 =  Approval.process(req2);
        } else {
            throw new AuraException('Something went wrong, contact your system administrator');
        }
    }
    @AuraEnabled public static Map<String, Object> checkApprovalStep(Id recordId){
        List<ProcessInstance> procInst = [
                SELECT Id, Status, CreatedDate,
                (SELECT Id, StepStatus, ProcessNodeId, ProcessNode.DeveloperName, IsPending, CreatedDate
                FROM StepsAndWorkitems ORDER BY CreatedDate DESC) FROM ProcessInstance
                WHERE TargetObjectId =:recordId ORDER BY CreatedDate DESC
        ];
        List<ProcessInstanceHistory> procInstHist = new List<ProcessInstanceHistory>();
        if(procInst.isEmpty()) return new Map<String, Object>();
        for(ProcessInstanceHistory pih : procInst[0].StepsAndWorkitems){
            if(pih.StepStatus == 'Pending' && pih.ProcessNode.DeveloperName == 'SG_comment'){
                procInstHist.add(pih);
            }
        }
        if(!procInstHist.isEmpty()){
            return new Map<String, Object>{
                    'stepName'=>procInstHist[0].ProcessNode.DeveloperName,
                    'stepStatus'=>procInstHist[0].StepStatus
            };
        } else {
            return new Map<String, Object>();
        }
    }
}