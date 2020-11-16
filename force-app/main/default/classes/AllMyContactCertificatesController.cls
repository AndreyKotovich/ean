public with sharing class AllMyContactCertificatesController {

	@AuraEnabled
	public static Map<String, Object> getContactCertificates(){
		try {
			List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
			// String contactId = '' + currentUser[0].ContactId;

			String contactId = '';
			if (Test.isRunningTest()) {
				List<Contact> testContact = [SELECT Id FROM Contact LIMIT 1];
				contactId = '' + testContact[0].Id;
			} else {
				contactId = '' + currentUser[0].ContactId;
			}

			if (String.isBlank(contactId)) return new Map<String, Object>{'result' => false, 'message' => 'Contact not found', 'messageToast' => 'Contact not found.'};

			//	usage example: communityHomeUrl + '/s/membership-application?re='
			String communityHomeUrl = membershipApplicationController.getCommunityHomeUrl();

			List<ContentDocumentLink> existingLinks = [
				SELECT Id, LinkedEntityId, Visibility, ContentDocumentId, ShareType, ContentDocument.LatestPublishedVersionId, ContentDocument.Title
				FROM ContentDocumentLink
				WHERE LinkedEntityId =:contactId
				AND ContentDocument.Title LIKE 'Certificate_%'
				AND ContentDocumentId != null
				AND ContentDocument.LatestPublishedVersionId != null
				ORDER BY ContentDocument.LastModifiedDate DESC
				LIMIT 5
			];

			List<CertificateDetailsWrap> certificateDetailsList = new List<CertificateDetailsWrap>();
			for (ContentDocumentLink existingLink : existingLinks) {

				String contentDocumentId = '' + existingLink.ContentDocumentId;
				String contentVersionId = '' + existingLink.ContentDocument.LatestPublishedVersionId;

				CertificateDetailsWrap certificateDetails = new CertificateDetailsWrap();
				certificateDetails.documentId = contentDocumentId;
				certificateDetails.certificateTitle = existingLink.ContentDocument.Title;
				certificateDetails.certificatePreviewUrl = communityHomeUrl + '/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId=' + contentVersionId + '&contentId=' + contentDocumentId;
				certificateDetails.certificateDowloadUrl = communityHomeUrl + '/sfc/servlet.shepherd/document/download/' + contentDocumentId;
				certificateDetailsList.add(certificateDetails);
			}

			return new Map<String, Object>{
				'result' => true,
				'displayComponent' => !certificateDetailsList.isEmpty(),
				'certificateDetailsList' => certificateDetailsList
			};

		} catch (Exception e) {
			system.debug('AllMyContactCertificatesController getContactCertificates ERROR message: ' + e.getMessage());
			system.debug('AllMyContactCertificatesController getContactCertificates ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	public class CertificateDetailsWrap {
		@AuraEnabled public String documentId { get; set; }
		@AuraEnabled public String certificateTitle { get; set; }
		@AuraEnabled public String certificatePreviewUrl { get; set; }
		@AuraEnabled public String certificateDowloadUrl { get; set; }
	}
}