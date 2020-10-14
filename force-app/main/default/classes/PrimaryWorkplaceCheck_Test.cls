@IsTest
public with sharing class PrimaryWorkplaceCheck_Test {
    /*@TestSetup public static void setup(){
        RecordType rtAccDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Department'];
        List<Account> accs = new List<Account>();
        accs.add(new Account(Name = 'Test account 1', RecordTypeId = rtAccDepartment.Id));
        accs.add(new Account(Name = 'Test account 2', RecordTypeId = rtAccDepartment.Id));
        insert accs;
        Contact contact = new Contact(LastName = 'TestContact');
        insert contact;
    }
    @IsTest public static void PWCheckTestInsert(){
        Contact cont = [SELECT Id FROM Contact WHERE LastName = 'TestContact'];
        List<Account> accs = [SELECT Id, Name FROM Account];
        RecordType rtDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        try {
            Contact_Role__c cr1 = new Contact_Role__c(Account__c = accs[0].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
            insert cr1;
            System.assertEquals(1, [SELECT Id FROM Contact_Role__c WHERE Contact__c = :cont.Id].size());
            insert new Contact_Role__c(Account__c = accs[1].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
        }catch (Exception e ){
            Boolean expectedExceptionThrown =  e.getMessage().contains(PrimaryWorkplaceCheckHelper.message);
            System.assertEquals(true, expectedExceptionThrown);
            System.assertEquals(1, [SELECT Id FROM Contact_Role__c WHERE Contact__c = :cont.Id AND is_primary_workplace__c=true].size());
        }
    }
    @IsTest public static void PWCheckTestUpdate(){
        Contact cont = [SELECT Id FROM Contact WHERE LastName = 'TestContact'];
        List<Account> accs = [SELECT Id, Name FROM Account];
        RecordType rtDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        try {
            Contact_Role__c cr1 = new Contact_Role__c(Account__c = accs[0].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
            insert cr1;
            Contact_Role__c cr2 = new Contact_Role__c(Account__c = accs[1].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = false, RecordTypeId=rtDepartment.Id);
            insert cr2;
            System.assertEquals(2, [SELECT Id FROM Contact_Role__c WHERE Contact__c = :cont.Id].size());
            cr2.is_primary_workplace__c = true;
            update cr2;
        }catch (Exception e ){
            Boolean expectedExceptionThrown =  e.getMessage().contains(PrimaryWorkplaceCheckHelper.message);
            System.assertEquals(true, expectedExceptionThrown);
            System.assertEquals(1, [SELECT Id FROM Contact_Role__c WHERE Contact__c = :cont.Id AND is_primary_workplace__c=true].size());
        }
    }
    @IsTest public static void PWCheckTestUndelete(){
        Contact cont = [SELECT Id FROM Contact WHERE LastName = 'TestContact'];
        List<Account> accs = [SELECT Id, Name FROM Account];
        RecordType rtDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        try {
            Contact_Role__c cr1 = new Contact_Role__c(Account__c = accs[0].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
            insert cr1;
            delete cr1;

            Contact_Role__c cr2 = new Contact_Role__c(Account__c = accs[1].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = false, RecordTypeId=rtDepartment.Id);
            insert cr2;
            cr2.is_primary_workplace__c = true;
            update cr2;
            delete cr2;

            undelete cr1;
            undelete cr2;
        }catch (Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(PrimaryWorkplaceCheckHelper.message);
            System.assertEquals(true, expectedExceptionThrown);
            System.assertEquals(1, [SELECT Id FROM Contact_Role__c WHERE Contact__c = :cont.Id AND is_primary_workplace__c=true].size());
        }
    }
    @IsTest public static void uncheckedPWAndPWDeletedTest(){
        Contact cont = [SELECT Id FROM Contact WHERE LastName = 'TestContact'];
        List<Account> accs = [SELECT Id, Name FROM Account];
        RecordType rtDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        update new Account(Id=accs[0].Id, ShippingCity='test', ShippingCountry='Belarus', ShippingPostalCode='12231', ShippingStreet='test');
        Contact_Role__c cr1 = new Contact_Role__c(Account__c = accs[0].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
        insert cr1;
        cont.Mailing_address__c = 'Work Address';
        update cont;
        System.assertEquals('Work Address', [SELECT Id, Mailing_address__c FROM Contact WHERE LastName = 'TestContact'].Mailing_address__c);
        //uncheckedPW test
        cr1.is_primary_workplace__c = false;
        update cr1;
        Contact c = [SELECT Id, Mailing_address__c, Previous_Mailing_Address__c FROM Contact WHERE LastName = 'TestContact'];
        System.assertEquals(null, c.Mailing_address__c);
        System.assertEquals('Work Address', c.Previous_Mailing_Address__c);
        //checkedPW test
        cr1.is_primary_workplace__c = true;
        update cr1;
        System.assertEquals('Work Address', [SELECT Id, Mailing_address__c FROM Contact WHERE LastName = 'TestContact'].Mailing_address__c);
        //PWDeleted test
        delete cr1;
        c = [SELECT Id, Mailing_address__c, Previous_Mailing_Address__c FROM Contact WHERE LastName = 'TestContact'];
        System.assertEquals(null, c.Mailing_address__c);
        System.assertEquals('Work Address', c.Previous_Mailing_Address__c);
        //checkedPWInInsert test
        Contact_Role__c cr2 = new Contact_Role__c(Account__c = accs[0].Id, Contact__c = cont.Id, Role__c = 'Member', is_primary_workplace__c = true, RecordTypeId=rtDepartment.Id);
        insert cr2;
        c = [SELECT Id, Mailing_address__c, Previous_Mailing_Address__c FROM Contact WHERE LastName = 'TestContact'];
        System.assertEquals('Work Address', c.Mailing_address__c);
    }*/
}