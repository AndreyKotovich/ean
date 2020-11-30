({
	doInit: function(component, event, helper) {
		console.log(component.get('v.recordId'));
        $A.get('e.force:showToast').setParams({
          title: 'Success',
          type: 'success',
          message: 'OKAY'
        }).fire();
        $A.get("e.force:closeQuickAction").fire();
    },
})