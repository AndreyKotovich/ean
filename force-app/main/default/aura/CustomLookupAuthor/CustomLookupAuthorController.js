({
    onfocus : function(component,event,helper){
      $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");

        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');

        // Get Default 5 Records order by createdDate DESC  
        var getInputkeyWord = component.get("v.SearchKeyWord");
        if(getInputkeyWord == null || getInputkeyWord == undefined){
          getInputkeyWord = '';
        }

        helper.searchHelper(component,event,getInputkeyWord);
    },

    onblur : function(component,event,helper){       
      component.set("v.listOfSearchRecords", null );
      var forclose = component.find("searchRes");
      
      $A.util.addClass(forclose, 'slds-is-close');
      $A.util.removeClass(forclose, 'slds-is-open');
    },

    keyPressController : function(component, event, helper) {
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
          var forOpen = component.find("searchRes");
          
          $A.util.addClass(forOpen, 'slds-is-open');
          $A.util.removeClass(forOpen, 'slds-is-close');
          
          helper.searchHelper(component,event,getInputkeyWord);
        }else{  
          component.set("v.listOfSearchRecords", null ); 
          var forclose = component.find("searchRes");
          
          $A.util.addClass(forclose, 'slds-is-close');
          $A.util.removeClass(forclose, 'slds-is-open');
        }
    },
     
    // delete pill item
    deletePill :function(component,event,heplper){
      var pillsDiv = component.find("lookup-pill");
      var outputText = component.find("output");  
      
      // add delete item from listOfSelectedRecords
      var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
      if(listOfSelectedRecords.size() == 0){
        component.set("v.pillsVisible", false);
      }

      $A.util.addClass(outputText, 'slds-hide');
      $A.util.removeClass(outputText, 'slds-show');
        
      component.set("v.SearchKeyWord",null);
      component.set("v.listOfSearchRecords", null );
      component.set("v.selectedRecord", {} );   
    },
     
    // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
      // get the selected Account record from the COMPONETN event 	 
      var selectedRecord = event.getParam("recordByEvent");
      component.set("v.selectedRecord" , selectedRecord); 

      // add record to listOfSelectedRecords
      var listOfSelectedRecords = component.get("v.listOfSelectedRecords");
      if(listOfSelectedRecords.size() > 0){
        component.set("v.pillsVisible", true);
      }
    
      var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');         

      var outputText = component.find("output"); 
        $A.util.addClass(outputText, 'slds-show');
        $A.util.removeClass(outputText, 'slds-hide');

        component.set("v.selectedRecordId", selectedRecord.Id); 
    }
})