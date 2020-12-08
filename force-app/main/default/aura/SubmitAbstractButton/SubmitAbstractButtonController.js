({
    handleClick: function (component, event, helper) {
        
        let navService = component.find("navService");
        let pageReference = {
            type: "comm__namedPage",
            attributes: {
                name: 'Submit_Abstract__c'
            }

        };

        navService.navigate(pageReference);
    }
});