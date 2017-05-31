package com.saiglobal.sf.reporting.processor;

public class SalesBacklogSummaryAndDetails extends AbstractMultiQueryReport {
	private AbstractQueryReport[] reports = null;
	
	public SalesBacklogSummaryAndDetails() {
		reports = new AbstractQueryReport[] {
				new SalesOverSLAWIP(),
				new SalesOverSLAWIPDetails()
		};
	}
	
	@Override
	public boolean append() {
		return false;
	}

	@Override
	protected AbstractQueryReport[] getReports() {
		return reports;
	}

}
