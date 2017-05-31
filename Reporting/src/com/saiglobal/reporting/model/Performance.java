package com.saiglobal.reporting.model;

public enum Performance {
	WI_FINISHED_TO_ARG_SUBMMITTED("WI Finished To ARG Submitted"),
	ARG_SUBMITTED_TO_ARG_APPROVED("ARG Submitted To ARG Approved"),
	ARG_SUBMITTED_TO_ARG_APPROVED_WITH_REJECTION("ARG Submitted To ARG Approved with Rejections"),
	ARG_SUBMITTED_TO_ARG_APPROVED_WITH_TA("ARG Submitted To ARG Approved with TR"),
	ARG_REJECTED_TO_ARG_RESUBMITTED("ARG Rejected To ARG Resubmitted"),
	ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD("ARG Approved to ARG Completed or On Hold"),
	WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD("WI Finished to ARG Completed or On Hold");
	
	String name; 
	Performance(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
}
