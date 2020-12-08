({
    handleClick: function (component, event, helper) {
        
        let navService = component.find("navService");
        let pageReference = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: component.get("v.targetObject"),
                actionName: "list"
            },

        };

        navService.navigate(pageReference);
    }
});