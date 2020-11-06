public without sharing class DiscountHelper {

	/* 	request
		
		new Map<String,Object> {
			'eventId' => 'a1M0E000002oBvTUAU',
			'session' => new List<Map<String,Object>> {
				new Map<String,Object> {
					'id' =>'a1X0E000000d10HUAQ',
					'amount' => 30
				}
			},
			'tickets' => new List<Map<String,Object>> {
				new Map<String,Object> {
					'id' =>'a1X0E000000d10HUAQ',
					'amount' => 30
				}
			},
			'discountCode' => 'SUM10'
		};  
		
		response
	
		new Map<String,Object> {
			'status' => 'Success',
			'message' => 'Coupon code applied successfully.',
			'data' => new Map<String,Object> {
				'session' => new List<Map<String,Object>> {
					new Map<String,Object> {
						'id' =>'a1X0E000000d10HUAQ',
						'amount' => 30,
						discountAmount => 10,
						discountId => 'discountId'
						
					}
				},
				'tickets' => new List<Map<String,Object>> {
					new Map<String,Object> {
						'id' =>'a1X0E000000d10HUAQ',
						'amount' => 30,
						discountAmount => 10,
						discountId => 'discountId'
					}
				},
				'discount' => discounts[0]
			}
		}; 
		
		*/
	
		private static final Set<String> SESSION_TYPE = new Set<String>{ 'eventDiscount', 'sessionDiscount', 'sessionEventDiscount' };
		private static final Set<String> TICKET_TYPE = new Set<String>{ 'eventDiscount', 'ticketDiscount', 'ticketEventDiscount' };
	
		private static List<SessionWrapper> sessions = new List<SessionWrapper>();
		private static List<TicketWrapper> tickets = new List<TicketWrapper>();
		private static Map<String,Object> discountParam  = new Map<String,Object>();
		private static String eventId;
		private static Decimal totalDiscountAmount;
		
		@AuraEnabled
		public static Map<String,Object> getDiscount (Map<String,Object> generalData) {
			totalDiscountAmount = 0;
			Datetime dateNow = Datetime.now();
			String discountCode = String.valueOf(generalData.get('discountCode'));
			List<Discount__c> discounts = [
				SELECT 
					Id, Name, StartDate__c, EndDate__c, PromoCode__c, Discount_Type__c, Discount_Amount__c,
					(SELECT Id, Event_custom__c, Ticket__c, Session__c FROM Discount_Items__r) 
				FROM Discount__c
				WHERE PromoCode__c =:discountCode AND StartDate__c <=:dateNow AND EndDate__c >=:dateNow
			];
	
			if (discounts.isEmpty() || discounts[0].Discount_Items__r.isEmpty()) {
				return new Map<String,Object> {
					'status' => 'Error',
					'message' => 'Discount code not found. Please try again.',
					'data' => generalData
				};
			}
	
			discountParam = new Map<String,Object> {
				'type' => discounts[0].Discount_Type__c,
				'amount' => discounts[0].Discount_Amount__c
			};
	
			eventId = String.valueOf(generalData.get('eventId'));
			sessions = generalData.containsKey('sessions') ?
				(List<SessionWrapper>)JSON.deserialize(JSON.serialize(generalData.get('sessions')), List<SessionWrapper>.class) : new List<SessionWrapper>();
			tickets = generalData.containsKey('tickets') ?
				(List<TicketWrapper>)JSON.deserialize(JSON.serialize(generalData.get('tickets')), List<TicketWrapper>.class) : new List<TicketWrapper>();
			
			for (DiscountItem__c dI : discounts[0].Discount_Items__r) {
				toApplyDiscount(discounts[0].Id, dI);
			}
	
			if (totalDiscountAmount > 0) {
				return new Map<String,Object> {
					'status' => 'Success',
					'message' => 'Discount code applied successfully.',
					'data' => new Map<String,Object> {
						'sessions' => JSON.deserializeUntyped(JSON.serialize(sessions)),
						'tickets' => JSON.deserializeUntyped(JSON.serialize(tickets)),
						'discount' => discounts[0]
					}
				};
			}
			
			return new Map<String,Object> {
				'status' => 'Error',
				'message' => 'Invalid discount code.',
				'data' => generalData
			};
			
		}
	
		private static void toApplyDiscount (String discountId, DiscountItem__c dI) {
			String typeDiscount = getTypeDiscount(dI);
			if (!String.isBlank(typeDiscount)) {
				if (!sessions.isEmpty() && SESSION_TYPE.contains(typeDiscount)) {
					for (SessionWrapper s : sessions) {
						if ((typeDiscount == 'eventDiscount' && dI.Event_custom__c == eventId) || (typeDiscount == 'sessionDiscount' &&  s.id == dI.Session__c) || 
							(typeDiscount == 'sessionEventDiscount' && dI.Event_custom__c == eventId && s.id == dI.Session__c)) {
							s.discountAmount = calculateDiscount(s.amount);
							totalDiscountAmount += s.discountAmount;
							s.discountId = discountId;
						}
					}
				}
				if (!tickets.isEmpty() && TICKET_TYPE.contains(typeDiscount)) {
					for (TicketWrapper t : tickets) {
						if ((typeDiscount == 'eventDiscount' && dI.Event_custom__c == eventId) || (typeDiscount == 'ticketDiscount' &&  t.id == dI.Ticket__c) || 
							(typeDiscount == 'ticketEventDiscount' && dI.Event_custom__c == eventId && t.id == dI.Ticket__c)) {
							t.discountAmount = calculateDiscount(t.amount);
							totalDiscountAmount += t.discountAmount;
							t.discountId = discountId;
						}
					}
				}
			}
		}
	
		private static Decimal calculateDiscount (Decimal amount) {
			String discountType = String.valueOf(discountParam.get('type'));
			Decimal discountAmount = (Decimal)discountParam.get('amount');
			if (discountType == '%') { return (amount * discountAmount / 100).setScale(2, RoundingMode.CEILING); }
			return discountAmount;
		}
	
		private static String getTypeDiscount (DiscountItem__c oI) {
			Boolean isEvent = !String.isBlank(oI.Event_custom__c);
			Boolean isTicket = !String.isBlank(oI.Ticket__c);
			Boolean isSession = !String.isBlank(oI.Session__c);
			
			return 	isEvent && !isTicket && !isSession ? 'eventDiscount' : 
					isTicket && !isEvent && !isSession ? 'ticketDiscount' :
					isSession && !isEvent && !isTicket ? 'sessionDiscount' :
					isSession && isEvent && !isTicket ? 'sessionEventDiscount' :
					isTicket && isEvent && !isSession  ? 'ticketEventDiscount' : null;
		}
	
		public class TicketWrapper {
			public String id { get; set; }
			public Decimal amount { get; set; }
			public String discountId { get; set; }
			public Decimal discountAmount { get; set; }
		}
		
		public class SessionWrapper {
			public String id { get; set; }
			public Decimal amount { get; set; }
			public String discountId { get; set; }
			public Decimal discountAmount { get; set; }
		}
	
	}