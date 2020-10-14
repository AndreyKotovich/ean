@IsTest
public class NewsletterSubscriptionControllerTest {
    @TestSetup
    public static void setupTest() {
        TestService.insertMcCustomSettings();

        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'Test1';

        Campaign testCampaign2 = new Campaign();
        testCampaign2.Name = 'Test2';

        insert new List<Campaign> { testCampaign1, testCampaign2};

        Contact newContact = new Contact();
        newContact.LastName = 'LastName';
        insert newContact;

    }

    @IsTest
    public static void getNewsletterList_Test() {
        Contact currentContact = [
            SELECT Id, LastName
            FROM Contact
            LIMIT 1
        ];

        Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');

        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :cmpgNames.Newsletter_Name__c OR Name = :cmpgNames.IPE_Name__c
        ]);

        Id campaignId = campaigns.values()[0].Id;

        CampaignMember newMember = new CampaignMember();
        newMember.ContactId = currentContact.Id;
        newMember.CampaignId = campaignId;
        insert newMember;

        String result = NewsletterSubscriptionController.getNewsletterList(currentContact.Id);
        List<NewsletterSubscriptionController.Subscription> resultList = (List<NewsletterSubscriptionController.Subscription>) JSON.deserialize(result, List<NewsletterSubscriptionController.Subscription>.class);
    
        System.assertEquals(campaigns.keySet().size(), resultList.size());
        for (NewsletterSubscriptionController.Subscription item : resultList) {
            System.assertEquals(true, campaigns.containsKey(item.campaignRecord.Id));
            if (item.campaignRecord.Id == campaignId) {
                System.assertEquals(true, item.isSubscribed);
            } else {
                System.assertEquals(false, item.isSubscribed);
            }
        }
    }

    @IsTest
    public static void updateSubscriptions_Test() {
        Contact currentContact = [
            SELECT Id, LastName
            FROM Contact
            LIMIT 1
        ];

        Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');

        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :cmpgNames.Newsletter_Name__c OR Name = :cmpgNames.IPE_Name__c
        ]);
        System.debug('campaignsTest');
        System.debug(campaigns);
        List<CampaignMember> members = new List<CampaignMember>();
        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND Campaign.Name = :cmpgNames.Newsletter_Name__c
        ];
        System.assertEquals(0, members.size());

        NewsletterSubscriptionController.updateSubscriptions(new List<Id>(campaigns.keySet()), currentContact.Id);
        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND (Campaign.Name = :cmpgNames.Newsletter_Name__c OR Campaign.Name = :cmpgNames.IPE_Name__c)
        ];
        System.assertEquals(campaigns.keySet().size(), members.size());

        NewsletterSubscriptionController.updateSubscriptions(new List<Id>(), currentContact.Id);

        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND Campaign.Name = :cmpgNames.Newsletter_Name__c
        ];
        System.assertEquals(0, members.size());
    }

    @IsTest
    public static void subscriptionManagement_Test() {
        Contact currentContact = [
            SELECT Id, LastName
            FROM Contact
            LIMIT 1
        ];
        
        Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');
        List<CampaignMember> members = new List<CampaignMember>();
        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND (Campaign.Name = :cmpgNames.Newsletter_Name__c OR Campaign.Name = :cmpgNames.IPE_Name__c)
        ];
        System.assertEquals(0, members.size());

        currentContact.Newsletter__c = true;
        update currentContact;

        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :cmpgNames.Newsletter_Name__c
        ]);

        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND Campaign.Name = :cmpgNames.Newsletter_Name__c
        ];
        System.assertEquals(campaigns.keySet().size(), members.size());

        currentContact.Newsletter__c = false;
        update currentContact;

        members = [
            SELECT Id, ContactId, CampaignId 
            FROM CampaignMember
            WHERE ContactId = :currentContact.Id AND Campaign.Name = :cmpgNames.Newsletter_Name__c
        ];
        System.assertEquals(0, members.size());
    }

    @IsTest
    public static void mc_Test() {
        Test.setMock(HttpCalloutMock.class, new McMock());
        Test.startTest();
        Contact currentContact = [
            SELECT Id, LastName
            FROM Contact
            LIMIT 1
        ];
        NewsletterSubscriptionController.createMcSubscribers(new Set<Id> { currentContact.Id});

        NewsletterSubscriptionController.McInfo mcInfo = NewsletterSubscriptionController.getMcAccessToken();
        System.assertEquals('successToken', mcInfo.access_token);
        Boolean isSubscribed = NewsletterSubscriptionController.checkMcSubscriberStatus(mcInfo, 'maksim.lavreniyk@succraft.com');
        System.assertEquals(false, isSubscribed);
        mcInfo.isSubscribed = isSubscribed;
        isSubscribed = NewsletterSubscriptionController.updateMcStatus('maksim.lavreniyk@succraft.com', JSON.serialize(mcInfo));
        System.assertEquals(true, isSubscribed);
        Test.stopTest();
    }

}