package com.saiglobal.sf.core.model;

import org.apache.log4j.Logger;

public enum SfWorkItemStatus {
	ApplicationUnpaid("Application Unpaid"),
	Open("Open"),
	Allocated("Allocated"),
	Scheduled("Scheduled"),
	ScheduledOffered("Scheduled - Offered"),
	Confirmed("Confirmed"),
	Servicechange("Service change"),
	InProgress("In Progress"),
	Submitted("Submitted"),
	UnderReview("Under Review"),
	Support("Support"),
	Completed("Completed"),
	Cancelled("Cancelled"),
	InitiateService("Initiate service"),
	Incomplete("Incomplete"),
	UnderReviewRejected("Under Review - Rejected"),
	Complete("Complete"),
	Draft("Draft"),
	Unknown("Unknown");
	
	String name; 
	SfWorkItemStatus(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static SfWorkItemStatus getValueForName(String typeString) {
		try {
			return valueOf(typeString.trim().replace(" ", "").replace("-", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfWorkItemStatus.getValueForName(" + typeString + ")", e);
		}
	return SfWorkItemStatus.Unknown; 
	}
}
