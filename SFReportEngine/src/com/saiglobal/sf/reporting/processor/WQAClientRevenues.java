package com.saiglobal.sf.reporting.processor;

public class WQAClientRevenues extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_WQA_Clients_Revenues";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\WQA_Clients_Revenues";
	}
	
	@Override
	protected String getTitle() {
		return "WQA Clients Revenues";
	}
}
