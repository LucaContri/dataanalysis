package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenSalesWIP extends AbstractQueryReport {

	public EnlightenSalesWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select t.Team, '' as 'User', t.WIP as 'Activity', sum(t.Value) as 'WIP', now() as 'Date/Time' from enlighten_sales_wip t group by t.WIP";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_Sales_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
