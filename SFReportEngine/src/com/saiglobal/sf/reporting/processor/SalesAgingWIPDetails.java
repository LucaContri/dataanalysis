package com.saiglobal.sf.reporting.processor;

public class SalesAgingWIPDetails extends AbstractQueryReport {

	public SalesAgingWIPDetails() {
		this.columnWidth = new int[] {80,150,150,150,150,150,150,150,150,150};
	}
	
	@Override
	protected String getQuery() {
		return "(select * from enlighten_sales_qualify_lead_cert) UNION "
 + "(select * from enlighten_sales_qualify_lead_tis) UNION "
 + "(select * from enlighten_sales_lead_followup_cert) UNION "
 + "(select * from enlighten_sales_opp_followup_cert) UNION "
 + "(select * from enlighten_sales_proposal_sub_view) UNION "
 + "(select * from enlighten_sales_riskass_view) UNION "
 + "(select * from enlighten_sales_lead_followup_tis) UNION "
 + "(select * from enlighten_sales_opp_followup_tis)";
	}

	@Override
	protected String getReportName() {
		return "Sales\\EnlightenAgingWIP.Details";
	}
	
	@Override
	protected String getTitle() {
		return "Enlighten Aging WIP Details";
	}
}
