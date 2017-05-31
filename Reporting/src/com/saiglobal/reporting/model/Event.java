package com.saiglobal.reporting.model;

import java.util.Calendar;

public class Event {
	public String eventId;
	public String wi;
	public String wiId;
	public String wiType;
	public String resource;
	public String resourceId;
	public String resourceType;
	public Calendar startDate;
	public Calendar endDate;
	public String type;
	public String subType;
	public String site;
	public String primaryStandard;
	public String notes;
	public double returnDistance;
	public double returnTravelTime;
	public String resourceLocation;
	public String siteLocation;
	public String timeZoneSidKey;
	
	public Event(String eventId, String wi, String wiId, String resource,
			String resourceId, Calendar startDate, Calendar endDate,
			String type, String subType, String site, String auditorLocation,
			double returnDistance, double returnTravelTime) {
		super();
		this.eventId = eventId;
		this.wi = wi;
		this.wiId = wiId;
		this.resource = resource;
		this.resourceId = resourceId;
		this.startDate = startDate;
		this.endDate = endDate;
		this.type = type;
		this.subType = subType;
		this.site = site;
		this.resourceLocation = auditorLocation;
		this.returnDistance = returnDistance;
		this.returnTravelTime = returnTravelTime;
	}
	public Event(String eventId, String wi, String wiId, String resource,
			String resourceId, String resourceType, Calendar startDate, Calendar endDate,
			String type, String subType, String site, String auditorLocation, String siteLocation,			
			double returnDistance, double returnTravelTime, String primaryStandard, String wiType, String notes, String timeZoneSidKey) {
		super();
		this.eventId = eventId;
		this.wi = wi;
		this.wiId = wiId;
		this.resource = resource;
		this.resourceId = resourceId;
		this.resourceType = resourceType;
		this.startDate = startDate;
		this.endDate = endDate;
		this.type = type;
		this.subType = subType;
		this.site = site;
		this.resourceLocation = auditorLocation;
		this.siteLocation = siteLocation;
		this.returnDistance = returnDistance;
		this.returnTravelTime = returnTravelTime;
		this.primaryStandard = primaryStandard;
		this.wiType = wiType;
		this.notes = notes;
		this.timeZoneSidKey = timeZoneSidKey;
	}
	
	
	
	
}