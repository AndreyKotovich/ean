public class MyContactController {

    @AuraEnabled
    public static String getContactId() {
        String returnId = '';
        User current = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if (current.ContactId == null) {
            returnId = 'none';
        } else {
            returnId = current.ContactId;
        }

        return returnId;
    }
}