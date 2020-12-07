({
    doInit: function (component, event, helper) {
        var action = component.get("c.getOrder");
        action.setParams({
            applicationFormId: component.get('v.recordId')
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var order = response.getReturnValue();
                if(order==null){
                    //show error screen
                    component.set('v.errorScreen', true);
                }else{
                    if(order["Status__c"]==="Paid"){
                        //show paid screen
                        component.set('v.paidScreen', true);
                    }else{
                        //redirect to payment page
                        let navService = component.find("navService");
                        let pageReference = {
                            type: "comm__namedPage",
                            attributes: {
                                name: 'payment_component'
                            },
                            state:{
                                orderId: order["Id"]
                            }
                        };
                        navService.navigate(pageReference);
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
});