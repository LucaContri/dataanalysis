package com.saiglobal.sf.reporting.processor;

public class SalesAgingWIP extends AbstractQueryReport {

	public SalesAgingWIP() {
		this.columnWidth = new int[] {80,150,150,150,150,150,150,150,150,150};
	}
	
	@Override
	protected String getQuery() {
		return "select date_format(a.`From`, '%Y-%m') as 'Period', " +  
 "sum(if (a.`Details`='Qualify Lead - Cert',a.`unit time (min)`,0))/60 as 'Qualify Lead - Cert', " + 
 "sum(if (a.`Details`='Qualify Lead - TIS',a.`unit time (min)`,0))/60 as 'Qualify Lead - TIS', " + 
 "sum(if (a.`Details`='Lead Follow Up - Cert',a.`unit time (min)`,0))/60 as 'Lead Follow Up - Cert', " + 
 "sum(if (a.`Details`='Lead Follow Up - TIS',a.`unit time (min)`,0))/60 as 'Lead Follow Up - TIS', " + 
 "sum(if (a.`Details`='Opp Follow Up - Cert',a.`unit time (min)`,0))/60 as 'Opp Follow Up - Cert', " + 
 "sum(if (a.`Details`='Opp Follow Up - TIS',a.`unit time (min)`,0))/60 as 'Opp Follow Up - TIS', " + 
 "sum(if (a.`Details`='Proposal & CR - Complex',a.`unit time (min)`,0))/60 as 'Proposal & CR - Complex', " + 
 "sum(if (a.`Details`='Proposal & CR - Simple',a.`unit time (min)`,0))/60 as 'Proposal & CR - Simple', " + 
 "sum(if (a.`Details`='Risk Assessment',a.`unit time (min)`,0))/60 as 'Risk Assessment' from ( "
 + "(select * from enlighten_sales_qualify_lead_cert) UNION "
 + "(select * from enlighten_sales_qualify_lead_tis) UNION "
 + "(select * from enlighten_sales_lead_followup_cert) UNION "
 + "(select * from enlighten_sales_opp_followup_cert) UNION "
 + "(select * from enlighten_sales_proposal_sub_view) UNION "
 + "(select * from enlighten_sales_riskass_view) UNION "
 + "(select * from enlighten_sales_lead_followup_tis) UNION "
 + "(select * from enlighten_sales_opp_followup_tis) ) a " + 
 "group by `Period` " + 
 "order by `Period` desc ";
	}

	@Override
	protected String getReportName() {
		return "Sales\\EnlightenAgingWIP";
	}
	
	@Override
	protected String getTitle() {
		return "Enlighten Aging WIP (Hrs)";
	}
}
