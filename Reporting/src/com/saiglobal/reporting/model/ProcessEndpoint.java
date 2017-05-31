package com.saiglobal.reporting.model;

public class ProcessEndpoint {
	public String name;
	public ProcessEndpointDirection direction;
	
	public ProcessEndpoint(String name, ProcessEndpointDirection direction) {
		this.name = name;
		this.direction = direction;
	}
}
