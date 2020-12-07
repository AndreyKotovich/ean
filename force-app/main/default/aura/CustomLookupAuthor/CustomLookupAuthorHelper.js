({
    searchHelper: function (component, event, getInputkeyWord, selectedItems) {
        // set array of selected Ids
        var selectedIds = [];
        selectedItems.forEach(element => selectedIds.push(element.Id));
        // call the apex class method 
        var action = component.get("c.fetchLookUpValues");
        // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'selectedIds': selectedIds
        });
        // set a callBack    
        action.setCallback(this, function (response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            } else {
                console.log(response.getState());
            }

        });
        // enqueue the Action  
        $A.enqueueAction(action);

    },

    createContact: function (component) {
        var action = component.get("c.createContact");
        var FirstName = component.get("v.FirstName");
        var LastName = component.get("v.LastName");
        var Email = component.get("v.Email");
        var Department = component.get("v.Department");
        var City = component.get("v.City");
        var Country = component.get("v.Country");

        action.setParams({
            'FirstNameString': FirstName,
            'LastNameString': LastName,
            'EmailString': Email,
            'Department': Department,
            'City': City,
            'Country': Country
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var newContact = response.getReturnValue();
                console.log(newContact);

                var AbstractRecordVariable = component.get("v.AbstractRecordVariable");
                AbstractRecordVariable = JSON.parse(JSON.stringify(AbstractRecordVariable));

                var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
                listOfSelectedRecords = JSON.parse(JSON.stringify(listOfSelectedRecords));

                var associations = component.get("v.associations");
                associations.push({
                    Abstract__c: AbstractRecordVariable.Id,
                    Abstract_Author__c: newContact.Id
                });
                component.set("v.associations", associations);

                listOfSelectedRecords.push({
                    type: 'icon',
                    sobjectType: 'Contact',
                    Id: newContact.Id,
                    label: newContact.Name,
                    iconName: 'standard:contact',
                });
                component.set("v.listOfSelectedRecords", listOfSelectedRecords);

                if (listOfSelectedRecords.length > 0) {
                    component.set("v.pillsVisible", true);
                }

                console.log(listOfSelectedRecords);
                component.set("v.showModal", false);
            } else {

                console.log(response.getError());
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast('Error', errors[0].message, 'error')
                    }
                }
            }
        });

        $A.enqueueAction(action);
    },

    showToast: function (title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    getContacts: function (component) {
        var AbstractRecordVariable = component.get("v.AbstractRecordVariable");
        AbstractRecordVariable = JSON.parse(JSON.stringify(AbstractRecordVariable));

        var action = component.get("c.getContacts");
        action.setParams({
            'abstractId': AbstractRecordVariable.Id
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var contacts = response.getReturnValue();
                this.setContactsPills(component, contacts);
            } else {
                console.log(response.getState());
            }

        });
        $A.enqueueAction(action);
    },

    setContactsPills: function (component, contacts) {
        var pillsArray = [];

        contacts.forEach(contact => {
            pillsArray.push({
                type: 'icon',
                sobjectType: 'Contact',
                Id: contact.Id,
                label: contact.Name,
                iconName: 'standard:contact',
            });
        })

        component.set("v.listOfSelectedRecords", pillsArray);

        if (pillsArray.length == 0) {
            component.set("v.pillsVisible", false);
        } else if (pillsArray.length > 0) {
            component.set("v.pillsVisible", true);
        }

        var maxAuthors = component.get('v.maxAuthors');
        if (pillsArray.length > maxAuthors - 1) {
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-hide');
            $A.util.removeClass(forclose, 'slds-show');

            var bottomText = component.find("newElement");
            $A.util.addClass(bottomText, 'slds-hide');
            $A.util.removeClass(bottomText, 'slds-show');
        } else {
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-show');
            $A.util.removeClass(forclose, 'slds-hide');

            var bottomText = component.find("newElement");
            $A.util.addClass(bottomText, 'slds-show');
            $A.util.removeClass(bottomText, 'slds-hide');
        }
    },

    getAddresses: function (component) {
        var action = component.get("c.getMailingCountries");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var countries = response.getReturnValue();
                countries = JSON.parse(JSON.stringify(countries));
                component.set("v.Countries", countries);
                component.set("v.Country", countries[0]);
            } else {
                console.log(response.getState());
            }
        });
        $A.enqueueAction(action);
    },

    validateRequiredInputs: function (component, auraId) {
        return new Promise( (resolve => {
            console.log('getElements', component.getElements());
            let allValid = component.find(auraId).reduce(function (validSoFar, inputCmp) {
                inputCmp.showHelpMessageIfInvalid();
                return validSoFar && !inputCmp.get('v.validity').valueMissing;
            }, true);

            console.log('allValid',allValid);

            if(!allValid){
                this.showToast('Error', 'Check your inputs', 'error');
            }

            resolve(allValid);
        }))
    }
})