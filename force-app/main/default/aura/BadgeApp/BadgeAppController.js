({

  doInit: function (component, event, helper) {
    let ids = component.get("v.id") || '';
    if (ids === '') {
      return;
    }
    var settings = {
      colorAccent: 'rgb(125, 206, 242)',
    };

    document.documentElement.style.setProperty('--color-accent', settings.colorAccent);
    console.log('ids ', ids);
    
    var action = component.get("c.getTemplateBadge");
    action.setParams({
      ids: ids.split(',')
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      let badges = response.getReturnValue();
      console.log('response ', response);
      console.log('getReturnValue ', badges);
      if (state === "SUCCESS" && badges && badges.length > 0) {
        component.set('v.badges', badges);
      } else {
        $A.get('e.force:showToast').setParams({
          title: "Error",
          message: 'Something Went Wrong'
        }).fire();
      }
    });
    $A.enqueueAction(action);
  }
})