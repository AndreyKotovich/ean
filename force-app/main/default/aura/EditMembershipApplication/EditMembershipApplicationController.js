({
    doInit: function (component, event, helper) {
        var action = component.get("c.getCommunityHomeUrl");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                window.location.href = response.getReturnValue() + '/s/membership-application?fi='+component.get('v.recordId');
            } else {
                location.reload();
            }
        });
        $A.enqueueAction(action);
    }
});