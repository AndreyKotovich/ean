public without sharing class setEANDefaultAvatar {
    @AuraEnabled public static Boolean setEANDefaultAvatar(String userId) {
        List<Default_EAN_Avatar__c> defaultEANAvatar = [SELECT ContentDocumentId__c FROM Default_EAN_Avatar__c LIMIT 1];
        if(!defaultEANAvatar.isEmpty()) {
            List<ContentVersion> cv = [SELECT Id, VersionData, Title FROM ContentVersion WHERE ContentDocumentId=:defaultEANAvatar[0].ContentDocumentId__c];
            if (!cv.isEmpty()) {
                ConnectApi.BinaryInput photoFileInput = new ConnectApi.BinaryInput(cv[0].VersionData, 'image/png', cv[0].Title + '.png');
                Network myNetwork = [SELECT Id FROM Network WHERE Name = 'ean'];
                ConnectApi.UserProfiles.setPhoto(myNetwork.Id, userId, photoFileInput);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    @AuraEnabled public static Boolean assignDefaultAvatar() {
        if (isSalesforceDefaultAvatar(UserInfo.getUserId())) {
            return setEANDefaultAvatar(UserInfo.getUserId());
        } else{
            return false;
        }
    }
    public static Boolean isSalesforceDefaultAvatar(Id userId) {
        User currentUser = [SELECT Id, SmallPhotoUrl FROM User WHERE Id = :userId];
        return currentUser.SmallPhotoUrl.contains('profilephoto/005/T');
    }
}