package com.saiglobal.sf.reporting.processor;

public class ChinaCNCAReport extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from china_cnca_report";
	}

	@Override
	protected String getReportName() {
		return "Asia\\China\\CNCA Report";
	}
	
	@Override
	protected String getTitle() {
		return "CNCA Report";
	}
}
