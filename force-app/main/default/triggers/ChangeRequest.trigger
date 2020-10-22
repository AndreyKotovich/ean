trigger ChangeRequest on Change_Request__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter) {
        ChangeRequestHelper.createChangeRequestOrder(Trigger.new);
        String objectApiName = 'Change_Request__c';
        String rejectTemplateDevName = 'EAN_ChangeRequestRejected';
        String approveTemplateDevName = 'EAN_ChangeRequestApproved';

        Map<String, List<String>> contactIdToRejectedChangeRequestIdsMap = new Map<String, List<String>>();
        Map<String, List<String>> contactIdToApprovedChangeRequestIdsMap = new Map<String, List<String>>();
        for (Change_Request__c changeRequest : Trigger.new) {
                if (changeRequest.Status__c == 'Rejected' && Trigger.oldMap.get(changeRequest.Id).Status__c != changeRequest.Status__c) {
                    if (contactIdToRejectedChangeRequestIdsMap.containsKey(changeRequest.Contact__c) == false) {
                        contactIdToRejectedChangeRequestIdsMap.put(changeRequest.Contact__c, new List<String>());
                    }
                    contactIdToRejectedChangeRequestIdsMap.get(changeRequest.Contact__c).add(changeRequest.Id);
                }
            if (changeRequest.Status__c == 'Approved' && Trigger.oldMap.get(changeRequest.Id).Status__c != changeRequest.Status__c) {
                if (contactIdToApprovedChangeRequestIdsMap.containsKey(changeRequest.Contact__c) == false) {
                    contactIdToApprovedChangeRequestIdsMap.put(changeRequest.Contact__c, new List<String>());
                }
                contactIdToApprovedChangeRequestIdsMap.get(changeRequest.Contact__c).add(changeRequest.Id);
            }

        }
        System.debug(contactIdToRejectedChangeRequestIdsMap.size());
        System.debug(contactIdToRejectedChangeRequestIdsMap);
        for (String rejectedContactId : contactIdToRejectedChangeRequestIdsMap.keySet()) {
            Map<String, Object> rejectedEmailOptionsMap = new Map<String, Object>();
            rejectedEmailOptionsMap.put('recordIds', contactIdToRejectedChangeRequestIdsMap.get(rejectedContactId));
            rejectedEmailOptionsMap.put('objectApiName', objectApiName);
            rejectedEmailOptionsMap.put('emailTemplateDevName', rejectTemplateDevName);
            rejectedEmailOptionsMap.put('contactId', rejectedContactId);
            try {
                EAN_EmailController.sendEmail(rejectedEmailOptionsMap);
            } catch(Exception error) {
                System.debug(error.getMessage());
            }
            
        }
                System.debug(contactIdToApprovedChangeRequestIdsMap.size());
        System.debug(contactIdToApprovedChangeRequestIdsMap);
        for (String approvedContactId : contactIdToApprovedChangeRequestIdsMap.keySet()) {
            Map<String, Object> approvedEmailOptionsMap = new Map<String, Object>();
            approvedEmailOptionsMap.put('recordIds', contactIdToApprovedChangeRequestIdsMap.get(approvedContactId));
            approvedEmailOptionsMap.put('objectApiName', objectApiName);
            approvedEmailOptionsMap.put('emailTemplateDevName', approveTemplateDevName);
            approvedEmailOptionsMap.put('contactId', approvedContactId);
            for (String key : approvedEmailOptionsMap.KeySet()){
                System.debug(key);
                System.debug(approvedEmailOptionsMap.get(key));
            }
            
            try {
                EAN_EmailController.sendEmail(approvedEmailOptionsMap);
            } catch(Exception error) {
                System.debug(error.getMessage());
            }
        }
    }
}