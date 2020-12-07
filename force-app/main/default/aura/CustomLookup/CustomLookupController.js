({
  doInit: function(component, event, helper){
    helper.getContact(component);
    helper.getAddresses(component);
  },
    onfocus : function(component,event,helper){
        $A.util.addClass(component.find("mySpinner"), "slds-show");
         var forOpen = component.find("searchRes");
             $A.util.addClass(forOpen, 'slds-is-open');
             $A.util.removeClass(forOpen, 'slds-is-close');
         // Get Default 5 Records order by createdDate DESC  
          var getInputkeyWord = component.get("v.SearchKeyWord");
          if(getInputkeyWord == null || getInputkeyWord == undefined)
            getInputkeyWord = '';
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
         }
         else{  
              component.set("v.listOfSearchRecords", null ); 
              var forclose = component.find("searchRes");
                $A.util.addClass(forclose, 'slds-is-close');
                $A.util.removeClass(forclose, 'slds-is-open');
           }
     },
     
   // function for clear the Record Selaction 
     clear :function(component,event,heplper){
          var pillTarget = component.find("lookup-pill");
          var lookUpTarget = component.find("lookupField"); 
          var outputText = component.find("output"); 
         
          $A.util.addClass(pillTarget, 'slds-hide');
          $A.util.removeClass(pillTarget, 'slds-show');
         
          $A.util.addClass(lookUpTarget, 'slds-show');
          $A.util.removeClass(lookUpTarget, 'slds-hide');

          $A.util.addClass(outputText, 'slds-hide');
          $A.util.removeClass(outputText, 'slds-show');

          var bottomText = component.find("newElement");
                    $A.util.addClass(bottomText, 'slds-show');
                    $A.util.removeClass(bottomText, 'slds-hide');
       
          component.set("v.SearchKeyWord",null);
          component.set("v.listOfSearchRecords", null );
          component.set("v.selectedRecord", {} );   
          component.set("v.selectedRecordId", "" ); 
     },
     
   // This function call when the end User Select any record from the result list.   
     handleComponentEvent : function(component, event, helper) {
     // get the selected Account record from the COMPONETN event 	 
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent); 
        
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

         var outputText = component.find("output"); 
             $A.util.addClass(outputText, 'slds-show');
             $A.util.removeClass(outputText, 'slds-hide');

             component.set("v.checkedPresenter", selectedAccountGetFromEvent.deleted1__c);
             component.set("v.selectedRecordId", selectedAccountGetFromEvent.Id);
       
     },

     createPresenter : function(component, event, helper) {
      component.set("v.showModal", true);
    },

    cancel : function(component, event, helper) {
      component.set("v.showModal", false);
    },

    save : function(component, event, helper) {
      helper.createContact(component)
      component.set("v.showModal", false);
    }
})