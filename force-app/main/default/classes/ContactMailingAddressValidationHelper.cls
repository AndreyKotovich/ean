public with sharing class ContactMailingAddressValidationHelper {
    public static String message1 = 'You can\'t choose this address as mailing. It\'s not completely filled.';
    public static String message2 = 'You don\'t have Primary Workplace.';
    public static void addressCheck(List<Contact> contacts){
        List<Contact_Role__c> contactRoles = [SELECT Id, is_primary_workplace__c, Contact__c, Account__r.ShippingCountry, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingPostalCode FROM Contact_Role__c WHERE Contact__c IN :contacts];
        for(Contact c : contacts){
            if(c.Mailing_address__c == 'Work Address'){
                List<Contact_Role__c> currentCR = new List<Contact_Role__c>();
                for(Contact_Role__c cr : contactRoles){
                    if(cr.Contact__c == c.Id){
                        currentCR.add(cr);
                    }
                }
                if(!currentCR.isEmpty()){
                    Contact_Role__c contRole;
                    for(Contact_Role__c ccr : currentCR){
                        if(ccr.is_primary_workplace__c){
                            contRole = ccr;
                        }
                    }
                    if(contRole !=null){
                        if(contRole.Account__r.ShippingCountry == null || contRole.Account__r.ShippingStreet  == null || contRole.Account__r.ShippingCity == null || contRole.Account__r.ShippingPostalCode == null){
                            c.addError(message1);

                        }
                    }else{
                        c.addError(message2);
                    }
                }else{
                    c.addError(message2);
                }
            }
        }
    }
    public static void saveLastMailingAddress(List<Contact> newCont, List<Contact>oldCont){
        for(Integer i = 0; i<newCont.size(); i++){
            if(oldCont[i].Mailing_address__c!=newCont[i].Mailing_address__c){
                newCont[i].Previous_Mailing_Address__c = oldCont[i].Mailing_address__c;
            }
        }
    }
}