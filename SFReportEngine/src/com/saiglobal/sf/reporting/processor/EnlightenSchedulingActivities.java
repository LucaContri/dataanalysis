package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenSchedulingActivities extends AbstractQueryReport {

	public EnlightenSchedulingActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_scheduling_activity;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_Scheduling_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
