({
	doInit : function(component, event, helper) {
		var spinner = component.find('mySpinner');
		$A.util.removeClass(spinner, 'slds-hide');

		helper.checkStatus(component, event);
		console.log(component.get("v.recordId"));
		helper.getCampaigns(component, event);

		$A.util.addClass(spinner, 'slds-hide');
	},

	update : function(component, event, helper) {
		var spinner = component.find('mySpinner');
		$A.util.removeClass(spinner, 'slds-hide');
		
		var action = component.get("c.updateSubscriptions");
		action.setParams({
			campaignIds: component.get("v.selectedCampaigns"),
			recordId: component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			$A.util.addClass(spinner, 'slds-hide');
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				$A.get('e.force:refreshView').fire();
				helper.showToast(component, event, 'success', 'Your subscriptions have been updated successfully');
			} else if (state === 'ERROR') {
				helper.processErrors(component, event, response.getError(), 'dI[1]:');
			} else {
				helper.processErrors(component, event, {}, 'dI[2]');
			}

		});
		$A.enqueueAction(action);
	},

	updateStatus : function(component, event, helper) {
		var spinner = component.find('mySpinner');
		$A.util.removeClass(spinner, 'slds-hide');
		console.log(1);
		
		var action = component.get("c.updateMcStatus");
		var mcData = JSON.parse(component.get("v.mcInfo"));
		mcData.isSubscribed = component.get("v.isSubscribed");

		action.setParams({
			recordId: component.get("v.recordId"),
			data: JSON.stringify(mcData)
		});

		action.setCallback(this, function(response) {
			$A.util.addClass(spinner, 'slds-hide');
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log(result);
				if (!result) {
					var subscriptions = [];
					component.set("v.selectedCampaigns", subscriptions);
				}
				component.set("v.isSubscribed", result);
				//$A.get('e.force:refreshView').fire();
				helper.showToast(component, event, 'success', 'Your subscription status has been updated successfully');
				component.set("v.isMcFail", false);
			} else if (state === 'ERROR') {
				component.set("v.isMcFail", true);
				helper.processErrors(component, event, response.getError(), 'dI[1]:');
			} else {
				component.set("v.isMcFail", true);
				helper.processErrors(component, event, {}, 'dI[2]');
			}

		});
		$A.enqueueAction(action);
	}
})