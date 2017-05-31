package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenWowActivities extends AbstractQueryReport {

	public EnlightenWowActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_prc_wow_activity;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_WOW_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
