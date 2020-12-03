({
    loadData : function(cmp){
        this.setColumns(cmp);
        this.getTopics(cmp)
            .then(
                result => this.getAbstracts(cmp)
            );
    },

    setColumns : function(cmp){
        cmp.set("v.columns", [
            {label: 'Name', fieldName: 'Name', type: 'text'},
            {label: 'Title', fieldName: 'Title__c', type: 'text'},
            {label: 'Topic', fieldName: 'Abstract_Topic__c', type: 'text'},
            {label: 'Type', fieldName: 'Type__c', type: 'text'},
            {label: 'Stage', fieldName: 'Stage__c', type: 'text'},
            {label: 'Status', fieldName: 'Status__c', type: 'text'}
        ])
    },

    getTopics : function(cmp) {
        return new Promise((resolve, reject) => {
            var action = cmp.get("c.getTopics");
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var advTopics = ['All'];
                    Array.prototype.push.apply(advTopics, response.getReturnValue());

                    cmp.set("v.topics", advTopics);
                    resolve();
                }else{
                    console.log(response.getState());
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
    },

    getAbstracts : function(cmp) {
        cmp.set("v.abstracts", {});

        var action = cmp.get("c.getAbstracts");
        var selectedTopic = cmp.get("v.selectedTopic");
        if(selectedTopic == 'All'){
            selectedTopic = '';
        }
        action.setParams({
            'abstractTopic': selectedTopic
          });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.abstracts", response.getReturnValue());
            }else{
                console.log(response.getState());
            }
        });
        $A.enqueueAction(action);
    },

    assignReviewers : function(cmp){

    }
})