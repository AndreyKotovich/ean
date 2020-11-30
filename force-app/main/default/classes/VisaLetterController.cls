public class VisaLetterController {
	public List<Visa_Letter__c> visaLetters { get; set; }
	public String dateVisaLetter { get; set; }
	public String dateBirth { get; set; }
	public String dateIssue { get; set; }
	public String dateExpiry { get; set; }
	public String country { get; set; }

	public VisaLetterController() {
		visaLetters = new List<Visa_Letter__c>();
		dateVisaLetter = (Datetime.now()).format('MMMM dd, yyyy');
		String id = ApexPages.currentPage().getParameters().get('id');
		dateBirth = '';
		dateIssue = '';
		dateExpiry = '';
		country = '';
		visaLetters = [
			SELECT 
				Id, Name, Official_Country__c, Official_Street__c, Official_ZIP_Postal_Code__c, First_Name__c, Last_Name__c,
				Official_City__c, Official_State_Province__c, Sex__c, Date_of_Birth__c, Date_of_Issue__c, Date_of_Expiry__c,
				Passport_Number__c, Authority__c, Place_of_Birth__c, Gender__c
			FROM Visa_Letter__c
			WHERE Id = : id
		];

		if (visaLetters.size() > 0) {
			dateBirth = generateDate(visaLetters[0].Date_of_Birth__c);
			dateIssue = generateDate(visaLetters[0].Date_of_Issue__c);            
			dateExpiry = generateDate(visaLetters[0].Date_of_Expiry__c);

			Map<String, String> countryMap = new Map<String, String>();
			Schema.DescribeFieldResult field = Contact.MailingCountryCode.getDescribe();

			for (Schema.PicklistEntry f : field.getPicklistValues()) {
				countryMap.put(f.getValue(), f.getLabel());
			}

			country = countryMap.containsKey(visaLetters[0].Official_Country__c) ? countryMap.get(visaLetters[0].Official_Country__c) : '';
		}

	}
	
    @TestVisible
	private string generateDate(Date dt) {
		return (datetime.newInstance(dt.year(), dt.month(),dt.day())).format('MMMM dd, yyyy');
	}
}