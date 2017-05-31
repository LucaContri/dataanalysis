package com.saiglobal.sf.reporting.processor;

public class WQAClientList extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_Client_List";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\WQA_Client_Sites_List";
	}
	
	@Override
	protected String getTitle() {
		return "WQA Client Sites List";
	}
}
