package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class Property600SearchManagerReport extends AbstractQueryReport {
	
	private Calendar today = Calendar.getInstance();
	private Calendar yesterday = Calendar.getInstance();
	
	public Property600SearchManagerReport() {
		setExecuteStatement(false);
		setHeader(true);
		dateTimePattern = "d/MM/yyyy";
		columnWidth = new int[] {200,200,100};
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("oscar");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
		yesterday.setTime(today.getTime());
		yesterday.add(Calendar.DAY_OF_MONTH, -1);
	}
	
	@Override
	protected String getQuery() {
		SimpleDateFormat dateFormat = new SimpleDateFormat("MM/d/yyyy");
		
		String select = 
				"SELECT " +
				" u.GivenName + ' ' + u.Surname + ' (' + u.Username + ')' as Name, " +
				" 'Certificates Reviewed' as 'TaskType', " +
				" count(at.AuditTrailID) as Number " +
				" FROM " +
				" Users u with(nolock), " +
				" AuditTrails at with(nolock) " +
				" WHERE " +
				" u.UserID = at.UserID  " +
				" and at.EntityTypeID = 14 " +
				" and at.EventID = 77 " +
				" and at.EventTime between '" + dateFormat.format(yesterday.getTime()) + "' and '" + dateFormat.format(today.getTime()) + "' " +
				" GROUP BY " +
				" at.UserID, " +
				" u.GivenName, " +
				" u.Surname, " +
				" u.Username " +
				" UNION  " +
				" SELECT " +
				" u.GivenName + ' ' + u.Surname + ' (' + u.Username + ')' as Name, " +
				" 'Certificates Proofed' as 'TaskType', " +
				" count(at.AuditTrailID) as Number " +
				" FROM " +
				" Users u with(nolock), " +
				" AuditTrails at with(nolock) " +
				" WHERE " +
				" u.UserID = at.UserID " +
				" and at.EntityTypeID = 14 " +
				" and at.EventID = 78  " +
				" and at.EventTime between '" + dateFormat.format(yesterday.getTime()) + "' and '" + dateFormat.format(today.getTime()) + "'  " +
				" and at.UserID is not null " +
				" GROUP BY " +
				" at.UserID, " +
				" u.GivenName, " +
				" u.Surname, " +
				" u.Username " +
				" ORDER BY 1";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "600 Search Manager";
	}
	
}
