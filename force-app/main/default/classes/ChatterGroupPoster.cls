public with sharing class ChatterGroupPoster {
    @Future(Callout=true)
    public static void postChatterQuestionFromCase(List<Id> casesId, Id groupId, Id communityId){
        Map<Case, List<Blob>> caseFilesMap = new Map<Case, List<Blob>>();
        List<Case> cases = [
                SELECT Id, CaseNumber, Scans_or_other_images__c, Subject, Clinical_History__c,
                        Examination_Investigation_Findings__c, Differential_Diagnosis__c, OwnerId
                FROM Case
                WHERE Id IN :casesId];

        for(Case c : cases){
            caseFilesMap.put(c, getRichTextImgBlobs(c.Scans_or_other_images__c));
        }

        insertBlobAsChatterGroupFile(caseFilesMap, groupId, communityId);

        Date dateToday = Date.today();
        String likeString = '%'+dateToday.day() + '_' + dateToday.month() + '_' + dateToday.year()+'%';
        List<ContentDocument> insertedContentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE :likeString ORDER BY CreatedDate DESC];
        Map<Case, List<Id>> caseContentDocumentMap = new Map<Case, List<Id>>();

        for(Case c : cases){

            List<Id> caseContentDocumentIds = new List<Id>();

            for (ContentDocument cd : insertedContentDocuments){
                if(cd.Title.contains(c.CaseNumber)){
                    caseContentDocumentIds.add(cd.Id);
                }
            }

            caseContentDocumentMap.put(c, caseContentDocumentIds);
        }

        Map<Case, ConnectApi.FeedItemInput> caseFeedItemsInputMap = generateQuestionFeedElements(caseContentDocumentMap, groupId);
        List<Case> caseToUpdate = new List<Case>();

        for(Case c : caseFeedItemsInputMap.keySet()){
            if(!Test.isRunningTest()){
                ConnectApi.ChatterFeeds.postFeedElement(communityId, caseFeedItemsInputMap.get(c));
            }
            c.Status = 'Posted';
            caseToUpdate.add(c);
        }

        update caseToUpdate;

    }

    public static List<Blob> getRichTextImgBlobs(String richTextField){
        List<Blob> resultBlobs = new List<Blob>();
        if(richTextField!=null) {
            Matcher imgMatcher = Pattern.compile('<img(.+?)>').matcher(richTextField);

            while (imgMatcher.find()) {
                String imageTag = imgMatcher.group();
                String imageURL = imageTag.substringBetween(' src="', '"');
                String decodedURL = imageURL.unescapeHtml4();

                PageReference page = new PageReference(decodedURL);

                if (Test.isRunningTest()){
                    resultBlobs.add(Blob.valueOf('Test'));
                } else {
                    resultBlobs.add(page.getContent());
                }

            }
        }

        return resultBlobs;
    }

    public static void insertBlobAsChatterGroupFile(Map<Case, List<Blob>> caseBlobsMap, Id groupId, Id communityId){
        List<ContentVersion> cvs = new List<ContentVersion>();
        Date dateToday = Date.today();

        for(Case c : caseBlobsMap.keySet()){
            List<Blob> blobs = caseBlobsMap.get(c);
            if(!blobs.isEmpty()) {

                for (Integer i = 0; i < blobs.size(); i++) {
                    ContentVersion contVerFile = new ContentVersion();
                    contVerFile.VersionData = blobs[i];
                    String title = c.CaseNumber + '-DOC-' + i + '-' + dateToday.day() + '_' + dateToday.month() + '_' + dateToday.year() + '.jpg';
                    contVerFile.Title = title;
                    contVerFile.PathOnClient = '/' + title + '.jpg';
                    contVerFile.NetworkId = communityId;
                    cvs.add(contVerFile);
                }

            }
        }

        insert cvs;
        cvs = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvs];
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();

        for(ContentVersion cv : cvs){
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = cv.ContentDocumentId;
            link.LinkedEntityId = groupId;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
            documentLinks.add(link);
        }

        insert documentLinks;
    }

    public static Map<Case, ConnectApi.FeedItemInput> generateQuestionFeedElements(Map<Case, List<Id>> caseContentDocumentMap, Id groupId){
        Map<Case, ConnectApi.FeedItemInput> caseFeedItemsInputMap = new Map<Case, ConnectApi.FeedItemInput>();

        for(Case c : caseContentDocumentMap.keySet()){
            ConnectApi.QuestionAndAnswersCapabilityInput question = new ConnectApi.QuestionAndAnswersCapabilityInput();
            question.questionTitle = c.Subject;

            ConnectApi.FeedElementCapabilitiesInput itemCapabilities = new ConnectApi.FeedElementCapabilitiesInput();
            itemCapabilities.questionAndAnswers = question;

            if (!caseContentDocumentMap.get(c).isEmpty()) {
                ConnectApi.FilesCapabilityInput filesInput = new ConnectApi.FilesCapabilityInput();
                filesInput.items = new List<ConnectApi.FileIdInput>();

                List<Id> documentsIds = caseContentDocumentMap.get(c);
                //max 10 files per post
                Integer filesSize = documentsIds.size() > 10 ? 10 : documentsIds.size();

                for (Integer i = 0; i < filesSize; i++) {
                    ConnectApi.FileIdInput idInput = new ConnectApi.FileIdInput();
                    idInput.id = documentsIds[i];
                    filesInput.items.add(idInput);
                }

                itemCapabilities.files = filesInput;
            }

            ConnectApi.FeedItemInput feedItem = new ConnectApi.FeedItemInput();

            feedItem.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItem.capabilities = itemCapabilities;
            feedItem.subjectId = groupId;

            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();

//            ===================BOLD===================>>>>>>
            ConnectApi.MarkupBeginSegmentInput markupBeginBoldSegment;
            markupBeginBoldSegment = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginBoldSegment.markupType = ConnectApi.MarkupType.Bold;

            ConnectApi.MarkupEndSegmentInput markupEndBoldSegment;
            markupEndBoldSegment = new ConnectApi.MarkupEndSegmentInput();
            markupEndBoldSegment.markupType = ConnectApi.MarkupType.Bold;
//            <<<<<<===================BOLD===================

//            ===================Paragraph===================>>>>>>
            ConnectApi.MarkupBeginSegmentInput markupBeginParagraphSegment;
            markupBeginParagraphSegment = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginParagraphSegment.markupType = ConnectApi.MarkupType.Paragraph;

            ConnectApi.MarkupEndSegmentInput markupEndParagraphSegment;
            markupEndParagraphSegment = new ConnectApi.MarkupEndSegmentInput();
            markupEndParagraphSegment.markupType = ConnectApi.MarkupType.Paragraph;
//            <<<<<<===================Paragraph===================


            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();


            if(c.OwnerId!=null) {
                messageBodyInput.messageSegments.add(markupBeginBoldSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Author: ';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndBoldSegment);
                //mention
                mentionSegmentInput.id = c.OwnerId;
                messageBodyInput.messageSegments.add(mentionSegmentInput);
                //new line X2
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = '&nbsp;';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);
            }


            if(c.Clinical_History__c!=null) {
                messageBodyInput.messageSegments.add(markupBeginBoldSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Clinical History:';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndBoldSegment);
                //new line
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);

                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = c.Clinical_History__c;
                messageBodyInput.messageSegments.add(textSegment);
                //new line X2
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = '&nbsp;';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);
            }

            if(c.Examination_Investigation_Findings__c!=null) {
                messageBodyInput.messageSegments.add(markupBeginBoldSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Examination & Investigation Findings:';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndBoldSegment);
                //new line
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);

                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = c.Examination_Investigation_Findings__c;
                messageBodyInput.messageSegments.add(textSegment);
                //new line X2
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = '&nbsp;';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);
            }

            if(c.Differential_Diagnosis__c!=null) {
                messageBodyInput.messageSegments.add(markupBeginBoldSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Differential Diagnosis:';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndBoldSegment);
                //new line
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);

                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = c.Differential_Diagnosis__c;
                messageBodyInput.messageSegments.add(textSegment);
                //new line X2
                messageBodyInput.messageSegments.add(markupBeginParagraphSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = '&nbsp;';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndParagraphSegment);
            }

            if(!caseContentDocumentMap.get(c).isEmpty()) {
                messageBodyInput.messageSegments.add(markupBeginBoldSegment);
                textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Scans or other images:';
                messageBodyInput.messageSegments.add(textSegment);
                messageBodyInput.messageSegments.add(markupEndBoldSegment);
            }

            feedItem.body = messageBodyInput;
            caseFeedItemsInputMap.put(c, feedItem);
        }

        return caseFeedItemsInputMap;

    }

}