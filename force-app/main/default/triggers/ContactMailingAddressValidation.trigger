trigger ContactMailingAddressValidation on Contact (after insert, before update) {
    ContactMailingAddressValidationHelper.addressCheck(Trigger.new);
    if(Trigger.isUpdate){
        ContactMailingAddressValidationHelper.saveLastMailingAddress(Trigger.new, Trigger.old);
    }
}