package com.saiglobal.sf.reporting.processor;

public class SalesOverSLAWIP extends AbstractQueryReport {

	public SalesOverSLAWIP() {
		this.columnWidth = new int[] {150,150,150,150,150,150,150,150,150,150};
	}
	
	@Override
	protected String getQuery() {
		return "select Owner,  "
			+"count(distinct if (t.`Details`='Qualify Lead - Cert' or t.`Details`='Qualify Lead - TIS', t.`Id`, null)) as 'Qualify Lead', "
			+"count(distinct if ((t.`Details`='Qualify Lead - Cert' or t.`Details`='Qualify Lead - TIS') and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Qualify Lead - Over SLA', "
			+"count(distinct if (t.`Details`='Lead Follow Up - TIS' or t.`Details`='Lead Follow Up - Cert', t.`Id`, null)) as 'Lead Follow Up', "
			+"count(distinct if ((t.`Details`='Lead Follow Up - TIS' or t.`Details`='Lead Follow Up - Cert') and t.`SLA Due Date` < date_format(now(),'%Y-%m-%d'), t.`Id`, null)) as 'Lead Follow Up - Over SLA', "
			+"count(distinct if (t.`Details`='Opp Follow Up - Cert' or t.`Details`='Opp Follow Up - TIS', t.`Id`, null)) as 'Opp Follow Up', "
			+"count(distinct if ((t.`Details`='Opp Follow Up - Cert' or t.`Details`='Opp Follow Up - TIS') and t.`SLA Due Date` < date_format(now(),'%Y-%m-%d'), t.`Id`, null)) as 'Opp Follow Up - Over SLA', "
			+"count(distinct if (t.`Details`='Proposal & CR - Simple', t.`Id`, null)) as 'Proposal & CR - Simple', "
			+"count(distinct if (t.`Details`='Proposal & CR - Complex', t.`Id`, null)) as 'Proposal & CR - Complex', "
			+"count(distinct if (t.`Details`='Proposal & CR - Simple' and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Proposal & CR Simple - Over SLA', "
			+"count(distinct if (t.`Details`='Proposal & CR - Complex' and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Proposal & CR Complex - Over SLA', "
			+"count(distinct if (t.`Details`='Risk Assessment', t.`Id`, null)) as 'Risk Assessment', "
			+"count(distinct if (t.`Details`='Risk Assessment' and t.`SLA Due Date` < utc_timestamp(), t.`Id`, null)) as 'Risk Assessment' "
			+"from ( "
			+"(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_qualify_lead_cert) UNION  "
			+"(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_qualify_lead_tis) UNION  "
			+"(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_lead_followup_cert wip inner join salesforce.task t on wip.Id = t.Id ) UNION  "
			+"(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_opp_followup_cert wip inner join salesforce.task t on wip.Id = t.Id ) UNION  "
			+"(select *, date_add(`From`, interval if(Details='Proposal & CR - Simple', 2,5) day) as 'SLA Due Date' from enlighten_sales_proposal_sub_view) UNION  "
			+"(select *, date_add(`From`, interval 1 day) as 'SLA Due Date' from enlighten_sales_riskass_view where Aging > 1) UNION  "
			+"(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_lead_followup_tis wip inner join training.task t on wip.Id = t.Id) UNION  "
			+"(select wip.*, t.ActivityDate as 'SLA Due Date' from enlighten_sales_opp_followup_tis wip inner join training.task t on wip.Id = t.Id)) t  "
			+"group by t.`Owner`;";
	}

	@Override
	protected String getReportName() {
		return "Sales\\EnlightenSalesBacklog";
	}
	
	@Override
	protected String getTitle() {
		return "Enlighten Sales Backlog";
	}
}
