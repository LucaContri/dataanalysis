package com.saiglobal.sf.reporting.processor;

public class AssuranceGlobalMetrics2 extends AbstractMultiQueryReport {
	private AbstractQueryReport[] reports = null;
	
	public AssuranceGlobalMetrics2() {
		reports = new AbstractQueryReport[] {
				new AssuranceGlobalMetrics(),
				new ClientChurningWorkItems()
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
