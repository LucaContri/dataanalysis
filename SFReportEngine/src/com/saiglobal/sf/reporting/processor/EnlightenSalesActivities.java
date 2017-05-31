package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenSalesActivities extends AbstractQueryReport {

	public EnlightenSalesActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select 'Sales' as 'Team', t.User, t.Activity, t.`Count` as 'Completed', date_format(now(), '%d/%m/%Y') as 'Date/Time', t.`Notes` from enlighten_sales_activity t;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_Sales_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
