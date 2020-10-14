public without sharing class SelfRegHelper{
    public static void checkExistedUsers(String email){
        List<User> users = [SELECT Id FROM User WHERE (Email = :email OR Username = :email)];
        System.debug('users:: '+users);
        if(users.size()>0){
            throw new AuraException('A user account with this email address already exists. Please click “forgot password” to reset your account. \n If you need further assistance, please contact headoffice@ean.org.');
        }
    }
}