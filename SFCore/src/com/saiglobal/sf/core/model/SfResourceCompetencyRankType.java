package com.saiglobal.sf.core.model;

public enum SfResourceCompetencyRankType {
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
	IndustryExpert("Industry Expert");

	String name; 
	SfResourceCompetencyRankType(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static SfResourceCompetencyRankType getValueForName(String rankString) {
		return valueOf(rankString.replace(" ", ""));
	}
}
