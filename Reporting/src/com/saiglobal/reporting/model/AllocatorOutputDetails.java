package com.saiglobal.reporting.model;

import java.util.Calendar;
import java.util.List;

public class AllocatorOutputDetails {

	public String name;
	public List<Event> events;
	public List<SimpleParameter> resources;
	public Calendar lastUpdated;
	public Calendar created;
	public Calendar nextUpdate;
	public Calendar startDate;
	public Calendar endDate;
	public int page;
	public boolean more;
	
	public AllocatorOutputDetails(String name) {
		this.name = name;
	}
	
}
