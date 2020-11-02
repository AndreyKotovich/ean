public with sharing class MembershipContainerController {
    @AuraEnabled public static String getCurrentContactMemberships(){
        List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        List<MembershipContactAssotiation__c> contactsMemberships = [SELECT Id, Expiration_date__c, Membership__r.Name, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c=:currentUser[0].ContactId AND IsActive__c=true];
        List<Application_form__c> contactAppForms = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Contact__c=:currentUser[0].ContactId];

        // return JSON.serialize(new Map<String, List<Object>>{'app-forms'=>contactAppForms, 'memberships'=>contactsMemberships});

        Map<String, Object> renewalSettings = collectRenewalInfo(contactsMemberships);
        return JSON.serialize(new Map<String, Object>{'app-forms'=>contactAppForms, 'memberships'=>contactsMemberships, 'renewalSettings' => renewalSettings});
    }


    public static Map<String, Object> collectRenewalInfo(List<MembershipContactAssotiation__c> contactsMemberships) {
        try {
            Datetime now = System.now();
            Datetime thisYearStart = Datetime.newInstanceGmt(now.yearGMT(), 1, 1, 0, 0, 0);
            Datetime nextYearStart = thisYearStart.addYears(1);
            Datetime previousYearStart = thisYearStart.addYears(1);

            List<String> membershipPriority = new List<String>{
                'Fellow of EAN (FEAN) Membership',
                'Full Membership',
                'Corresponding Membership',
                'Resident and Research Membership',
                'Student Membership'
            };

            String currentMembershipStatusToRenewalId = '';
            Integer currentMembershipStatusIndex = membershipPriority.size() + 1;
            String previousMembershipStatusToRenewalId = '';
            Integer previousMembershipStatusIndex = membershipPriority.size() + 1;
            for (MembershipContactAssotiation__c contactsMembership : contactsMemberships) {
                Integer membershipIndex = membershipPriority.indexOf(contactsMembership.Membership__r.Name);
                if (membershipIndex < 0) continue;

                //  priority 1: current year
                if (contactsMembership.Expiration_date__c != null
                    && contactsMembership.Expiration_date__c >= thisYearStart && contactsMembership.Expiration_date__c < nextYearStart
                    && membershipIndex < currentMembershipStatusIndex
                ) {
                    currentMembershipStatusToRenewalId = '' + contactsMembership.Id;
                    currentMembershipStatusIndex = membershipIndex;
                }

                //  priority 2: previous year
                if (contactsMembership.Expiration_date__c != null
                    && contactsMembership.Expiration_date__c >= thisYearStart && contactsMembership.Expiration_date__c < nextYearStart
                    && membershipIndex < previousMembershipStatusIndex
                ) {
                    previousMembershipStatusToRenewalId = '' + contactsMembership.Id;
                    previousMembershipStatusIndex = membershipIndex;
                }
            }

            return new Map<String, Object>{
                'result' => true,
                'membershipStatusToRenewalId' => !String.isBlank(currentMembershipStatusToRenewalId) ? currentMembershipStatusToRenewalId : previousMembershipStatusToRenewalId,
                'displayMembershipRenewalButton' => !String.isBlank(currentMembershipStatusToRenewalId) || !String.isBlank(previousMembershipStatusToRenewalId)
            };
		} catch (Exception e) {
            return new Map<String, Object>{
                'result' => false,
                'displayMembershipRenewalButton' => false,
                'message' => '[collectRenewalInfo] Error: ' + e.getMessage(),
                'messageStackTrace' => '[collectRenewalInfo] StackTrace: ' + e.getStackTraceString()
            };
		}
    }

}