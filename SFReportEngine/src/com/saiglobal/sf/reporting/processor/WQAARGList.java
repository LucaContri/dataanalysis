package com.saiglobal.sf.reporting.processor;

public class WQAARGList extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_ARG_List";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\ARG_List";
	}
	
	@Override
	protected String getTitle() {
		return "WQA ARG List";
	}
}
