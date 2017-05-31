package com.saiglobal.sf.reporting.processor;

public class WQARevenues extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_WQA_Revenues";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\WQA_Revenues";
	}
	
	@Override
	protected String getTitle() {
		return "WQA Revenues";
	}
}
