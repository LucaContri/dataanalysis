package com.saiglobal.reporting.model;

public enum ErrorType {
	REQUEST_NOT_DEFINED("Request not defined", "Request not defined"),
	REQUEST_NOT_IMPLEMENTED("Request not implemented", "Request not implemented"),
	FUNCTION_NOT_IMPLEMENTED("Function not implemented", "Function not implemented"),
	FUNCTION_NOT_DEFINED("Function not defined", "Function not defined"),
	MISSING_PARAMETER_METRIC_QUERY("Missing String parameter queryMetrics", "Missing String parameter queryMetrics"),
	MISSING_PARAMETER_METRIC_GROUP("Missing String parameter metricGroup", "Missing String parameter metricGroup"),
	MISSING_PARAMETER_PRODUCT("Missing String parameter product", "Missing String parameter product"),
	MISSING_PARAMETER_PERIOD_TO("Missing String parameter toDate", "Missing String parameter toDate"),
	MISSING_PARAMETER_PERIOD_FROM("Missing String parameter fromDate", "Missing String parameter fromDate"),
	MISSING_PARAMETER_REGION("Missing String parameter region", "Missing String parameter region"),
	MISSING_PARAMETER_METRICSIDS("Missing String parameter metricsIds", "Missing String parameter metricsIds");
	
	private String name, description;
	private ErrorType(String name, String description) {
		this.name = name;
		this.description = description;
	}
	
	public String getName() {
		return name;
	}
	
	public String getDescription() {
		return description;
	}
	
	public String toJson() {
		return "{\"error\": {\"name\": \"" + name +"\", \"description\": \"" + description +"\"}}";  
	}
}
