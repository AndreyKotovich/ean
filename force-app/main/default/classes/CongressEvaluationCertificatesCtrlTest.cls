@IsTest
public with sharing class CongressEvaluationCertificatesCtrlTest {
    @IsTest public static void getContactInfoTest(){
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        Contact returnContact = CongressEvaluationCertificatesCtrl.getContactInfo(contact.Id);
        System.assertEquals(contact.Id, returnContact.Id);
        try{
            returnContact = CongressEvaluationCertificatesCtrl.getContactInfo(null);
        } catch (Exception e) {
            System.assertEquals('Cannot find a contact', e.getMessage());
        }
    }

    @IsTest public static void getComponentMetadataTest(){
        try{
            List<Congress_Component_Metadata__mdt> metadata = CongressEvaluationCertificatesCtrl.getComponentMetadata();
            System.assert(!metadata.isEmpty());
        } catch (Exception e) {
            System.assertEquals('There are no congresses yet.', e.getMessage());
        }
    }
    @IsTest public static void getAuthorizationCredentialsTest(){
        try{
            List<Congress_Component_Metadata__mdt> metadata = CongressEvaluationCertificatesCtrl.getAuthorizationCredentials();
            System.assert(!metadata.isEmpty());
        } catch (Exception e) {
            System.assertEquals('Authorization problem', e.getMessage());
        }
    }

    @IsTest public static void getAuthorizationTokenTest(){
        Test.startTest();
        CongressEvaluationCertificatesCtrlMock c = new CongressEvaluationCertificatesCtrlMock();
        c.isAuthorization = true;
        Test.setMock(HttpCalloutMock.class, c);
        String response = CongressEvaluationCertificatesCtrl.getAuthorizationToken();
        Test.stopTest();
        System.assertEquals('Test Token', response);
    }

    @IsTest public static void getCertificatesLinksTest(){
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        Test.startTest();
        CongressEvaluationCertificatesCtrlMock c = new CongressEvaluationCertificatesCtrlMock();
        c.isAuthorization = false;
        Test.setMock(HttpCalloutMock.class, c);
        List<Map<String, Object>> response = CongressEvaluationCertificatesCtrl.getCertificatesLinks(contact.Id);
        Test.stopTest();
        System.assert(!response.isEmpty());
        System.assert(JSON.serialize(response).contains('{"test":"OK"}'));
    }
}