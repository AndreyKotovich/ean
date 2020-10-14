//BATCH FOR RETRIVE EXTERNAL IN OF MIGRATE USERS WITH AVATARS
global class GetUsersWithAvatarsBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    global String usersWithPhotoString;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        usersWithPhotoString = 'External_Id__c' + '\r\n';
        return Database.getQueryLocator(
                'SELECT Id, External_Id__c FROM User WHERE ContactId!=null AND External_Id__c!=null AND IsPortalEnabled=true'
        );
    }

    global void execute(Database.BatchableContext bc, List<User> records) {
//        usersWithPhoto
        for(User u : records){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://www.ean.org/fileadmin/efnsusr_user_photo/'+u.External_Id__c+'-image-cropped.jpg');
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                usersWithPhotoString += u.External_Id__c + '\r\n';
            }
        }

    }
    global void finish(Database.BatchableContext bc) {
        ContentVersion cv = new ContentVersion(
                ContentLocation = 'S',
                PathOnClient = 'usersWithAvatars.csv',
                Title = 'usersWithAvatars',
                VersionData = Blob.valueOf(usersWithPhotoString)
        );
        insert cv;
    }
}