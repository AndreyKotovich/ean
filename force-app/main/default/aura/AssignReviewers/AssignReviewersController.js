({
    init : function(cmp, event, helper) {
        helper.loadData(cmp);
    },

    selectTopic : function(cmp, event, helper){
        helper.getAbstracts(cmp)
    },

    selectType : function(cmp, event, helper) {
        helper.getAbstracts(cmp)
    },

    autoAssignReviewers : function(cmp, event, helper){
        helper.autoAssignReviewers(cmp);
    },

    manualAssignReviewers : function(cmp, event, helper){
        helper.manualAssignReviewers(cmp);
    },

    previous : function(cmp, event, helper){
        helper.previous(cmp);
    },

    getSelectedRecords : function(cmp, event, helper){
        helper.getSelectedRecords(cmp, event);
    },

    getAbstractReviewers : function(cmp, event, helper){
        helper.getAbstractReviewers(cmp, event);
    },

    selectReviewer : function(cmp, event, helper){
        helper.selectReviewer(cmp, event);
    },

    save : function(cmp, event, helper){
        helper.save(cmp);
    },
})