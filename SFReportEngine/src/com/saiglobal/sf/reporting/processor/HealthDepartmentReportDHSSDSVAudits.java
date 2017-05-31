package com.saiglobal.sf.reporting.processor;

public class HealthDepartmentReportDHSSDSVAudits extends AbstractQueryReport {

	public HealthDepartmentReportDHSSDSVAudits() {
		//this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {200,200,200,100,100,100,100,100,100,100};
	}
	
	@Override
	protected String getQuery() {
		return "select "
				+ "c.Primary_Client_Name__c as 'Client Name', "
				+ "sc.Primary_Client_Location__c as 'Location',"
				+ "wi.Primary_Standard__c as 'Primary Standard', "
				+ "wi.Work_Item_Stage__c as 'Type', "
				+ "wi.Status__c as 'Status', "
				+ "wi.Earliest_Service_Date__c as 'Start Service Date', "
				+ "wi.End_Service_Date__c as 'End Service Date', "
				+ "scsp.SAI_Certification_Std_Certificate_Number__c as 'SAI Certificate Number', "
				+ "wi.Name as 'Work Item', "
				+ "sc.Name as 'Site Certification' "
				+ "from work_item__c wi "
				+ "inner join work_package__c wp on wi.Work_Package__c = wp.Id "
				+ "inner join certification__c sc on wp.Site_Certification__c = sc.Id "
				+ "inner join Site_Certification_Standard_Program__c scsp on scsp.Site_Certification__c = sc.Id "
				+ "inner join certification__c c on sc.Primary_Certification__c = c.Id "
				+ "where (wi.Primary_Standard__c like 'Department of Human Services Standards%' "
				+ "or wi.Primary_Standard__c like 'Standards for Disability Services in Victoria%' "
				+ "or wi.Primary_Standard__c like 'Human Services Standards%') "
				+ "and wi.IsDeleted=0 "
				+ "and wi.Status__c not in ('Cancelled', 'Open', 'Inititate service') "
				+ "and date_format(wi.Earliest_Service_Date__c, '%Y %m')>=date_format(now(), '%Y %m') "
				+ "and date_format(wi.Earliest_Service_Date__c, '%Y %m')<=date_format(date_add(now(), interval 12 month), '%Y %m') "
				+ "order by `Client Name`, `Location`";
	}

	@Override
	protected String getReportName() {
		return "Health Department\\Planned DHSS-DSV Audits";
	}
	
	@Override
	protected String getTitle() {
		return "Planned DHSS/DSV Audits";
	}
}
