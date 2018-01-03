package com.saiglobal.sf.core.model;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import com.saiglobal.sf.core.utility.Utility;

public class BlackoutPeriod extends GenericSfObject {
	
	public Calendar fromDate, toDate;

	
	public BlackoutPeriod(Calendar fromDate, Calendar toDate) {
		super();
		this.fromDate = fromDate;
		this.toDate = toDate;
	}

	public BlackoutPeriod(Date fromDate, Date toDate) {
		super();
		Calendar fromC = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
		Calendar toC = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
		fromC.setTime(fromDate);
		toC.setTime(toDate);
		this.fromDate = fromC;
		this.toDate = toC;
	}
	
	public BlackoutPeriod(String fromDate, String toDate) throws ParseException {
		this(Utility.getMysqlutcdateformat().parse(fromDate), Utility.getMysqlutcdateformat().parse(toDate));
	}
	
	public boolean contains(Calendar date) {
		return date.after(fromDate) && date.before(toDate);
	}
	public Calendar getFromDate() {
		return fromDate;
	}

	public void setFromDate(Calendar fromDate) {
		this.fromDate = fromDate;
	}

	public Calendar getToDate() {
		return toDate;
	}

	public void setToDate(Calendar toDate) {
		this.toDate = toDate;
	}
	
}
