({
	doInit: function(component, event, helper) {
		var action = component.get("c.sendInvoice");
    action.setParams({
      orderId: component.get('v.recordId')
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      console.log('state ', state);
      if (state === "SUCCESS") {
        $A.get('e.force:showToast').setParams({
          title: 'Success',
          type: 'success',
          message: 'Sent'
        }).fire();
        $A.get("e.force:closeQuickAction").fire();
      } else {
        $A.get('e.force:showToast').setParams({
          title: "Error",
          message: 'Something Went Wrong'
        }).fire();
        $A.get("e.force:closeQuickAction").fire();
      }
    });
    $A.enqueueAction(action);
  } 
})