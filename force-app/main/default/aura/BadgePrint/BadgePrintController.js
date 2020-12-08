({
	doInit: function (component, event, helper) {
		var action = component.get("c.getUrl");

		action.setCallback(this, function (response) {
			let state = response.getState();
			let url = response.getReturnValue();
			console.log('url', url);
			if (state === "SUCCESS") {
				window.open(`${url}/c/BadgeApp.app?id=${component.get('v.recordId')}`);
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
	},
})