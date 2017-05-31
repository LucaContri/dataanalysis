package com.saiglobal.sf.reporting.processor;

public class PlanningDaysReportMSChart extends PlanningDaysReportChart {

	public PlanningDaysReportMSChart() {
		super();
		this.operationalOwnershipString = "'AUS - Management Systems'";
		this.revenueOwnershipString = "'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD','AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW'";
		this.historyBusinessUnits = "'Planning Days - MS - History'";
		this.chartYmax = 2000;
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {"..\\Charts\\Planning Day Report (MS)"};
	}
	
	@Override
	public String[] getFileReportNames() {
		return new String[] {"Planning Day Report - MS"};
	}
}
