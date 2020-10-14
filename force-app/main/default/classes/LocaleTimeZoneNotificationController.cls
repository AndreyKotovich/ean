public with sharing class LocaleTimeZoneNotificationController {
    @AuraEnabled public static Map<String, Object> showModalCheck(){
        List<User> user = [SELECT Id, Locale_Time_Zone_Notification_Date__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if(!user.isEmpty()){
            if(user[0].Locale_Time_Zone_Notification_Date__c==null){
                Map <String, String> mapLocales = LocaleTimeZoneNotificationController.getPicklistValuesMap('User', 'LocaleSidKey');
                return new Map<String, Object>{
                        'result'=>true,
                        'userId'=>UserInfo.getUserId(),
                        'locale'=>mapLocales.get(UserInfo.getLocale()),
                        'timezone'=>UserInfo.getTimeZone().getDisplayName()
                };
            } else {
                return new Map<String, Object>{'result'=>false, 'userId'=>UserInfo.getUserId()};
            }
        } else{
            return new Map<String, Object>{'result'=>false, 'userId'=>UserInfo.getUserId()};
        }
    }

    @AuraEnabled public static void writeNotificationTime(){
        try{
            List<User> user = [SELECT Id, Locale_Time_Zone_Notification_Date__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if(!user.isEmpty()){
                user[0].Locale_Time_Zone_Notification_Date__c = Datetime.now();
                update user;
            } else{
                throw new AuraHandledException('Locale/Time Zone notification error. Please, contact your system administrator.');
            }
        }catch (Exception e){
            throw new AuraHandledException('Locale/Time Zone notification error. Please, contact your system administrator.');
        }
    }

    public static Map<String, String> getPicklistValuesMap(String object_name, String field_name) {
        Map<String, String> values = new Map<String, String>();
        String[] types = new String[]{object_name};
        Schema.DescribeSObjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSObjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(field_name).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {values.put(entry.getValue(),entry.getLabel());}
            }
        }
        return values;
    }
}