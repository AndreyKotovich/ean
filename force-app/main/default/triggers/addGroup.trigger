trigger addGroup on CollaborationGroup (after insert, after delete, after update, after undelete) {
    List<Group__c> groupFind = [SELECT Id, Name FROM Group__c];
    List<Group__c> groupList;
    Boolean check;
    if (Trigger.isDelete) {
        groupList = new List<Group__c>();
        for (CollaborationGroup cg : Trigger.old) {
            for (Group__c g : groupFind) {
                if (g.Name == cg.Name) {
                    groupList.add(g);
                    break;
                }
            }
        }
        delete groupList;
    }
    if (Trigger.isUpdate) {
        groupList = new List<Group__c>();
        List<CollaborationGroup> groupsOld = Trigger.old;
        List<CollaborationGroup> groupsNew = Trigger.new;
        for (Integer i = 0; i < groupsNew.size(); i++) {
            if (groupsOld[i].Name != groupsNew[i].Name) {
                for (Group__c g : groupFind) {
                    if (g.Name == groupsOld[i].Name) {
                        g.Name = groupsNew[i].Name;
                        groupList.add(g);
                    }
                }
            }
        }
        update groupList;
    }
}