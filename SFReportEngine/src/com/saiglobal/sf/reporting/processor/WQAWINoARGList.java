package com.saiglobal.sf.reporting.processor;

public class WQAWINoARGList extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_Submitted_Audits_With_No_ARG";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\WI_No_ARG_List";
	}
	
	@Override
	protected String getTitle() {
		return "Submitted Work Items with no ARG";
	}
}
