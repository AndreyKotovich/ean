public class TestService {
    public static void insertMcCustomSettings() {

        Campaign_Names__c cmpgNames = new Campaign_Names__c();
        cmpgNames.Newsletter_Name__c = 'Test1';
        cmpgNames.IPE_Name__c = 'Test2';
        cmpgNames.Name = 'MC';

        insert cmpgNames;
        
        MC_credentials__c creds = new MC_credentials__c();
        creds.Name = 'MC';
        creds.ClientId__c = 'test';
        creds.ClientSecret__c = 'test';
        creds.AuthUri__c = 'test';
        creds.SoapUri__c = 'test';
        
        insert creds;
    }
}