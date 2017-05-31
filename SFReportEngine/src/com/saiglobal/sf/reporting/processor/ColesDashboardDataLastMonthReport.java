package com.saiglobal.sf.reporting.processor;

public class ColesDashboardDataLastMonthReport extends AbstractQueryReport {

	@Override
	protected String getQuery() {
		return "select * from coles_dashboard_data_last_month";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Coles\\Coles_DAshboard_Data_Last_Month";
	}
	
	@Override
	protected String getTitle() {
		return "Coles Dashboard Data Last Month";
	}
}
