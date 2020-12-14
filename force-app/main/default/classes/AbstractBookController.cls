public with sharing class AbstractBookController {
    public Map<String,Object> abAll { get; set; }
    public Map<String,Object> abInfo { get; set; }
    public Map<String,String> imageMap { get; set; }
    public Map<String,Object> newAbs { get; set; }
    public AbstractBookController() {
        String idPar = ApexPages.currentPage().getParameters().get('id');
        String[] ids = idPar.split('\\,');
        List<Abstract__c> abstracts = new List<Abstract__c>();

        abstracts = [
            SELECT Id, Name, Stage__c, Session__c, Event__c, Author_Details__c, Status__c, Topics__c, 
                Title__c, Body__c,RecordTypeId, RecordType.Name,  Introduction__c, 
                Methods__c, Results__c, Conclusion__c, Type__c,  
                Image_1__c, Image_2__c, Image_3__c, Image_1_Caption__c, Image_2_Caption__c, Image_3_Caption__c,
                Image_1_Location__c, Image_2_Location__c, Image_3_Location__c, Disclosure__c,
                Abstract_Topic__c, Image_1_ID__c, Image_2_ID__c, Image_3_ID__c,Abstract_Presenter__c,
                (SELECT ID, Abstract_Author__c, Abstract_Author__r.Id, Abstract_Author__r.LastName, 
                    Abstract_Author__r.FirstName, Abstract_Author__r.Official_Department_Name__c,
                    Abstract_Author__r.Department_Name__c, Abstract_Author__r.MailingCity, Abstract_Author__r.MailingCountry 
                FROM Abstract_Authors__r)
            FROM Abstract__c 
            WHERE Id IN: ids
        ];
       
        Map<String,Object> abMap = new Map<String,Object>();
        Set<String> imgId = new Set<String>();
        abInfo = new Map<String,Object>();
        newAbs = new Map<String,Object>();
        imageMap = new Map<String,String>();
        
        if (abstracts.size() == 0 ) {
            return;
        }

        for (Abstract__c ab : abstracts) {
            if (!String.isBlank(ab.Abstract_Topic__c)) {
                if (abMap.containsKey(ab.Abstract_Topic__c)) {
                    List<Abstract__c> abOlds = (List<Abstract__c>)abMap.get(ab.Abstract_Topic__c);
                    abOlds.add(ab);
                    abMap.put(ab.Abstract_Topic__c, abOlds);
                } else {
                    abMap.put(ab.Abstract_Topic__c, new List<Abstract__c>{ab});
                }
                if (!String.isBlank(ab.Image_1_ID__c)) {
                    imgId.add(ab.Image_1_ID__c);
                }
                if (!String.isBlank(ab.Image_2_ID__c)) {
                    imgId.add(ab.Image_2_ID__c);
                }
                if (!String.isBlank(ab.Image_3_ID__c)) {
                    imgId.add(ab.Image_3_ID__c);
                }
            }            
        }

        for (String str : abMap.keySet()) {
            Map<String,Integer> depMap = new Map<String,Integer>();
            Integer count = 0;
            List<Abstract__c> abs = (List<Abstract__c>)abMap.get(str);
            for (Abstract__c a : abs) {
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
                                'departmentName' => aas.Abstract_Author__r.Department_Name__c,
                                'city' => aas.Abstract_Author__r.MailingCity,
                                'country' => aas.Abstract_Author__r.MailingCountry                             
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
                            
                            authors.add(  new Map<String,Object> {
                                'isPresenter' => isPresenter,
                                'count' => cnt,
                                'name' => aas.Abstract_Author__r.FirstName.substring(0, 1) + '. ' + aas.Abstract_Author__r.LastName                      
                            }); 
                        }
                    }
                }
                abInfo.put(a.Id, new Map<String,Object> {
                    'authors' => authors,
                    'departments' => departments
                });
 
            }

        }
        // str_Autor

        List<ContentVersion> CDs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: imgId];
       
        this.imageMap.put('', '');
        for (ContentVersion cd : CDs) {
            this.imageMap.put(cd.ContentDocumentId, cd.Id);
        }

        this.abAll = abMap;
    }

}
