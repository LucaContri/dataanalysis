package com.saiglobal.reporting.model;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.model.SfSaigOffice;

public enum RegionFilterType {
	RevenueOwnership("Revenue Ownership"),
	SchedulingOwner("Scheduling Ownership"),
	ClientOwnership("Client Ownership"),
	AdministrationOwnership("Administration Ownership"),
	Unknown("Unknown");
	
	String name; 
	RegionFilterType(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static RegionFilterType getValueForName(String filterType) {
		try {
			return valueOf(filterType.replace(" ", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in RegionFilterType.getValueForName(" + filterType + ")", e);
		}
		return RegionFilterType.Unknown;
	}
}
