({
    doInit: function (component, event, helper) {
        var action = component.get("c.displayEventRegisterButton");
        action.setParams({
            recordId: component.get('v.recordId')
        });

        action.setCallback(this, function (response) {
            let state = response.getState();
            let showButton = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set('v.showButton', showButton);
            }
        });
        $A.enqueueAction(action);
    },

    handleClick: function (component, event, helper) {
        let navService = component.find("navService");

        let pageReference = {
            type: "comm__namedPage",
            attributes: {
                name: 'Event_Registration__c'
            },
            state:{
                ei: component.get("v.recordId")
            }
        };

        navService.navigate(pageReference);
    }
});