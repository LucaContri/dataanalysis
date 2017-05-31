package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenFinanceWIP extends AbstractQueryReport {

	public EnlightenFinanceWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_finance_wip";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_Finance_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
