public without sharing class RecordSearchController {

	// Returns JSON of list of ResultWrapper

	// @listfields - list fields for query (example 'Id,Name,Source') (max number of fields = 10) (warning in "listfields" do not use spaces)
	// @objectname - API name of SObject
	// @searchfield - API name of field to be searched (required !!!)
	// @searchtext - text to be searched
	// @whereclause - additional where clause (example 'FirstName != null') (not required)
	// @limitrecords - total number of record to be returned (not required)
	// @disabledvalues - list of String values. result will not include records where searchfield in these values (only for text fields)
	// @enabledvalue - this value will be removed from 'disabledvalues'

	@AuraEnabled (cacheable=true)
	public static String searchRecordsInDatabase(String listfields, String objectname, String searchfield, String searchtext,
		String whereclause, Integer limitrecords, String disabledvalues, String enabledvalue){
		List<String> disabledValuesList = String.isBlank(disabledvalues) ? new List<String>() : (List<String>) JSON.deserialize(disabledvalues, List<String>.class);

		if (!String.isBlank(enabledvalue) && disabledValuesList.indexOf(enabledvalue) > -1) {
			disabledValuesList.remove(disabledValuesList.indexOf(enabledvalue));
		}

		system.debug('disabledValuesList= ' + disabledValuesList);

		List<ResultWrapper> recordsResult = new List<ResultWrapper>();
		searchtext = '\'%' + String.escapeSingleQuotes(searchtext.trim()) + '%\'';
		List<String> objectFields = !String.isBlank(listfields) ? listfields.split(',') : new List<String>();

		String queryString = 'SELECT ';
		queryString += !objectFields.isEmpty() ? listfields : 'Id, ' + searchfield;
		queryString += ' FROM ' + objectname + ' WHERE ';
		queryString += searchfield + ' LIKE ' + searchtext;
		queryString += !String.isBlank(whereclause) ? ' AND (' + whereclause + ')' : '';

		queryString += !disabledValuesList.isEmpty() ? ' AND ' + searchfield + ' NOT IN :disabledValuesList' : '';

		queryString += ' ORDER BY Name';
		queryString += limitrecords != null ? ' LIMIT ' + limitrecords : '';

		system.debug('queryString= ' + queryString);
		List<sObject> sobjList = Database.query(queryString);
		system.debug('sobjList= ' + sobjList);
		Integer fieldsSize = objectFields.size();

		for(SObject s : sobjList){
			ResultWrapper recordWrapper = new ResultWrapper();
			recordWrapper.id = s.Id;
			recordWrapper.text = String.valueOf(s.get(searchfield));
			recordWrapper.field1val = fieldsSize > 0 ? String.valueOf(s.get(objectFields[0])) : null;
			recordWrapper.field2val = fieldsSize > 1 ? String.valueOf(s.get(objectFields[1])) : null;
			recordWrapper.field3val = fieldsSize > 2 ? String.valueOf(s.get(objectFields[2])) : null;
			recordWrapper.field4val = fieldsSize > 3 ? String.valueOf(s.get(objectFields[3])) : null;
			recordWrapper.field5val = fieldsSize > 4 ? String.valueOf(s.get(objectFields[4])) : null;
			recordWrapper.field6val = fieldsSize > 5 ? String.valueOf(s.get(objectFields[5])) : null;
			recordWrapper.field7val = fieldsSize > 6 ? String.valueOf(s.get(objectFields[6])) : null;
			recordWrapper.field8val = fieldsSize > 7 ? String.valueOf(s.get(objectFields[7])) : null;
			recordWrapper.field9val = fieldsSize > 8 ? String.valueOf(s.get(objectFields[8])) : null;
			recordWrapper.field10val = fieldsSize > 9 ? String.valueOf(s.get(objectFields[9])) : null;
			recordsResult.add(recordWrapper);
		}
		return JSON.serialize(recordsResult) ;
	}
	
	public class ResultWrapper{
		public String id { get; set; }
		public String text { get; set; }
		public String field1val { get; set; }
		public String field2val { get; set; }
		public String field3val { get; set; }
		public String field4val { get; set; }
		public String field5val { get; set; }
		public String field6val { get; set; }
		public String field7val { get; set; }
		public String field8val { get; set; }
		public String field9val { get; set; }
		public String field10val { get; set; }
	}
}