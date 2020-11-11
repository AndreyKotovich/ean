trigger SendInvoice on Order__c (after update) {
    //Sending PDF Invoices
    if (Trigger.isUpdate && Trigger.isAfter) {
        Set<Id> orderIds = Trigger.newMap.keySet();
        List<Id> eventOrderIds = new List<Id>();
        List<Id> membershipOrderIds = new List<Id>();
        for (Id i : orderIds) {

            String orderType = Trigger.newMap.get(i).Type__c;

            // Check if the Status was changed to Paid
            if (Trigger.newMap.get(i).Status__c == 'Paid' && Trigger.oldMap.get(i).Status__c != 'Paid') {

                //  old logic without field Type__c: String.isBlank(orderType)
                if (String.isBlank(orderType) || orderType == 'Membership' || orderType == 'Renewal') {
                    membershipOrderIds.add(i);
                }

                //  type 'Upgrade' ???
                if (orderType == 'Event registration') {
                    eventOrderIds.add(i);
                }
            }
        }

        if (!membershipOrderIds.isEmpty()){
            InvoicePDFGenerator.generateInvoicePDFs(membershipOrderIds);
        }
        if (!eventOrderIds.isEmpty()) {
            InvoicePDFGenerator.updateParticipantsStatus(eventOrderIds);
            InvoicePDFGenerator.insertEmailActivity(eventOrderIds);
        }
    }
}