@isTest
private class MembershipRenewalControllerTest {

	@isTest
	static void membershipRenewalTest() {
		Datetime now = System.now();
		Datetime thisYearStart = Datetime.newInstance(now.year(), 1, 1, 0, 0, 0);
		Datetime nextYearStart = thisYearStart.addYears(1);
		Datetime previousYearStart = thisYearStart.addYears(1);

		Contact testContact1 = new Contact(
			FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com',
			Salutation = 'Prof.', Title = 'testTitle', Birthdate = (now.addYears(-50)).date(),
			Gender__c = 'Male', Nationality__c = 'Austria', Residency__c = 'Austria',
			MailingStreet = '1621 Walnut Street', MailingPostalCode = '60621', MailingCity = 'Chicago',
			Phone = '1234567890', Expected_Date_Of_Graduation__c = (now.addYears(-1)).date(), License_issued__c = (now.addYears(1)).date(),
			AAN_Member__c = true, Retired__c = true, Profession__c = 'Neurologist'
		);
		insert testContact1;

		Membership__c membership = new Membership__c(
			Name = 'Full Membership', API__c = 'full_membership', 
			isForUpdateMembershipApplication__c = true, www__c = 'https://www.ean.org/Full-Member.3801.0.html'
		);
		insert membership;

		Country_Price__c priceA = new Country_Price__c(
			price_for_deadline_1__c = 1000,
			Membership__c = membership.Id,
			Region__c = 'A'
		);
		insert priceA;

		Application_form__c appForm = new Application_form__c(
				First_name__c = 'Test', Last_name__c = 'Contact', Date_of_birth__c = testContact1.Birthdate,
				Gender__c = 'Male', Email__c = 'test@email.com', Nationality__c = 'Austria',
				Residency__c = 'Austria', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = testContact1.Id, Membership__c = membership.Id,
				Profession__c = 'Other', Street__c = 'TestStreet', Form_Status__c = 'Approved');
		insert appForm;

		MembershipContactAssotiation__c membershipStatus = new MembershipContactAssotiation__c(
			Contact__c = testContact1.Id, Membership__c = membership.Id,
			Application_form__c = appForm.Id,
			Expiration_date__c = (thisYearStart.addDays(-1)).date()
		);
		insert membershipStatus;

		Map<String, Object> result = MembershipRenewalController.getPreparedData();
		System.assertEquals(true, Boolean.valueOf(result.get('result')));

		result = MembershipRenewalController.recalculateRenewalFee(
			new Map<String, Object>{
				'formCountryOfResidence' => 'Austria',
				'membershipId' => '' + membership.Id,
				'membershipName' => membership.Name
			}
		);
		MembershipRenewalController.deleteContentDocumentById(null);

		System.assertEquals(1000, Decimal.valueOf(String.valueOf(result.get('renewalFee'))));

		result = MembershipRenewalController.submitRenewal(
			new Map<String, Object>{
				'membershipId' => '' + membership.Id,
				'membershipName' => membership.Name,
				'membershipStatusId' => '' + membershipStatus.Id,
				'applicationFormId' => '',
				'currentContactId' => '' + testContact1.Id,
				'formSalutation' => 'Prof.',
				'formFirstName' => 'testFirst1',
				'formLastName' => 'testLast1',
				'formPostNominalTitle' => 'testTitle',
				'formDateOfBirth' => testContact1.Birthdate,
				'formGender' => 'Male',
				'formEmail' => 'testmail1@nomail.com',
				'formNationality' => 'Austria',
				'formCountryOfResidence' => 'Austria',
				'formStreet' => '1621 Walnut Street',
				'formZipPostalCode' => '60621',
				'formCity' => 'Chicago',
				'formPhoneNumber' => '1234567890',
				'formIamAANMember' => true,
				'formIamRetired' => true,
				'formProfession' => 'Neurologist',
				'dateOfGraduation' => (now.addYears(-1)).date(),
				'licenseIssuedDate' => (now.addYears(1)).date(),
				'uploadedFilesPillsString' => '',
				'totalRenewalFee' => '1000',
				'selectedJournalsString' => ''
			}
		);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
		System.assertEquals(1, [SELECT COUNT() FROM Order__c]);
	}

	@isTest
	static void getAppFormInfoTest() {
		Datetime now = System.now();
		Datetime thisYearStart = Datetime.newInstance(now.year(), 1, 1, 0, 0, 0);
		Datetime nextYearStart = thisYearStart.addYears(1);
		Datetime previousYearStart = thisYearStart.addYears(1);

		Contact testContact1 = new Contact(
			FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com',
			Salutation = 'Prof.', Title = 'testTitle', Birthdate = (now.addYears(-50)).date(),
			Gender__c = 'Male', Nationality__c = 'Austria', Residency__c = 'Austria',
			MailingStreet = '1621 Walnut Street', MailingPostalCode = '60621', MailingCity = 'Chicago',
			Phone = '1234567890', Expected_Date_Of_Graduation__c = (now.addYears(-1)).date(), License_issued__c = (now.addYears(1)).date(),
			AAN_Member__c = true, Retired__c = true, Profession__c = 'Neurologist'
		);
		insert testContact1;

		Membership__c membership = new Membership__c(
			Name = 'student_membership', API__c = 'student_membership', 
			isForUpdateMembershipApplication__c = true, www__c = 'https://www.ean.org/Full-Member.3801.0.html'
		);
		insert membership;


		Application_form__c testForm = new Application_form__c(
			First_name__c = 'testFirst1', Last_name__c = 'testLast1', Date_of_birth__c = Date.today(),
			Gender__c = 'Male', Email__c = 'testmail1@nomail.com', Nationality__c = 'United States',
			Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = testContact1.Id, Membership__c = membership.Id,
			Profession__c = 'Other', Street__c = 'TestStreet', Form_Status__c = 'Submitted', Renewal_End_Date__c = nextYearStart.addYears(1)
		);
		insert testForm;

		Map<String, Object> result = MembershipRenewalController.getAppFormInfo(new Map<String, Object>{'recordId' => '' + testForm.Id});
		System.assertEquals(true, Boolean.valueOf(result.get('result')));

		MRenewalStudentMisInformationController contr = new MRenewalStudentMisInformationController();
		contr.appFormId = '' + testForm.Id;
		String testString = contr.getLastApprovalComment();

		result = MembershipRenewalController.updateAppFormApproval(new Map<String, Object>{'action' => 'Reject', 'appFormId' => '' + testForm.Id, 'formStatus' => 'Submitted', 'contactId' => '' + testContact1.Id});
		System.assertEquals(false, result.isEmpty());
	}
}