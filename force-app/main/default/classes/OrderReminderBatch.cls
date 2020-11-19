public without sharing class OrderReminderBatch implements Database.Batchable<Order__c>, Database.Stateful, Database.AllowsCallouts {
    public OrderReminderBatch() {

    }

    public List<Order__c> start(Database.BatchableContext bc) {
        Datetime currentDatetime = Datetime.newInstance(System.now().date(), Time.newInstance(0, 0, 0, 0));
        List<Order__c> remindOrders = [
            SELECT Id, Event_custom__c, Contact__r.Email, CreatedDate, Status__c
            FROM Order__c
            WHERE Status__c = 'Opened'
            AND Type__c = 'Event registration'
            AND CreatedDate >= :currentDatetime.addDays(-7)
            AND CreatedDate <= :currentDatetime.addDays(-6)
        ];
        List<Order__c> overdueOrders = [
            SELECT Id, Event_custom__c, Contact__r.Email, CreatedDate, Status__c
            FROM Order__c
            WHERE Status__c = 'Opened'
            AND Type__c = 'Event registration'
            AND CreatedDate >= :currentDatetime.addDays(-14)
            AND CreatedDate <= :currentDatetime.addDays(-13)
        ];
        List<Order__c> orders = new List<Order__c>();
        orders.addAll(remindOrders);
        orders.addAll(overdueOrders);
        return orders;
    }

    public void execute(Database.BatchableContext BC, List<Order__c> orders) {
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        List<Order__c> updateOrders = new List<Order__c>();
        for (Order__c order : orders) {
            if (order.CreatedDate.date().addDays(14) == Date.today()) {
                order.Status__c = 'overdue';
                updateOrders.add(order);
            } else if (order.CreatedDate.date().addDays(7) == Date.today()) {
                Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = order.Contact__c,
                Event_Custom__c = order.Event_custom__c,
                Order__c = order.Id,
                Send_To_Email__c = order.Contact__r.Email,
                Type__c = 'Open order reminder'
                );
                emailActivities.add(emailActivity);
            }
        }
        if (updateOrders.size() > 0) {
            update updateOrders;
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
        }
         
    }

    public void finish(Database.BatchableContext BC) {
        String jobName = 'Order Reminder';
        List<CronTrigger> orderReminderJobs = [SELECT Id
                                FROM CronTrigger
                                WHERE CronJobDetail.Name = :jobName];
        for (CronTrigger orderReminderJob : orderReminderJobs) {
            System.abortJob(orderReminderJob.Id);
        }
        System.scheduleBatch(new OrderReminderBatch(), jobName, 1400);
    }
}