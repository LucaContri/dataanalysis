package com.saiglobal.sf.core.model;

import org.apache.log4j.Logger;

public enum SfCapabilityRank {
	Provisional("Provisional"),
	Auditor("Auditor"),
	LeadAuditor("Lead Auditor"),
	Inspector("Inspector"),
	VerifyingAuditor("Verifying Auditor"),
	LaboratoryAuditor("Laboratory Auditor"),
	ProjectManager("Project Manager"),
	TechnicalAdvisor("Technical Advisor"),
	Observer("Observer"),
	TechnicalReviewer("Technical Reviewer"),
	CertificationApprover("Certification Approver"),
	BusinessAdministrator("Business Administrator"),
	IndustryExpert("Industry Expert"),
	Unknown("Unknown");
	
	String name; 
	SfCapabilityRank(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static SfCapabilityRank getValueForName(String rankString) {
		try {
			return valueOf(rankString.replace(" ", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfCapabilityRank.getValueForName(" + rankString + ")", e);
		}
		return SfCapabilityRank.Unknown;
	}
}
