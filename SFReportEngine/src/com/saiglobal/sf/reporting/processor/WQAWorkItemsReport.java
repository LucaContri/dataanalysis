package com.saiglobal.sf.reporting.processor;

public class WQAWorkItemsReport extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Woolworths_Audits_Next_Six_Months";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Woolworths\\WQA_Audits_Next_Six_Months";
	}
	
	@Override
	protected String getTitle() {
		return "WQA Audits Next Six Months";
	}
}
