package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenProductServicesWIP extends AbstractQueryReport {

	public EnlightenProductServicesWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_product_backlog";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_ProductServices_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
