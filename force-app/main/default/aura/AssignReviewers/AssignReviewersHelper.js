({
    loadData: function (cmp) {
        cmp.set("v.spinnerVisible", true);

        this.getPickList(cmp)
            .then(result => {
                this.getAbstracts(cmp);
                this.setAbstractsColumns(cmp);
                cmp.set("v.spinnerVisible", false);
            })
            .catch(error => {
                cmp.set("v.spinnerVisible", false);
                console.log(error);
            });
    },

    setAbstractsColumns: function (cmp) {
        cmp.set("v.abstractColumns", [
            {
                label: 'Name', fieldName: 'abstractLink', type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Name' }, target: '_blank',
                    tooltip: 'Click to see object page'
                }
            },
            { label: 'Title', fieldName: 'Title__c', type: 'text' },
            { label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Stage', fieldName: 'Stage__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Assigned Reviewers', fieldName: 'assignedReviewers', type: 'text' },
            { label: 'Required Reviewers', fieldName: 'Required_number_of_reviewers__c', type: 'text' }
        ])
    },

    setAbstractsColumnsToAssign: function (cmp) {
        cmp.set("v.abstractColumnsToAssign", [
            {
                label: 'Name', fieldName: 'abstractLink', type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Name' }, target: '_blank',
                    tooltip: 'Click to see object page'
                }
            },
            { label: 'Title', fieldName: 'Title__c', type: 'text' },
            { label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Stage', fieldName: 'Stage__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Assigned Reviewers', fieldName: 'assignedReviewers', type: 'text' },
            { label: 'Required Reviewers', fieldName: 'Required_number_of_reviewers__c', type: 'text' },
            { label: '', type: 'button', initialWidth: 135, typeAttributes: { label: 'Select', name: 'select_abstract', title: 'Click to Select Abstract' } },
        ])
    },

    setAbstractsColumnsToAssignAuto: function (cmp) {
        cmp.set("v.abstractColumnsToAssign", [
            {
                label: 'Name', fieldName: 'abstractLink', type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Name' }, target: '_blank',
                    tooltip: 'Click to see object page'
                }
            },
            { label: 'Title', fieldName: 'Title__c', type: 'text' },
            { label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Stage', fieldName: 'Stage__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Assigned Reviewers', fieldName: 'assignedReviewers', type: 'text' },
            { label: 'Required Reviewers', fieldName: 'Required_number_of_reviewers__c', type: 'text' },
            { label: '', type: 'button', initialWidth: 135, typeAttributes: { label: 'Remove', name: 'remove', title: 'Click to remove Abstract' } },
        ])
    },


    setReviewersColumns: function (cmp) {
        cmp.set("v.reviewerColumns", [
            {
                label: 'Name', fieldName: 'ReviewerLink', type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Name' }, target: '_blank',
                    tooltip: 'Click to see object page'
                }
            },
            {
                label: 'Contact Name', fieldName: 'ContactLink', type: 'url',
                typeAttributes: {
                    label: { fieldName: 'ContactName' }, target: '_blank',
                    tooltip: 'Click to see object page'
                }
            },
            { label: 'Membership Status', fieldName: 'Membership_Status', type: 'text' },
            { label: 'Remaining Capacity', fieldName: 'Remaining_Capacity__c', type: 'text' },
            { label: 'Assigned Abstracts', fieldName: 'Assigned_Abstracts__c', type: 'text' }
        ])
    },

    getPickList: function (cmp) {
        return new Promise((resolve, reject) => {
            var request = {};
            var objectApiName = 'Abstract__c';
            var fieldApiNames = [];
            var topicFieldApiName = 'Abstract_Topic__c';
            var typeFieldApiName = 'Type__c';
            fieldApiNames.push(topicFieldApiName, typeFieldApiName);
            request[objectApiName] = fieldApiNames;
            var action = cmp.get("c.getPickListValues");
            action.setParams({
                'objectApiNameTofieldApiNameMap': request
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var advTopics = ['All'];
                    Array.prototype.push.apply(advTopics, response.getReturnValue()[objectApiName][topicFieldApiName]);

                    cmp.set("v.topics", advTopics);

                    var advTypes = ['All'];
                    Array.prototype.push.apply(advTypes, response.getReturnValue()[objectApiName][typeFieldApiName]);
                    cmp.set("v.types", advTypes);
                    resolve();
                } else {
                    console.log(response.getState());
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
    },

    getAbstracts: function (cmp) {
        cmp.set("v.abstracts", {});

        var action = cmp.get("c.getAbstracts");
        var selectedTopic = cmp.get("v.selectedTopic");
        var selectedType = cmp.get("v.selectedType");
        if (selectedTopic == 'All') {
            selectedTopic = '';
        }
        if (selectedType == 'All') {
            selectedType = '';
        }
        action.setParams({
            'abstractTopic': selectedTopic,
            'abstractType': selectedType
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let res = response.getReturnValue();
                res.forEach(e => {
                    e.assignedReviewers = e.Abstract_Reviews__r ? e.Abstract_Reviews__r.length : 0;
                    e.abstractLink = '/' + e.Id;
                });
                cmp.set("v.abstracts", res);
            } else {
                console.log(response.getState());
            }
        });
        $A.enqueueAction(action);
    },

    getReviewers: function (cmp, abstractId) {
        return new Promise((resolve, reject) => {
            var action = cmp.get("c.getReviewers");
            let isAuto = cmp.get('v.isAutoAssign');
            action.setParams({
                'abstractIds': abstractId,
                'isAuto': isAuto,
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    let generalData = [];
                    res.forEach(e => {
                        e.ReviewerLink = '/' + e.Id;
                        e.Membership_Status = e.Contact__r.Membership_Status__c;
                        let el = Object.assign({}, e);
                        el.ContactName = e.Contact__r.Name;
                        el.ContactLink = '/' + e.Contact__c;
                        generalData.push(el);
                    });

                    cmp.set("v.reviewers", generalData);
                    resolve();
                } else {
                    console.log(response.getState());
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
    },

    getReviewersForAuto: function (cmp, abstractIds) {
        return new Promise((resolve, reject) => {
            var action = cmp.get("c.getReviewers");
            action.setParams({
                'abstractIds': abstractId
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    let generalData = [];
                    res.forEach(e => {
                        e.ReviewerLink = '/' + e.Id;
                        e.Membership_Status = e.Contact__r.Membership_Status__c;
                        let el = Object.assign({}, e);
                        el.ContactName = e.Contact__r.Name;
                        el.ContactLink = '/' + e.Contact__c;
                        generalData.push(el);
                    });

                    cmp.set("v.reviewers", generalData);
                    resolve();
                } else {
                    console.log(response.getState());
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
    },

    getSelectedRecords: function (cmp, event) {
        var selectedRows = JSON.parse(JSON.stringify(event.getParam('selectedRows')));
        cmp.set("v.selectedRecords", selectedRows);
    },

    autoAssignReviewers: function (cmp) {
        if (cmp.get("v.selectedRecords").length > 0) {
            cmp.set("v.isAutoAssign", true);
            cmp.set("v.abstractListStage", false);
            cmp.set("v.spinnerVisible", true);
            let abstractId = [];
            if (cmp.get("v.selectedAbstract")) {
                abstractId.push(cmp.get("v.selectedAbstract").Id);
            } else {
                (cmp.get("v.selectedRecords")).forEach(e => {
                    abstractId.push(e.Id);
                });
            }

            this.getReviewers(cmp, abstractId)
                .then(result => {
                    this.setAbstractsColumnsToAssignAuto(cmp);
                    this.setReviewersColumns(cmp);
                    cmp.set("v.spinnerVisible", false);
                    cmp.set("v.abstractAssignStage", true);
                })
                .catch(error => {
                    console.log(error);
                    cmp.set("v.spinnerVisible", false);
                });
        }
    },

    manualAssignReviewers: function (cmp) {
        if (cmp.get("v.selectedRecords").length > 0) {
            cmp.set("v.abstractListStage", false);
            cmp.set("v.spinnerVisible", true);
            var abstractId;
            if (cmp.get("v.selectedAbstract")) {
                abstractId = cmp.get("v.selectedAbstract").Id;
            } else {
                var abstractId = cmp.get("v.selectedRecords")[0].Id;
                cmp.set("v.selectedAbstract", cmp.get("v.selectedRecords")[0]);
                cmp.set("v.selectedNameAbstract", `${cmp.get("v.selectedRecords")[0].Name} - ${cmp.get("v.selectedRecords")[0].Title__c}`);
            }

            this.getReviewers(cmp, [abstractId])
                .then(result => {
                    this.setAbstractsColumnsToAssign(cmp);
                    this.setReviewersColumns(cmp);
                    cmp.set("v.spinnerVisible", false);
                    cmp.set("v.abstractAssignStage", true);
                })
                .catch(error => {
                    console.log(error);
                    cmp.set("v.spinnerVisible", false);
                });
        }
    },

    previous: function (cmp) {
        cmp.set("v.selectedRecords", []);
        cmp.set("v.isAutoAssign", false);
        cmp.set("v.abstractAssignStage", false);
        cmp.set("v.spinnerVisible", true);
        cmp.set("v.abstractListStage", true);
        this.getAbstracts(cmp);
        cmp.set("v.spinnerVisible", false);
    },

    getAbstractReviewers: function (cmp, event) {

        var action = event.getParam('action');
        var row = event.getParam('row');
        console.log('action', action.name);
        console.log('row ', row);
        if (action.name === 'select_abstract') {
            cmp.set("v.selectedAbstract", row);

            cmp.set("v.reviewers", []);
            cmp.set("v.spinnerVisible", true);
            cmp.set("v.selectedNameAbstract", `${row.Name} - ${row.Title__c}`);
            this.getReviewers(cmp, [row.Id])
                .then(result => {
                    this.setReviewersColumns(cmp);
                    cmp.set("v.spinnerVisible", false);
                })
                .catch(error => {
                    cmp.set("v.spinnerVisible", false);
                    console.log(error);
                });
        }

        if (action.name === 'remove') {
            let selectedRecords = cmp.get("v.selectedRecords");
            for (let i = 0; i < selectedRecords.length; i++) {
                if (selectedRecords[i].Id === row.Id) {
                    selectedRecords.splice(i, 1);
                }
            }
            if (selectedRecords.length === 0) {
                this.previous(cmp);
            }
            cmp.set("v.selectedRecords", selectedRecords);

        }

    },

    getAuthorsData: function (cmp, abstractId, reviewerContactId, reviewerContactEmail) {
        return new Promise((resolve, reject) => {
            var action = cmp.get("c.getAuthorsData");
            action.setParams({
                'abstractId': abstractId,
                'reviewerContactId': reviewerContactId,
                'reviewerContactEmail': reviewerContactEmail
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else {
                    console.log(response.getState());
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
    },

    selectReviewer: function (cmp, event) {
        try {
            var selectedAbstract = cmp.get("v.selectedAbstract");
            var selectedReviewers = JSON.parse(JSON.stringify(event.getParam('selectedRows')));
            if (selectedAbstract) {
                selectedReviewers.forEach(reviewer => {
                    this.getAuthorsData(cmp, selectedAbstract.Id, reviewer.Contact__c, reviewer.Contact__r.Email)
                        .then(resultArray => {
                            if (reviewer.Contact__c === selectedAbstract.Abstract_Presenter__c ||
                                reviewer.Contact__r.Email === selectedAbstract.Abstract_Presenter__r.Email ||
                                resultArray.lenght > 0) {
                                cmp.set("v.notificationVisible", true);
                                cmp.set("v.notificationMessage", 'Conflicts of interest');
                                // unselect row
                                console.log('conflict');
                            } else {
                                // add junction object to map
                            }
                        })
                        .catch(error => {
                            cmp.set("v.spinnerVisible", false);
                            console.log(error);
                        })
                });
            }

        }
        catch (e) {
            console.log('selectReviewer catch', e);
        }
    },

    save: function (cmp, event) {
        if (!cmp.get("v.isAutoAssign")) {
            this.saveManual(cmp, event);
        }
        else {
            this.saveAuto(cmp, event);
        }
    },

    saveAuto: function (cmp, event) {
        let selectedRecords = cmp.get("v.selectedRecords");
        console.log('selectedRecords', selectedRecords);

        let reviewers = cmp.find('linesTable').getSelectedRows();
        console.log('reviewers', reviewers);
        if (reviewers.length === 0) { return; }
        let resList = [];

        selectedRecords.forEach(ab => {
            let countRew = ab.Required_number_of_reviewers__c - ab.assignedReviewers;

            if (countRew > 0) {
                for (let i = 0; i < reviewers.length; i++) {
                    if (countRew == 0) { break; }

                    if (ab.Abstract_Reviews__r &&
                        ab.Abstract_Reviews__r.find(el => {
                            return el.Reviewer__c === reviewers[i].Id;
                        })) { continue; }

                    if (ab.Abstract_Authors__r &&
                        ab.Abstract_Authors__r.find(el => {
                            return el.Abstract_Author__c === reviewers[i].Id;
                        })) { continue; }

                    if (ab.Abstract_Presenter__c === reviewers[i].Contact__c ||
                        ab.Submitter__c === reviewers[i].Contact__c) {
                        continue;
                    }

                    let topics = reviewers[i].Topics__c.split(';');
                    if (reviewers[i].Remaining_Capacity__c > 0 && topics.includes(ab.Abstract_Topic__c)) {
                        resList.push({ abId: ab.Id, rewId: reviewers[i].Id });
                        countRew--;
                        reviewers[i].Remaining_Capacity__c = reviewers[i].Remaining_Capacity__c - 1;
                    }
                }
            }

        });

        if (resList.length > 0) {
            console.log('go');
            cmp.set("v.spinnerVisible", true);
            var action = cmp.get("c.setAbstractRevAuto");
            action.setParams({
                'generalData': resList
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                cmp.set("v.spinnerVisible", false);
                console.log('state', state);
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    $A.get('e.force:showToast').setParams({
                        title: res.status,
                        message: res.message,
                        type: res.status,
                    }).fire();
                } else {
                    let errorMessage = 'Something Went Wrong';
                    $A.get('e.force:showToast').setParams({
                        title: "Error",
                        message: errorMessage,
                        type: "error"
                    }).fire();
                }
                this.previous(cmp);
            });
            $A.enqueueAction(action);
        } else {
            $A.get('e.force:showToast').setParams({
                title: 'Success',
                message: 'No reviewers to assign',
                type: 'Success',
            }).fire();

            this.previous(cmp);
        }
    },

    saveManual: function (cmp, event) {
        var selectedAbstract = cmp.get("v.selectedAbstract");
        // console.log('selectedAbstract ', selectedAbstract);
        let lines = cmp.find('linesTable').getSelectedRows();
        // console.log('lines ' , JSON.stringify(lines));
        let abstRev = {};
        lines.forEach(e => {
            abstRev[e.Id] = selectedAbstract.Id;
        });
        console.log('selectedAbstract ', selectedAbstract);
        console.log('lines ', lines);

        if (Object.keys(abstRev).length > 0) {
            var action = cmp.get("c.setAbstractRev");
            action.setParams({
                'generalData': abstRev
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    $A.get('e.force:showToast').setParams({
                        title: res.status,
                        message: res.message,
                        type: res.status,
                    }).fire();
                    selectedAbstract.assignedReviewers = selectedAbstract.assignedReviewers + lines.length;
                    cmp.set("v.selectedAbstract", selectedAbstract);
                    let selectedRecords = cmp.get("v.selectedRecords");
                    selectedRecords.forEach(function (record) {
                        if (record.Id == selectedAbstract.Id) {
                            record.assignedReviewers = selectedAbstract.assignedReviewers;
                        }
                    });
                    cmp.set("v.selectedRecords", selectedRecords);
                    if (res.isAbstractInReview) {
                        let filteredRecords = selectedRecords.filter(record => record != selectedAbstract);
                        if (filteredRecords.length > 0) {
                            cmp.set("v.selectedRecords", filteredRecords);
                            cmp.set("v.selectedAbstract", filteredRecords[0]);
                            cmp.set("v.selectedNameAbstract", `${filteredRecords[0].Name} - ${filteredRecords[0].Title__c}`);
                        } else {
                            this.previous(cmp);
                        }
                    }
                } else {
                    let errorMessage = 'Something Went Wrong';
                    if (response.getError()[0].message.length > 0) {
                        errorMessage = response.getError()[0].message;
                    }
                    $A.get('e.force:showToast').setParams({
                        title: "Error",
                        message: errorMessage,
                        type: "error"
                    }).fire();
                }
                this.manualAssignReviewers(cmp);
            });
            $A.enqueueAction(action);
        }

        console.log('abstRev ', abstRev);
    }
})