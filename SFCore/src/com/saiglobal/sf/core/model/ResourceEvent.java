package com.saiglobal.sf.core.model;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

import javax.xml.bind.annotation.XmlTransient;

import com.saiglobal.sf.core.utility.Utility;

public class ResourceEvent extends GenericSfObject {
	@XmlTransient
	public Date startDateTime;
	@XmlTransient
	public Date endDateTime;
	@XmlTransient
	public ResourceEventType type;
	@XmlTransient
	public String refId;
	@XmlTransient
	public String description;
	
	public ResourceEvent() {
		super();
	}
	
	public ResourceEvent(String id, String name, Date lastModified) throws SQLException {
		super(id, name, lastModified); 
	}
	
	public ResourceEvent(ResultSet rs) throws SQLException {
		super(rs);
	}
	
	public double getDurationDays() {
		return (endDateTime.getTime() - startDateTime.getTime())/(1000*60*60*24);
	}
	
	public double getDurationWorkingDays() {
		return (endDateTime.getTime() - startDateTime.getTime())/(1000.0*60.0*60.0*8.0);
	}
	
	public double getDurationHours() {
		return (endDateTime.getTime() - startDateTime.getTime())/(1000*60*60);
	}
	
	public long getDurationMillisecods() {
		return (endDateTime.getTime() - startDateTime.getTime());
	}

	public Date getStartDateTime() {
		return startDateTime;
	}
	public void setStartDateTime(Date startDateTime) {
		this.startDateTime = startDateTime;
	}
	public String getPeriod() {
		return startDateTime==null?null:Utility.getPeriodformatter().format(startDateTime);
	}
	public String getDate() {
		return startDateTime==null?null:Utility.getActivitydateformatter().format(startDateTime);
	}
	public Calendar getCalendarDate() {
		if (startDateTime==null)
			return null;
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDateTime);
		return aux;
	}
	public Date getEndDateTime() {
		return endDateTime;
	}
	public void setEndDateTime(Date endDateTime) {
		this.endDateTime = endDateTime;
	}
	public ResourceEventType getType() {
		return type;
	}
	public void setType(ResourceEventType type) {
		this.type = type;
	}
	public void setDescription(String description) {
		this.description = description;
	}
	
	public boolean overlap(ResourceEvent anEvent) {
		return ((anEvent.startDateTime.after(this.startDateTime) && anEvent.startDateTime.before(this.endDateTime)) || 
				(anEvent.endDateTime.after(this.startDateTime) && anEvent.endDateTime.before(this.startDateTime)));
	}
	
	public boolean overlap(Calendar day) {
		day.set(Calendar.HOUR, 0);
		day.set(Calendar.MINUTE, 0);
		day.set(Calendar.SECOND, 0);
		Calendar dayEnd = new GregorianCalendar();
		dayEnd.setTime(day.getTime());
		dayEnd.set(Calendar.HOUR, 23);
		dayEnd.set(Calendar.MINUTE, 59);
		dayEnd.set(Calendar.SECOND, 59);
		
		if (this.startDateTime.after(day.getTime()) && this.startDateTime.before(dayEnd.getTime()))
			return true;
		
		if (this.endDateTime.after(day.getTime()) && this.endDateTime.before(dayEnd.getTime()))
			return true;
		
		return false;
	}

	public String getRefId() {
		return refId;
	}

	public void setRefId(String refId) {
		this.refId = refId;
	}

	public String getDescription() {
		return description;
	}
}
