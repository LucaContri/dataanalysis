package com.saiglobal.reporting.model;

public enum MetricFunctionType {
	OPERATIONS("Operations"),
	FINANCE("Finance"),
	COMMERCIAL("Commercial"),
	HR("HR"),
	EPMO("EPMO"),
	TECHNOLOGY("Technology"),
	NOT_DEFINED("Not Defined");
	
	private String name;
	private MetricFunctionType(String name) {
		this.name = name;
	}
	public String getName() {
		return name;
	}
}
