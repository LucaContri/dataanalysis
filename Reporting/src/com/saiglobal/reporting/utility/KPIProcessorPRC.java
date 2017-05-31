package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;

import com.saiglobal.reporting.model.KPIData;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class KPIProcessorPRC extends AbstractKPIProcessor {

	private TimeZone timeZone = TimeZone.getTimeZone("Australia/Sydney");
	private static final SimpleDateFormat mysqlUTCDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
	private static final double submittedToReviewedTASLA = 2.0;
	
	public KPIProcessorPRC(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getRejectionsByAuditorPeriod()throws Exception {
		List<Object[]> returnValue = new ArrayList<Object[]>();
		String[] periods = getPeriods();
		Object[] header = new Object[periodsToReport+2];
		header[0] = "Auditor";
		int j = 1;
		String query = "select r.Name,";
		for (String period : periods) {
			query += "sum(if(ah.Status__c='Rejected' and date_format(ah.Timestamp__c, '%Y %m')='" + period + "', 1, 0)) as '" + period + "',";
			header[j++] = displayMonthFormat.format(mysqlPeriodFormat.parseObject(period));
		}
		header[periodsToReport+1] = "Total Rejections";
		returnValue.add(header);
		
		query += "sum(if(ah.Status__c='Rejected', 1, 0)) as 'TotalRejections' "
				+ "from approval_history__c ah "
				+ "inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c "
				+ "inner join resource__c r on r.Id = arg.RAudit_Report_Author__c "
				+ "where ah.RAudit_Report_Group__c is not null "
				+ "and arg.Client_Ownership__c in ('Australia') "
				+ "and date_format(ah.Timestamp__c, '%Y %m') >= date_format(date_add(now(), interval " + (1-this.periodsToReport) + " month), '%Y %m') "
				+ "group by Name; ";
		
		
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		while (rs.next()) {
			List<Object> row = new ArrayList<Object>();
			row.add(rs.getString("Name"));
			for (String period : periods) {
				row.add(rs.getInt(period));
			} 
			row.add(rs.getInt("TotalRejections"));
			returnValue.add(row.toArray(new Object[row.size()]));
		}
		
		return returnValue.toArray(new Object[returnValue.size()][]);
	}
	
	public String[] getPeriods() {
		String[] returnValue = new String[periodsToReport];
		Calendar aux = Calendar.getInstance();
		for(int i=1; i<=periodsToReport; i++) {
			returnValue[periodsToReport-i] = mysqlPeriodFormat.format(aux.getTime());
			aux.add(Calendar.MONTH, -1);
		}
		
		return returnValue;
	}
	
	public HashMap<String, Object[][]> getARGProcessingDays() throws Exception {
		HashMap<String, Object[][]> returnValue = new HashMap<String, Object[][]>();
		returnValue.put(KPIData.FOOD, new Object[periodsToReport+1][4]);
		returnValue.put(KPIData.MS, new Object[periodsToReport+1][4]);
		returnValue.put(KPIData.PS, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.FOOD)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		returnValue.get(KPIData.MS)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		returnValue.get(KPIData.PS)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		String query = "select t.*,"
				+ "if(wi.Revenue_Ownership__c like '%Food%', 'food', if(wi.Revenue_Ownership__c like '%Product%', 'ps', 'ms')) as 'Stream' "
				+ "from ("
				+ "select "
				+ "ah.RAudit_Report_Group__c as 'ARG_Id',"
				+ "min(if(ah.Status__c='Submitted', concat(Timestamp__c, ' UTC'), null)) as 'First_Submitted',"
				+ "min(if(ah.Status__c='Taken', concat(Timestamp__c, ' UTC'), null)) as 'First_Taken',"
				+ "min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved'), concat(Timestamp__c, ' UTC'), null)) as 'First_Reviewed' "
				+ "from approval_history__c ah "
				+ "inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c "
				+ "where ah.RAudit_Report_Group__c is not null "
				+ "and arg.Client_Ownership__c in ('Australia') "
				+ "group by ah.RAudit_Report_Group__c) t "
				+ "inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id "
				+ "inner join work_item__c wi on wi.id = argwi.RWork_Item__c "
				+ "where t.First_Submitted >= date_format(date_add(now(), interval " + (1-this.periodsToReport) + " month), '%Y-%m-01') "
				+ "and wi.IsDeleted=0 "
				+ "and wi.Status__c not in ('Cancelled') "
				+ "and argwi.IsDeleted=0 "
				+ "group by t.ARG_Id "
				+ "order by t.First_Submitted, Stream";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		String currentPeriod = null;
		int periodCounter = 0;
		double submittedToReviewedTAItem = 0.0;
		Date firstSubmitDate = null;
		String firstSubmitPeriod = null;
		Date firstReviewedDate = null;
		int reviewedRecordCount = 0;
		
		while (rs.next()) {
			if (rs.getString("First_Submitted") != null) {
				firstSubmitDate = mysqlUTCDateFormat.parse(rs.getString("First_Submitted"));
				firstSubmitPeriod = displayMonthFormat.format(firstSubmitDate);
				if ((currentPeriod==null) || !currentPeriod.equalsIgnoreCase(firstSubmitPeriod)) {
					currentPeriod = firstSubmitPeriod;
					periodCounter++;
					reviewedRecordCount = 0;
					returnValue.get(KPIData.FOOD)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
					returnValue.get(KPIData.MS)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
					returnValue.get(KPIData.PS)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
				}
				returnValue.get(rs.getString("Stream"))[periodCounter][1] = ((int) returnValue.get(rs.getString("Stream"))[periodCounter][1]) +1;
				
				if (rs.getString("First_Reviewed") != null) {
					firstReviewedDate = mysqlUTCDateFormat.parse(rs.getString("First_Reviewed"));
					submittedToReviewedTAItem = Utility.calculateWorkingDaysInPeriodV2(firstSubmitDate, firstReviewedDate, timeZone);
					returnValue.get(rs.getString("Stream"))[periodCounter][3] = (((double) returnValue.get(rs.getString("Stream"))[periodCounter][3])*reviewedRecordCount + submittedToReviewedTAItem)/(reviewedRecordCount+1);
					reviewedRecordCount++;
				} else {
					// Assume it was reviewed now.  If the turn-around is greater than the target, then add it to the count
					submittedToReviewedTAItem = Utility.calculateWorkingDaysInPeriodV2(firstSubmitDate, new Date(), timeZone);					
				}
				if (submittedToReviewedTAItem>submittedToReviewedTASLA) {
					returnValue.get(rs.getString("Stream"))[periodCounter][2] = ((int) returnValue.get(rs.getString("Stream"))[periodCounter][2]) +1;
				}
			} else {
				// Ignore this record
				continue;
			}
		}
		return returnValue;
	}
	/*
	public HashMap<String, HashMap<String, Object[][]>> getRejections() throws Exception {
		HashMap<String,HashMap<String, Object[][]>> returnValue = new HashMap<String,HashMap<String, Object[][]>>();
		returnValue.put(KPIData.TABLE, new HashMap<String, Object[][]>());
		returnValue.put(KPIData.TABLE2, new HashMap<String, Object[][]>());
		/*
		returnValue.get(KPIData.TABLE).put(KPIData.FOOD, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.TABLE).put(KPIData.MS, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.TABLE).put(KPIData.PS, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.TABLE2).put(KPIData.FOOD, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.TABLE2).put(KPIData.MS, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.TABLE2).put(KPIData.PS, new Object[periodsToReport+1][4]);
		returnValue.get(KPIData.FOOD)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		returnValue.get(KPIData.MS)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		returnValue.get(KPIData.PS)[0] = new Object[] {"Submitted Period", "ARGs Submitted", "ARGs Not Reviewed within 2 days", "ARGs Turnaround Days"};
		
		String query = "select t.*,"
				+ "if(wi.Revenue_Ownership__c like '%Food%', 'food', if(wi.Revenue_Ownership__c like '%Product%', 'ps', 'ms')) as 'Stream' "
				+ "from ("
				+ "select "
				+ "ah.RAudit_Report_Group__c as 'ARG_Id',"
				+ "min(if(ah.Status__c='Submitted', concat(Timestamp__c, ' UTC'), null)) as 'First_Submitted',"
				+ "min(if(ah.Status__c='Taken', concat(Timestamp__c, ' UTC'), null)) as 'First_Taken',"
				+ "min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved'), concat(Timestamp__c, ' UTC'), null)) as 'First_Reviewed' "
				+ "from approval_history__c ah "
				+ "inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Grousalesp__c "
				+ "where ah.RAudit_Report_Group__c is not null "
				+ "and arg.Client_Ownership__c in ('Australia') "
				+ "group by ah.RAudit_Report_Group__c) t "
				+ "inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id "
				+ "inner join work_item__c wi on wi.id = argwi.RWork_Item__c "
				+ "where t.First_Submitted >= date_format(date_add(now(), interval " + (1-this.periodsToReport) + " month), '%Y-%m-01') "
				+ "and wi.IsDeleted=0 "
				+ "and wi.Status__c not in ('Cancelled') "
				+ "and argwi.IsDeleted=0 "
				+ "group by t.ARG_Id "
				+ "order by t.First_Submitted, Stream";
		
		/*
		ResultSet rs = db_certification.executeSelect(query, -1);
		String currentPeriod = null;
		int periodCounter = 0;
		double submittedToReviewedTAItem = 0.0;
		Date firstSubmitDate = null;
		String firstSubmitPeriod = null;
		Date firstReviewedDate = null;
		int reviewedRecordCount = 0;
		
		while (rs.next()) {
			if (rs.getString("First_Submitted") != null) {
				firstSubmitDate = mysqlUTCDateFormat.parse(rs.getString("First_Submitted"));
				firstSubmitPeriod = displayMonthFormat.format(firstSubmitDate);
				if ((currentPeriod==null) || !currentPeriod.equalsIgnoreCase(firstSubmitPeriod)) {
					currentPeriod = firstSubmitPeriod;
					periodCounter++;
					reviewedRecordCount = 0;
					returnValue.get(KPIData.FOOD)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
					returnValue.get(KPIData.MS)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
					returnValue.get(KPIData.PS)[periodCounter] = new Object[] {currentPeriod,0,0,0.0};
				}
				String tmp = rs.getString("Stream");
				returnValue.get(rs.getString("Stream"))[periodCounter][1] = ((int) returnValue.get(rs.getString("Stream"))[periodCounter][1]) +1;
				
				if (rs.getString("First_Reviewed") != null) {
					firstReviewedDate = mysqlUTCDateFormat.parse(rs.getString("First_Reviewed"));
					submittedToReviewedTAItem = Utility.calculateWorkingDaysInPeriodV2(firstSubmitDate, firstReviewedDate, timeZone);
					returnValue.get(rs.getString("Stream"))[periodCounter][3] = (((double) returnValue.get(rs.getString("Stream"))[periodCounter][3])*reviewedRecordCount + submittedToReviewedTAItem)/(reviewedRecordCount+1);
					reviewedRecordCount++;
				} else {
					// Assume it was reviewed now.  If the turn-around is greater than the target, then add it to the count
					submittedToReviewedTAItem = Utility.calculateWorkingDaysInPeriodV2(firstSubmitDate, new Date(), timeZone);					
				}
				if (submittedToReviewedTAItem>submittedToReviewedTASLA) {
					returnValue.get(rs.getString("Stream"))[periodCounter][2] = ((int) returnValue.get(rs.getString("Stream"))[periodCounter][2]) +1;
				}
			} else {
				// Ignore this record
				continue;
			}
		}
		
		return returnValue;
	}
	*/
}
