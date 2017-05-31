package com.saiglobal.reporting.model;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class ProcessDetails {

	public String name;
	public ProcessEndpoint[] edges;
	public List<ProcessQueue> queues;
	public List<ProcessPerformances> performances;
	public Calendar lastUpdated;
	
	public ProcessDetails(String name) {
		this.name = name;
		this.queues = new ArrayList<ProcessQueue>();
		this.performances= new ArrayList<ProcessPerformances>();
	}
}
