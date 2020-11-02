public without sharing class CallForRenewalEmailTemplateController {

	public final static String COMPANY_LOGO_DOCUMENT_NAME = 'LetterHeadLogo';

	public final static String CUSTOM_SETTING_NAME_VIDEO1_LINK = 'MRenewal.Video1Link';
	public final static String CUSTOM_SETTING_NAME_VIDEO1_LABEL = 'MRenewal.Video1Label';
	public final static String CUSTOM_SETTING_NAME_VIDEO2_LINK = 'MRenewal.Video2Link';
	public final static String CUSTOM_SETTING_NAME_VIDEO2_LABEL = 'MRenewal.Video2Label';
	public final static String CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LINK = 'MRenewal.NextYearCongressLink';
	public final static String CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LABEL = 'MRenewal.NextYearCongressLabel';
	public final static String CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LINK = 'MRenewal.SurveyOnWhyNotRenewLink';
	public final static String CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LABEL = 'MRenewal.SurveyOnWhyNotRenewLabel';

	//	Text field - relevant for FEANs, Full, Corresponding members who do not come from low/lower/middle/upper-middle country
	private final static Set<String> retiredMembers = new Set<String>{
		'Full Membership', 'Full Institutional Members', 'Corresponding Membership', 'Corresponding Institutional Members', 'Fellow of EAN (FEAN) Membership'
	};
	private final static Set<String> notRetiredRegions = new Set<String>{'A', 'B', 'C', 'D'};
	private String membershipStatusRegion { get; set; }

	public String membershipStatusId { get; set; }

	public MembershipContactAssotiation__c membershipStatusRecord { get; set; }
	public Decimal totalRenewalFee { get; set; }

	public String thisYearString { get; set; }
	public String nextYearString { get; set; }
	public String reductionString { get; set; }
	public String connumityMembershipLink { get; set; }
	
	public String video1Link { get; set; }
	public String video1Label { get; set; }
	public String video2Link { get; set; }
	public String video2Label { get; set; }

	public String nextYearCongressLink { get; set; }
	public String nextYearCongressLabel { get; set; }

	public String surveyOnWhyNotRenewLink { get; set; }
	public String surveyOnWhyNotRenewLabel { get; set; }

	public String communityUrl { get; set; }



	//	not used
	public String imageURL { get; set; }
	
	
	public CallForRenewalEmailTemplateController() {
		List<Document> documentList = [SELECT Id, Name FROM Document WHERE Name =:COMPANY_LOGO_DOCUMENT_NAME LIMIT 1];
		List<Organization> orgList = [SELECT Id, Name FROM Organization LIMIT 1];
		imageURL = (!documentList.isEmpty() && !orgList.isEmpty()) ? URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=' + documentList[0].id + '&oid=' + orgList[0].id : '';
	}

	public String getPrepareData() {
		try {
			Datetime now = System.now();
			thisYearString = now.format('yyyy');
			nextYearString = now.addYears(1).format('yyyy');

			membershipStatusRecord = new MembershipContactAssotiation__c();
			Id.valueOf(membershipStatusId);

			List<MembershipContactAssotiation__c>  membershipStatusList = [
				SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, toLabel(Contact__r.Salutation), Contact__r.Email,
					Membership__c, Membership__r.Name, Application_form__c, Application_form__r.Residency__c
				FROM MembershipContactAssotiation__c
				WHERE Id =:membershipStatusId
				LIMIT 1
			];
			membershipStatusRecord = membershipStatusList.isEmpty() ? new MembershipContactAssotiation__c() : membershipStatusList[0];

			String countryName = membershipStatusRecord.Application_form__c != null && !String.isBlank(membershipStatusRecord.Application_form__r.Residency__c)
				? membershipStatusRecord.Application_form__r.Residency__c : '';

			//	Used to calculate total fee
			//	Based on membership category and country of residence (low/lower/middle/upper-middle country) pay 50% less, RRFS instead of €45 only €25 -  correct fees to be included in Salesforce
			List<Country__mdt> countryList = !String.isBlank(countryName) ? [SELECT Id, Region__c FROM Country__mdt WHERE Country__c =:countryName LIMIT 1] : new List<Country__mdt>();
			membershipStatusRegion = !countryList.isEmpty() && !String.isBlank(countryList[0].Region__c) ? countryList[0].Region__c : null;

			//	Additional rule: //	Text field - relevant for FEANs, Full, Corresponding members who do not come from low/lower/middle/upper-middle country
			reductionString = retiredMembers.contains(membershipStatusRecord.Name) && !notRetiredRegions.contains(membershipStatusRegion) ? '(retired members get a 50% reduction)' : '';

			totalRenewalFee = calculateTotalRenewalFee();

			//	LOGIC TO GENERATE LINK TO COMMUNITY MEMBERSHIP PAGE
			//	'https://eventreg1-myeanspace.cs89.force.com/s/membership-application'
			connumityMembershipLink = '';
			try {
				Network myNetwork = [SELECT Id FROM Network WHERE Name ='ean' LIMIT 1];
				ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
				connumityMembershipLink = myCommunity.siteUrl + '/s/membership-application';

			} catch (Exception e) {
				connumityMembershipLink = 'Generate Community URL ERROR';
			}

			Map<String, EAN_Settings__c> settingsMap = EAN_Settings__c.getAll();
			//	LOGIC TO GET VIDEO LINKS AND LABELS
			video1Link = settingsMap.containsKey(CUSTOM_SETTING_NAME_VIDEO1_LINK) ? settingsMap.get(CUSTOM_SETTING_NAME_VIDEO1_LINK).Value__c : '';
			video1Label = settingsMap.containsKey(CUSTOM_SETTING_NAME_VIDEO1_LABEL) ? settingsMap.get(CUSTOM_SETTING_NAME_VIDEO1_LABEL).Value__c : '';
			video1Label = String.isBlank(video1Link) && String.isBlank(video1Label) ? CUSTOM_SETTING_NAME_VIDEO1_LINK + ' and ' + CUSTOM_SETTING_NAME_VIDEO1_LABEL + ' settings are empty'
				: String.isBlank(video1Label) ? video1Link : video1Label;

			video2Link = settingsMap.containsKey(CUSTOM_SETTING_NAME_VIDEO2_LINK) ? settingsMap.get(CUSTOM_SETTING_NAME_VIDEO2_LINK).Value__c : '';
			video2Label = settingsMap.containsKey(CUSTOM_SETTING_NAME_VIDEO2_LABEL) ? settingsMap.get(CUSTOM_SETTING_NAME_VIDEO2_LABEL).Value__c : '';
			video2Label = String.isBlank(video2Link) && String.isBlank(video2Label) ? CUSTOM_SETTING_NAME_VIDEO2_LINK + ' and ' + CUSTOM_SETTING_NAME_VIDEO2_LABEL + ' settings are empty'
				: String.isBlank(video2Label) ? video2Link : video2Label;

			//	LOGIC TO GET NEXT YEAR LINKS AND LABELS
			nextYearCongressLink = settingsMap.containsKey(CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LINK) ? settingsMap.get(CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LINK).Value__c : '';
			nextYearCongressLabel = settingsMap.containsKey(CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LABEL) ? settingsMap.get(CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LABEL).Value__c : '';
			nextYearCongressLabel = String.isBlank(nextYearCongressLink) && String.isBlank(nextYearCongressLabel) ? CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LINK + ' and ' + CUSTOM_SETTING_NAME_NEXT_YEAR_CONGRESS_LABEL + ' settings are empty'
				: String.isBlank(nextYearCongressLabel) ? nextYearCongressLink : nextYearCongressLabel;

			//	LOGIC TO GET SURVEY LINK AND LABEL
			surveyOnWhyNotRenewLink = settingsMap.containsKey(CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LINK) ? settingsMap.get(CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LINK).Value__c : '';
			surveyOnWhyNotRenewLabel = settingsMap.containsKey(CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LABEL) ? settingsMap.get(CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LABEL).Value__c : '';
			surveyOnWhyNotRenewLabel = String.isBlank(surveyOnWhyNotRenewLink) && String.isBlank(surveyOnWhyNotRenewLabel) ? CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LINK + ' and ' + CUSTOM_SETTING_NAME_SURVEY_ON_WHY_NOT_RENEW_LABEL + ' settings are empty'
				: String.isBlank(surveyOnWhyNotRenewLabel) ? surveyOnWhyNotRenewLink : surveyOnWhyNotRenewLabel;

		} catch (Exception e) {
			return 'Email Generation Error';
		}

		return '';
	}

	//	membershipStatusRecord
	//	membershipStatusRegion
	public Decimal calculateTotalRenewalFee() {
		String membershipCategory = membershipStatusRecord.Membership__r.Name;
		List<Country_Price__c> countryPrice = [
			SELECT Id, Name, price_for_deadline_1__c,
				price_for_deadline_2__c, price_for_deadline_3__c
			FROM Country_Price__c
			WHERE Region__c =:membershipStatusRegion
			AND Membership__c =:membershipStatusRecord.Membership__c
			LIMIT 1
		];

		return countryPrice.isEmpty() ? 999 : countryPrice[0].price_for_deadline_1__c;
	}


}