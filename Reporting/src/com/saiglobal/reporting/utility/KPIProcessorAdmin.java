package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class KPIProcessorAdmin extends AbstractKPIProcessor {

	private TimeZone timeZone = TimeZone.getTimeZone("Australia/Sydney");
	private static final SimpleDateFormat mysqlUTCDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
	private static final double approvedToCompletedTarget = 3.0;
	
	public KPIProcessorAdmin(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getARGProcessingDays() throws Exception {
		Object[][] returnValue = new Object[periodsToReport+1][4];
		returnValue[0] = new Object[] {"Approved Period", "ARGs Approved", "ARGs Not Completed within 3 days", "ARGs Turnaround Days"};
		String query = "select "
				+ "arg.id as 'ARG_Id',"
				+ "concat(arg.CA_Approved__c, ' UTC') as 'Approved Date',"
				+ "if(arg.Admin_Closed__c is null, null, concat(arg.Admin_Closed__c, ' UTC')) as 'Completed Date' "
				+ "from audit_report_group__c arg "
				+ "where arg.Client_Ownership__c in ('Australia') "
				+ "and arg.IsDeleted=0 "
				+ "and arg.Hold_Reason__c is null "
				+ "and arg.CA_Approved__c >= date_format(date_add(now(), interval " + (1-this.periodsToReport) + " month), '%Y-%m-01') "
				+ "order by arg.CA_Approved__c";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		String currentPeriod = null;
		int periodCounter = 0;
		double approvedTocompletedTAItem = 0.0;
		Date approvedDate = null;
		String approvedPeriod = null;
		Date completedDate = null;
		int completedCount = 0;
		
		while (rs.next()) {
			approvedDate = mysqlUTCDateFormat.parse(rs.getString("Approved Date"));
			approvedPeriod = displayMonthFormat.format(approvedDate);
			if ((currentPeriod==null) || !currentPeriod.equalsIgnoreCase(approvedPeriod)) {
				currentPeriod = approvedPeriod;
				periodCounter++;
				completedCount = 0;
				returnValue[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
			}
			returnValue[periodCounter][1] = ((int) returnValue[periodCounter][1]) +1;
			
			if (rs.getString("Completed Date") != null) {
				completedDate = mysqlUTCDateFormat.parse(rs.getString("Completed Date"));
				approvedTocompletedTAItem = Utility.calculateWorkingDaysInPeriodV2(approvedDate, completedDate, timeZone);
				returnValue[periodCounter][3] = (((double) returnValue[periodCounter][3])*completedCount + approvedTocompletedTAItem)/(completedCount+1);
				completedCount++;
			} else {
				// Assume it was reviewed now.  If the turn-around is greater than the target, then add it to the count
				approvedTocompletedTAItem = Utility.calculateWorkingDaysInPeriodV2(approvedDate, new Date(), timeZone);					
			}
			if (approvedTocompletedTAItem>approvedToCompletedTarget) {
				returnValue[periodCounter][2] = ((int) returnValue[periodCounter][2]) +1;
			}
		}
		return returnValue;
	}
	
	public Object[][] getPhoneMetrics() throws Exception {
		Object[][] returnValue = new Object[periodsToReport+1][5];
		returnValue[0] = new Object[] {"Period", "Handled #", "Abandoned/Interflowed #", "Avg Answering Time (s)", "Avg Handling Time (s)"};
		String query = "select t2.*,"
				+ "round(t2.`Total Handling Time`/t2.`ACD calls handled`,0) as 'Avg Handling Time',"
				+ "round(t2.`Total Answering Time`/t2.`ACD calls handled`,0) as 'Avg Answering Time' "
				+ "from ("
				+ "select t.`Period`,"
				+ "round(sum(t.`ACD calls offered`),0) as 'ACD calls offered',"
				+ "round(sum(t.`ACD calls handled`),0) as 'ACD calls handled',"
				+ "round(sum(t.`Average ACD handling time (sec)`*t.`ACD calls handled`),0) as 'Total Handling Time',"
				+ "round(sum(t.`Average speed of answer (sec)`*t.`ACD calls handled`),0) as 'Total Answering Time' from ("
				+ "select "
				+ "RefDate,"
				+ "RefName,"
				+ "date_format(RefDate, '%Y %m') as 'Period',"
				+ "sum(if (DataSubType='ACD calls handled', refValue,0)) as 'ACD calls handled',"
				+ "sum(if (DataSubType='ACD calls offered', refValue,0)) as 'ACD calls offered',"
				+ "sum(if (DataSubType='Average speed of answer (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average speed of answer (sec)',"
				+ "sum(if (DataSubType='Average ACD handling time (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average ACD handling time (sec)' "
				+ "from sf_data "
				+ "where DataType='Mitel' "
				+ "and RefName not in ('Public Training','In-House','Online Learning','Recognition') "
				+ "and date_format(RefDate, '%Y %m') <= date_format(now(), '%Y %m') "
				+ "and date_format(RefDate, '%Y %m') >= date_format(date_add(now(), interval " + (1-periodsToReport) + " month), '%Y %m') "
				+ "group by RefDate, RefName) t "
				+ "group by t.`Period`) t2";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		
		while (rs.next()) {
			returnValue[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getInt("ACD calls handled"), rs.getInt("ACD calls offered") - rs.getInt("ACD calls handled"), rs.getInt("Avg Answering Time"), rs.getInt("Avg Handling Time")};
		}
		
		return returnValue;
	}
}
