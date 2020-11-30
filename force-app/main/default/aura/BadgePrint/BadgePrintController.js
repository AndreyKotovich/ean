({
	doInit: function(component, event, helper) {
	   window.open(`${window.location.origin}/c/BadgeApp.app?id=${component.get('v.recordId')}`);
	   $A.get("e.force:closeQuickAction").fire();
	},
})