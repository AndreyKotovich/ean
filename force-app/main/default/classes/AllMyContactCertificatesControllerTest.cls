@isTest
private class AllMyContactCertificatesControllerTest {

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