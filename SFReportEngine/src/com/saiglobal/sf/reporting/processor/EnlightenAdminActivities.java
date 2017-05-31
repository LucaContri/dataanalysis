package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenAdminActivities extends AbstractQueryReport {

	public EnlightenAdminActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from Enlighten_Admin_Completed";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_Admin_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
