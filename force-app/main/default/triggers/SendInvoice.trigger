trigger SendInvoice on Order__c (before update, after update, after insert) {
    //Generating invoice number
    if (Trigger.isBefore && Trigger.isUpdate) {
        List<Order__c> paidEventOrders = new List<Order__c>();
        for (Order__c order : Trigger.new) {
            if (order.Type__c == 'Event registration'
                && order.Status__c == 'Paid'
                && Trigger.oldMap.get(order.Id).Status__c != order.Status__c
                && String.isBlank(order.Invoice_Number__c)) {
                    paidEventOrders.add(order);
                }
        }
        if (paidEventOrders.size() > 0) {
            InvoicePDFGenerator.generateEventInvoiceNumber(paidEventOrders);
        }
    }
    //Sending PDF Invoices
    if (Trigger.isUpdate && Trigger.isAfter) {
        Set<Id> orderIds = Trigger.newMap.keySet();
        List<Id> eventOrderIds = new List<Id>();
        List<Id> membershipOrderIds = new List<Id>();
        List<Id> soloEventRegOrderBTIds = new List<Id>();
        List<Id> soloEventRegOrderPaidIds = new List<Id>();
        List<Id> groupEventRegOrderPaidIds = new List<Id>();
        for (Id i : orderIds) {

            String orderType = Trigger.newMap.get(i).Type__c;

            // Check if the Status was changed to Paid
            if (Trigger.newMap.get(i).Status__c == 'Paid' && Trigger.oldMap.get(i).Status__c != 'Paid') {

                //  old logic without field Type__c: String.isBlank(orderType)
                if (String.isBlank(orderType) || orderType == 'Membership' || orderType == 'Renewal') {
                    membershipOrderIds.add(i);
                }

                //  type 'Upgrade' ???z
                if (orderType == 'Event registration') {
                    eventOrderIds.add(i);
                    if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)) {
                            soloEventRegOrderPaidIds.add(i);
                    } else if (String.isNotBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                        && Trigger.newMap.get(i).Payment_Method__c == 'Bank Transfer') {
                            groupEventRegOrderPaidIds.add(i);
                    }
                }
            } else if (Trigger.newMap.get(i).Status__c == 'Opened' 
                        && Trigger.oldMap.get(i).Status__c != Trigger.newMap.get(i).Status__c) {
                if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Payment_Method__c == 'Bank Transfer'
                    && Trigger.newMap.get(i).Type__c == 'Event registration') {
                        soloEventRegOrderBTIds.add(i);
                }
            } else if (Trigger.newMap.get(i).Payment_Method__c == 'Bank Transfer' 
                        && Trigger.oldMap.get(i).Payment_Method__c != Trigger.newMap.get(i).Payment_Method__c) {
                if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Opened'
                    && Trigger.newMap.get(i).Type__c == 'Event registration') {
                        soloEventRegOrderBTIds.add(i);
                } else if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Paid'
                    && Trigger.newMap.get(i).Type__c == 'Event registration') {
                        soloEventRegOrderPaidIds.add(i);
                } else if (String.isNotBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Paid'
                    && Trigger.newMap.get(i).Type__c == 'Event registration') {
                        groupEventRegOrderPaidIds.add(i);
                }
            } else if (Trigger.newMap.get(i).Type__c == 'Event registration' 
                        && Trigger.oldMap.get(i).Type__c != Trigger.newMap.get(i).Type__c) {
                if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Opened'
                    && Trigger.newMap.get(i).Payment_Method__c == 'Bank Transfer') {
                        soloEventRegOrderBTIds.add(i);
                } else if (String.isBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Paid') {
                        soloEventRegOrderPaidIds.add(i);
                } else if (String.isNotBlank(Trigger.newMap.get(i).Event_Registration_Sub_Group__c)
                    && Trigger.newMap.get(i).Status__c == 'Paid'
                    && Trigger.newMap.get(i).Payment_Method__c == 'Bank Transfer') {
                        groupEventRegOrderPaidIds.add(i);
                }
            }
        }

        if (!membershipOrderIds.isEmpty()){
            InvoicePDFGenerator.generateInvoicePDFs(membershipOrderIds);
        }
        if (!eventOrderIds.isEmpty()) {
            InvoicePDFGenerator.updateParticipantsStatus(eventOrderIds);
        }
        if (!soloEventRegOrderBTIds.isEmpty()) {
            InvoicePDFGenerator.sendInvoiceSoloRegBT(soloEventRegOrderBTIds);
        }
        if (!soloEventRegOrderPaidIds.isEmpty()) {
            InvoicePDFGenerator.sendEmailOrderPaidSoloReg(soloEventRegOrderPaidIds);
        }
        if (!groupEventRegOrderPaidIds.isEmpty()) {
            InvoicePDFGenerator.sendEmailOrderPaidGroupRegBT(groupEventRegOrderPaidIds);
        }
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        List<String> openedOrderIds = new List<String>();
        for (Order__c order : Trigger.new) {
            if (order.Status__c == 'Opened'
            && order.Type__c == 'Event registration') {
                openedOrderIds.add(order.Id);
            }
        }
        if (openedOrderIds.size() > 0) {
            Utils.startOrderReminder();
        }
    }
}