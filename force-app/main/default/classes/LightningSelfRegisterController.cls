global without sharing class LightningSelfRegisterController {

    public LightningSelfRegisterController() {

    }

    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
        Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword, Boolean newsletter, Boolean industrySponsored) {
        Savepoint sp = null;
        try {
            System.debug('work');
            sp = Database.setSavepoint();
            
            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }
            
            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }
            
            User u = new User();
            u.Username = email;
            u.put('Email',email);
            
            u.FirstName = firstname;
            u.LastName = lastname;
            u.Newsletter__c= newsletter;
//            u.Industry_Sponsored_Emails__c= industrySponsored;

            SelfRegHelper.checkExistedUsers(email);
            String networkId = Network.getNetworkId();

            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }
            
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);
                     
            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    u.put(sof, thisField.get('value'));
                }
            }
                        
            if (includePassword) {    
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
             validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }




            List<Contact> duplicateContacts = [
                    SELECT Id, Email, FirstName, LastName, AccountId,
                            Title, Phone, MobilePhone
                    FROM Contact
                    WHERE Email = :email
                    ORDER BY CreatedDate DESC
            ];

            System.debug('duplicateContacts: '+duplicateContacts);
            System.debug('duplicateContacts.size: '+duplicateContacts.size());

            String userId;

            if (!duplicateContacts.isEmpty()) {
                //check if the contacts have active users
                List<User> users = [
                        SELECT Id, ContactId
                        FROM User
                        WHERE ContactId IN :duplicateContacts
                        AND IsPortalEnabled = TRUE
                ];

                Contact newCommunityContact;

                for (Contact contact : duplicateContacts) {
                    Boolean hasUser = false;

                    for (User user : users)
                        if (user.ContactId == contact.Id)
                            hasUser = true;

                    if (!hasUser) {
                        newCommunityContact = contact;
                        break;
                    }
                }

                System.debug('before newCommunityContact IF');
                if (newCommunityContact != null && networkId != null) {
                    System.debug('inside newCommunityContact IF');
                    Network community = [SELECT Id, SelfRegProfileId FROM Network WHERE Id = :networkId];
                    u.ProfileId = community.SelfRegProfileId;
                    u.Alias = Utils.getUserAlias(u.FirstName, u.LastName);
                    u.EmailEncodingKey = 'UTF-8';
                    u.ContactId = newCommunityContact.Id;
                    u.Username = email;

                    String contactTitle = !String.isBlank(newCommunityContact.Title) && newCommunityContact.Title.length() > 80 ? newCommunityContact.Title.substring(0, 80) : newCommunityContact.Title;

                    u.Title = contactTitle;
                    u.Phone = newCommunityContact.Phone;
                    u.MobilePhone = newCommunityContact.MobilePhone;
                    u.LanguageLocaleKey = UserInfo.getLanguage();
                    u.LocaleSidKey = UserInfo.getLocale();
                    u.TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone());

                    insert u;

                    userId = u.Id;
                }
            }

            if(userId == ''  || userId == null){
                System.debug('userId: '+userId);
                // lastName is a required field on user, but if it isn't specified, we'll default it to the username
                userId = Site.createPortalUser(u, accountId, password);
            }


            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';           
            }
            if (userId != null) { 
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                     aura.redirect(lgn);
                    }
                }
                else {
                    ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                    aura.redirect(confirmRef);
                   }

                }
            }
            return null;
        }
        catch (Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();            
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
        if (fieldSet != null) {
            for (Schema.FieldSetMember f : fieldSet.getFields()) {
                Map<String, Object> fieldDetail = new Map<String, Object>();
                fieldDetail.put('dbRequired', f.getDBRequired());
                fieldDetail.put('fieldPath', f.getFieldPath());
                fieldDetail.put('label', f.getLabel());
                fieldDetail.put('required', f.getRequired());
                fieldDetail.put('type', f.getType());
                fieldDetail.put('value', '');   // client will populate
                extraFields.add(fieldDetail);
            }}}
        return extraFields;
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    }
}