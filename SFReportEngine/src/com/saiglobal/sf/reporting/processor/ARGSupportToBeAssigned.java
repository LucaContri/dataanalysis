package com.saiglobal.sf.reporting.processor;

public class ARGSupportToBeAssigned extends AbstractQueryReport {

	public ARGSupportToBeAssigned() {
		this.columnWidth = new int[] {150};
	}
	
	@Override
	protected String getQuery() {
		return "select * from ARG_Support_To_Be_Assigned";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Admin\\ARG_Support_To_Be_Assigned";
	}
	
	@Override
	protected String getTitle() {
		return "ARG Support To Be Assigned";
	}
}
