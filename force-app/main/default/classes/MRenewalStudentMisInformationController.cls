public with sharing class MRenewalStudentMisInformationController {

	public MRenewalStudentMisInformationController() {
	}

	public String appFormId { get; set; }

	public String getLastApprovalComment() {
		if (String.isBlank(appFormId)) return '';

		List<ProcessInstanceStep> steps = [SELECT Comments FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :appFormId ORDER BY SystemModStamp DESC LIMIT 1];
		return !steps.isEmpty() ? steps[0].comments : '';

		// return 'getLastApprovalComment';
	}
}