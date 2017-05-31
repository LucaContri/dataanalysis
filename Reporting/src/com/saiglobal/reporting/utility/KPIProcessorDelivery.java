package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class KPIProcessorDelivery extends AbstractKPIProcessor {

	private TimeZone timeZone = TimeZone.getTimeZone("Australia/Sydney");
	private static final int targetDays = 5;
	public KPIProcessorDelivery(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getARGProcessingDays() throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Object[][] returnValue = new Object[periodsToReport+1][4];
		returnValue[0] = new Object[] {"Audit Period", "# Audit Performed", "# Audit not submitted within " + targetDays + " days", "Avg Days to Submit" };
		/*String query = "select t.* from ("
				+ "select "
				+ "arg.id as 'ARG_Id',"
				+ "max(wi.End_Service_Date__c) as 'End Last Audit',"
				+ "arg.First_Submitted__c as 'Submitted Date' "
				+ "from audit_report_group__c arg "
				+ "inner join arg_work_item__c argwi on arg.id = argwi.RAudit_Report_Group__c "
				+ "inner join work_item__c wi on wi.Id = argwi.RWork_Item__c "
				+ "where arg.Client_Ownership__c in ('Australia') "
				+ "and arg.IsDeleted=0 "
				+ "and arg.Hold_Reason__c is null "
				+ "and wi.IsDeleted = 0 "
				+ "and wi.Status__c not in ('Cancelled') "
				+ "group by arg.id) t "
				+ "where t.`End Last Audit` >= date_format(date_add(now(), interval " + (-this.periodsToReport) + " month), '%Y-%m-01') "
				+ "and t.`End Last Audit` < date_format(now(), '%Y-%m-01') "
				+ "order by `End Last Audit`";
		*/
		String query = "select "
				+ "wi.id as 'WI_Id',"
				+ "wi.End_Service_Date__c as 'End Last Audit',"
				+ "min(if (wih.Field='Status__c' and wih.newValue = 'Submitted', wih.CreatedDate, null)) as 'Submitted Date'  "
				+ "from work_item__c wi "
				+ "left join work_item__history wih on wih.ParentId = wi.Id "
				+ "where "
				//+ "wi.Client_Ownership__c in ('Australia') "
				+ "(wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				+ "and wi.IsDeleted = 0 "
				+ "and wi.Status__c not in ('Cancelled', 'Budget', 'Draft', 'Open') "
				+ "and wi.End_Service_Date__c >= date_format(date_add(now(), interval " + (-this.periodsToReport) + " month), '%Y-%m-01') "
				+ "and wi.End_Service_Date__c < date_format(now(), '%Y-%m-01') "
				+ "and wih.Field='Status__c' "
				+ "group by wi.id "
				+ "order by wi.End_Service_Date__c";
		ResultSet rs = db_certification.executeSelect(query, -1);
		String currentPeriod = null;
		int periodCounter = 0;
		double finishedToSubmittedTA = 0.0;
		Date auditEndDate = null;
		String auditEndPeriod = null;
		Date submittedDate = null;
		int submittedCount = 0;
		
		while (rs.next()) {
			if (rs.getString("End Last Audit") != null) {
				auditEndDate = Utility.getActivitydateformatter().parse(rs.getString("End Last Audit"));
				auditEndPeriod = displayMonthFormat.format(auditEndDate);
				if ((currentPeriod==null) || !currentPeriod.equalsIgnoreCase(auditEndPeriod)) {
					currentPeriod = auditEndPeriod;
					periodCounter++;
					submittedCount = 0;
					returnValue[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
				}
				returnValue[periodCounter][1] = ((int) returnValue[periodCounter][1]) +1;
				
				if (rs.getString("Submitted Date") != null) {
					submittedDate = mysqlDateFormat.parse(rs.getString("Submitted Date"));
					finishedToSubmittedTA = Utility.calculateWorkingDaysInPeriodV2(auditEndDate, submittedDate, timeZone);
					if (finishedToSubmittedTA>targetDays)
						returnValue[periodCounter][2] = ((int) returnValue[periodCounter][2]) +1;
					returnValue[periodCounter][3] = (((double) returnValue[periodCounter][3])*submittedCount + finishedToSubmittedTA)/(submittedCount+1);
					submittedCount++;
				} else {
					double bestCaseScenario = Utility.calculateWorkingDaysInPeriodV2(auditEndDate, new Date(), timeZone);
					if (bestCaseScenario>targetDays)
						returnValue[periodCounter][2] = ((int) returnValue[periodCounter][2]) +1;
					
					//returnValue[periodCounter][2] = ((int) returnValue[periodCounter][2]) +1;
				}
			} else {
				// Ignore this record
				continue;
			}
		}
		return returnValue;
	}
}
