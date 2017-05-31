package com.saiglobal.sf.reporting.processor;

public class SuspendedLicencesByPeriod extends AbstractQueryReport {

	public SuspendedLicencesByPeriod() {
		this.columnWidth = new int[] {150};
	}
	
	@Override
	protected String getQuery() {
		return "select t.`Suspended Period`, count(distinct t.Id) as 'Suspensions Count' from ("
				+ "select a.Id as 'ClientId', a.Name as 'Client Name', csp.ID, csp.Name, date_format(csph.CreatedDate, '%Y-%m-%d') as 'Suspended Date', date_format(csph.CreatedDate, '%Y-%m') as 'Suspended Period', csph.OldValue, csph.NewValue  "
				+ "from Certification_Standard_Program__c csp "
				+ "inner join Certification__c c on csp.Certification__c = c.Id "
				+ "inner join account a on c.Primary_client__c = a.Id "
				+ "inner join certification_standard_program__history csph on csph.ParentId = csp.Id "
				+ "where csph.NewValue = 'Under Suspension' "
				+ "and csph.Field = 'Status__c' "
				+ "and a.Client_Ownership__c = 'Australia') t group by t.`Suspended Period`;";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Admin\\SuspendedLicences";
	}
	
	@Override
	protected String getTitle() {
		return "Licences Suspended by Period";
	}
}
