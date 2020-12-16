({
    loadData: function (cmp) {
        cmp.set("v.spinnerVisible", true);

        this.getTopics(cmp)
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
            { label: 'Name', fieldName: 'abstractLink', type: 'url', 
                typeAttributes: {label: { fieldName: 'Name' },target: '_blank',
                tooltip: 'Click to see object page'}},
            { label: 'Title', fieldName: 'Title__c', type: 'text' },
            { label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Stage', fieldName: 'Stage__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },            
            { label: 'Assigned Reviewers', fieldName: 'assignedReviewers', type: 'text' },
        ])
    },

    setAbstractsColumnsToAssign: function (cmp) {
        cmp.set("v.abstractColumnsToAssign", [
            { label: 'Name', fieldName: 'abstractLink', type: 'url', 
                typeAttributes: {label: { fieldName: 'Name' },target: '_blank',
                tooltip: 'Click to see object page'}},
            { label: 'Title', fieldName: 'Title__c', type: 'text' },
            { label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Stage', fieldName: 'Stage__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Assigned Reviewers', fieldName: 'assignedReviewers', type: 'text' },
            { label: '', type: 'button', initialWidth: 135, typeAttributes: { label: 'Select', name: 'select_abstract', title: 'Click to Select Abstract' } },
        ])
    },


    setReviewersColumns: function (cmp) {
        cmp.set("v.reviewerColumns", [
            { label: 'Name', fieldName: 'ReviewerLink', type: 'url', 
                typeAttributes: {label: { fieldName: 'Name' },target: '_blank',
                tooltip: 'Click to see object page'}},
            { label: 'Contact Name', fieldName: 'ContactLink', type: 'url', 
                typeAttributes: {label: { fieldName: 'ContactName' },target: '_blank',
                tooltip: 'Click to see object page'}},           
            { label: 'Remaining Capacity', fieldName: 'Remaining_Capacity__c', type: 'text' },
            { label: 'Assigned Abstracts', fieldName: 'Assigned_Abstracts__c', type: 'text' }
        ])
    },

    getTopics: function (cmp) {
        return new Promise((resolve, reject) => {
            var objectApiName = 'Abstract__c';
            var request = {
                'Abstract__c' : ['Abstract_Topic__c', 'Type__c']
            };
            var action = cmp.get("c.getPickListValues");
            action.setParams({
                'objectApiNameTofieldApiNameMap': request
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var advTopics = ['All'];
                    Array.prototype.push.apply(advTopics, response.getReturnValue()[objectApiName]['Abstract_Topic__c']);

                    cmp.set("v.topics", advTopics);

                    var advTypes = ['All'];
                    Array.prototype.push.apply(advTypes, response.getReturnValue()[objectApiName]['Type__c']);
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

    getTypes: function (cmp) {
        return new Promise((resolve, reject) => {
            var objectApiName = 'Abstract__c';
            var fieldApiName = 'Type__c';
            var action = cmp.get("c.getPickListValues");
            action.setParams({
                'objectApiName': objectApiName,
                'fieldApiName': fieldApiName
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var advTypes = ['All'];
                    Array.prototype.push.apply(advTypes, response.getReturnValue());

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
            action.setParams({
                'abstractId': abstractId
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let res = response.getReturnValue();
                    let generalData = [];
                    res.forEach(e => {
                        e.ReviewerLink = '/' + e.Id;
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

    },

    manualAssignReviewers: function (cmp) {
        cmp.set("v.abstractListStage", false);
        cmp.set("v.spinnerVisible", true);

        var abstractId = cmp.get("v.selectedRecords")[0].Id;
        cmp.set("v.selectedAbstract", cmp.get("v.selectedRecords")[0]);

        cmp.set("v.selectedNameAbstract", `${cmp.get("v.selectedRecords")[0].Name} - ${cmp.get("v.selectedRecords")[0].Title__c}`);

        this.getReviewers(cmp, abstractId)
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
    },

    previous: function (cmp) {
        cmp.set("v.selectedRecords", []);

        cmp.set("v.abstractAssignStage", false);
        cmp.set("v.spinnerVisible", true);
        cmp.set("v.abstractListStage", true);

        cmp.set("v.spinnerVisible", false);
    },

    getAbstractReviewers: function (cmp, event) {
        var row = event.getParam('row');
        console.log('row ', row);
        cmp.set("v.selectedAbstract", row);

        cmp.set("v.reviewers", []);
        cmp.set("v.spinnerVisible", true);
        cmp.set("v.selectedNameAbstract", `${row.Name} - ${row.Title__c}`);
        this.getReviewers(cmp, row.Id)
            .then(result => {
                this.setReviewersColumns(cmp);
                cmp.set("v.spinnerVisible", false);
            })
            .catch(error => {
                cmp.set("v.spinnerVisible", false);
                console.log(error);
            });
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
        catch (e) {
            console.log('selectReviewer catch', e);
        }
    },

    save: function (cmp, event) {
        console.log('selectedRows ');

        var selectedAbstract = cmp.get("v.selectedAbstract");
        // console.log('selectedAbstract ', selectedAbstract);
        let lines = cmp.find('linesTable').getSelectedRows();
        // console.log('lines ' , JSON.stringify(lines));
        let abstRev = {};
        lines.forEach(e => {
            abstRev[e.Id] = selectedAbstract.Id;
        });
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
                } else {
                    $A.get('e.force:showToast').setParams({
                        title: "Error",
                        message: 'Something Went Wrong',
                        type: "error"
                    }).fire();
                }
                this.manualAssignReviewers(cmp);
            });
            $A.enqueueAction(action);
        }

        console.log('abstRev ', abstRev);
    },
})