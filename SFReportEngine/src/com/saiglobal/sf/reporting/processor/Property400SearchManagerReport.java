package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class Property400SearchManagerReport extends AbstractQueryReport {
	
	private Calendar today = Calendar.getInstance();
	private Calendar yesterday = Calendar.getInstance();
	
	public Property400SearchManagerReport() {
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
				" (u.GivenName + ' ' + u.surname)as 'Name', " +
				" tt.DisplayName as TaskType, " +
				" count(t.TaskID) as Number " +
				" FROM " +
				" OscarUsers u with(nolock), " +
				" Tasks t with(nolock), " +
				" TaskTypes tt with(nolock), " +
				" AuditTrails at with(nolock) " +
				" WHERE" +
				" U.UserID = at.UserID" +
				" and t.TaskTypeID = tt.TaskTypeID" +
				" and t.TaskID = at.EntityID" +
				" and at.EntityTypeID = 8" +
				" and at.EventTime between '" + dateFormat.format(yesterday.getTime()) + "' and '" + dateFormat.format(today.getTime()) + "' " +
				" and at.UserID is not null" +
				" and at.EventID = 2" +
				" GROUP BY u.givenname, u.surname, tt.DisplayName " +
				" UNION " +
				" SELECT " +
				" (u.GivenName + ' ' + u.surname)as 'Name', " +
				" 'Manual Task Completed', " +
				" COUNT(*) As Number " +
				" FROM " +
				" AuditTrails at WITH(NOLOCK)" +
				" JOIN Tasks t WITH(NOLOCK) ON t.TaskID = at.EntityID AND t.TaskTypeID in (23,24,25,26)" +
				" AND t.EntityTypeID =1" +
				" JOIN (SELECT DISTINCT " +
				" O.OrderID " +
				" FROM Orders o WITH(NOLOCK)" +
				" JOIN CertificateOrders co WITH(NOLOCK) ON co.OrderID = o.OrderID " +
				" JOIN AuthorityCertificateTypes act WITH(NOLOCK) ON co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID" +
				" AND act.TransmissionHandlerID = 33) O ON o.OrderID = t.EntityID " +
				" JOIN Users u WITH(NOLOCK) ON u.UserID = at.UserID" +
				" WHERE at.AuditTrailEventTypeID = 1" +
				" AND at.EventID = 2" +
				" AND U.UserID IS NOT NULL " +
				" AND at.EventTime BETWEEN '" + dateFormat.format(yesterday.getTime()) + "' and '" + dateFormat.format(today.getTime()) + "' " +
				" and at.EventID = 2 " +
				" GROUP BY " +
				" u.givenname, " +
				" u.surname" +
				" UNION " +
				" SELECT" +
				" (u.GivenName + ' ' + u.surname)as 'Name', " +
				" 'Uploaded Bundle', " +
				" COUNT(*) As Uploaded " +
				" FROM AuditTrails at WITH(NOLOCK) " +
				" JOIN CertificateOrderBundles cob WITH(NOLOCK) ON cob.BundleID = at.EntityID " +
				" JOIN Users u WITH(NOLOCK) ON u.UserID = at.UserID " +
				" WHERE at.AuditTrailEventTypeID = 2" +
				" AND at.EventID = 1" +
				" AND at.EventTime BETWEEN '" + dateFormat.format(yesterday.getTime()) + "' and dateadd(d, 1, '" + dateFormat.format(today.getTime()) + "') " +
				" GROUP BY " +
				" u.givenname, " +
				" u.surname" +
				" UNION " +
				" SELECT " +
				" (u.GivenName + ' ' + u.surname)as 'Name', " +
				" 'Associated Bundle', " +
				" count(at.entityid) as Total " +
				" FROM " +
				" AuditTrails at with(nolock), Users u with(nolock) " +
				" WHERE " +
				" at.eventid = 43" +
				" and at.userid is not null " +
				" and u.userid = at.userid " +
				" and at.EventTime >= '" + dateFormat.format(yesterday.getTime()) + "'" +
				" and at.EventTime < dateadd(d, 1, '" + dateFormat.format(today.getTime()) + "')" +
				" GROUP BY" +
				" u.givenname, " +
				" u.surname";
		
		return select;
	}

	@Override
	protected void finaliseQuery() throws Exception {
	}
	
	@Override
	protected String getReportName() {
		return "400 Search Manager";
	}
	
}
