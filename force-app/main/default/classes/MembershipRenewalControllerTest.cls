@isTest
private class MembershipRenewalControllerTest {


	@isTest
	static void getPreparedDataTest() {

		Datetime now = System.now();

		Contact testContact1 = new Contact(
			FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com',
			Salutation = 'Prof.', Title = 'testTitle', Birthdate = (now.addYears(-50)).date(),
			Gender__c = 'Male', Nationality__c = 'Austria', Residency__c = 'Austria',
			MailingStreet = '1621 Walnut Street', MailingPostalCode = '60621', MailingCity = 'Chicago',
			Phone = '1234567890', Expected_Date_Of_Graduation__c = (now.addYears(-1)).date(), License_issued__c = (now.addYears(1)).date(),
			AAN_Member__c = true, Retired__c = true, Profession__c = 'Neurologist'
		);
		insert testContact1;

	}

	@isTest
	static void getContactCertificatesTest() {

		Contact testContact1 = new Contact(FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com');
		insert testContact1;

		ContentVersion newCertificateV = new ContentVersion(
				VersionData = Blob.valueOf('Unit.Test'),
				Title = 'Certificate_1.pdf',
				PathOnClient = '/Certificate_1.pdf',
				IsMajorVersion = true,
				SharingPrivacy = 'N',
				ContentLocation = 'S'
		);
		insert newCertificateV;

		List<ContentDocument> newCertificate = [SELECT Id FROM ContentDocument LIMIT 1];

		ContentDocumentLink certificateLink = new ContentDocumentLink(
			LinkedEntityId = testContact1.Id,
			ContentDocumentId = newCertificate[0].Id,
			shareType = 'V'
		);
		insert certificateLink;

		Map<String, Object> result = AllMyContactCertificatesController.getContactCertificates();
		System.assertEquals(true, !result.isEmpty());
	}

}