({
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