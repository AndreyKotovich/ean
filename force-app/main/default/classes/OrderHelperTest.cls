@isTest
public with sharing class OrderHelperTest {
    @isTest
    public static void createOrderTest() {
        Contact c = new Contact(LastName = 'test', Email = 'orderCreate@test.com', MailingStreet = 'TestStreet',
        MailingCity = 'TestCity', MailingPostalCode = '11111',
        MailingCountry = 'Germany');
        insert c;
        Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
        Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, 
            Start_Time__c = System.now().addDays(10), End_Time__c = System.now().addDays(20), Status__c = 'Scheduled');
        insert event;

        Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
        Participant__c p = new Participant__c(Contact__c = c.Id, Event_custom__c = event.Id, 
            RecordTypeId = congressParticipantRT, Status__c = 'Registered');
        insert p;
        
        Session__c session = new Session__c(Name = 'Test Session', Event_custom__c = event.Id, Type__c = 'Payable');
        insert session;

        Session_Participation__c sessionParticipation = new Session_Participation__c(Contact__c = c.Id, Session__c = session.Id, Status__c = 'Pending');
        insert sessionParticipation;

        List<Order__c> ords = OrderHelper.createNewOrder(
            new Map<String,Object> {
                'participantsPrice' => new List<Map<String,Object>> {
                    new Map<String,Object> {
                        'participant' => p,
                        'price' => 50
                    }
                },
                'sessionParticipantPrice' => new Map<String,Object> {
                    sessionParticipation.Id => new Map<String,Object> {
                        'id' => session.Id, 
                        'price' => 5
                    }
                },
                'generalData' =>  new Map<String,Object> {
                    'contactId' => c.Id,
                	'eventId' => event.Id
                }
            }
        );
        System.assertEquals(1, ords.size());
        List<Order__c> secondAttemptOrds = OrderHelper.createNewOrder(
            new Map<String,Object> {
                'participantsPrice' => new List<Map<String,Object>> {
                    new Map<String,Object> {
                        'participant' => p,
                        'price' => 50
                    }
                },
                'sessionParticipantPrice' => new Map<String,Object> {
                    sessionParticipation.Id => new Map<String,Object> {
                        'id' => session.Id, 
                        'price' => 5
                    }
                },
                'generalData' =>  new Map<String,Object> {
                    'contactId' => c.Id,
                	'eventId' => event.Id
                }
            }
        );
        System.assertEquals(2, secondAttemptOrds.size());
        
        List<Order__c> orders = [
        	SELECT 
                Id, Total_amount__c, Status__c, Contact__c, Invoice_Number__c, 
                (SELECT Id, Amount__c, Total_amount__c FROM Order_Items__r) 
         	FROM Order__c WHERE Id =: ords[0].Id 
        ];
        
        System.assertEquals(55, orders[0].Total_amount__c);
        // System.assertEquals('EAN' + String.valueOf(Date.today().year()).right(2) + '-OC-000001', orders[0].Invoice_Number__c);
        //  https://jira.towa-digital.com/browse/EANER-19   use EAN21-F-#### (= Invoice Number) 
        System.assertEquals('EAN' + String.valueOf(Date.today().year()).right(2) + '-F-000001', orders[0].Invoice_Number__c);
        System.assertEquals(2, orders[0].Order_Items__r.size());

    }

    @isTest
    public static void cancelOrderTest() {

        Contact c = new Contact(LastName = 'test', Email = 'orderCreate@test.com', MailingStreet = 'TestStreet',
        MailingCity = 'TestCity', MailingPostalCode = '11111',
        MailingCountry = 'Germany');
        insert c;
    
        Order__c order = new Order__c( Contact__c = c.Id );
        insert order;
        Order_Item__c oI = new Order_Item__c( Order_Custom__c = order.Id, Amount__c =  50, Quantity__c = 1 );
    	insert oI;
        
        insert new Transaction__c(Order_Custom__c = order.Id, Status__c = 'Success', Amount__c = 50, Payment_Method__c='Bank Transfer');

        oI.Refund_Amount__c = 50;
        Map<String,Object> resMap = OrderHelper.cancelOrder(new Map<String,Object> {
            'id' => order.Id,
            'refundAmount' => 50,
            'oI' => new List<Order_Item__c>{ oI },
            'oIOrig' => new Map<String,Object> {
                oI.Id => 50
            }
        });

        System.assertEquals('Success', String.valueOf(resMap.get('status')));
        
        List<Transaction__c> trs = [SELECT Id, Amount__c, Status__c FROM Transaction__c WHERE Id =: String.valueOf(resMap.get('id'))];
        System.assertEquals(1, trs.size());
        System.assertEquals('Refund', trs[0].Status__c);
        System.assertEquals(-50, trs[0].Amount__c);

        List<Order__c> os = OrderHelper.getOrderInfo(order.Id);

        System.assertEquals(1, os.size());
        System.assertEquals(0, os[0].Paid_Amount__c);
        System.assertEquals(50, os[0].Total_amount__c);

        Map<String, Object> result = OrderHelper.getCancellationSettings(order.Id);
        System.assert(result.containsKey('displayContactColumn'));
        System.assert(Boolean.valueOf(result.get('displayContactColumn')) == false);

    }

    @isTest
    public static void getSoloParticipatCommunityButtonsInitDataTest() {
        Contact c = new Contact(LastName = 'test', Email = 'orderCreate@test.com', MailingStreet = 'TestStreet',
        MailingCity = 'TestCity', MailingPostalCode = '11111',
        MailingCountry = 'Germany');
        insert c;

		Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event1 = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event1;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c p = new Participant__c(Contact__c = c.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
        insert p;
        
        Map<String, Object> resMap = OrderHelper.getSoloParticipatCommunityButtonsInitData(p.Id);

        System.assertEquals(false, Boolean.valueOf(resMap.get('displayCancelButton')));
        System.assertEquals(false, Boolean.valueOf(resMap.get('displayDoPaymentButton')));
        System.assertEquals(false, Boolean.valueOf(resMap.get('displayUpgradeButton')));
    }
    
}