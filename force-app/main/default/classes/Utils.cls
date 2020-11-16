// public without sharing class Utils {
public with sharing class Utils {

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getUserMemberships(){

        User currentUser = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];

        return getContactMemberships(currentUser.ContactId);

    }

    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getContactMemberships(String contactId){

        List<MembershipContactAssotiation__c> contactsMemberships = [
                SELECT Id, Membership__r.Name, Membership__r.API__c, CreatedDate
                FROM MembershipContactAssotiation__c
                WHERE Contact__c = :contactId
                AND IsActive__c = TRUE
                ORDER BY CreatedDate DESC
        ];

        return contactsMemberships;
    }

    public static List<Map<String, String>> picklistValues(String objectName, String fieldName) {
        List<Map<String, String>> values = new List<Map<String, String>>();
        List<String> types = new List<String>{objectName};
        List<Schema.DescribeSObjectResult> results = Schema.describeSObjects(types);
        for(Schema.DescribeSObjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(new Map<String, String>{'value' => entry.getValue(), 'label' => entry.getLabel()});
                }
            }
        }
        return values;
    }

    public static void insertSObjectsWithoutSharing(List<SObject> sbojects) {
        insert sbojects;
    }

    //  TEMPORARY DEPRECATED (by Vitaly Serebrakov)

	// /**
	//  * @description								method for creating EAN_Settings__c (custom settings)
	//  * @param Map<String, String> newSettings	custom setting name TO value
	//  */
	// public static void setEANSettings(Map<String, String> newSettings) {
	// 	try {
	// 		Map<String, EAN_Settings__c> result = new Map<String, EAN_Settings__c>();
	// 		Map<String, EAN_Settings__c> allSettings = EAN_Settings__c.getAll();

	// 		for (String settingKey : newSettings.keySet()) {
	// 			if (settingKey != '' && settingKey != 'null') {
	// 				if (allSettings.containsKey(settingKey)) {
	// 					EAN_Settings__c item = allSettings.get(settingKey);
	// 					item.Value__c = newSettings.get(settingKey);
	// 					result.put(settingKey, item);
	// 				}
	// 				else {
	// 					result.put(settingKey, new EAN_Settings__c(
	// 						Name = settingKey,
	// 						Value__c = newSettings.get(settingKey)
	// 					));
	// 				}
	// 			}
	// 		}
	// 		if (!result.isEmpty()) upsert result.values();
	// 	} catch (Exception e) { throw new PrivilegesException('Privileges Exception L69: ' + e.getMessage()); }
	// }

    // public with sharing class PrivilegesException extends Exception {}
}