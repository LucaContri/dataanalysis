package com.saiglobal.sf.reporting.processor;

import java.sql.ResultSet;

public class AuditorSLAReport extends AbstractQueryReport {

	public AuditorSLAReport() {
		super();
		setExecuteStatement(true);
	}

	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("compass");
	}
	
	@Override
	protected void initialiseQuery() throws Throwable {
		String otherEmails  = this.gp.getReportEmailsAsString();
		// Get list of Auditors
		String query = "select r.Id, r.Name as 'Auditor', r.Reporting_Business_Units__c, r.Email__c as 'AuditorEmail', m.Email as 'ManagerEmail' "
				+ "from salesforce.resource__c r "
				+ "inner join salesforce.user u on r.User__c = u.Id "
				+ "inner join salesforce.user m on u.ManagerId = m.Id "
				+ "where "
				+ "r.Reporting_Business_Units__c like 'AUS%' "
				+ "and r.Reporting_Business_Units__c not like 'AUS-Product%' "
				+ "and r.Resource_Type__c not in ('Client Services') "
				+ "and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') "
				+ "and r.Resource_Target_Days__c > 50 "
				+ "and r.Active_User__c = 'Yes';";
		
		ResultSet rs = this.db.executeSelect(query, -1);
		while (rs.next()) {
			// For each auditor initiate Thread to create report
			String auditor = rs.getString("Auditor");
			String auditorEmail = rs.getString("AuditorEmail");
			String managerEmail = rs.getString("ManagerEmail");
			//auditorEmail = "";
			//managerEmail = "";
			Runtime rt = Runtime.getRuntime();
			String cmdString = "javaw -jar \"C:\\SAI\\lib\\sf_report_engine.jar\" -rb com.saiglobal.sf.reporting.processor.AuditorPersonalisedSLAReport -rff xlsxTemplate -itin false -sdth false -cp xlsxTemplate:Templates\\AuditorPersonalisedSLAReport.xlsx;auditor:\"" + auditor + "\" -re " + auditorEmail + ";" + managerEmail + ";" + otherEmails;
			Process proc = rt.exec(cmdString);
			proc.waitFor();
		}
	}
	
	@Override
	protected String getQuery() {
		return "";
	}

	@Override
	protected String getReportName() {
		return null;
	}

}
