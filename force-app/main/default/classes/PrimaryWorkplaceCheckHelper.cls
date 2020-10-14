public with sharing class PrimaryWorkplaceCheckHelper {
    public static String message = 'This contact already have a Primary Workplace';
    public static void PWUniqueCheck(List<Contact_Role__c> contactRoles){
        List<String> contactIds = new List<String>();
        for(Contact_Role__c cr : contactRoles){
            if(cr.is_primary_workplace__c){
                contactIds.add(cr.Contact__c);
            }
        }
        List<Contact_Role__c> contactsCR = [SELECT Id, is_primary_workplace__c, Contact__c FROM Contact_Role__c WHERE Contact__c IN :contactIds];
        for(Contact_Role__c cr : contactRoles){
            for(Contact_Role__c ccr : contactsCR){
                if(cr.Contact__c == ccr.Contact__c && ccr.is_primary_workplace__c && cr.Id!=ccr.Id){
                    cr.addError(message);
                }
            }
        }
    }
    public static void PWDeleted(List<Contact_Role__c> contactRoles){
        List<String> contactsIds = new List<String>();
        for(Contact_Role__c cr:contactRoles){
            if(cr.is_primary_workplace__c){
                contactsIds.add(cr.Contact__c);
            }
        }
        List<Contact> contacts = [SELECT Id, Mailing_address__c FROM Contact WHERE Id IN :contactsIds];
        List<Contact> contactsForUpdate = new List<Contact>();
        for(Contact c: contacts){
            if(c.Mailing_address__c == 'Work Address'){
                c.Mailing_address__c = '';
                contactsForUpdate.add(c);
            }
        }
        update contactsForUpdate;
    }
    public static void uncheckedPW(List<Contact_Role__c> contactRolesNew, List<Contact_Role__c> contactRolesOld){
        List<Contact_Role__c> pwToUpdateContact = new List<Contact_Role__c>();
        for(Integer i = 0; i<contactRolesNew.size(); i++){
            if(!contactRolesNew[i].is_primary_workplace__c && contactRolesOld[i].is_primary_workplace__c){
                pwToUpdateContact.add(contactRolesOld[i]);
            }
        }
        PWDeleted(pwToUpdateContact);
    }
    public static void checkedPW(List<Contact_Role__c> contactRolesNew, List<Contact_Role__c> contactRolesOld){
        List<String> contactsIds = new List<String>();
        for(Integer i = 0; i<contactRolesNew.size(); i++){
            if(contactRolesNew[i].is_primary_workplace__c && !contactRolesOld[i].is_primary_workplace__c){
                contactsIds.add(contactRolesOld[i].Contact__c);
            }
        }
        previousStatusCheck(contactsIds);

    }
    public static void checkedPWInInsert(List<Contact_Role__c> contactRoles){
        List<String> contactsIds = new List<String>();
        for(Contact_Role__c cr: contactRoles){
            if(cr.is_primary_workplace__c){
                contactsIds.add(cr.Contact__c);
            }
        }
        previousStatusCheck(contactsIds);
    }
    public static void previousStatusCheck(List<String> contactsIds){
        List<Contact> contactsToUpdate = [SELECT Id, Previous_Mailing_Address__c, Mailing_address__c FROM Contact WHERE Previous_Mailing_Address__c='Work Address' AND Id IN :contactsIds];
        for(Contact c : contactsToUpdate){
            if(c.Mailing_address__c==null&&c.Previous_Mailing_Address__c=='Work Address'){
                c.Mailing_address__c = c.Previous_Mailing_Address__c;
            }
        }
        update contactsToUpdate;
    }
}