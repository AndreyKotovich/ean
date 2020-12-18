public without sharing class AbstractBookController {
	public List<Abstract__c> abAll { get; set; }
	public Map<String,Object> abInfo { get; set; }
	public Map<String,Object> SessionInfo { get; set; }
	public Map<String,String> imageMap { get; set; }
	public Map<String,Object> imageNameMap { get; set; }
	public Map<String,Object> newAbs { get; set; }
	public Map<String,Abstract_Review__c> abRew { get; set; }
	public Map<String,Abstract__c> abstractMap { get; set; }
	public Map<String,Object> lectMap { get; set; }
	public List<String> lectSorts { get; set; }  
	
	public String typeDoc { get; set; }
	
	public AbstractBookController() {
		String idPar = ApexPages.currentPage().getParameters().containsKey('id') ? ApexPages.currentPage().getParameters().get('id') : '';
		typeDoc = ApexPages.currentPage().getParameters().containsKey('type') ? ApexPages.currentPage().getParameters().get('type') : '';
		String event = ApexPages.currentPage().getParameters().containsKey('event') ? ApexPages.currentPage().getParameters().get('event') : '';
		
		List<String> ids = !String.isBlank(idPar) ? idPar.split('\\,') : new List<String>();
		List<Abstract__c> abstracts = new List<Abstract__c>();
		String userId = UserInfo.getUserId();
		List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id =:userId LIMIT 1];

		sessionInfo = new Map<String,String>();
		abInfo = new Map<String,Object>();
		newAbs = new Map<String,Object>();
		lectMap = new Map<String,Object>();
		imageMap = new Map<String,String>();
		imageNameMap = new Map<String,Object>();
		abstractMap = new Map<String,Abstract__c>();
		lectSorts = new List<String>();

		Map<String,Integer> depMap = new Map<String,Integer>();
		Map<String,Object> abMap = new Map<String,Object>();
		Set<String> imgId = new Set<String>();

		if (typeDoc == 'AbstractReviews') {
			abRew = new Map<String,Abstract_Review__c>();
			List<Abstract_Review__c> ars = new List<Abstract_Review__c>();
			String queryRew = 
				'SELECT Id, Abstract__c, Grading__c, Comments__c, Public_relevance__c, Investigator_Award__c, Reviewer__r.Contact__c   ' +
				'FROM Abstract_Review__c WHERE ';
 
			if (ids.size() > 0) { queryRew += ' Id IN: ids AND '; } 
			queryRew += '  ( Stage__c=\'Assigned\' OR Stage__c=\'Rated\') '; 
		
			ars = (List<Abstract_Review__c>)Database.query(queryRew);
			System.debug('ars ' + ars); 
			for (Abstract_Review__c ar : ars) {
				System.debug('ar.Reviewer__r.Contact__c ' + ar.Reviewer__r.Contact__c + ' ' +  currentUser[0].ContactId); 
				if (ar.Reviewer__r.Contact__c == currentUser[0].ContactId) {
					abRew.put(ar.Abstract__c, ar);
				}
			}

			ids = new List<String>(abRew.keySet());
			if (ids.size() == 0) { return; } 
		}

		if (typeDoc == 'AbstractStaff') {
			List<Lecture__c> lects = new List<Lecture__c>();
			String queryLect = 'SELECT Id, Abstract__c, Session__c, Session__r.Session_Start__c, Session__r.Session_Title__c, ' +
				'Session__r.Session_Type__c, Presentation_Number__c, Presentation_Type__c ' +
				'FROM Lecture__c where Abstract__c != NULL and Session__c != NULL ';

			if (!String.isBlank(event)) { queryLect += ' AND Event_custom__c=:event '; } 
			if (ids.size() > 0) { queryLect += ' AND Abstract__c IN: ids '; }

			queryLect += ' ORDER BY Session__r.Session_Title__c, Presentation_Number__c ASC';
			
			lects = (List<Lecture__c>)Database.query(queryLect);
			ids = new List<String>();
			System.debug('lects ' + lects);
			for (Lecture__c l : lects) {
				ids.add(l.Abstract__c);
				System.debug('l.Presentation_Number__c ' + l.Presentation_Number__c );
				if (lectMap.containsKey(l.Session__c)) {
					Map<String,Object> absts = (Map<String,Object>)((Map<String,Object>)lectMap.get(l.Session__c)).get('abstract');
					absts.put(l.Abstract__c, l.Presentation_Number__c);
					((Map<String,Object>)lectMap.get(l.Session__c)).put('abstract',absts);
					List<String> abstSort = (List<String>)((Map<String,Object>)lectMap.get(l.Session__c)).get('abstractSort');
					abstSort.add(l.Abstract__c);
					((Map<String,Object>)lectMap.get(l.Session__c)).put('abstractSort',abstSort);
				} else {
					lectSorts.add(l.Session__c);
					lectMap.put(l.Session__c, new Map<String,Object> {
						'sessionType' => l.Session__r.Session_Type__c,
						'sessionData' => (l.Session__r.Session_Start__c).format('EEEE, MMMM dd, yyyy'),
						'sessionTitle' => l.Session__r.Session_Title__c,
						'abstractSort'=> new List<String> { l.Abstract__c },
						'abstract' => new Map<String,Object> { l.Abstract__c => l.Presentation_Number__c }
					});
				}
			}
			System.debug('lects ids' + ids);
			System.debug('lectMap ' + lectMap);
			if (ids.size() == 0) { return; } 

		}

		String queryAbs = 
			'SELECT Id, Name, Stage__c, Session__c, Event__c, Author_Details__c, Status__c, Topics__c, ' +
			'Title__c, Body__c,RecordTypeId, RecordType.Name,  Introduction__c, ' +
			'Methods__c, Results__c, Conclusion__c, Type__c,  ' +
			'Image_1__c, Image_2__c, Image_3__c, Image_1_Caption__c, Image_2_Caption__c, Image_3_Caption__c,' +
			'Image_1_Location__c, Image_2_Location__c, Image_3_Location__c, Disclosure__c,' +
			'Abstract_Topic__c, Image_1_ID__c, Image_2_ID__c, Image_3_ID__c,Abstract_Presenter__c, ' +
			'(SELECT ID, Abstract_Author__c, Abstract_Author__r.Id, Abstract_Author__r.LastName , ' +
			'Abstract_Author__r.FirstName, Abstract_Author__r.Official_Department_Name__c,' +
			'Abstract_Author__r.Department_Name__c, Abstract_Author__r.MailingCity, Abstract_Author__r.MailingCountry ' +
			'FROM Abstract_Authors__r) FROM Abstract__c ';
		
		if (ids.size() > 0) {
			queryAbs += 'WHERE Id IN: ids ';
			if (typeDoc == 'AbstractSubmission') {
				queryAbs += 'AND Status__c != \'Rejected\' AND OwnerId=:userId';
			}
		} else {
			if (typeDoc == 'AbstractSubmission') {
				queryAbs += 'WHERE Status__c != \'Rejected\' AND OwnerId=:userId';
			}
		}

		abstracts = (List<Abstract__c>)Database.query(queryAbs);
	   
		
		if (abstracts.size() == 0 ) {
			return;
		}

		for (Abstract__c a : abstracts) {
			abstractMap.put(a.Id, a);
			Integer count = 0;
			if (!String.isBlank(a.Image_1_ID__c)) { imgId.add(a.Image_1_ID__c); }
			if (!String.isBlank(a.Image_2_ID__c)) { imgId.add(a.Image_2_ID__c); }
			if (!String.isBlank(a.Image_3_ID__c)) { imgId.add(a.Image_3_ID__c); }

			newAbs.put(a.Id ,new Map<String,Object> {
				'Image_1' => !String.isBlank(a.Image_1_ID__c) ? a.Image_1_ID__c : '',
				'Image_2' => !String.isBlank(a.Image_2_ID__c) ? a.Image_2_ID__c : '',
				'Image_3' => !String.isBlank(a.Image_3_ID__c) ? a.Image_3_ID__c : ''
			});
			Boolean isPresenter = false;
			List<Map<String,Object>> authors = new List<Map<String,Object>>();
			List<Map<String,Object>> departments = new List<Map<String,Object>>();
			for (Abstract_Author__c aas : a.Abstract_Authors__r) {
				if (!String.isBlank(aas.Abstract_Author__r.Department_Name__c)) {
					if (!depMap.containsKey(aas.Abstract_Author__r.Department_Name__c)) {
						count++;
						depMap.put(aas.Abstract_Author__r.Department_Name__c, count);
						departments.add( new Map<String,Object>{
							'count' => count,
							'departmentName' => !String.isBlank(aas.Abstract_Author__r.Department_Name__c) ? aas.Abstract_Author__r.Department_Name__c : '',
							'city' => !String.isBlank(aas.Abstract_Author__r.MailingCity) ? aas.Abstract_Author__r.MailingCity : '',
							'country' => !String.isBlank(aas.Abstract_Author__r.MailingCountry) ? aas.Abstract_Author__r.MailingCountry : ''                             
						}); 

						isPresenter = a.Abstract_Presenter__c ==  aas.Abstract_Author__c;
						String name = '';
						if (!String.isBlank(aas.Abstract_Author__r.FirstName)) {
							name +=aas.Abstract_Author__r.FirstName.substring(0, 1) + '. ';
						}
						name +=  aas.Abstract_Author__r.LastName;
						authors.add(  new Map<String,Object> {
							'isPresenter' => isPresenter,
							'count' => count,
							'name' => name                     
						}); 
					}
					else {
						Integer cnt = depMap.get(aas.Abstract_Author__r.Department_Name__c);
							
						isPresenter = a.Abstract_Presenter__c ==  aas.Abstract_Author__c;
						String name = '';
						if (!String.isBlank(aas.Abstract_Author__r.FirstName)) {
							name +=aas.Abstract_Author__r.FirstName.substring(0, 1) + '. ';
						}
						name +=  aas.Abstract_Author__r.LastName;
						authors.add(  new Map<String,Object> {
							'isPresenter' => isPresenter,
							'count' => cnt,
							'name' => name                    
						}); 
					}
				}
			}
			abInfo.put(a.Id, new Map<String,Object> {
				'authors' => authors,
				'departments' => departments
			});
 
		}

		List<ContentVersion> CDs = [SELECT Id, ContentDocument.Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: imgId];
	   
		this.imageMap.put('', '');
		this.imageNameMap.put('', '');
		
		for (ContentVersion cd : CDs) {
			this.imageMap.put(cd.ContentDocumentId, cd.Id); 
			this.imageNameMap.put(cd.ContentDocumentId, cd.ContentDocument.Title);
		}

		this.abAll = abstracts;
	}

}