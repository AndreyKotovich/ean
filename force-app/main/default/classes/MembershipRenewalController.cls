public without sharing class MembershipRenewalController {

	public final static List<String> ALLOWED_REGIONS_TO_GET_AAN_DISCOUNT = new List<String>{'B', 'C', 'D', 'E', 'F', ''};
	public final static List<String> ALLOWED_REGIONS_TO_GET_RETIRED_DISCOUNT = new List<String>{'A', 'C'};		//	EANMR-4 David at 05/11/2020
	public final static List<String> ALLOWED_MEMBERS_TO_GET_RETIRED_DISCOUNT = new List<String>{'Full Membership', 'Corresponding Membership', 'Fellow of EAN (FEAN) Membership'};

	//	SUPPORTED_MEMBERSHIP_CATEGORIES_BY_PRIORITY (all other categories are not allow to be renewed)
	public final static List<String> MEMBERSHIP_CATEGORIES_BY_PRIORITY = new List<String>{
		'Fellow of EAN (FEAN) Membership',
		'Full Membership',
		'Corresponding Membership',
		'Resident and Research Membership',
		'Student Membership'
	};

	@AuraEnabled
	public static Map<String, Object> getPreparedData() {
		try {

			List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];

			Map<String, MembershipContactAssotiation__c> idToMembershipStatus = new Map<String, MembershipContactAssotiation__c>([
				SELECT Id, Contact__c, Expiration_date__c, Membership__c, Membership__r.Name, Membership__r.API__c, Membership__r.www__c,
					Application_form__c, Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName,
					Contact__r.Title, Contact__r.Birthdate, Contact__r.Gender__c,
					Contact__r.Email, Contact__r.Nationality__c, Contact__r.Residency__c,
					Contact__r.MailingStreet, Contact__r.MailingPostalCode, Contact__r.MailingCity,
					Contact__r.Phone, Contact__r.Expected_Date_Of_Graduation__c, Contact__r.License_issued__c,
					Contact__r.AAN_Member__c, Contact__r.Retired__c, Contact__r.Profession__c
				FROM MembershipContactAssotiation__c
				WHERE Contact__c =:currentUser[0].ContactId
				// AND Application_form__c != null
				AND IsActive__c = true
				LIMIT 20
			]);

			
			Map<String, Object> renewalSettings = collectRenewalInfo(idToMembershipStatus.values());
			String membershipStatusToRenewalId = renewalSettings.containsKey('membershipStatusToRenewalId') ? String.valueOf(renewalSettings.get('membershipStatusToRenewalId')) : '';
			//	Available Membership_Status not found OR error in 'collectRenewalInfo' OR 'alreadyExistMembershipStatusForNextYear'
			if (String.isBlank(membershipStatusToRenewalId)) {
				Map<String, Object> result = new Map<String, Object>{'result' => false};
				if (renewalSettings.containsKey('message')) result.put('message', renewalSettings.get('message'));
				if (renewalSettings.containsKey('messageStack')) result.put('messageStack', renewalSettings.get('messageStack'));
				if (renewalSettings.containsKey('alreadyExistMembershipStatusForNextYear')) result.put('alreadyExistMembershipStatusForNextYear', renewalSettings.get('alreadyExistMembershipStatusForNextYear'));
				return result;
			}

			//	regular flow
			MembershipContactAssotiation__c membershipStatus = idToMembershipStatus.get(membershipStatusToRenewalId);

			List<Map<String, String>> availableSalutations = Utils.picklistValues('Contact', 'Salutation');
			List<Map<String, String>> availableGenders = Utils.picklistValues('Contact', 'Gender__c');
			List<Map<String, String>> availableNationalities = Utils.picklistValues('Contact', 'Nationality__c');
			List<Map<String, String>> availableCountryOfResidences = Utils.picklistValues('Contact', 'Residency__c');

			String formCountryOfResidence = !String.isBlank(membershipStatus.Contact__r.Residency__c) ? membershipStatus.Contact__r.Residency__c : '';
			List<Country__mdt> countryList = !String.isBlank(formCountryOfResidence) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:formCountryOfResidence LIMIT 1] : new List<Country__mdt>();
			String membershipRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;
			Decimal renewalFee = calculateRenewalFee(membershipRegion, membershipStatus.Membership__c);

			//	EANMR-15, EANMR-16
			Boolean displayDateOfGraduation = membershipStatus.Membership__r.Name == 'Resident and Research Membership' || membershipStatus.Membership__r.Name == 'Student Membership';
			Boolean displayLicenseIssued = membershipStatus.Membership__r.Name == 'Resident and Research Membership';
			Boolean enableGraduationAndLicenseStep = (displayDateOfGraduation || displayLicenseIssued);
			Date now = System.now().date();
			Date minimumDateOfGraduation = membershipStatus.Membership__r.Name == 'Resident and Research Membership' ? now.addYears(-3)
				: membershipStatus.Membership__r.Name == 'Student Membership' ? now.addDays(1) : now;

			String currentYearString = System.now().format('YYYY');
			String nextYearString = System.now().addYears(1).format('YYYY');
			String communityHomeUrl = membershipApplicationController.getCommunityHomeUrl();

			return new Map<String, Object>{
				'result' => true,
				'currentContactId' => '' + membershipStatus.Contact__c,
				'membershipId' => '' + membershipStatus.Membership__c,
				'membershipName' => membershipStatus.Membership__r.Name,
				'membershipStatusId' => membershipStatusToRenewalId,
				'membershipRegion' => membershipRegion,
				'membershipURL' => membershipStatus.Membership__r.www__c,
				'applicationFormId' => '' + membershipStatus.Application_form__c,
				'renewalFee' => renewalFee,
				'currentYearString' => currentYearString,
				'nextYearString' => currentYearString,
				'communityHomeUrl' => communityHomeUrl,

				//	EANMR-2, EANMR-5	//	STEP 1
				'formSalutation' => !String.isBlank(membershipStatus.Contact__r.Salutation) ? membershipStatus.Contact__r.Salutation : '--None--',
				'formFirstName' => !String.isBlank(membershipStatus.Contact__r.FirstName) ? membershipStatus.Contact__r.FirstName : '',
				'formLastName' => !String.isBlank(membershipStatus.Contact__r.LastName) ? membershipStatus.Contact__r.LastName : '',
				'formPostNominalTitle' => !String.isBlank(membershipStatus.Contact__r.Title) ? membershipStatus.Contact__r.Title : '',
				'formDateOfBirth' => membershipStatus.Contact__r.Birthdate,
				'formGender' => !String.isBlank(membershipStatus.Contact__r.Gender__c) ? membershipStatus.Contact__r.Gender__c : '--None--',
				'formEmail' => !String.isBlank(membershipStatus.Contact__r.Email) ? membershipStatus.Contact__r.Email : '',
				'formNationality' => !String.isBlank(membershipStatus.Contact__r.Nationality__c) ? membershipStatus.Contact__r.Nationality__c : '',
				'formCountryOfResidence' => formCountryOfResidence,
				'formStreet' => !String.isBlank(membershipStatus.Contact__r.MailingStreet) ? membershipStatus.Contact__r.MailingStreet : '',
				'formZipPostalCode' => !String.isBlank(membershipStatus.Contact__r.MailingPostalCode) ? membershipStatus.Contact__r.MailingPostalCode : '',
				'formCity' => !String.isBlank(membershipStatus.Contact__r.MailingCity) ? membershipStatus.Contact__r.MailingCity : '',
				'formPhoneNumber' => !String.isBlank(membershipStatus.Contact__r.Phone) ? membershipStatus.Contact__r.Phone : '',
				'formIamAANMember' => Boolean.valueOf(membershipStatus.Contact__r.AAN_Member__c),
				'formIamRetired' => Boolean.valueOf(membershipStatus.Contact__r.Retired__c),
				'formProfession' => !String.isBlank(membershipStatus.Contact__r.Profession__c) ? membershipStatus.Contact__r.Profession__c : '',

				'availableSalutations' => availableSalutations,
				'availableGenders' => availableGenders,
				'availableNationalities' => availableNationalities,
				'availableCountryOfResidences' => availableCountryOfResidences,

				'allowAANMemberDiscount' => ALLOWED_REGIONS_TO_GET_AAN_DISCOUNT.contains(membershipRegion),
				'allowRetiredDiscount' => ALLOWED_REGIONS_TO_GET_RETIRED_DISCOUNT.contains(membershipStatus.Membership__r.Name) && ALLOWED_MEMBERS_TO_GET_RETIRED_DISCOUNT.contains(membershipRegion),

				'enableEditFromDateOfBirth' => membershipStatus.Contact__r.Birthdate == null,
				'enableNextButtonStep1' => renewalFee != 9999,

				//	EANMR-15, EANMR-16	// STEP 2
				'enableGraduationAndLicenseStep' => enableGraduationAndLicenseStep,
				'minimumDateOfGraduation' => minimumDateOfGraduation,
				'dateOfGraduation' => membershipStatus.Contact__r.Expected_Date_Of_Graduation__c,
				'licenseIssuedDate' => membershipStatus.Contact__r.License_issued__c,
				'displayDateOfGraduation' => displayDateOfGraduation,
				'displayLicenseIssued' => displayLicenseIssued
			};


		} catch (Exception e) {
			system.debug('MembershipRenewalController getPreparedData ERROR message: ' + e.getMessage());
			system.debug('MembershipRenewalController getPreparedData ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	public static Map<String, Object> collectRenewalInfo(List<MembershipContactAssotiation__c> contactsMemberships) {
		try {
			Datetime now = System.now();
			Datetime thisYearStart = Datetime.newInstanceGmt(now.yearGMT(), 1, 1, 0, 0, 0);
			Datetime nextYearStart = thisYearStart.addYears(1);
			Datetime previousYearStart = thisYearStart.addYears(1);

			String currentMembershipStatusToRenewalId = '';
			Integer currentMembershipStatusIndex = MEMBERSHIP_CATEGORIES_BY_PRIORITY.size() + 1;
			String previousMembershipStatusToRenewalId = '';
			Integer previousMembershipStatusIndex = MEMBERSHIP_CATEGORIES_BY_PRIORITY.size() + 1;

			Boolean alreadyExistMembershipStatusForNextYear = false;

			for (MembershipContactAssotiation__c contactsMembership : contactsMemberships) {
				Integer membershipIndex = MEMBERSHIP_CATEGORIES_BY_PRIORITY.indexOf(contactsMembership.Membership__r.Name);
				
				if (membershipIndex < 0) continue;

				//  priority 0: exist for next year
				if (contactsMembership.Expiration_date__c != null
					&& contactsMembership.Expiration_date__c >= nextYearStart
				) {
					alreadyExistMembershipStatusForNextYear = true;
					currentMembershipStatusToRenewalId = '';
					previousMembershipStatusToRenewalId = '';
				}

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
				'displayMembershipRenewalButton' => (!String.isBlank(currentMembershipStatusToRenewalId) || !String.isBlank(previousMembershipStatusToRenewalId)) && !alreadyExistMembershipStatusForNextYear,
				'alreadyExistMembershipStatusForNextYear' => alreadyExistMembershipStatusForNextYear
			};
		} catch (Exception e) {
			return new Map<String, Object>{
				'result' => false,
				'displayMembershipRenewalButton' => false,
				'message' => '[collectRenewalInfo] Error: ' + e.getMessage(),
				'messageStack' => '[collectRenewalInfo] StackTrace: ' + e.getStackTraceString()
			};
		}
	}

	@AuraEnabled
	public static Map<String, Object> recalculateRenewalFee(Map<String, Object> params) {
		try {
			String formCountryOfResidence = params.containsKey('formCountryOfResidence') ? String.valueOf(params.get('formCountryOfResidence')) : '';
			String membershipId = params.containsKey('membershipId') ? String.valueOf(params.get('membershipId')) : '';
			String membershipName = params.containsKey('membershipName') ? String.valueOf(params.get('membershipName')) : '';
			if (String.isBlank(formCountryOfResidence) || String.isBlank(membershipId)) {
				return new Map<String, Object>{
					'result' => false, 'resultMessage' => 'Not All Params Are Defined (' + formCountryOfResidence + ' / ' + membershipId + ')'
				};
			}

			List<Country__mdt> countryList = !String.isBlank(formCountryOfResidence) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:formCountryOfResidence LIMIT 1] : new List<Country__mdt>();
			if (countryList.isEmpty()) return new Map<String, Object>{'result' => false, 'resultMessage' => 'Country Error.'};

			String membershipRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;
			Decimal renewalFee = calculateRenewalFee(membershipRegion, membershipId);
			if (renewalFee == 9999) return new Map<String, Object>{'result' => false, 'resultMessage' => 'Calculate Renewal Fee Error.'};

			return new Map<String, Object>{
				'result' => true,
				'renewalFee' => renewalFee,
				'allowAANMemberDiscount' => ALLOWED_REGIONS_TO_GET_AAN_DISCOUNT.contains(membershipRegion),
				'allowRetiredDiscount' => ALLOWED_MEMBERS_TO_GET_RETIRED_DISCOUNT.contains(membershipName) && ALLOWED_REGIONS_TO_GET_RETIRED_DISCOUNT.contains(membershipRegion)
			};

		} catch (Exception e) {
			system.debug('MembershipRenewalController recalculateRenewalFee ERROR message: ' + e.getMessage());
			system.debug('MembershipRenewalController recalculateRenewalFee ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'resultMessage' => 'Calculate Renewal Fee Error', 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	//	also used in CallForRenewalEmailTemplateController.cls
	public static Decimal calculateRenewalFee(String membershipRegion, Id membershipId) {

		List<Country_Price__c> countryPrice = [
			SELECT Id, Name, price_for_deadline_1__c,
				price_for_deadline_2__c, price_for_deadline_3__c
			FROM Country_Price__c
			WHERE Region__c =:membershipRegion
			AND Membership__c =:membershipId
			LIMIT 1
		];

		return countryPrice.isEmpty() ? 9999 : countryPrice[0].price_for_deadline_1__c;
	}

	@AuraEnabled
	public static void deleteContentDocumentById(String recordId){
		delete [SELECT Id FROM ContentDocument WHERE Id =:recordId];
	}

	@AuraEnabled
	public static Map<String, Object> submitRenewal(Map<String, Object> params) {
		try {
	
			String membershipId = params.containsKey('membershipId') ? String.valueOf(params.get('membershipId')) : '';
			String membershipName = params.containsKey('membershipName') ? String.valueOf(params.get('membershipName')) : '';
			String membershipStatusId = params.containsKey('membershipStatusId') ? String.valueOf(params.get('membershipStatusId')) : '';

			String currentContactId = params.containsKey('currentContactId') ? String.valueOf(params.get('currentContactId')) : '';
			String formSalutation = params.containsKey('formSalutation') ? String.valueOf(params.get('formSalutation')) : '';
			String formFirstName = params.containsKey('formFirstName') ? String.valueOf(params.get('formFirstName')) : '';
			String formLastName = params.containsKey('formLastName') ? String.valueOf(params.get('formLastName')) : '';
			String formPostNominalTitle = params.containsKey('formPostNominalTitle') ? String.valueOf(params.get('formPostNominalTitle')) : '';
			Date formDateOfBirth = params.containsKey('formDateOfBirth') ? Date.valueOf(String.valueOf(params.get('formDateOfBirth'))) : null;
			String formGender = params.containsKey('formGender') ? String.valueOf(params.get('formGender')) : '';
			String formEmail = params.containsKey('formEmail') ? String.valueOf(params.get('formEmail')) : '';
			String formNationality = params.containsKey('formNationality') ? String.valueOf(params.get('formNationality')) : '';
			String formCountryOfResidence = params.containsKey('formCountryOfResidence') ? String.valueOf(params.get('formCountryOfResidence')) : '';
			String formStreet = params.containsKey('formStreet') ? String.valueOf(params.get('formStreet')) : '';
			String formZipPostalCode = params.containsKey('formZipPostalCode') ? String.valueOf(params.get('formZipPostalCode')) : '';
			String formCity = params.containsKey('formCity') ? String.valueOf(params.get('formCity')) : '';
			String formPhoneNumber = params.containsKey('formPhoneNumber') ? String.valueOf(params.get('formPhoneNumber')) : '';
			Boolean formIamAANMember = params.containsKey('formIamAANMember') ? Boolean.valueOf(params.get('formIamAANMember')) : false;
			Boolean formIamRetired = params.containsKey('formIamRetired') ? Boolean.valueOf(params.get('formIamRetired')) : false;
			String formProfession = params.containsKey('formProfession') ? String.valueOf(params.get('formProfession')) : '';

			Date dateOfGraduation = params.containsKey('dateOfGraduation') ? Date.valueOf(String.valueOf(params.get('dateOfGraduation'))) : null;
			Date licenseIssuedDate = params.containsKey('licenseIssuedDate') ? Date.valueOf(String.valueOf(params.get('licenseIssuedDate'))) : null;

			String uploadedFilesPillsString = params.containsKey('uploadedFilesPillsString') ? String.valueOf(params.get('uploadedFilesPillsString')) : '';
			List<Map <String, String>> uploadedFilesPills = !String.isBlank(uploadedFilesPillsString) ? (List<Map <String, String>>) JSON.deserialize(uploadedFilesPillsString, List<Map <String, String>>.class) : new List<Map <String, String>>();

			// used to generate order
			String totalRenewalFeeString = params.containsKey('totalRenewalFee') ? String.valueOf(params.get('totalRenewalFee')) : '';
			Decimal totalRenewalFee = !String.isBlank(totalRenewalFeeString) ? Decimal.valueOf(totalRenewalFeeString) : 0;

			String selectedJournalsString = params.containsKey('selectedJournalsString') ? String.valueOf(params.get('selectedJournalsString')) : '';
			List<JournalWrap> selectedJournals = !String.isBlank(selectedJournalsString) ? (List<JournalWrap>) JSON.deserialize(selectedJournalsString, List<JournalWrap>.class) : new List<JournalWrap>();
			Id generatedOrderId = generateOrder(membershipId, totalRenewalFee, selectedJournals, currentContactId);

			List<MembershipContactAssotiation__c> prevMembershipStatus = [
				SELECT Id, Assignment_date__c, Next_Membership_Status__c, Role__c
				FROM MembershipContactAssotiation__c
				WHERE Id =:membershipStatusId
				AND IsActive__c = true
				LIMIT 1
			];

			if (prevMembershipStatus .isEmpty() || String.isBlank(membershipId) || String.isBlank(currentContactId) || String.isBlank(formFirstName)
				|| String.isBlank(formLastName) || formDateOfBirth == null || String.isBlank(formEmail)) {
				return new Map<String, Object>{
					'result' => false, 'resultMessage' => 'Not All Params Are Defined (' + currentContactId + ' / ' + formFirstName  + ' / ' + formLastName + ' / ' + formDateOfBirth + ' / ' + formEmail + ')'
				};
			}

			// update contact record
			update new Contact(
				Id = currentContactId, Salutation = formSalutation, FirstName = formFirstName, LastName = formLastName,
				Title = formPostNominalTitle, Birthdate = formDateOfBirth, Gender__c = formGender, Email = formEmail,
				Nationality__c = formNationality, Residency__c = formCountryOfResidence, MailingStreet = formStreet,
				MailingPostalCode = formZipPostalCode, MailingCity = formCity, Phone = formPhoneNumber,
				AAN_Member__c = formIamAANMember, Retired__c = formIamRetired, Profession__c = formProfession,
				Expected_Date_Of_Graduation__c = dateOfGraduation, License_issued__c = licenseIssuedDate
			);

			//	insert new Application_form__c
			Application_form__c newApplicationForm = new Application_form__c(
				Salutation__c = formSalutation, First_name__c = formFirstName, Last_name__c = formLastName,
				Post_nominal_Title__c = formPostNominalTitle, Date_of_birth__c = formDateOfBirth,
				Gender__c = formGender, Email__c = formEmail, Street__c = formStreet, ZIP_Postal_code__c = formZipPostalCode,
				City__c = formCity, Phone_number__c = formPhoneNumber, Profession__c = formProfession,
				Expected_Date_Of_Graduation__c = dateOfGraduation, License_issued__c = licenseIssuedDate,
				Order__c = generatedOrderId, Contact__c = currentContactId,
				Form_Status__c = membershipName == 'Student Membership' ? 'Submitted' : 'Approved',
				Nationality__c = formNationality, Residency__c = formCountryOfResidence, Membership__c = membershipId,
				AAN_Member__c = formIamAANMember, Retired__c = formIamRetired
			);
			insert newApplicationForm;
			attachFilesToForm(uploadedFilesPills, currentContactId, newApplicationForm.Id);

			String lockResultString = '';

			if (membershipName == 'Student Membership') {
				submitForApproval('' + newApplicationForm.Id);
			} else {
				Approval.LockResult lockResult = Approval.lock(newApplicationForm.Id, false);
				lockResultString = JSON.serialize(lockResult);
			}


			Datetime now = System.now();
			// Datetime thisYearStart = Datetime.newInstance(now.yearGMT(), 1, 1, 0, 0, 0);
			Datetime thisYearStart = Datetime.newInstance(now.year(), 1, 1, 0, 0, 0);
			// Datetime thisYearStart = Datetime.newInstanceGmt(now.yearGMT(), 1, 1, 0, 0, 0);
			Datetime nextYearEnd = thisYearStart.addYears(2).addMinutes(-1);

			MembershipContactAssotiation__c newMembershipStatus = new MembershipContactAssotiation__c(
				Application_form__c = newApplicationForm.Id,
				// Assignment_date__c = now.Date(),
				Assignment_date__c = prevMembershipStatus[0].Assignment_date__c,
				Contact__c = currentContactId,
				Expiration_date__c = nextYearEnd,
				Membership__c = membershipId,
				Role__c = prevMembershipStatus[0].Role__c
			);
			insert newMembershipStatus;
			update new MembershipContactAssotiation__c(Id = membershipStatusId, Next_Membership_Status__c = newMembershipStatus.Id);

			return new Map<String, Object>{
				'lockResultString' => lockResultString,
				'result' => true,
				'orderId' => generatedOrderId
			};

		} catch (Exception e) {
			system.debug('MembershipRenewalController submitRenewal ERROR message: ' + e.getMessage());
			system.debug('MembershipRenewalController submitRenewal ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'resultMessage' => 'Submit Renewal Error', 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	public class JournalWrap {
		@AuraEnabled public String journalProductId { get; set; }
		@AuraEnabled public String journalPrice { get; set; }
	}

	public static Id generateOrder(String membershipId, Decimal totalRenewalFee, List<JournalWrap> selectedJournals, String currentContactId) {

		Decimal journalsPrices = 0;

		Map<String, Decimal> productIdToPrice = new Map <String, Decimal>();

		for (JournalWrap selectedJournal : selectedJournals) {
			if (String.isBlank(selectedJournal.journalPrice) || String.isBlank(selectedJournal.journalProductId)) continue;
			Decimal journalPrice = Decimal.valueOf(selectedJournal.journalPrice);
			productIdToPrice.put(selectedJournal.journalProductId, journalPrice);
			journalsPrices = journalsPrices + journalPrice;
		}

		Datetime now = System.now();

		Order__c newOrder = new Order__c(
			Billing_address__c = '',
			Contact__c = currentContactId,
			Payment_Date__c = totalRenewalFee + journalsPrices == 0 ? now : null,
			Purchase_Type__c = 'New',
			Status__c = totalRenewalFee + journalsPrices == 0 ? 'Paid' : 'Opened',
			Type__c = 'Renewal'
		);
		insert newOrder;

		List<Order_Item__c> orderItems = new List<Order_Item__c>();
		orderItems.add(new Order_Item__c(
			Amount__c = totalRenewalFee,
			Membership__c = membershipId,
			Order_Custom__c = newOrder.Id,
			Quantity__c = 1
		));

		for (String productId : productIdToPrice.keySet()) {
			orderItems.add(new Order_Item__c(
				Amount__c = productIdToPrice.get(productId),
				Product__c = productId,
				Order_Custom__c = newOrder.Id,
				Quantity__c = 1
			));
		}
		insert orderItems;

		//	create transaction for ZERO amount order
		if (totalRenewalFee + journalsPrices == 0) {
			Transaction__c zeroTransaction = new Transaction__c(
				Amount__c = 0,
				Completion_Time_Stamp__c = now,
				JSONResponse__c = 'None',
				Order_Custom__c = newOrder.Id,
				Status__c = 'Success'
			);
			insert zeroTransaction;
		}

		return newOrder.Id;
	}

	public static void submitForApproval(String formId) {
		String userId = UserInfo.getUserId();
		Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
		req1.setObjectId(formId);
		req1.setSubmitterId(userId);
		Approval.ProcessResult result = Approval.process(req1);
	}

	public static void attachFilesToForm(List<Map <String, String>> uploadedFilesPills, String currentContactId, Id applicationFormId) {

		Set<Id> documentIdList = new Set<Id>();
		for (Map <String, String> uploadedFilePill : uploadedFilesPills) {
			documentIdList.add(Id.valueOf(uploadedFilePill.get('documentId')));
		}

		List<ContentDocumentLink> existingLinks = [
			SELECT Id, LinkedEntityId, Visibility, ContentDocumentId, ShareType
			FROM ContentDocumentLink
			WHERE ContentDocumentId IN :documentIdList
			AND LinkedEntityId =:currentContactId
		];

		List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
		Set<Id> processedDocumentIdList = new Set<Id>();
		for (ContentDocumentLink existingLink : existingLinks) {
			if (processedDocumentIdList.contains(existingLink.ContentDocumentId)) continue;
			processedDocumentIdList.add(existingLink.ContentDocumentId);

			existingLink.Id = null;
			existingLink.LinkedEntityId = applicationFormId;
			linksToInsert.add(existingLink);
		}

		if (!linksToInsert.isEmpty()) insert linksToInsert;
	}

}