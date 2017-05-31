package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenFinanceActivities extends AbstractQueryReport {

	public EnlightenFinanceActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_finance_activity;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_Finance_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
