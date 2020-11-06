trigger SendInvoice on Order__c (after update) {
    //Sending PDF Invoices
    if (Trigger.isUpdate && Trigger.isAfter) {
        Set<Id> orderIds = Trigger.newMap.keySet();
        List<Id> orderIdsToProcess = new List<Id>();
        List<Id> eventOrderIds = new List<Id>();
        List<Id> notEventsOrderIds = new List<Id>();
        for (Id i : orderIds) {
            // Check if the Status was changed to Paid
            if (Trigger.newMap.get(i).Status__c == 'Paid' && Trigger.oldMap.get(i).Status__c != 'Paid') {
                orderIdsToProcess.add(i);
                if (String.isNotBlank(Trigger.newMap.get(i).Type__c)) {
                    eventOrderIds.add(i);
                } else {
                    notEventsOrderIds.add(i);
                }
            }
        }
        if (!orderIdsToProcess.isEmpty()) {
            
            InvoicePDFGenerator.updateParticipantsStatus(orderIdsToProcess);
        }
        if (!notEventsOrderIds.isEmpty()){
            InvoicePDFGenerator.generateInvoicePDFs(notEventsOrderIds);
        }
        if (!eventOrderIds.isEmpty()) {
            InvoicePDFGenerator.insertEmailActivity(eventOrderIds);
        }
    }
}