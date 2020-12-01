public with sharing class BadgeController {
    public static final Set<String> LARGE_SIZE = new Set<String> { 'Exhibitor', 'Meeting only', 'Day of the week' };
   
    @AuraEnabled
    public static List<Map<String,Object>> getTemplateBadge(List<String> ids) {
        if (ids.size() == 0) { return new List<Map<String,Object>>(); }
        try {
            List<Map<String,Object>> badges = new List<Map<String,Object>>();
            // List<String> ids = new List<String>(); 
            // ids.add('a090E000006IxcNQAS');

            List<Event_Badge__c> upgradeEB = new List<Event_Badge__c>();

            System.debug('ids' + ids);
            List<Event_Badge__c> eBs = [
                SELECT 
                    Id, Event_Participation__c, FirstName__c, LastName__c, City__c, Country__c, Label__c, Label_type__c, Barcode__c, 
                    QR_code__c, Company__c, Footer_Definitions__c, Non_Prescriber_Info__c, Event_Participation_Role__c, 
                    Event_Registration_Group__c, Event_custom__c, Requested_For_Print_Or_Preview__c, QR_code_link__c,
                    Event_custom__r.Id,Event_custom__r.Name,Event_custom__r.City__c, Event_custom__r.Country__c, 
                    Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c, Event_custom__r.Wi_Fi_Name__c, 
                    Event_custom__r.Wi_Fi_Supported_By__c,Event_custom__r.Certificate_Link__c,Event_custom__r.Congress_Postfix__c,
                    Event_custom__r.Event_Number__c, Event_custom__r.Marketing_Name__c, Event_custom__r.App_Supported_By__c
                FROM Event_Badge__c 
                WHERE id IN :ids
            ];

            System.debug('eBs' + eBs);
            if (eBs.size() == 0) {
                return new List<Map<String,Object>>();
            }

            Set<Id> partIds = new Set<Id>();

            for (Event_Badge__c eB: eBs) {
                if (!String.isBlank(eB.Event_Participation__c)) {
                    partIds.add(eB.Event_Participation__c);
                }
            }

            Map<String, Participant__c> sessionMap = new Map<String, Participant__c> (
                [
                    SELECT Id, (SELECT Id, Session__c, Session__r.Name FROM Session_Participations__r) 
                    FROM Participant__c where Id IN :partIds
                ]
            );

            for (Event_Badge__c eB: eBs) {
                upgradeEB.add( new Event_Badge__c(Id = eB.Id, Requested_For_Print_Or_Preview__c = true) );
                List<String> sessions = new List<String>();
                System.debug('sessionMap.containsKey(eB.Id) '  + sessionMap.containsKey(eB.Id));
                if (sessionMap.containsKey(eB.Id)) {
                    Participant__c part = sessionMap.get(eB.Id);
                    for (Session_Participation__c sP : part.Session_Participations__r) {
                        if (!String.isBlank(sP.Session__c)) {
                            sessions.add(sP.Session__r.Name);
                        }
                    }
                }
                
                String dates = eB.Event_custom__r.Start_Time__c.format('MMMM dd') + ' - ' + eB.Event_custom__r.End_Time__c.format('MMMM dd');
                List<Map<String, Object>> footers = new List<Map<String, Object>>();
                
                if (!String.isBlank(eB.Footer_Definitions__c)) {
                    for (String s : eB.Footer_Definitions__c.split(';')) {
                        String lg = LARGE_SIZE.contains(s) ? 'lg' : '';
                        footers.add(new Map<String, Object> {
                            'label' => s, 
                            'size' => lg
                        });
                    } 
                }
                
                badges.add( new Map<String,Object> {
                    'cityEvent' => eB.Event_custom__r.City__c,
                    'bookedTickets' => sessions,
                    'wiFiName' => eB.Event_custom__r.Wi_Fi_Name__c,
                    'wiFiSupportedBy' => eB.Event_custom__r.Wi_Fi_Supported_By__c,
                    'appSupportedBy' => eB.Event_custom__r.App_Supported_By__c,
                    'certificateLink' => eB.Event_custom__r.Certificate_Link__c,
                    'year' => eB.Event_custom__r.Start_Time__c.year(),
                    'count' => eB.Event_custom__r.Event_Number__c,                
                    'countPostfix' => eB.Event_custom__r.Congress_Postfix__c,
                    'date' => dates,
                    'name' => eB.Event_custom__r.Marketing_Name__c,
                    'company' => eB.Company__c,
                    'firstName' => eB.FirstName__c,
                    'lastName' => eB.LastName__c,
                    'city' => eB.City__c,
                    'country' => eB.Country__c,
                    'label' => eB.Label__c,
                    'labelType' => eB.Label_type__c,
                    'barcode' => eB.Barcode__c,
                    'qrcode' => eB.QR_code_link__c,
                    'footer' => footers
                });
                
            }
            update upgradeEB;

            return badges;
        } 
        catch(Exception e) {
            return new List<Map<String,Object>>();
        }
    }

    @AuraEnabled
    public static String getUrl(){
        return Url.getOrgDomainUrl().toExternalForm();
    }
}