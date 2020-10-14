global class UserTriggerHelper {
    @future
    public static void AssignPermissionSetToCommunityLoginUsers(Set<Id> usersId) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_community_user_login_to_custom_objects'];
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        for (Id i : usersId) {
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = ps.Id, AssigneeId = i);
            permissionSetList.add(psa);
        }
        upsert permissionSetList;
    }
    public static void emailDuplicateValidationUpdate(List<User> usersNew, List<User> usersOld){
        Set<User> users = new Set<User>();
        for(Integer i =0; i<usersNew.size(); i++){
            if(usersNew[i].Email != usersOld[i].Email){
                users.add(usersNew[i]);
            }
        }
        List<User> usersList = new List<User>();
        usersList.addAll(users);
        emailDuplicateValidation(usersList);
    }
    public static void emailDuplicateValidationInsert(List<User> users){
        emailDuplicateValidation(users);
    }
    public static void emailDuplicateValidation(List<User> users){
        Set<String> setEmail = new Set<String>();
        for(User u : users){
            setEmail.add(u.Email);
        }
        List<User> ul = [SELECT Id, Email FROM User WHERE Email IN: setEmail];
        if(ul.size() > 0){
            users.get(0).addError('A user account with this email address already exists. If you need further assistance, please contact headoffice@ean.org.');
        }
    }
}