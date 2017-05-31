package com.saiglobal.reporting.model;

public enum Queue {
	WI_FINISHED_NOT_SUBMMITTED("WI Finished Not Submitted"),
	WI_SUBMITTED_WITHOUT_ARG("WI Submitted Without ARG"),
	WI_SUBMITTED_ARG_PENDING("WI Submitted ARG Pending"),
	ARG_REJECTED_TO_BE_RESUBMITTED("ARG Rejected To Be Re-submitted"),
	ARG_SUBMITTED_NOT_TAKEN("ARG Submitted Not Taken"),
	ARG_TAKEN_NOT_REVIEWED("ARG Taken Not Reviewed"),
	ARG_APPROVED_NOT_ASSIGNED_ADMIN("ARG Approved Not Assigned To Admin"),
	ARG_ASSIGNED_ADMIN_NOT_COMPLETED("ARG Assigned To Admin Not Completed");
	
	String name; 
	Queue(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
}
