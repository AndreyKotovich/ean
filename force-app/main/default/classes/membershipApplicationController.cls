public with sharing class membershipApplicationController {
    @AuraEnabled public static membershipApplicationWrapper getMemberships() {
        List<Membership__c> allmembrs = [SELECT Id, Name, API__c, isForUpdateMembershipApplication__c,
                www__c, (SELECT Id, Membership__c, Region__c, Price_for_Deadline_1__c,
                Price_for_Deadline_2__c, Price_for_Deadline_3__c FROM Country_Prices1__r) FROM Membership__c];
        List<Country_Price__c> countryPrices = new List<Country_Price__c>();
        for (Membership__c m : allmembrs) {
            for (Country_Price__c cp : m.Country_Prices1__r) {
                cp.Region__c = cp.Region__c == null ? 'Default' : cp.Region__c;
                countryPrices.add(cp);
            }
        }
        User user = [SELECT Contact.Id FROM User WHERE Id = :UserInfo.getUserId()];
        Contact cont = getContactForFormById(user.Contact.Id);
        List<Contact_Form__mdt> cf = [SELECT Id, Contact_field__c, Form_field__c FROM Contact_Form__mdt];
        List<Product2> product2s = [SELECT Id, Name, Product_use__c, IsActive, Description, (SELECT Id, Name, UnitPrice, Pricebook2.Name FROM PricebookEntries WHERE Pricebook2.IsActive=true) FROM Product2 WHERE Product_use__c INCLUDES ('Membership Application') AND IsActive = true];
        membershipApplicationWrapper wrapper = new membershipApplicationWrapper(
                allmembrs,
                countryPrices,
                cont,
                cf,
                product2s);
        return wrapper;
    }
    @AuraEnabled public static Contact getContactForFormById(String Id) {
        List<String> contactFieldForForm = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Contact.FieldSets.Form_fields.getFields()) {
            contactFieldForForm.add(f.getFieldPath());
        }
        String fields = String.join(contactFieldForForm, ',');
        List<Contact> cont = Database.query('SELECT ' + fields + ' FROM Contact WHERE Id=\'' + Id + '\'');
        return cont[0];
    }
    @AuraEnabled public static List<Country__mdt> getCountries() {
        List<Country__mdt> allCountries = [SELECT Id, Country__c, Country_code__c, Region__c, Label, is_in_europe__c, member_country__c FROM Country__mdt ORDER BY Label ASC];
        return allCountries;
    }
    @AuraEnabled public static List<List<String>> getFieldSets() {
        List<List<String>> allFieldSets = new List<List<String>>();
        List<String> firstFieldSet = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Application_form__c.FieldSets.Membership_application_form_part1.getFields()) {
            firstFieldSet.add(f.getFieldPath());
        }
        allFieldSets.add(firstFieldSet);

        List<String> secondFieldSet = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Application_form__c.FieldSets.Membership_application_form_part2.getFields()) {
            secondFieldSet.add(f.getFieldPath());
        }
        allFieldSets.add(secondFieldSet);
        return allFieldSets;
    }
    @AuraEnabled public static Application_form__c upsertForm(Application_form__c form) {
        try {
            upsert form;
            return form;
        } catch (Exception e) {
            String err = e.getMessage();
            if(err.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
            {
                List<String> tempErr = err.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                err = tempErr[1];
            }
            System.debug('err:: '+err);
            throw new AuraException(err);
        }
    }
    @AuraEnabled public static void updateContact(Contact contact) {
        try {
            update contact;
        } catch (Exception e) {
            String err = e.getMessage();
            if(err.contains('[Birthdate]')){
                err = 'Birthday cannot be in future.';
            } else if(err.contains('already exists')){
                err = 'A user account with this email address already exists. If you need further assistance, please contact headoffice@ean.org.';
            }
            AuraHandledException error = new AuraHandledException(err);
            error.setMessage(err);
            System.debug('err:: '+err);
            throw error;
        }
    }
    @AuraEnabled public static String getDeadline() {
        String deadline;
        Schema.DescribeSObjectResult cp = Country_Price__c.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = cp.fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            if (fieldName.contains('deadline')) {
                String label = Schema.getGlobalDescribe().get('Country_Price__c').getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
                List<String> dates = label.split('_');
                Date start = Date.valueOf(dates[0]);
                Date finish = Date.valueOf(dates[dates.size() - 1]);
                if (Date.today() >= start && Date.today() <= finish) {
                    deadline = String.valueOf(fieldsMap.get(fieldName));
                }
            }
        }
        return deadline;
    }
    @AuraEnabled public static void submitForApproval(String formId){
        String userId = UserInfo.getUserId();
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(formId);
        req1.setSubmitterId(userId);
        Approval.ProcessResult result = Approval.process(req1);
    }
    @AuraEnabled public static void deleteContentDocumentById(String docId){
        List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id =: docId];
        delete cd;
    }
    @AuraEnabled public static void attachFileToForm(List<ContentDocumentLink> contentDocumentLinks){
        // Checking if cdLink/cdLinks already exist
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        Boolean queryIsReady = false;
        String query = 'SELECT LinkedEntityId, Visibility, ContentDocumentId, ShareType FROM ContentDocumentLink WHERE ';
        for (ContentDocumentLink c : contentDocumentLinks) {
            query += '(LinkedEntityId = \'' +  c.LinkedEntityId +'\' AND ContentDocumentId = \'' + c.ContentDocumentId + '\') OR ';
        }
        if (query.contains('OR')) {
            query = query.substringBeforeLast('OR');
            queryIsReady = true;
        }
        if (queryIsReady) {
            List<ContentDocumentLink> existingLinks = Database.query(query);
            if(!existingLinks.isEmpty()){
                for (ContentDocumentLink c : contentDocumentLinks) {
                    Boolean isFound = false;
                    for (ContentDocumentLink c2 : existingLinks) {
                        if (c.LinkedEntityId == c2.LinkedEntityId && c.ContentDocumentId == c2.ContentDocumentId) {
                            isFound = true;
                        }
                    }
                    if(!isFound){
                        linksToInsert.add(c);
                    }
                }
            }else{
                linksToInsert = contentDocumentLinks.clone();
            }
        }
        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
    }
    @AuraEnabled public static Application_form__c getExistedForm(String formId){
        List<List<String>> formFields = getFieldSets();
        String queryFields = '';
        List<String> allFields = new List<String>();
        for(Integer i = 0; i<formFields.size(); i++){
            allFields.addAll(formFields[i]);
        }
        allFields.addAll(new List<String>{'Membership__c', 'Contact__c', 'Nationality__c', 'Residency__c', 'Form_Status__c', 'Expected_Date_Of_Graduation__c', 'License_issued__c', 'AAN_Member__c', 'Retired__c', 'Order__r.Purchase_Type__c' });
        queryFields = String.join(allFields, ',');
        System.debug(queryFields);
        List<Application_form__c> appForm = Database.query('SELECT '+queryFields + ' FROM Application_form__c WHERE Id=:formId');
        if(!appForm.isEmpty()){
//            if(appForm[0].Form_Status__c == 'Further Information Required'){
                return appForm[0];
//            } else {
//                throw new AuraException('This application cannot be re-submitted');
//            }
        } else{
            throw new AuraException('This application wasn\'t found' );
        }

    }
    @AuraEnabled public static List<ContentDocumentLink> getContentDocuments(String LinkedEntityId){
        return [SELECT Id, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId=:LinkedEntityId];
    }
    @AuraEnabled public static String getCommunityHomeUrl() {
        String result;
        if (!Test.isRunningTest()) {
            Network myNetwork = [SELECT Id FROM Network WHERE Name = 'ean'];
            ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            result = myCommunity.siteUrl;
        }else {
            result = 'community.com';
        }
        return result;
    }
    @AuraEnabled public static Map<String, Object> getOrderWithItems(String orderId){
        Map<String, Object> mapResult = new Map<String, Object>();
        List<Order__c> order = [SELECT Id, Status__c, Total_amount__c, Total_amount_Gros__c FROM Order__c WHERE Id = :orderId];
        if(!order.isEmpty()){
            mapResult.put('order', order[0]);
            List<Order_Item__c> orderItems = [SELECT Id, Membership__c, Product__c, Amount__c, Quantity__c FROM Order_Item__c WHERE Order_Custom__c = :order[0].Id];
            if(!orderItems.isEmpty()){
                mapResult.put('orderItems', orderItems);
            }
        }
        return mapResult;
    }
}