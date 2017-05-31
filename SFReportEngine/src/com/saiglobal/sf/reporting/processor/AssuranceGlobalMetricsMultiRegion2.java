package com.saiglobal.sf.reporting.processor;

public class AssuranceGlobalMetricsMultiRegion2 extends AbstractMultiQueryReport {
	private AbstractQueryReport[] reports = null;
	
	public AssuranceGlobalMetricsMultiRegion2() {
		reports = new AbstractQueryReport[] {
				new AssuranceGlobalMetricsMultiRegion(),
				new ClientChurningWorkItemsMultiRegion()
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
