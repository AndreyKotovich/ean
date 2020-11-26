public class CreateAndSendVisaLetter {
	@InvocableMethod(
		label = 'Attach and send Visa Letter' 
		description = 'Attach and send Visa Letter'
	)
	public static void AttachAndSendVisaLetter(List<Id> visaLetterIds) {
		AttachAndSendVisaLetterFuture(visaLetterIds);
	}
 
	@future(callout=true) 
	public static void AttachAndSendVisaLetterFuture(List<Id> visaLetterIds){
		List<ContentVersion> attachments = new List<ContentVersion>();
		List<ContentVersion> newAttachments = new List<ContentVersion>();
		Map<String, ContentVersion> attachmentMap = new Map<String, ContentVersion>();
		Map<String, String> fileOrderMap = new Map<String, String>();
		Set<String> attachmentNames = new Set<String>();
		List<Visa_Letter__c> visaLetters = new List<Visa_Letter__c>();
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		List<BCC_email__mdt> bccEmail = [SELECT Id, Email__c FROM BCC_email__mdt LIMIT 1];
		// Collect Visa Letter
		visaLetters = [
			SELECT Id, Name, Event_Participation__c, Event_Participation__r.Contact__c, 
				Event_Participation__r.Contact__r.Email, Event_Participation__r.Contact__r.MailingAddress 
			FROM Visa_Letter__c
			WHERE 
				Id IN :visaLetterIds AND Event_Participation__c != null AND 
				Event_Participation__r.Contact__c != null AND Event_Participation__r.Contact__r.Email != null
			ORDER BY CreatedDate ASC
		];
		
		for (Visa_Letter__c vL : visaLetters) {
			attachmentNames.add('VisaLetter_1_' + vL.Name + '.pdf');
			attachmentNames.add('VisaLetter_2_' + vL.Name + '.pdf');
		}
		
		// Collect all related Attachments
		attachments = [SELECT Title, VersionData FROM ContentVersion WHERE Title IN :attachmentNames];

		for (ContentVersion at : attachments) {
			attachmentMap.put(at.Title, at);
		}
		
		// Send an email with new or existing PDF
		List<EmailTemplate> ets = [ SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Visa_Letter_Email' ];
		EmailTemplate et = new EmailTemplate();
		OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'membership@ean.org' LIMIT 1];
		for (Visa_Letter__c vL : visaLetters) {
			ContentVersion att = new ContentVersion();
			ContentVersion att2 = new ContentVersion();

			et = ets.size() > 0 ? ets[0] : new EmailTemplate();
			
			// if PDF doesn't exist
			if (!attachmentMap.keySet().contains('VisaLetter_1_' + vL.Name + '.pdf')) {
				PageReference defaultPage = new PageReference('/apex/VisaLetterOne');
				defaultPage.getParameters().put('id', vL.Id);
				Blob pageData;

				if (Test.isRunningTest()) {
					pageData = Blob.valueOf('Unit.Test');
				} else {
					pageData = defaultPage.getContent();
				}
				att = new ContentVersion(
					VersionData = pageData,
					Title = 'VisaLetter_1_' + vL.Name + '.pdf',
					PathOnClient = 'VisaLetter_1_' + vL.Name + '.pdf',
					IsMajorVersion = true,
					ContentLocation = 'S',
					NetworkId = ConnectApi.Communities.getCommunities().communities[0].id
				);
				newAttachments.add(att);
				fileOrderMap.put(att.Title, vL.Event_Participation__c);
				// else if PDF exists
			} else {
				att = attachmentMap.get('VisaLetter_1_' + vL.Name + '.pdf');
			}
				
			if (!attachmentMap.keySet().contains('VisaLetter_2_' + vL.Name + '.pdf')) {
				PageReference defaultPage = new PageReference('/apex/VisaLetterSecond');
				defaultPage.getParameters().put('id', vL.Id);
				Blob pageData;

				if (Test.isRunningTest()) {
					pageData = Blob.valueOf('Unit.Test');
				} else {
					pageData = defaultPage.getContent();
				}
				att2 = new ContentVersion(
					VersionData = pageData,
					Title = 'VisaLetter_2_' + vL.Name + '.pdf',
					PathOnClient = 'VisaLetter_2_' + vL.Name + '.pdf',
					IsMajorVersion = true,
					ContentLocation = 'S',
					NetworkId = ConnectApi.Communities.getCommunities().communities[0].id
				);
				newAttachments.add(att2);
				fileOrderMap.put(att2.Title, vL.Event_Participation__c);
				// else if PDF exists
			} else {
				att2 = attachmentMap.get('VisaLetter_2_' + vL.Name + '.pdf');
			}

			Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(et.Id, vL.Event_Participation__r.Contact__c, vL.Event_Participation__c);
			
			List<Messaging.EmailFileAttachment> attachs = new List<Messaging.EmailFileAttachment>();
			
			Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
			attach.setBody(att.VersionData);
			attach.setFileName(att.Title);
			attach.setContentType('application/pdf');
			attachs.add(attach);

			Messaging.EmailFileAttachment attach2 = new Messaging.EmailFileAttachment();
			attach2.setBody(att2.VersionData);
			attach2.setFileName(att2.Title);
			attach2.setContentType('application/pdf');
			attachs.add(attach2);

			String emailTextBody = message.getPlainTextBody();
			message.setTargetObjectId(vL.Event_Participation__r.Contact__c);
			message.setPlainTextBody(emailTextBody);
			message.saveAsActivity = false;
			message.setOrgWideEmailAddressId(address.Id);

			if(!bccEmail.isEmpty()){
				message.setBccAddresses(new List<String>{bccEmail[0].Email__c});
			}

			message.setFileAttachments(attachs);
			emails.add(message);
		}

		try {
			// Insert new PDF Invoices as Attachments
			if (!newAttachments.isEmpty()) {
				System.debug(newAttachments);
				insert newAttachments;

				List<ContentVersion> cds = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN : newAttachments];
				List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
				for (ContentVersion cd : cds) {
					Id visaId = fileOrderMap.get(cd.Title);
					ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = visaId,
					ShareType = 'V', ContentDocumentId = cd.ContentDocumentId);
					cdLinks.add(link);
				}

				if (!cdLinks.isEmpty()) {
					insert cdLinks;
				}
			}
			// Send Emails with attached PDF Invoices
			if (!emails.isEmpty()) {
				Messaging.sendEmail(emails);
			}
		} catch (Exception e) {
			Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
			errorEmail.setSubject('New Invoice sending error');
			String[] emailIds = new String[] { 'andrey.kotovich@succraft.com' };
			errorEmail.setToAddresses(emailIds);
			errorEmail.setPlainTextBody('Error Description: \n Message:' + e.getMessage() + '\n Line Number: ' + e.getLineNumber() + '\n Stack Trace: ' + e.getStackTraceString());
			Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ errorEmail });
		}
	}
}