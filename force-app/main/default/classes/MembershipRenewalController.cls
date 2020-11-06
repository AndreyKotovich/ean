public without sharing class MembershipRenewalController {
	@AuraEnabled
	public static Map<String, Object> getPreparedData() {
		try {

			List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];

			Map<String, MembershipContactAssotiation__c> idToMembershipStatus = new Map<String, MembershipContactAssotiation__c>([
				SELECT Id, Contact__c, Expiration_date__c, Membership__c, Membership__r.Name, Membership__r.API__c,
					Application_form__c, Application_form__r.Salutation__c, Application_form__r.First_name__c, Application_form__r.Last_name__c,
					Application_form__r.Post_nominal_Title__c, Application_form__r.Date_of_birth__c, Application_form__r.Gender__c,
					Application_form__r.Email__c, Application_form__r.Nationality__c, Application_form__r.Residency__c,
					Application_form__r.Street__c, Application_form__r.ZIP_Postal_code__c, Application_form__r.City__c,
					Application_form__r.Phone_number__c, Application_form__r.Expected_Date_Of_Graduation__c, Application_form__r.License_issued__c,
					Application_form__r.Retired__c
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

			List<Map<String, String>> availableSalutations = Utils.picklistValues('Application_form__c', 'Salutation__c');
			List<Map<String, String>> availableGenders = Utils.picklistValues('Application_form__c', 'Gender__c');
			List<Map<String, String>> availableNationalities = Utils.picklistValues('Application_form__c', 'Nationality__c');
			List<Map<String, String>> availableCountryOfResidences = Utils.picklistValues('Application_form__c', 'Residency__c');

			String formCountryOfResidence = !String.isBlank(membershipStatus.Application_form__r.Residency__c) ? membershipStatus.Application_form__r.Residency__c : '';
			List<Country__mdt> countryList = !String.isBlank(formCountryOfResidence) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:formCountryOfResidence LIMIT 1] : new List<Country__mdt>();
			String membershipRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;
			Decimal totalRenewalFee = calculateTotalRenewalFee(membershipRegion, membershipStatus.Membership__c);

			//	EANMR-15, EANMR-16
			Boolean displayDateOfGraduation = membershipStatus.Membership__r.Name == 'Resident and Research Membership' || membershipStatus.Membership__r.Name == 'Student Membership';
			Boolean displayLicenseIssued = membershipStatus.Membership__r.Name == 'Resident and Research Membership';
			Boolean enableGraduationAndLicenseStep = (displayDateOfGraduation || displayLicenseIssued);
			Date now = System.now().date();
			Date minimumDateOfGraduation = membershipStatus.Membership__r.Name == 'Resident and Research Membership' ? now.addYears(-3)
				: membershipStatus.Membership__r.Name == 'Student Membership' ? now.addDays(1) : now;


			

			return new Map<String, Object>{
				'result' => true,
				'currentContactId' => '' + membershipStatus.Contact__c,
				'membershipId' => '' + membershipStatus.Membership__c,
				'membershipName' => '' + membershipStatus.Membership__r.Name,
				'membershipStatusId' => membershipStatusToRenewalId,
				'applicationFormId' => '' + membershipStatus.Application_form__c,
				'totalRenewalFee' => totalRenewalFee,

				//	EANMR-2, EANMR-5	//	STEP 1
				'formSalutation' => !String.isBlank(membershipStatus.Application_form__r.Salutation__c) ? membershipStatus.Application_form__r.Salutation__c : '--None--',
				'formFirstName' => !String.isBlank(membershipStatus.Application_form__r.First_name__c) ? membershipStatus.Application_form__r.First_name__c : '',
				'formLastName' => !String.isBlank(membershipStatus.Application_form__r.Last_name__c) ? membershipStatus.Application_form__r.Last_name__c : '',
				'formPostNominalTitle' => !String.isBlank(membershipStatus.Application_form__r.Post_nominal_Title__c) ? membershipStatus.Application_form__r.Post_nominal_Title__c : '',
				'formDateOfBirth' => membershipStatus.Application_form__r.Date_of_birth__c,
				'formGender' => !String.isBlank(membershipStatus.Application_form__r.Gender__c) ? membershipStatus.Application_form__r.Gender__c : '--None--',
				'formEmail' => !String.isBlank(membershipStatus.Application_form__r.Email__c) ? membershipStatus.Application_form__r.Email__c : '',
				'formNationality' => !String.isBlank(membershipStatus.Application_form__r.Nationality__c) ? membershipStatus.Application_form__r.Nationality__c : '',
				'formCountryOfResidence' => formCountryOfResidence,
				'formStreet' => !String.isBlank(membershipStatus.Application_form__r.Street__c) ? membershipStatus.Application_form__r.Street__c : '',
				'formZipPostalCode' => !String.isBlank(membershipStatus.Application_form__r.ZIP_Postal_code__c) ? membershipStatus.Application_form__r.ZIP_Postal_code__c : '',
				'formCity' => !String.isBlank(membershipStatus.Application_form__r.City__c) ? membershipStatus.Application_form__r.City__c : '',
				'formPhoneNumber' => !String.isBlank(membershipStatus.Application_form__r.Phone_number__c) ? membershipStatus.Application_form__r.Phone_number__c : '',

				'availableSalutations' => availableSalutations,
				'availableGenders' => availableGenders,
				'availableNationalities' => availableNationalities,
				'availableCountryOfResidences' => availableCountryOfResidences,

				'enableEditFromDateOfBirth' => membershipStatus.Application_form__r.Date_of_birth__c == null,
				'enableNextButtonStep1' => totalRenewalFee != 9999,

				//	EANMR-15, EANMR-16	// STEP 2
				'enableGraduationAndLicenseStep' => enableGraduationAndLicenseStep,
				'minimumDateOfGraduation' => minimumDateOfGraduation,
				'dateOfGraduation' => membershipStatus.Application_form__r.Expected_Date_Of_Graduation__c,
				'licenseIssuedDate' => membershipStatus.Application_form__r.License_issued__c,
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

            Boolean alreadyExistMembershipStatusForNextYear = false;

            for (MembershipContactAssotiation__c contactsMembership : contactsMemberships) {
                Integer membershipIndex = membershipPriority.indexOf(contactsMembership.Membership__r.Name);
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
			if (String.isBlank(formCountryOfResidence) || String.isBlank(membershipId)) {
				return new Map<String, Object>{
					'result' => false, 'resultMessage' => 'Not All Params Are Defined (' + formCountryOfResidence + ' / ' + membershipId + ')'
				};
			}

			List<Country__mdt> countryList = !String.isBlank(formCountryOfResidence) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:formCountryOfResidence LIMIT 1] : new List<Country__mdt>();
			if (countryList.isEmpty()) return new Map<String, Object>{'result' => false, 'resultMessage' => 'Country Error.'};

			String membershipRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;
			Decimal totalRenewalFee = calculateTotalRenewalFee(membershipRegion, membershipId);
			if (totalRenewalFee == 9999) return new Map<String, Object>{'result' => false, 'resultMessage' => 'Calculate Renewal Fee Error.'};

            return new Map<String, Object>{
                'result' => true,
                'totalRenewalFee' => totalRenewalFee
            };

		} catch (Exception e) {
			system.debug('MembershipRenewalController recalculateRenewalFee ERROR message: ' + e.getMessage());
			system.debug('MembershipRenewalController recalculateRenewalFee ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'resultMessage' => 'Calculate Renewal Fee Error', 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	//	also used in CallForRenewalEmailTemplateController.cls
	public static Decimal calculateTotalRenewalFee(String membershipRegion, Id membershipId) {

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