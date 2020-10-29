@isTest
private class RecordSearchControllerTest {

	@isTest
	static void searchRecordsInDatabaseTest() {

		Contact testContact1 = new Contact(
			FirstName = 'testFirst1',
			LastName = 'testLast1',
			Email = 'testmail1@nomail.com'
		);
		Contact testContact2 = new Contact(
			FirstName = 'testFirst2',
			LastName = 'testLast2',
			Email = 'testmail2@nomail.com'
		);
		Contact testContact3 = new Contact(
			FirstName = 'testFirst3',
			LastName = 'testLast3',
			Email = 'testmail3@nomail.com'
		);
		Contact testContact4 = new Contact(
			FirstName = 'testFirst4',
			LastName = 'testLast4',
			Email = 'testmail4@nomail.com'
		);
		insert new List<Contact> {testContact1, testContact2, testContact3, testContact4};

		String searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'testmail', '', 4, '', '');
		List<RecordSearchController.ResultWrapper> resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		System.assertEquals(true, searchResult.contains('testLast4'));
		System.assertEquals(4, resultWrapper.size());

		searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'nomail', '', 5, '', '');
		resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		System.assertEquals(true, searchResult.contains('testmail2@nomail.com'));
		System.assertEquals(4, resultWrapper.size());

		searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'testmail3', '', 5, '', '');
		resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		System.assertEquals(true, searchResult.contains('testmail3@nomail.com'));
		System.assertEquals(1, resultWrapper.size());

		searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'wrong', '', 2, '', '');
		resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		System.assertEquals(0, resultWrapper.size());

		searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'testmail', '', 5,
			JSON.serialize(new List<String>{'testmail1@nomail.com', 'testmail4@nomail.com'}), '');
		resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		System.assertEquals(true, searchResult.contains('testmail2@nomail.com'));
		System.assertEquals(true, searchResult.contains('testmail3@nomail.com'));
		System.assertEquals(false, searchResult.contains('testmail1@nomail.com'));
		System.assertEquals(false, searchResult.contains('testmail4@nomail.com'));
		System.assertEquals(2, resultWrapper.size());

		searchResult = RecordSearchController.searchRecordsInDatabase('Id,Name,Email', 'Contact', 'Email', 'testmail', '', 5,
			JSON.serialize(new List<String>{'testmail1@nomail.com', 'testmail4@nomail.com'}), 'testmail4@nomail.com');
		resultWrapper = (List<RecordSearchController.ResultWrapper>) JSON.deserialize(searchResult, List<RecordSearchController.ResultWrapper>.class);
		system.debug('searchResult: ' + searchResult);
		System.assertEquals(true, searchResult.contains('testmail2@nomail.com'));
		System.assertEquals(true, searchResult.contains('testmail3@nomail.com'));
		System.assertEquals(false, searchResult.contains('testmail1@nomail.com'));
		System.assertEquals(true, searchResult.contains('testmail4@nomail.com'));
		System.assertEquals(3, resultWrapper.size());

	}
}