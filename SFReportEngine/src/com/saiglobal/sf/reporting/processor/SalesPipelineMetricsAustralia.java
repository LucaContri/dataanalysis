package com.saiglobal.sf.reporting.processor;

public class SalesPipelineMetricsAustralia extends AbstractQueryReport {

	public SalesPipelineMetricsAustralia() {
		setHeader(false);
	}
	
	@Override
	protected void finaliseQuery() throws Throwable {
		
	}

	@Override
	protected void initialiseQuery() throws Throwable {
		
	}
	
	@Override
	protected String getQuery() {
		return "(select Region,Stream,SubStream,Source,Metric,date_format(`Date (UTC)`, '%Y-%m') as 'Period', sum(Days) as 'Days', sum(Amount) as 'Amount', sum(Count) as 'Count'"
				+ "from sales_pipeline_metrics "
				+ "where `Date (UTC)` >= '2014-07-01' "
				+ "and Region like 'Australia' "
				+ "group by Region,Stream,SubStream,Source,Metric, `Period`)";
	}

	@Override
	protected String getReportName() {
		return "Sales\\SalesPipelineMetrics";
	}
	
	@Override
	protected String getTitle() {
		return "Sales Pipeline Metrics";
	}
}
