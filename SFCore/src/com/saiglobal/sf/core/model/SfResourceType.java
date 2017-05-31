package com.saiglobal.sf.core.model;

import org.apache.log4j.Logger;

public enum SfResourceType {
	ClientServices("Client Services"),
	Contractor("Contractor"),
	Employee("Employee"),
	ExternalRegulator("External Regulator"),
	Unknown("Unknown");
	
	String name; 
	SfResourceType(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static SfResourceType getValueForName(String typeString) {
		try {
			return valueOf(typeString.replace(" ", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfResourceType.getValueForName(" + typeString + ")", e);
		}
		return SfResourceType.Unknown;
	}
}
