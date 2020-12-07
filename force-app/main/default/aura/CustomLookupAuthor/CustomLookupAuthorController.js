({
    doInit: function (component, event, helper) {
        helper.getContacts(component);
        helper.getAddresses(component);
    },
    onfocus: function (component, event, helper) {
        var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");

        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');

        // Get Default 5 Records order by createdDate DESC  
        var getInputkeyWord = component.get("v.SearchKeyWord");
        if (getInputkeyWord == null || getInputkeyWord == undefined) {
            getInputkeyWord = '';
        }

        helper.searchHelper(component, event, getInputkeyWord, listOfSelectedRecords);
    },

    onblur: function (component, event, helper) {
        component.set("v.listOfSearchRecords", null);
        var forclose = component.find("searchRes");

        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },

    keyPressController: function (component, event, helper) {
        var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if (getInputkeyWord.length > 0) {
            var forOpen = component.find("searchRes");

            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');

            helper.searchHelper(component, event, getInputkeyWord, listOfSelectedRecords);
        } else {
            component.set("v.listOfSearchRecords", null);
            var forclose = component.find("searchRes");

            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },

    // delete pill item
    deletePill: function (component, event) {
        var listOfSelectedRecords = component.get('v.listOfSelectedRecords');
        var associations = component.get("v.associations");

        var itemToDelete = event.getParam("index");
        listOfSelectedRecords.splice(itemToDelete, 1);
        associations.splice(itemToDelete, 1);

        component.set('v.listOfSelectedRecords', listOfSelectedRecords);
        component.set('v.associations', associations);
        console.log(associations);

        if (listOfSelectedRecords.length == 0) {
            component.set("v.pillsVisible", false);
        }

        var maxAuthors = component.get('v.maxAuthors');
        if (listOfSelectedRecords.length < maxAuthors) {
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-show');
            $A.util.removeClass(forclose, 'slds-hide');

            var bottomText = component.find("newElement");
            $A.util.addClass(bottomText, 'slds-show');
            $A.util.removeClass(bottomText, 'slds-hide');
        }
    },

    // This function call when the end User Select any record from the result list.   
    handleComponentEvent: function (component, event, helper) {
        // get the selected Account record from the COMPONETN event
        var selectedRecord = event.getParam("recordByEvent");
        selectedRecord = JSON.parse(JSON.stringify(selectedRecord));
        component.set("v.selectedRecord", selectedRecord);

        var AbstractRecordVariable = component.get("v.AbstractRecordVariable");
        AbstractRecordVariable = JSON.parse(JSON.stringify(AbstractRecordVariable));

        // add record to listOfSelectedRecords
        var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
        listOfSelectedRecords = JSON.parse(JSON.stringify(listOfSelectedRecords));

        var associations = component.get("v.associations");
        associations.push({
            Abstract__c: AbstractRecordVariable.Id,
            Abstract_Author__c: selectedRecord.Id
        });
        component.set("v.associations", associations);

        listOfSelectedRecords.push({
            type: 'icon',
            sobjectType: 'Contact',
            Id: selectedRecord.Id,
            label: selectedRecord.Name,
            iconName: 'standard:contact',
        });

        if (listOfSelectedRecords.length > 0) {
            component.set("v.pillsVisible", true);
        }

        component.set("v.listOfSelectedRecords", listOfSelectedRecords);

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');

        var maxAuthors = component.get('v.maxAuthors');
        if (listOfSelectedRecords.length > maxAuthors - 1) {
            $A.util.addClass(forclose, 'slds-hide');
            $A.util.removeClass(forclose, 'slds-show');

            var bottomText = component.find("newElement");
            $A.util.addClass(bottomText, 'slds-hide');
            $A.util.removeClass(bottomText, 'slds-show');
        }

        var outputText = component.find("output");
        $A.util.addClass(outputText, 'slds-show');
        $A.util.removeClass(outputText, 'slds-hide');

        component.set("v.selectedRecordId", selectedRecord.Id);
    },

    createAuthor: function (component, event, helper) {
        component.set("v.showModal", true);
    },

    cancel: function (component, event, helper) {
        component.set("v.showModal", false);
    },

    save: function (component, event, helper) {
        helper.validateRequiredInputs(component, 'field')
            .then(result => {
                if(result){
                    helper.createContact(component)
                }
            })
    }
})