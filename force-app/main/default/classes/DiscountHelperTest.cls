@isTest
public with sharing class DiscountHelperTest {

	@IsTest
	public static void getDiscount() {
		
		Event__c e = new Event__c(Name = 'Event');
		insert e;

		Ticket__c t1 = new Ticket__c(Name = 'Non-Member Ticket', Available_for_Countries__c = 'A;B;C;F');
		Ticket__c t2 = new Ticket__c(Name = 'Any Member Ticket', Available_for_Countries__c = 'A;B;C;F');

		insert new List<Ticket__c> { t1 , t2 } ;

		Session__c s1 = new Session__c( Name = 'Session Extra 1', Type__c = 'Payable', Session_Type__c = 'Special Session', Event_custom__c = e.Id,
				Max_Participants__c = 50, Session_Start__c = Datetime.now(), Session_End__c = Datetime.now().addDays(1));
		
		Session__c s2 = new Session__c( Name = 'Session Extra 2', Type__c = 'Payable', Session_Type__c = 'Special Session', Event_custom__c = e.Id,
			Max_Participants__c = 50, Session_Start__c = Datetime.now(), Session_End__c = Datetime.now().addDays(1));
		
		insert new List<Session__c> { s1, s2 };

		Discount__c disc1 = new Discount__c(
			StartDate__c = Datetime.now() - 2, EndDate__c = Datetime.now() + 2, PromoCode__c = 'PROC50',
			Discount_Type__c = '%', Discount_Amount__c = 50            
		);

		Discount__c disc2 = new Discount__c(
			StartDate__c = Datetime.now() - 2, EndDate__c = Datetime.now() + 2, PromoCode__c = 'SUM10',
			Discount_Type__c = '€', Discount_Amount__c = 10            
		);

		insert new List<Discount__c> { disc1, disc2 };

		List<DiscountItem__c> dIs = new List<DiscountItem__c>();
		
		dIs.add(new DiscountItem__c(Event_custom__c = e.Id, Ticket__c = t1.Id, Discount__c = disc2.Id));
		dIs.add(new DiscountItem__c(Event_custom__c = e.Id, Session__c = s1.Id, Discount__c = disc1.Id));
		
		insert dIs;

		Map<String,Object> generalData = new Map<String,Object>();

		generalData = new Map<String,Object> {
			'eventId' => e.Id,
			'sessions' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => s2.Id, 'amount' => 30 }
			},
			'tickets' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => t2.Id, 'amount' => 30 }
			},
			'discountCode' => 'testCode'
		};  

		Map<String,Object> resMap = DiscountHelper.getDiscount(generalData);

		System.assertEquals('Error', String.valueOf(resMap.get('status')));
		System.assertEquals('Discount code not found. Please try again.', String.valueOf(resMap.get('message')));

		generalData = new Map<String,Object> {
			'eventId' => e.Id,
			'sessions' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => s2.Id, 'amount' => 30 }
			},
			'tickets' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => t2.Id, 'amount' => 30 }
			},
			'discountCode' => 'SUM10'
		};  

		resMap = DiscountHelper.getDiscount(generalData);

		System.assertEquals('Error', String.valueOf(resMap.get('status')));
		System.assertEquals('Invalid discount code.', String.valueOf(resMap.get('message')));
		
		generalData = new Map<String,Object> {
			'eventId' => e.Id,
			'sessions' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => s1.Id, 'amount' => 30 }
			},
			'tickets' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => t1.Id, 'amount' => 30 }
			},
			'discountCode' => 'SUM10'
		};  

		resMap = DiscountHelper.getDiscount(generalData);
		System.assertEquals('Success', String.valueOf(resMap.get('status')));
		System.assertEquals('Discount code applied successfully.', String.valueOf(resMap.get('message')));
		
		Map<String,Object> data = (Map<String,Object>)resMap.get('data');
        List<Object> sessionList = (List<Object>)data.get('sessions');
        System.assertEquals(1, sessionList.size());
        
        Map<String, Object> sessions = (Map<String, Object>)sessionList[0];        
        System.assertEquals(null, sessions.get('discountAmount'));
		
		List<Object> ticketList = (List<Object>)data.get('tickets');
		System.assertEquals(1, ticketList.size());

		Map<String, Object> tickets = (Map<String, Object>)ticketList[0];
        System.assertEquals(10, (Decimal)tickets.get('discountAmount'));
        
		generalData = new Map<String,Object> {
			'eventId' => e.Id,
			'sessions' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => s1.Id, 'amount' => 30 }
			},
			'tickets' => new List<Map<String,Object>> {
				new Map<String,Object> { 'id' => t1.Id, 'amount' => 30 }
			},
			'discountCode' => 'PROC50'
		};  

		resMap = DiscountHelper.getDiscount(generalData);
		System.assertEquals('Success', String.valueOf(resMap.get('status')));
		System.assertEquals('Discount code applied successfully.', String.valueOf(resMap.get('message')));
		
		data = (Map<String,Object>)resMap.get('data');
        ticketList = (List<Object>)data.get('tickets');
		System.assertEquals(1, ticketList.size());

		tickets = (Map<String, Object>)ticketList[0];
		System.assertEquals(null, tickets.get('discountAmount'));
		
		sessionList = (List<Object>)data.get('sessions');
        System.assertEquals(1, sessionList.size());
        
        sessions = (Map<String, Object>)sessionList[0];        
        System.assertEquals(15, (Decimal)sessions.get('discountAmount'));
		
	}
}