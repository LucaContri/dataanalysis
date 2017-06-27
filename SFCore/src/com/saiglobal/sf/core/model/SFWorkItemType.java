package com.saiglobal.sf.core.model;

import org.apache.log4j.Logger;

public enum SFWorkItemType {
	Assessment("Assessment"),
	Certification("Certification"),
	Compliance("Compliance"),
	Customised("Customised"),
	DocumentReview("Document Review"),
	FollowUp("Follow Up"),
	FollowUp2("Followup"),
	Gap("Gap"),
	InitialInspection("Initial Inspection"),
	InitialProject("Initial Project"),
	InitialVerification("Initial Verification"),
	Inspection("Inspection"),
	PreAssessment("Pre Assessment"),
	ProductEvaluation("Product Evaluation"),
	ProductUpdate("Product Update"),
	ReCertification("Re-Certification"),
	Special("Special"),
	Stage1("Stage 1"),
	Stage2("Stage 2"),
	StandardChange("Standard Change"),
	Surveillance("Surveillance"),
	Transfer("Transfer"),
	Transition("Transition"),
	Verification("Verification"),
	WitnessAudit("Witness Audit"),
	WitnessTesting("Witness Testing"),
	UnannouncedCertification("Unannounced Certification"),
	UnannouncedReCertification("Unannounced Re-Certification"),
	UnannouncedSpecial("Unannounced Special"),
	UnannouncedSurveillance("Unannounced Surveillance"),
	UnannouncedVerification("Unannounced Verification"),
	Unknown("Unknown");

	private String name;
	
	SFWorkItemType(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static SFWorkItemType getValueForName(String typeString) {
		try {
			return valueOf(typeString.replace(" ", "").replace("-", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SFWorkItemType.getValueForName(" + typeString + ")", e);
		}
		return SFWorkItemType.Unknown;
	}
}
