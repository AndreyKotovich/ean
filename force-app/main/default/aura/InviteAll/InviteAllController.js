({
    doInit: function (component, event, helper) {
        let action = component.get("c.getGroupMembers");
        action.setParams({
            groupId: component.get('v.recordId')
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let users = response.getReturnValue();
                component.set("v.participantsAmount", users.length);
                let selectedAmount = users.length>=150 ? 150 : users.length;
                component.set("v.selectedAmount", selectedAmount);

                for(let i=0; i<users.length; i++){
                    if(i<150){
                        users[i].isChecked = true;
                    }
                }

                component.set("v.groupMembers", users);
                component.set("v.loaded", true);

            } else {
                component.set("v.loaded", true);
                console.log('error: '+JSON.stringify(response.getError()));
                let errors = response.getError();
                component.set("v.showErrors", true);
                let errorMessage = errors[0].message.includes('No members found')?errors[0].message:'Something went wrong';
                component.set("v.errorMessage", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },

    next: function (component, event, helper) {
        let checkboxes = document.getElementsByName('options');
        let checkedUsersId = [];

        for (let i=0; i<checkboxes.length; i++) {
            if (checkboxes[i].checked) {
                checkedUsersId.push(checkboxes[i].dataset.id);
            }
        }

        if(checkedUsersId.length === 0){
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Select at least one participant",
                "type": "error"
            });
            toastEvent.fire();
        } else if(checkedUsersId.length >= 150){
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "You can't choose more than 150 participants",
                "type": "error"
            });
            toastEvent.fire();
        } else {

            window.sessionStorage.setItem('selectedParticipants', JSON.stringify(checkedUsersId));

            let navService = component.find("navService");
            let pageReference = {
                type: "comm__namedPage",
                attributes: {
                    name: 'gotomeeting'
                }
            };
            navService.navigate(pageReference);

        }

    },

    cancel: function (component, event, helper) {
        let dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },

    inviteAll: function (component, event, helper) {
        let inviteAllCheckbox = document.getElementById('checkbox-invite-all');
        let checkboxes = document.getElementsByName('options');
        if(inviteAllCheckbox.checked){
            let arraySize = checkboxes.length>=150 ? 150 : checkboxes.length;

            for (let i=0; i<arraySize; i++) {
                checkboxes[i].checked = true;
            }

            component.set("v.selectedAmount", arraySize);


        } else {

            for (let i=0; i<checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            component.set("v.selectedAmount", 0);

        }
    },

    optionClick: function (component, event, helper) {
        let id = event.currentTarget.getAttribute('id');
        let element = document.getElementById(id);
        let selectedAmount = component.get('v.selectedAmount');
        let participantsAmount = component.get('v.participantsAmount');

        if(element.checked){
            selectedAmount++;
        } else {
            selectedAmount--;
        }

        let inviteAllCheckbox = document.getElementById('checkbox-invite-all');

        if(selectedAmount>=150 || participantsAmount == selectedAmount){
            inviteAllCheckbox.checked = true;
        } else {
            inviteAllCheckbox.checked = false;
        }


        component.set("v.selectedAmount", selectedAmount);
    }
});