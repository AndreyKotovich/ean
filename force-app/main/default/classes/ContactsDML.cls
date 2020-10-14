//BEFORE RUN THIS BATCH DEACTIVATE Process Builder - "Set 'IsCommunityUser__c' on Contact"
public class ContactsDML implements Database.Batchable<SObject>, Database.Stateful {
    PermissionSet permissionSet = new PermissionSet();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Access_community_user_login_to_custom_objects'];

        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = 'Non-Member Community User Profile' OR Name = 'Member Community User Profile'];
        return Database.getQueryLocator(
                'SELECT Id, IsActive FROM User WHERE ProfileId IN :profiles AND IsActive = false AND isportalenabled=true'
        );
    }

    public void execute(Database.BatchableContext BC, List<User> scope) {
        //=====ACTIVATE COMMUNITY USERS==========
            List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();

            for (User u : scope) {

                if (!u.IsActive) {
                    u.IsActive = true;
                }

                permissionSetList.add(new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = u.Id));
            }
            update scope;
            upsert permissionSetList;
    }

    public void finish(Database.BatchableContext BC) {
    }
}