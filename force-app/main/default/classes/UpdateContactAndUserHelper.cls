public class UpdateContactAndUserHelper {
    public static void updateContact(List<User> userNew, List<User> userOld) {
        List<User_Contact_fields__mdt> fieldMapping = [SELECT Contact_Field__c, User_Field__c FROM User_Contact_fields__mdt];
        Boolean contactUpdateFlag = false;
        Set<User> userToUpdate = new Set<User>();
        Set<String> contactFields = new Set<String>();
        for (Integer i = 0; i < userNew.size(); i++) {
            for (User_Contact_fields__mdt uc : fieldMapping) {
                contactFields.add(uc.Contact_Field__c);
                if (userNew[i].get(uc.User_Field__c) != userOld[i].get(uc.User_Field__c)) {
                    if (userNew[i].ContactId != null) {
                        contactUpdateFlag = true;
                        userToUpdate.add(userNew[i]);
                    }

                }
            }
        }
        if (contactUpdateFlag) {
            Set<String> contactId = new Set<String>();
            for (User u : userToUpdate) {
                contactId.add(u.ContactId);
            }
            List<Contact> existingContact = Database.query('SELECT ' + String.join(new List<String>(contactFields), ',') + ' FROM Contact WHERE Id IN :contactId');
            for (User u : userToUpdate) {
                Map<String, Object> userMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(u));
                for (Contact c : existingContact) {
                    if (c.Id == u.ContactId) {
                        for (User_Contact_fields__mdt fm : fieldMapping) {
                            c.put(fm.Contact_Field__c, userMap.get(fm.User_Field__c));
                        }
                    }
                }
            }
            update existingContact;
        }
    }
    public static void updateUser(List<Contact> contactNew, List<Contact> contactOld) {
        List<User_Contact_fields__mdt> fieldMapping = [SELECT Contact_Field__c, User_Field__c FROM User_Contact_fields__mdt];
        Boolean userUpdateFlag = false;
        Set<Contact> contactToUpdate = new Set<Contact>();
        Set<String> userFields = new Set<String>();
        for (Integer i = 0; i < contactNew.size(); i++) {
            for (User_Contact_fields__mdt uc : fieldMapping) {
                userFields.add(uc.User_Field__c);
                if (contactNew[i].get(uc.Contact_Field__c) != contactOld[i].get(uc.Contact_Field__c)) {
                    userUpdateFlag = true;
                    contactToUpdate.add(contactNew[i]);
                }
            }
        }
        if (userUpdateFlag) {
            List<User> existingUser = Database.query('SELECT ContactId, ' + String.join(new List<String>(userFields), ',') + ' FROM User WHERE ContactId IN :contactNew');
            for (User u : existingUser) {
                for (Contact c : contactNew) {
                    if (c.Id == u.ContactId) {
                        Map<String, Object> contactMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(c));
                        for (User_Contact_fields__mdt fm : fieldMapping) {
                            u.put(fm.User_Field__c, contactMap.get(fm.Contact_Field__c));
                        }
                    }
                }
            }
            update existingUser;
        }
    }
}