({

    doInit: function (component, event, helper) {
        var action2 = component.get("c.checkApprovalStep");
        action2.setParams({
            recordId: component.get("v.recordId"),
        });
        action2.setCallback(this, function (response) {
            var errorScreen = '0';
            var state = response.getState();
            if(state === 'SUCCESS'){
                let responseValue = response.getReturnValue();
                console.log(JSON.stringify(responseValue));
                if(responseValue.hasOwnProperty('stepName') && responseValue.hasOwnProperty('stepStatus')){
                    if(responseValue.stepName === 'SG_comment' && responseValue.stepStatus === 'Pending'){
                        console.log(responseValue);
                        errorScreen = '1';
                    }
                }
            } else if (state === "ERROR") {
                let resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error!",
                    "message": response.getError()[0].message,
                    "type": "error"
                });
                resultsToast.fire();
            }
            console.log(errorScreen);
            component.set("v.showCommentScreen", errorScreen);
        });
        $A.enqueueAction(action2);
    },
    handleAddComment: function (component, event, helper) {
        var action1 = component.get("c.insertComment");
        action1.setParams({
            recordId: component.get("v.recordId"),
            comment: component.get("v.comment")
        });
        action1.setCallback(this, function (response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                let resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success!",
                    "message": "Comment was added and record approved",
                    "type": "success"
                });
                resultsToast.fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                let resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error!",
                    "message": response.getError()[0].message,
                    "type": "error"
                });
                resultsToast.fire();
            }
        });
        $A.enqueueAction(action1);
    }
});