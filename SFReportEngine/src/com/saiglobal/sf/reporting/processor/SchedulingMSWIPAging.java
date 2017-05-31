package com.saiglobal.sf.reporting.processor;

public class SchedulingMSWIPAging extends AbstractQueryReport {

	public SchedulingMSWIPAging() {
		this.columnWidth = new int[] {180,100,80,120,80,120};
	}
	
	@Override
	protected String getQuery() {
		return "select t2.Team,"
				+ "date_format(t2.Service_Target_date__c, '%M %Y') as 'Target Month',"
				+ "sum(if(t2.Activity='Scheduled',t2.WIP,0)) as 'Scheduled',"
				+ "sum(if(t2.Activity='Scheduled Offered',t2.WIP,0)) as 'Scheduled Offered',"
				+ "sum(if(t2.Activity='Confirmed',t2.WIP,0)) as 'Confirmed',"
				+ "sum(if(t2.Activity='Open W Substatus',t2.WIP,0)) as 'Open W Substatus' "
				+ "from ("
				+ "select "
				+ "if(t.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling - FP') as 'Team',"
				+ "t.Service_Target_date__c,"
				+ "if((t.Status__c = 'Open' and t.Open_Sub_Status__c is null) or t.Status__c = 'Service change','Scheduled',"
				+ "if(t.Status__c = 'Open' and t.Open_Sub_Status__c is not null,'Open W Substatus',"
				+ "if (t.Status__c = 'Scheduled','Scheduled Offered','Confirmed'))) as 'Activity',"
				+ "count(t.Id) as 'WIP' "
				+ "from enlighten_scheduling_wip_sub t "
				+ "group by `Team`, Service_Target_date__c,`Activity`) t2 "
				+ "where t2.Team = 'Scheduling - MS' "
				+ "group by t2.Team, t2.Service_Target_date__c "
				+ "order by t2.Team, t2.Service_Target_date__c;";
	}

	@Override
	protected String getReportName() {
		return "Enlighten\\SchedulingMS.WIP";
	}
	
	@Override
	protected String getTitle() {
		return "Scheduling MS - Aging Backlog";
	}
}
