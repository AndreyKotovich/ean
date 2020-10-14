({
    doInit : function(component, event, helper) {

        var action = component.get("c.getContactId");
        action.setCallback(this, function(response) {
            let state = response.getState();
            let contactId = response.getReturnValue();
            if (state === "SUCCESS" && contactId !== 'none') {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/contact/" + contactId
                });
                urlEvent.fire();
            } else {
                $A.get('e.force:showToast').setParams({
                    title: "Error",
                    message: 'Your current user doesn\'t have related Contact'
                }).fire();
            }
        });
        $A.enqueueAction(action);
    }
})