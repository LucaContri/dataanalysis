package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;

import javax.xml.bind.annotation.XmlTransient;

import com.saiglobal.sf.core.utility.Utility;

public class ResourceCalendar {
	@XmlTransient
	private Calendar startDate;
	@XmlTransient
	private Calendar endEdate;
	private List<ResourceEvent> events;
	private HashMap<String, Integer> periodWorkingDays;
	private HashMap<String, byte[]> periodWorkingSlots;
	private Resource resource;

	public ResourceCalendar(Resource resource, Calendar startDate, Calendar endDate) {
		this.startDate = startDate;
		this.endEdate = endDate;
		events = new ArrayList<ResourceEvent>();
		this.resource = resource;
	}
	
	public ResourceCalendar(Resource resource, Date startDate, Date endDate) {
		if (startDate == null)
			startDate = Utility.getUtcNow();
		if (endDate == null)
			endDate = Utility.getUtcNow();
		
		this.startDate = new GregorianCalendar();
		this.endEdate = new GregorianCalendar();
		this.startDate.setTime(startDate);
		this.endEdate.setTime(endDate);
		events = new ArrayList<ResourceEvent>();
		this.resource = resource;
	}
	
	public boolean isAvailableFor(ResourceEvent eventToCheck) {
		for (ResourceEvent anEvent : events) {
			if (anEvent.overlap(eventToCheck)) {
				return false;
			}
		}
		return true;
	}
	
	public boolean isAvailableOn(Calendar day) {
		for (ResourceEvent anEvent : events) {
			if (anEvent.overlap(day)) {
				return false;
			}
		}
		return true;
	}
	
	public double hasAvailabilityFor(WorkItem wi) {
		String period = Utility.getPeriodformatter().format(wi.getStartDate());
		if (!periodWorkingDays.containsKey(period))
			return -1;
		//for (ResourceEvent re : this.events) {
		//	System.out.println(re.getName() + ", " + re.getPeriod() + ", " + re.getType());
		//	if (re.getPeriod().equalsIgnoreCase(period) && re.getType().toString().equalsIgnoreCase("SF_BOP")) {
		//		System.out.print("Found!");
		//	}
		//}
		//int requiredSlots = (int) Math.ceil(wi.getRequiredDuration()/4.0);
		double auditAndTravelDays = (double) (Math.ceil(wi.getRequiredDuration()/8.0 * 2) / 2) + Utility.calculateTravelReturnTimeHrs(wi.getClientSite().getLatitude(), wi.getClientSite().getLongitude(), this.resource.getHome().getLatitude(), this.resource.getHome().getLongitude())/8;
		double bopDays = (double) (Math.ceil(this.events.stream().filter(e -> e.getPeriod().equalsIgnoreCase(period) && e.getType().equals(ResourceEventType.SF_BOP)).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
		double auditDays = (double) (Math.ceil(this.events.stream().filter(e -> e.getPeriod().equalsIgnoreCase(period) && (e.getType().equals(ResourceEventType.ALLOCATOR_WIR)||e.getType().equals(ResourceEventType.SF_WIR)||e.getType().equals(ResourceEventType.ALLOCATOR_TRAVEL))).mapToDouble(ResourceEvent::getDurationWorkingDays).sum() * 2) / 2);
		return ((periodWorkingDays.get(period) - bopDays)*this.resource.getCapacity()/100 - auditDays - auditAndTravelDays);
		
		//int freeSlots = 0;
		//Date retDate = null;
		//for (int i=0; i<periodWorkingSlots.get(Utility.getPeriodformatter().format(wi.getStartDate())).length; i++) {
		//	if(periodWorkingSlots.get(Utility.getPeriodformatter().format(wi.getStartDate()))[i]==0) {
		//		freeSlots++;
		//		if (freeSlots==1) {
		//			retDate = new Date(wi.getStartDate().getYear(), wi.getStartDate().getMonth(), 1+i,i%2>0?9:13,0,0);
		//		}
		//	} else {
		//		freeSlots = 0;
		//	}
		//	if (freeSlots>=requiredSlots)
		//		return retDate;
		//}
		//return null;
	}
	
	public void bookFor(ResourceEvent eventToBook, boolean checkAvailability) throws ResourceCalenderException {
		if (checkAvailability && !isAvailableFor(eventToBook)) {
			throw new ResourceCalenderException();
		}
		events.add(eventToBook);
		/*
		int requiredSlots = (int) Math.ceil(eventToBook.getDurationHours()/4);
		for (int i=0; i<requiredSlots; i++) {
			Date startDate = new Date(eventToBook.getStartDateTime().getTime()+(i%2)*24*60*60*1000+(i%2>0?0:4*60*60*1000));
			Date endDate = new Date(startDate.getTime()+4*60*60*1000);
			ResourceEvent event = new ResourceEvent();
			event.setType(eventToBook.getType());
			event.setStartDateTime(startDate);
			event.setEndDateTime(endDate);
			events.add(event);
		}
		*/
	}
	
	public void bookFor(ResourceEvent eventToBook) throws ResourceCalenderException {
		this.bookFor(eventToBook, false);
	}

	public HashMap<String, Integer> getPeriodWorkingDays() {
		return periodWorkingDays;
	}

	public void setPeriodWorkingDays(HashMap<String, Integer> periodWorkingDays) {
		this.periodWorkingDays = periodWorkingDays;
	}
	
	public Calendar getStartDate() {
		return startDate;
	}

	public void setStartDate(Calendar startDate) {
		this.startDate = startDate;
	}

	public Calendar getEndEdate() {
		return endEdate;
	}

	public void setEndEdate(Calendar endEdate) {
		this.endEdate = endEdate;
	}
	
	public List<ResourceEvent> getEvents() {
		return events;
	}

	public void setEvents(List<ResourceEvent> events) {
		this.events = events;
	}

	public HashMap<String, byte[]> getPeriodWorkingSlots() {
		return periodWorkingSlots;
	}

	public void setPeriodWorkingSlots(HashMap<String, byte[]> periodWorkingSlots) {
		this.periodWorkingSlots = periodWorkingSlots;
	}
}
