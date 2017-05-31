package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class KPIProcessorNewBusiness extends AbstractKPIProcessor {

	private TimeZone timeZone = TimeZone.getTimeZone("Australia/Sydney");
	private static final int targetDays = 2;
	
	public KPIProcessorNewBusiness(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getNBProcessingDays() throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Object[][] returnValue = new Object[periodsToReport+1][5];
		returnValue[0] = new Object[] {"Opp Won Period", "# Opp Auto Finalised", "# Opp Manually Finalised", "# Opp Not Finalised", "# Not Processed within " + targetDays + " days", "% Not Processed within " + targetDays + " days", "Avg Processing Days" };
		for (int i = 1; i < returnValue.length; i++) {
			returnValue[i] = new Object[] {"",0,0,0,0,0};
		}
		String query = "SELECT * FROM "
				+ "(SELECT "
				+ "MAX(oh.createdDate) AS 'Won Date',"
				+ "if("
				+ "o.Delivery_Strategy_Created__c is not null, o.Delivery_Strategy_Created__c ,"
				+ "max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null))) AS 'Finalised Date',"
				+ "o.Manual_Certification_Finalised__c AS 'Manual Certification Finalised' "
				+ "FROM opportunity o "
				+ "LEFT JOIN opportunityfieldhistory oh ON oh.OpportunityId = o.id "
				+ "WHERE "
				+ "o.IsDeleted = 0 "
				+ "AND o.Business_1__c IN ('Australia') "
				+ "AND o.StageName = 'Closed Won' "
				+ "AND ((oh.Field = 'StageName' AND oh.NewValue = 'Closed Won') OR (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true')) "
				+ "GROUP BY o.id "
				+ "union "
				+ "SELECT "
				+ "MAX(if (oh.NewValue='Negotiation/Review', oh.createdDate, null)) AS 'Won Date',"
				+ " if("
				+ "MAX(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)) is not null,MAX(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)),"
				+ "max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null)))  AS 'Finalised Date',"
				+ "o.Manual_Certification_Finalised__c AS 'Manual Certification Finalised' "
				+ "FROM "
				+ "opportunity o "
				+ "LEFT JOIN opportunityfieldhistory oh ON oh.OpportunityId = o.id "
				+ "WHERE "
				+ "o.IsDeleted = 0 "
				+ "AND o.Business_1__c IN ('Product Services') "
				+ "AND o.StageName in ('Closed Won', 'Negotiation/Review') "
				+ "AND ((oh.Field = 'StageName' AND oh.NewValue IN ('Closed Won' , 'Negotiation/Review')) OR (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true')) "
				+ "GROUP BY o.id) t "
				+ "WHERE "
				+ "date_format(t.`Won Date`, '%Y %m') >= date_format(date_add(now(), interval " + (1-periodsToReport) + " month), '%Y %m') "
				+ "and date_format(t.`Won Date`, '%Y %m') <= date_format(now(), '%Y %m') "
				+ "ORDER BY t.`Won Date`";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		String currentPeriod = null;
		int periodCounter = 0;
		int oppCount = 0;
		int oppManuallyFinalised = 0;
		int oppAutoFinalised = 0;
		int oppNotFinalised = 0;
		int oppNotProcessedWithinTargetCount = 0;
		double avgProcessingDays = 0.0;
		
		while (rs.next()) {
			if (rs.getString("Won Date") == null) {
				// Ignore.  Some opportunity for Product Services are moved to Closed Won without going through Negotiation/Review.  It seems they are only old ones.  Ignore.
				continue;
			}
			String period = displayMonthFormat.format(mysqlDateFormat.parse(rs.getString("Won Date")));
			if ((currentPeriod == null) || !currentPeriod.equalsIgnoreCase(period) ) {
				if (currentPeriod != null) {
					returnValue[periodCounter] = new Object[] {currentPeriod, oppAutoFinalised, oppManuallyFinalised, oppNotFinalised, oppNotProcessedWithinTargetCount, ((double) oppNotProcessedWithinTargetCount)/(oppAutoFinalised + oppManuallyFinalised)*100 ,avgProcessingDays };
				}
				periodCounter++;
				currentPeriod = period;
				avgProcessingDays = 0.0;
				oppCount = 0;
				oppManuallyFinalised = 0;
				oppAutoFinalised = 0;
				oppNotFinalised++;
				oppNotProcessedWithinTargetCount = 0;
			}
			
			if (rs.getString("Finalised Date") != null) {
				double processingDays = Utility.calculateWorkingDaysInPeriodV2(mysqlDateFormat.parse(rs.getString("Won Date")), mysqlDateFormat.parse(rs.getString("Finalised Date")), timeZone);
				avgProcessingDays = (avgProcessingDays*oppCount + processingDays)/(oppCount+1);
				if (processingDays>targetDays)
					oppNotProcessedWithinTargetCount++;
				if (rs.getBoolean("Manual Certification Finalised")) {
					oppManuallyFinalised++;
				} else {
					oppAutoFinalised++;
				}
			} else {
				if (rs.getBoolean("Manual Certification Finalised")) {
					oppManuallyFinalised++;
				} else {
					oppNotFinalised++;
					double bestCaseProcessingDays = Utility.calculateWorkingDaysInPeriodV2(mysqlDateFormat.parse(rs.getString("Won Date")), new Date(), timeZone);
					if (bestCaseProcessingDays>targetDays)
						oppNotProcessedWithinTargetCount++;					
				}
			}
			oppCount++;
		}
		// Save last
		returnValue[periodCounter] = new Object[] {currentPeriod, oppAutoFinalised, oppManuallyFinalised, oppNotFinalised, oppNotProcessedWithinTargetCount, ((double) oppNotProcessedWithinTargetCount)/(oppAutoFinalised + oppManuallyFinalised)*100, avgProcessingDays};
		
		return returnValue;
	}
}
