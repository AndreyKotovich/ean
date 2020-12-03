({
    init : function(cmp, event, helper) {
        helper.loadData(cmp);
    },

    selectTopic : function(cmp, event, helper){
        helper.getAbstracts(cmp)
    },

    assignReviewers : function(cmp, event, helper){
        helper.assignReviewers(cmp);
    }
})