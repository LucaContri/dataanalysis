package com.saiglobal.sf.reporting.processor;

public class SalesOverSLAWIPDetails extends AbstractQueryReport {

	public SalesOverSLAWIPDetails() {
		this.columnWidth = new int[] {80,150,150,150,150,150,150,150,150,150,100,150};
	}
	
	@Override
	protected String getQuery() {
		return "(select *, date_add(`From`, interval 1 day) as 'SLA Due Date', if(Aging > 1, 'true', 'false') as 'Over SLA' from enlighten_sales_qualify_lead_cert) UNION "
				+ "(select *, date_add(`From`, interval 1 day) as 'SLA Due Date', if(Aging > 1, 'true', 'false') as 'Over SLA' from enlighten_sales_qualify_lead_tis) UNION "
				+ "(select wip.*, t.ActivityDate as 'SLA Due Date', if(date_format(t.`ActivityDate`,'%Y-%m-%d') < date_format(now(),'%Y-%m-%d'), 'true', 'false') as 'Over SLA' from enlighten_sales_lead_followup_cert wip inner join salesforce.task t on wip.Id = t.Id) UNION "
				+ "(select wip.*, t.ActivityDate as 'SLA Due Date', if(date_format(t.`ActivityDate`,'%Y-%m-%d') < date_format(now(),'%Y-%m-%d'), 'true', 'false') as 'Over SLA' from enlighten_sales_opp_followup_cert wip inner join salesforce.task t on wip.Id = t.Id) UNION "
				+ "(select *, date_add(`From`, interval if(Details='Proposal & CR - Simple', 2,5) day) as 'SLA Due Date', if((Details='Proposal & CR - Simple' and Aging > 2) or (Details='Proposal & CR - Complex' and Aging > 5), 'true', 'false') as 'Over SLA' from enlighten_sales_proposal_sub_view ) UNION "
				+ "(select *, date_add(`From`, interval 1 day) as 'SLA Due Date', if(Aging > 1, 'true', 'false') as 'Over SLA' from enlighten_sales_riskass_view) UNION "
				+ "(select wip.*, t.ActivityDate as 'SLA Due Date', if(date_format(t.`ActivityDate`,'%Y-%m-%d') < date_format(now(),'%Y-%m-%d'), 'true', 'false') as 'Over SLA' from enlighten_sales_lead_followup_tis wip inner join training.task t on wip.Id = t.Id) UNION "
				+ "(select wip.*, t.ActivityDate as 'SLA Due Date', if(date_format(t.`ActivityDate`,'%Y-%m-%d') < date_format(now(),'%Y-%m-%d'), 'true', 'false') as 'Over SLA' from enlighten_sales_opp_followup_tis wip inner join training.task t on wip.Id = t.Id);";
	}

	@Override
	protected String getReportName() {
		return "Sales\\EnlightenSalesBacklog.Details";
	}
	
	@Override
	protected String getTitle() {
		return "Enlighten Sales Backlog Details";
	}
}
