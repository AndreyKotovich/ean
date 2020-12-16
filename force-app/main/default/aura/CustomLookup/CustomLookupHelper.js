({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 
       var action = component.get("c.fetchLookUpValues");
        // set param to method  
          action.setParams({
              'searchKeyWord': getInputkeyWord
            });
        // set a callBack    
          action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
              var state = response.getState();
              if (state === "SUCCESS") {
                  var storeResponse = response.getReturnValue();
                  console.log(JSON.parse(JSON.stringify(storeResponse)));
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                  if (storeResponse.length == 0) {
                      component.set("v.Message", 'No Result Found...');
                  } else {
                      component.set("v.Message", '');
                  }
                  // set searchResult list with return value from server.
                  component.set("v.listOfSearchRecords", storeResponse);
              }
              else{
                  console.log(response.getState());
              }
   
          });
        // enqueue the Action  
          $A.enqueueAction(action);
      
      },

      createContact : function(component){
        var action = component.get("c.createContact");
        var FirstName = component.get("v.FirstName");
        var LastName = component.get("v.LastName");
        var Email = component.get("v.Email");
        var Department = component.get("v.Department");
        var City = component.get("v.City");
        var Country = component.get("v.Country");

        action.setParams({
              'FirstNameString': FirstName,
              'LastNameString' : LastName,
              'EmailString' : Email,
              'Department' : Department,
              'City' : City,
              'Country' : Country
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var newContact = response.getReturnValue();
                    component.set("v.selectedRecord" , newContact); 
                    component.set("v.selectedRecordId", newContact.Id);
                    component.set("v.checkedPresenter", newContact.deleted1__c);
                    component.set("v.showModal", false);
                    var forclose = component.find("lookup-pill");
                        $A.util.addClass(forclose, 'slds-show');
                        $A.util.removeClass(forclose, 'slds-hide');
              
                    var forclose = component.find("searchRes");
                        $A.util.addClass(forclose, 'slds-is-close');
                        $A.util.removeClass(forclose, 'slds-is-open');
                    
                    var lookUpTarget = component.find("lookupField");
                        $A.util.addClass(lookUpTarget, 'slds-hide');
                        $A.util.removeClass(lookUpTarget, 'slds-show'); 
                    
                        var bottomText = component.find("newElement");
                        $A.util.addClass(bottomText, 'slds-hide');
                        $A.util.removeClass(bottomText, 'slds-show');
                }
                else {
                    console.log(response.getState());                    
                    console.log(response.getError());
                    let errors = action.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.showToast('Error', errors[0].message, 'error')
                        }
                    }
                }
            });
        $A.enqueueAction(action);
    },

    getContact : function(component){
        var AbstractRecordVariable = component.get("v.AbstractRecordVariable");
        AbstractRecordVariable = JSON.parse(JSON.stringify(AbstractRecordVariable));

        var action = component.get("c.getContact");
        action.setParams({
          'abstractId': AbstractRecordVariable.Id
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var contact = response.getReturnValue();
                contact = JSON.parse(JSON.stringify(contact));
                if(contact != null){
                    component.set("v.selectedRecord" , contact); 

                    var forclose = component.find("lookup-pill");
                    $A.util.addClass(forclose, 'slds-show');
                    $A.util.removeClass(forclose, 'slds-hide');

                    var lookUpTarget = component.find("lookupField");
                    $A.util.addClass(lookUpTarget, 'slds-hide');
                    $A.util.removeClass(lookUpTarget, 'slds-show');

                    var bottomText = component.find("newElement");
                    $A.util.addClass(bottomText, 'slds-hide');
                    $A.util.removeClass(bottomText, 'slds-show');
                }
            }
            else{
                console.log(response.getState());
            }
 
        });
        $A.enqueueAction(action);
    },

    showToast: function (title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    getAddresses : function(component){
        var action = component.get("c.getMailingCountries");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var countries = response.getReturnValue();
                countries = JSON.parse(JSON.stringify(countries));
                component.set("v.Countries", countries);
                component.set("v.Country", countries[0]);
            }
            else{
                console.log(response.getState());
            }
        });
        $A.enqueueAction(action);
    },

    validateRequiredInputs: function (component, auraId) {
        return new Promise( (resolve => {
            console.log('component.find(auraId): '+ component.find(auraId));
            console.log('component.find(auraId): '+ component.find(auraId).length);
            let allValid = [].concat(component.find(auraId)).reduce(function (validSoFar, inputCmp) {
                inputCmp.showHelpMessageIfInvalid();
                return validSoFar && !inputCmp.get('v.validity').valueMissing;
            }, true);

            console.log('allValid',allValid);

            if(!allValid){
                this.showToast('Error', 'Check your inputs', 'error');
            }

            resolve(allValid);
        }))
    }
})