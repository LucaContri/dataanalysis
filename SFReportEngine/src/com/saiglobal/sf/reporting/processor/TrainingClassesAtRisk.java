package com.saiglobal.sf.reporting.processor;

public class TrainingClassesAtRisk extends AbstractQueryReport {

	private String weeks = "6";
	
	public TrainingClassesAtRisk() {
		this.columnWidth = new int[] {200,250};
	}
	
	@Override
	protected void initialiseQuery() {
		if (gp.hasCustomParameter("weeks"))
			weeks = gp.getCustomParameter("weeks");
	}

	@Override
	protected String getQuery() {
		return "select c.Id as 'Class Id', c.Name as 'Class Name', c.class_location__c as 'Location', date_format(c.Class_Begin_Date__c, '%d/%m/%Y') as 'Start Date', "
				+ "date_format(c.Class_End_Date__c, '%d/%m/%Y') as 'End Date', "
				+ "trainer.name as 'Trainer 1', "
				+ "c.Training_Days__c as 'Training Days', "
				+ "c.Number_of_Confirmed_Attendees__c as 'Current Attendees', c.Minimim_Attendee__c as 'Min Attendees',t3.`Avg Attendees`,c.Maximum_Attendee__c as 'Max Attendees', "
				+ "round(t3.`Avg wks Attendees %`*100,2) as 'Avg % Attendees " + weeks + "wks out', t3.`#Classes` as '# Classes in Avg',"
				+ "round(c.Number_of_Confirmed_Attendees__c/t3.`Avg wks Attendees %`,0) as 'Forcasted Final Attendees',"
				+ "round(greatest(0,(c.Minimim_Attendee__c-c.Number_of_Confirmed_Attendees__c/t3.`Avg wks Attendees %`)/c.Minimim_Attendee__c)*100,2) as 'Risk Factor' "
				+ "from class__c c "
				+ "left join training.contact trainer on c.Trainer_1__c = trainer.Id "
				+ "inner join training.recordtype rt ON c.RecordTypeId = rt.Id	"
				+ "inner join (select t2.`Class Name`, t2.`Location`, avg(t2.`wks Attendees %`) as 'Avg wks Attendees %', count(t2.`Class Id`) as `#Classes`, avg(t2.`Final Attendees`) as 'Avg Attendees' "
				+ "from ("
				+ "select t.`Class Id`, t.`Class Name`,t.`Location`,t.`Class_Status__c`, t.`Final Attendees`, t.`Min Attendees`,t.`Class Begin Date`, "
				+ "sum(if(date_format(t.`Class Begin Date`,'%x-%v') > date_format(date_add(t.`Date`,interval " + weeks + "*7 day), '%x-%v'), if(t.Event='Created',1,-1),0))/t.`Final Attendees` as 'wks Attendees %' "
				+ "from registrations_timing t "
				+ "group by t.`Class Id`) t2 "
				+ "group by t2.`Class Name`) t3 on t3.`Class Name` = c.Name  "
				+ "where "
				+ "c.IsDeleted = 0 "
				+ "and c.Name not like '%DO NOT USE%' "
				+ "and c.class_location__c not in ('Online') "
				+ "and c.Class_Status__c not in ('Cancelled') "
				+ "and rt.Name = 'Public Class' "
				+ "and date_format(c.Class_Begin_Date__c,'%x-%v') = date_format(date_add(now(),interval " + weeks + "*7 day), '%x-%v') "
				+ "order by `Risk Factor` desc;";
	}

	@Override
	protected String getReportName() {
		return "TIS\\PublicClassesRiskAnalysis_" + weeks + "_WeeksOut";
	}
	
	@Override
	protected String getTitle() {
		return "Public Classes Risk Analysis " + weeks + " weeks out";
	}
}
