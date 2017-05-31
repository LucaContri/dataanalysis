package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenWowWIP extends AbstractQueryReport {

	public EnlightenWowWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_prc_wow_wip";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_WOW_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
