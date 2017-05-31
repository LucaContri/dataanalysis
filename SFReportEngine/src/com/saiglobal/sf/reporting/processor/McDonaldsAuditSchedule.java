package com.saiglobal.sf.reporting.processor;

public class McDonaldsAuditSchedule extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from mcdonalds_schedule";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\McDonald\\McDonalds Audit Schedule";
	}
	
	@Override
	protected String getTitle() {
		return "McDonalds Audit Schedule";
	}
}
