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
				AND Application_form__c != null
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
                'displayMembershipRenewalButton' => !String.isBlank(currentMembershipStatusToRenewalId) || !String.isBlank(previousMembershipStatusToRenewalId),
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

}