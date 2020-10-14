public without sharing class SynchronizeEmailAndUsername {
    @AuraEnabled public static void synchronize(){
        User user = [SELECT Id, Email, Username FROM User WHERE Id = :UserInfo.getUserId()];
        if(user.Username != user.Email){
            user.Username = user.Email;
            try{
                user.Username = user.Email;
                update user;
            } catch (Exception e){
                if(e.getMessage().contains('username already exists')){
                    throw new AuraException('The username already exists in this or another Salesforce organization. Usernames must be unique across all Salesforce organizations.');
                } else {
                    throw new AuraException('Something went wrong. Update failed, contact your System Administrator.');
                }
            }
        } else {
            throw new AuraException('Username and Email already synchronized.');
        }
    }
}