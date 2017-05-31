package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenProductServicesActivities extends AbstractQueryReport {

	public EnlightenProductServicesActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_product_activity;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_ProductServices_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
