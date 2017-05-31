package com.saiglobal.sf.reporting.processor;


public class PlanningDaysReportFoodChart extends PlanningDaysReportChart {

	public PlanningDaysReportFoodChart() {
		super();
		this.operationalOwnershipString = "'AUS - Food'";
		this.revenueOwnershipString = "'AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW'";
		this.historyBusinessUnits = "'Planning Days - Food - History'";
		this.chartYmax = 350;
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {"..\\Charts\\Planning Day Report (Food)"};
	}
	
	@Override
	public String[] getFileReportNames() {
		return new String[] {"Planning Day Report - Food"};
	}
}
