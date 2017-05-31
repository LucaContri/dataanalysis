package com.saiglobal.sf.reporting.processor;

import java.sql.ResultSet;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.TimeZone;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

public class KpiPrc implements ReportBuilder {
	private DbHelper db_certification;
	private GlobalProperties gp;
	
	private static final Logger logger = Logger.getLogger(KpiPrc.class);
	private static final Calendar startDate = new GregorianCalendar();
	protected final Calendar reportDate;
	private boolean saveInHistory;
	private static final String reportName = "KPI PRC";
	private static final double submittedToReviewedTASLA = 2.0;
	private static final NumberFormat decimal_formatter = new DecimalFormat("#0.00");   	
	public KpiPrc() {
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		startDate.set(Calendar.DATE, 1); 
		startDate.set(2012,Calendar.JANUARY, 1);
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		return new JasperReportBuilder[] {};
	}
	
	public void init() throws Exception {
		try {

			Date firstSubmitDate = null;
			Date firstTakenDate = null;
			String firstSubmitPeriod = null;
			Date firstReviewedDate = null;
			TimeZone timeZone = TimeZone.getTimeZone("Australia/Sydney");
			HashMap<String, Double> submittedToTakenTA = new HashMap<String, Double>();
			HashMap<String, Double> takenToReviewedTA = new HashMap<String, Double>();
			HashMap<String, Double> submittedToReviewedTA = new HashMap<String, Double>();
			HashMap<String, Double> submittedRecordCount = new HashMap<String, Double>();
			HashMap<String, Double> submittedToTakenRecordCount = new HashMap<String, Double>();
			HashMap<String, Double> takenToReviewedRecordCount = new HashMap<String, Double>();
			HashMap<String, Double> submittedToReviewedRecordCountWithinSLA = new HashMap<String, Double>();
			double submittenToTakenTAItem;
			double takenToReviewedTAItem;
			String query = "select t.* from ("
					+ "select "
					+ "ah.RAudit_Report_Group__c as 'ARG_Id',"
					+ "min(if(ah.Status__c='Submitted', Timestamp__c, null)) as 'First_Submitted',"
					+ "min(if(ah.Status__c='Taken', Timestamp__c, null)) as 'First_Taken',"
					+ "min(if(ah.Status__c='Rejected' or (ah.Assigned_To__c='Client Administration' and ah.Status__c='Approved'), Timestamp__c, null)) as 'First_Reviewed' "
					+ "from approval_history__c ah "
					+ "inner join audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c "
					+ "where ah.RAudit_Report_Group__c is not null "
					+ "and arg.Client_Ownership__c in ('Australia')"
					+ "group by ah.RAudit_Report_Group__c) t "
					+ "where t.First_Submitted >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "'";
			ResultSet rs = db_certification.executeSelect(query, -1);
			while (rs.next()) {
				if (rs.getString("First_Submitted") != null) {
					firstSubmitDate = Utility.getMysqldateformat().parse(rs.getString("First_Submitted"));
					firstSubmitPeriod = Utility.getPeriodformatter().format(firstSubmitDate);
					if (!submittedToTakenTA.containsKey(firstSubmitPeriod)) {
						submittedRecordCount.put(firstSubmitPeriod, 0.0);
					}
					submittedRecordCount.put(firstSubmitPeriod, submittedRecordCount.get(firstSubmitPeriod)+1);
				} else {
					// Ignore this record
					continue;
				}
				
				if (rs.getString("First_Taken") != null) {
					firstTakenDate = Utility.getMysqldateformat().parse(rs.getString("First_Taken"));
					submittenToTakenTAItem = Utility.calculateWorkingDaysInPeriodV2(firstSubmitDate, firstTakenDate, timeZone);
					if (!submittedToTakenTA.containsKey(firstSubmitPeriod)) {
						submittedToTakenTA.put(firstSubmitPeriod, 0.0);
						submittedToTakenRecordCount.put(firstSubmitPeriod, 0.0);
					}
					submittedToTakenTA.put(firstSubmitPeriod, (submittedToTakenTA.get(firstSubmitPeriod)*submittedToTakenRecordCount.get(firstSubmitPeriod)+submittenToTakenTAItem)/(submittedToTakenRecordCount.get(firstSubmitPeriod)+1));
					submittedToTakenRecordCount.put(firstSubmitPeriod, submittedToTakenRecordCount.get(firstSubmitPeriod)+1);
				} else {
					// Ignore this record
					continue;
				}
				
				if (rs.getString("First_Reviewed") != null) {
					firstReviewedDate = Utility.getMysqldateformat().parse(rs.getString("First_Reviewed"));
					
					takenToReviewedTAItem = Utility.calculateWorkingDaysInPeriodV2(firstTakenDate, firstReviewedDate, timeZone);
					if (!takenToReviewedTA.containsKey(firstSubmitPeriod)) {
						takenToReviewedTA.put(firstSubmitPeriod, 0.0);
						takenToReviewedRecordCount.put(firstSubmitPeriod, 0.0);
						submittedToReviewedTA.put(firstSubmitPeriod, 0.0);
						submittedToReviewedRecordCountWithinSLA.put(firstSubmitPeriod, 0.0);
					}
					takenToReviewedTA.put(firstSubmitPeriod, (takenToReviewedTA.get(firstSubmitPeriod)*takenToReviewedRecordCount.get(firstSubmitPeriod)+takenToReviewedTAItem)/(takenToReviewedRecordCount.get(firstSubmitPeriod)+1));
					submittedToReviewedTA.put(firstSubmitPeriod, (submittedToReviewedTA.get(firstSubmitPeriod)*takenToReviewedRecordCount.get(firstSubmitPeriod)+takenToReviewedTAItem+submittenToTakenTAItem)/(takenToReviewedRecordCount.get(firstSubmitPeriod)+1));
					if (takenToReviewedTAItem+submittenToTakenTAItem<=submittedToReviewedTASLA) {
						submittedToReviewedRecordCountWithinSLA.put(firstSubmitPeriod, submittedToReviewedRecordCountWithinSLA.get(firstSubmitPeriod)+1);
					}
					takenToReviewedRecordCount.put(firstSubmitPeriod, takenToReviewedRecordCount.get(firstSubmitPeriod)+1);
				} else {
					// Ignore this record
					continue;
				}
			}
			
			if (saveInHistory) {
				for (String period : submittedToTakenTA.keySet()) {				
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Submitted To Taken Days", period, decimal_formatter.format(submittedToTakenTA.get(period)));	
				}
				for (String period : takenToReviewedTA.keySet()) {				
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Taken To Reviewed Days", period, decimal_formatter.format(takenToReviewedTA.get(period)));
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Turnaround Days", period, decimal_formatter.format(submittedToReviewedTA.get(period)));
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Submitted To Reviewed Within Target", period, submittedToReviewedRecordCountWithinSLA.get(period).toString());
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Not Reviewed within Target", period, String.valueOf(submittedRecordCount.get(period) - submittedToReviewedRecordCountWithinSLA.get(period)));
				}
				for (String period : submittedRecordCount.keySet()) {				
					db_certification.addToHistory(reportName, reportDate, "Australia", "ARGs Submitted", period, submittedRecordCount.get(period).toString());
				}
			}		
		} catch (Exception e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		}
	}
	
	public void setDb(DbHelper db) {
		this.db_certification = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		this.saveInHistory = gp.isSaveDataToHistory();
	}
	
	public String[] getReportNames() {
		return new String[] {};
	}
	
	public String[] getFileReportNames() {
		return new String[] {};
	}
	
	public boolean append() {
		return false;
	}
}
