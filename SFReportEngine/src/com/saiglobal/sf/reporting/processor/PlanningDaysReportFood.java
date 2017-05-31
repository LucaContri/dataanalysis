package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class PlanningDaysReportFood extends PlanningDaysReport {

	public PlanningDaysReportFood() {
		super();
		this.operationalOwnershipString = "'AUS - Food'";
		this.revenueOwnershipString = "'AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW'";
		this.historyBusinessUnits = "'Planning Days - Food - History'";
		this.chartYmax = 350;
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {"Audit Days Overview\\" + Utility.getPeriodformatter().format(reportDate.getTime()) + "\\Planning Days Report - Food"};
	}
	
	@Override
	public String[] getFileReportNames() {
		return new String[] {"Planning Days Report - Food"};
	}
}
