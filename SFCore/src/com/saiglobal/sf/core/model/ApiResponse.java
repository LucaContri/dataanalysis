package com.saiglobal.sf.core.model;

import java.util.List;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name="ApiResponse")
public class ApiResponse {
	@XmlElement(name="Client")
	public List<Client> client;
	
	@XmlElement(name="Error")
	public String errorMessage;
	
	@XmlElement(name="SearchResult")
	public List<WorkItem> workItems;
	
	@XmlElement(name="Allocation")
	public Allocation allocation;
	
	@XmlElement(name="NextPeriodUrl")
	public String nextPeriodUrl;
	
	@XmlElement(name="PreviousPeriodUrl")
	public String previousPeriodUrl;
}
