package com.saiglobal.sf.reporting.processor;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenPropertyOscarActivities extends AbstractQueryReport {
	private Calendar today = Calendar.getInstance();
	private Calendar yesterday = Calendar.getInstance();
	
	public EnlightenPropertyOscarActivities() {
		setHeader(false);
		append = true;
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("oscar");
	}
	
	@Override
	protected void initialiseQuery() {
		//today.set(2015, Calendar.MARCH, 10);
		yesterday.setTime(today.getTime());
		yesterday.add(Calendar.DAY_OF_MONTH, -1);
	}
	
	@Override
	protected String getQuery() {
		DateFormat sqlDateFormat = new SimpleDateFormat("MM/d/yyyy 00:00:00");
		DateFormat displayDateFormat = new SimpleDateFormat("dd/MM/yyyy 00:00:00");
		return "SELECT    "
			+"'Property' as Team,  "
			+"us.GivenName + ' ' + us.Surname as 'User', "
			+"CASE tt.DisplayName WHEN 'Proof Order' THEN 'Proof Order' "
			+"WHEN 'Proof For Customer' THEN 'Proof Customer' "
			+"WHEN 'Proof Customer Docs' THEN 'Proof Customer'   "
			+"WHEN 'Contact Authority' THEN 'Investigation - Error and failed'   "
			+"WHEN 'Investigate CC Transaction Problem' THEN 'Investigation - Error and failed'   "
			+"WHEN 'Fix Bundle Problem' THEN 'Investigation - Error and failed'  "
			+"WHEN 'Investigate Problem' THEN 'Investigation - Error and failed'  "
			+"WHEN 'Paused Certificate' THEN 'Release Certificate'  "
			+"WHEN 'Release Certificate' THEN 'Release Certificate'  "
			+"WHEN 'With Authority' THEN 'Release Certificate'  "
			+"WHEN 'With Client' THEN 'Release Certificate'  "
			+"WHEN 'In Progress' THEN 'Release Certificate'  "
			+"WHEN 'Verify Settlement Room Registration' THEN 'Client on boarding'   "
			+"WHEN 'Verify Registration' THEN 'Client on boarding'   "
			+"WHEN 'Verify Settlement Room & Search Manager Registration' THEN 'Client on boarding'  "
			+"WHEN 'Pay Account' THEN 'EFT'  "
			+"WHEN 'Order Certificate' THEN 'New SM Order Placement' "
			+"WHEN 'Certificates Reviewed' THEN 'Reviewing certificates'   "
			+"WHEN 'Uploaded bundle' THEN 'Manual Process order Search Manager' END as Activity,        "
			+"COUNT(t.TaskID) as Completed, "
			+"'" + displayDateFormat.format(yesterday.getTime()) + "' as 'Date/time' "
			+"FROM     "
			+"OscarUsers u with(nolock),   "
			+"Users us with(nolock),    "
			+"Tasks t with(nolock),   "
			+"TaskTypes tt with(nolock),       "
			+"AuditTrails at with(nolock) "
			+"WHERE      "
			+"U.UserID = at.UserID      "
			+"and t.TaskTypeID = tt.TaskTypeID          "
			+"and t.TaskID = at.EntityID              "
			+"and at.EntityTypeID = 8 "
			+"and (tt.DisplayName = 'Proof Order' OR "
			+"tt.DisplayName = 'Proof For Customer' OR "
			+"tt.DisplayName = 'Proof Customer Docs' OR "
			+"tt.DisplayName = 'Pay Account' OR "
			+"tt.DisplayName = 'Investigate Problem' OR "
			+"tt.DisplayName = 'Contact Authority' OR "
			+"tt.DisplayName = 'Investigate CC Transaction Problem' OR "
			+"tt.DisplayName = 'Fix Bundle Problem' OR "
			+"tt.DisplayName = 'Paused Certificate' OR "
			+"tt.DisplayName = 'Release Certificate' OR "
			+"tt.DisplayName = 'With Authority' OR "
			+"tt.DisplayName = 'With Client' OR "
			+"tt.DisplayName = 'In Progress' OR "
			+"tt.DisplayName = 'Order Certificate' OR "
			+"tt.DisplayName = 'Certificates Reviewed' OR "
			+"tt.DisplayName = 'Verify Settlement Room Registration' OR "
			+"tt.DisplayName = 'Verify Registration' OR "
			+"tt.DisplayName = 'Verify Settlement Room & Search Manager Registration' OR "
			+"tt.DisplayName = 'Uploaded bundle') "
			+"and at.EventTime between '" + sqlDateFormat.format(yesterday.getTime()) + "' and '" + sqlDateFormat.format(today.getTime()) + "'        "
			+"and at.UserID is not null      "
			+"and us.UserID = at.UserID  "
			+"and at.EventID = 2       "
			+"GROUP BY  "
			+"us.GivenName + ' ' + us.Surname, "
			+"CASE tt.DisplayName WHEN 'Proof Order' THEN 'Proof Order' "
			+"WHEN 'Proof For Customer' THEN 'Proof Customer' "
			+"WHEN 'Proof Customer Docs' THEN 'Proof Customer'   "
			+"WHEN 'Contact Authority' THEN 'Investigation - Error and failed'   "
			+"WHEN 'Investigate CC Transaction Problem' THEN 'Investigation - Error and failed'   "
			+"WHEN 'Fix Bundle Problem' THEN 'Investigation - Error and failed'  "
			+"WHEN 'Investigate Problem' THEN 'Investigation - Error and failed'  "
			+"WHEN 'Paused Certificate' THEN 'Release Certificate'  "
			+"WHEN 'Release Certificate' THEN 'Release Certificate'  "
			+"WHEN 'With Authority' THEN 'Release Certificate'  "
			+"WHEN 'With Client' THEN 'Release Certificate'  "
			+"WHEN 'In Progress' THEN 'Release Certificate'  "
			+"WHEN 'Verify Settlement Room Registration' THEN 'Client on boarding'   "
			+"WHEN 'Verify Registration' THEN 'Client on boarding'   "
			+"WHEN 'Verify Settlement Room & Search Manager Registration' THEN 'Client on boarding'  "
			+"WHEN 'Pay Account' THEN 'EFT'  "
			+"WHEN 'Order Certificate' THEN 'New SM Order Placement' "
			+"WHEN 'Certificates Reviewed' THEN 'Reviewing certificates'   "
			+"WHEN 'Uploaded bundle' THEN 'Manual Process order Search Manager' END       "
			+"UNION "
			+"SELECT "
			+"'Property' as Team,  "
			+"u.GivenName + ' ' + u.Surname as 'User',                   "
			+"'Manual Process order Search Manager' as Activity,          "
			+"COUNT(*) As Uploaded,    "
			+"'" + displayDateFormat.format(yesterday.getTime()) + "' as 'Date/time' "
			+"FROM      "
			+"AuditTrails at WITH(NOLOCK)          "
			+"JOIN CertificateOrderBundles cob WITH(NOLOCK) ON cob.BundleID = at.EntityID          "
			+"JOIN Users u WITH(NOLOCK) ON u.UserID = at.UserID   "
			+"WHERE         "
			+"at.AuditTrailEventTypeID = 2 "
			+"AND at.EventID = 1 "
			+"AND at.EventTime BETWEEN '" + sqlDateFormat.format(yesterday.getTime()) + "' and '" + sqlDateFormat.format(today.getTime()) + "' "
			+"GROUP BY    "
			+"u.GivenName + ' ' + u.Surname  "
			+"UNION "
			+"SELECT   "
			+"'Property' as Team,  "
			+"u.GivenName + ' ' + u.Surname as 'User',"
			+"'Reviewing Certificates' as Activity,"
			+"count(at.AuditTrailID) as Completed,"
			+"'" + displayDateFormat.format(yesterday.getTime()) + "' as 'Date/time'               "
			+"FROM      "
			+"Users u with(nolock), "
			+"AuditTrails at with(nolock) "
			+"WHERE    "
			+"u.UserID = at.UserID                       "
			+"and at.EntityTypeID = 14                      "
			+"and at.EventID = 77                      "
			+"and at.EventTime between '" + sqlDateFormat.format(yesterday.getTime()) + "' and '" + sqlDateFormat.format(today.getTime()) + "'               "
			+"GROUP BY         "
			+"u.GivenName + ' ' + u.Surname  "
			+"UNION      "
			+"SELECT      "
			+"'Property' as Team,  "
			+"u.GivenName + ' ' + u.Surname as 'User',             "
			+"'Proofing Certificates' as Activity,           "
			+"count(at.AuditTrailID) as Completed,      "
			+"'" + displayDateFormat.format(yesterday.getTime()) + "' as 'Date/time' "
			+"FROM "
			+"Users u with(nolock), "
			+"AuditTrails at with(nolock) "
			+"WHERE "
			+"u.UserID = at.UserID "
			+"and at.EntityTypeID = 14 "
			+"and at.EventID = 78 "
			+"and at.EventTime between '" + sqlDateFormat.format(yesterday.getTime()) + "' and '" + sqlDateFormat.format(today.getTime()) + "' "
			+"and at.UserID is not null "
			+"GROUP BY "
			+"u.GivenName + ' ' + u.Surname "
			+"ORDER BY 2 ";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Property\\Enlighten_Complete_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
