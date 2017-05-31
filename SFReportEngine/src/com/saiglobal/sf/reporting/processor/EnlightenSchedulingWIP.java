package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenSchedulingWIP extends AbstractQueryReport {

	public EnlightenSchedulingWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_scheduling_wip;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_Scheduling_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
