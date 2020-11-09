public without sharing class CallForRenewalEmailTemplateController {

	//	Text field - relevant for FEANs, Full, Corresponding members who do not come from low/lower/middle/upper-middle country
	private final static List<String> ALLOWED_MEMBERS_TO_GET_RETIRED_DISCOUNT = new List<String>{
		'Full Membership', 'Corresponding Membership', 'Fellow of EAN (FEAN) Membership'
	};
	private final static List<String> ALLOWED_REGIONS_TO_GET_RETIRED_DISCOUNT = new List<String>{'A', 'C'};		//	NEW		EANMR-4 David at 05/11/2020

	public String membershipStatusId { get; set; }

	public Decimal totalRenewalFee { get; set; }
	public String reductionString { get; set; }
	
	public CallForRenewalEmailTemplateController() {}

	public String getPrepareData() {
		try {
			MembershipContactAssotiation__c membershipStatusRecord = new MembershipContactAssotiation__c();
			Id.valueOf(membershipStatusId);

			List<MembershipContactAssotiation__c>  membershipStatusList = [
				SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, toLabel(Contact__r.Salutation), Contact__r.Email,
					Membership__c, Membership__r.Name, Application_form__c, Contact__r.Residency__c
				FROM MembershipContactAssotiation__c
				WHERE Id =:membershipStatusId
				LIMIT 1
			];
			membershipStatusRecord = membershipStatusList.isEmpty() ? new MembershipContactAssotiation__c() : membershipStatusList[0];

			String countryName = membershipStatusRecord.Application_form__c != null && !String.isBlank(membershipStatusRecord.Contact__r.Residency__c)
				? membershipStatusRecord.Contact__r.Residency__c : '';

			//	Used to calculate total fee
			//	Based on membership category and country of residence (low/lower/middle/upper-middle country) pay 50% less, RRFS instead of €45 only €25 -  correct fees to be included in Salesforce
			List<Country__mdt> countryList = !String.isBlank(countryName) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:countryName LIMIT 1] : new List<Country__mdt>();
			String membershipStatusRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;

			//	EANMR-4 David at 05/11/2020
			reductionString = MembershipRenewalController.ALLOWED_MEMBERS_TO_GET_RETIRED_DISCOUNT.contains(membershipStatusRecord.Name)
				&& MembershipRenewalController.ALLOWED_REGIONS_TO_GET_RETIRED_DISCOUNT.contains(membershipStatusRegion) ? '(retired members get a 50% reduction)' : '';

			//	USED FOR TESTING
			// reductionString = '(retired members get a 50% reduction)';

			totalRenewalFee = MembershipRenewalController.calculateRenewalFee(membershipStatusRegion, membershipStatusRecord.Membership__c);

		} catch (Exception e) {
			return 'Email Generation Error';
		}

		return '';
	}

}