({
    recordUpdate: function (component, event, helper) {
        console.log(component.get("v.fellowshipRecord").RecordType.DeveloperName);
        let recordType = component.get("v.fellowshipRecord").RecordType.DeveloperName;
        let redirectPageApi = recordType==='Clinical_Fellowship'?'clinical_fellowship_application':
                              recordType==='Research_Fellowship'?'Research_Fellowship_Application':'';
        let navService = component.find("navService");
        let pageReference = {
            type: "comm__namedPage",
            attributes: {
                name: redirectPageApi
            },
            state:{
                'fellowship-id': component.get('v.recordId')
            }
        };
        navService.navigate(pageReference);
    }
});