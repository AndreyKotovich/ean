({
    searchHelper : function(component,event,getInputkeyWord, selectedItems) {
      // set array of selected Ids
      var selectedIds = [];
      selectedItems.forEach(element => selectedIds.push(element.Id));
        // call the apex class method 
       var action = component.get("c.fetchLookUpValues");
        // set param to method  
          action.setParams({
              'searchKeyWord': getInputkeyWord,
              'selectedIds' : selectedIds
            });
        // set a callBack    
          action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
              var state = response.getState();
              if (state === "SUCCESS") {
                  var storeResponse = response.getReturnValue();
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
})