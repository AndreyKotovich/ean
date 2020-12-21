({
    handleWord : function(component, event, helper) {
		window.open(`${window.location.origin}/apex/AbstractBooksWord?type=AbstractStaff&id=${component.get('v.recordId')}`, '_blank');
	},
    handlePDF : function(component, event, helper) {
		window.open(`${window.location.origin}/apex/AbstractBooks?type=AbstractStaff&id=${component.get('v.recordId')}`, '_blank');
	},
    handleHTML : function(component, event, helper) {
		window.open(`${window.location.origin}/apex/AbstractBooksHtml?type=AbstractStaff&id=${component.get('v.recordId')}`, '_blank');
	}
})