package com.saiglobal.sf.reporting.processor;

public class HealthDepartmentReportNSQHSCSSQHCompleted extends AbstractQueryReport {

	public HealthDepartmentReportNSQHSCSSQHCompleted() {
		//this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {80,200,100,200,100,100,100,100,100,100};
	}
	
	@Override
	protected String getQuery() {
		return "select "
				+ "scs.Name as 'State',"
				+ "if (site.Site_Description__c is null, sc.Primary_Client_Name__c, site.Site_Description__c) as 'Name of all Heath Service Organisations Assessed',"
				+ "scsp.SAI_Certification_Std_Certificate_Number__c as 'SAI Certificate Number',"
				+ "csp.Scope__c as 'Scope',"
				+ "'' as 'Type of Service',"
				+ "'' as 'Public or Private',"
				+ "if (wi.Work_Item_Stage__c in ('Re-Certification','Certification'),'Organisational Wide', 'Mid-Cycle') as 'Organisational Wide or Mid-Cycle',"
				+ "wi.End_Service_Date__c as 'Date Assessed',"
				+ "csp.Expires__c as 'Date of Determination of Certification Status',"
				+ "if (csp.Status__c in ('Registered'),'Certified', 'Not Certified') as 'Status (Certified, Not Certified)' "
				+ "from work_item__c wi "
				+ "inner join work_package__c wp on wi.Work_Package__c = wp.Id "
				+ "inner join certification__c sc on wp.Site_Certification__c = sc.Id "
				+ "inner join Site_Certification_Standard_Program__c scsp on scsp.Site_Certification__c = sc.Id "
				+ "inner join certification__c c on sc.Primary_Certification__c = c.Id "
				+ "inner join Certification_Standard_Program__c csp on csp.Certification__c = c.Id "
				+ "inner join account site on sc.Primary_client__c = site.Id "
				+ "inner join state_code_setup__c scs on scs.Id = site.Business_State__c "
				+ "where (wi.Primary_Standard__c like 'Core Standards for Safety and Quality in Healthcare%' "
				+ "or wi.Primary_Standard__c like 'NSQHS Standard%') "
				+ "and wi.IsDeleted = 0 "
				+ "and wi.Status__c not in ('Open','Scheduled','Scheduled - Offered', 'Initiate service', 'Service Change', 'Cancelled') "
				+ "and date_format(wi.Work_Item_Date__c, '%Y %m') = date_format(date_add(now(), interval -1 month), '%Y %m')";
	}

	@Override
	protected String getReportName() {
		return "Health Department\\Completed NSQHS-CSSQH Audits";
	}
	
	@Override
	protected String getTitle() {
		return "Completed NSQHS/CSSQH Audits";
	}
}
