({
    doInit : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        setTimeout(() => {
            $A.get("e.force:closeQuickAction").fire();
        }, 1000);

        window.open(`${window.location.origin}/apex/AbstractBooks?type=AbstractReviews&id=${component.get('v.recordId')}`, '_blank');
        
    }
})