({
	checkStatus : function (component, event) {
		var action = component.get("c.checkMcStatus");
		action.setParams({
			recordId: component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			console.log('-----------------------------');
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var result = JSON.parse(response.getReturnValue());
				console.log(result);
				component.set("v.mcInfo", response.getReturnValue());
				component.set("v.isSubscribed", result.isSubscribed);
				component.set("v.isMcFail", false);
			} else if (state === 'ERROR') {
				component.set("v.isMcFail", true);
				console.log('error');
				console.log(response.getError());
				//this.processErrors(component, event, response.getError(), 'dI[1]:');
			} else {
				component.set("v.isMcFail", true);
				console.log('fail');
				//this.processErrors(component, event, {}, 'dI[2]');
			}
			console.log('-----------------------------');
		});
		$A.enqueueAction(action);
	},
	getCampaigns : function (component, event) {
		var action = component.get("c.getNewsletterList");
		action.setParams({
			recordId: component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();

			if (component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue();
				var campaings = JSON.parse(result);
				var campaingNames = [];
				var subscriptions = [];
				campaings.forEach(item => {
					campaingNames.push({label: item.campaignRecord.Name, value: item.campaignRecord.Id});
					if (item.isSubscribed) {
						subscriptions.push(item.campaignRecord.Id);
					}
				});
				component.set("v.campaigns", campaingNames);
				component.set("v.selectedCampaigns", subscriptions);
				
			} else if (state === 'ERROR') {
				this.processErrors(component, event, response.getError(), 'dI[1]:');
			} else {
				this.processErrors(component, event, {}, 'dI[2]');
			}
		});
		$A.enqueueAction(action);
	},
	
	processErrors : function(component, event, errors, place) {

		var message = 'Error: ' + JSON.stringify(errors);
	
		if (errors && errors[0]) {
			if (errors[0].message) {
				message = errors[0].message;
			} else if (errors[0].pageErrors && errors[0].pageErrors[0]) {
				message = errors[0].pageErrors.map(function(error) { return error.message; }).join(', ') + '.';
			} else if (errors[0].fieldErrors && errors[0].fieldErrors[0]) {
				message = errors[0].fieldErrors.map(function(error) { return error.message; }).join(', ') + '.';
			}
		}
	
		this.showToast (
			component,
			event,
			'warning',
			message
		);
	  },
	
	showToast: function(component, event, type, message) {
		$A.get('e.force:showToast').setParams({
			type: type,
			mode: (type === 'success' ? 'dismissible' : 'sticky'),
			title: (type === 'success' ? 'Success!' : 'Warning!'),
			message: message
		}).fire();
	}
})