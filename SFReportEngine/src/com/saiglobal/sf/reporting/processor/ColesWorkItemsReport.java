package com.saiglobal.sf.reporting.processor;

public class ColesWorkItemsReport extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from Coles_Audits_Next_Six_Months";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Coles\\Coles_Audits_Next_Six_Months";
	}
	
	@Override
	protected String getTitle() {
		return "Coles Audits Next Six Months";
	}
}
