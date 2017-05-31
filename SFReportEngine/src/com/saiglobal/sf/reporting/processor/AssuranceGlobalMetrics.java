package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.utility.Utility;

public class AssuranceGlobalMetrics extends AbstractQueryReport {

	private static final Calendar startFy;
	private static final Calendar endFy;
	private static final Calendar startPreviousFy;
	private static final Calendar endPreviousFy;
	private static final int periodsToReport;
	private static final String[] periods;
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	
	public AssuranceGlobalMetrics() {
		this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {110,80,220,50,80,80,80,80,80,80,80,80,80,80,80,80};
	}
	
	static {
		startFy = Calendar.getInstance();
		endFy = Calendar.getInstance();
		startPreviousFy = Calendar.getInstance();
		endPreviousFy = Calendar.getInstance();
		if (startFy.get(Calendar.MONTH)<Calendar.JULY) {
			endFy.set(startFy.get(Calendar.YEAR),Calendar.JUNE,30);
			startFy.set(startFy.get(Calendar.YEAR)-1,Calendar.JULY,1);
		} else {
			startFy.set(startFy.get(Calendar.YEAR),Calendar.JULY,1);
			endFy.set(startFy.get(Calendar.YEAR)+1,Calendar.JUNE,30);
		}
		
		// Manual override
		//startFy.set(2013, Calendar.JULY, 1);
		//endFy.set(2014, Calendar.JUNE, 30);
		// End Manual override
		
		startPreviousFy.setTime(startFy.getTime());
		startPreviousFy.add(Calendar.YEAR, -1);
		endPreviousFy.setTime(endFy.getTime());
		endPreviousFy.add(Calendar.YEAR, -1);
		
		periodsToReport = 12; // Full Financial Year
		periods = getPeriods();
	}
	
	private String getQueryConfirmedAuditDays() {
		String query = "select "
				+ "if(RowName like 'Food%', 'Food', 'MS') as 'Stream',"
				+ "'Confirmed Audit Days' as 'Metric', 'Days' as 'Unit', 10 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", sum(if(ColumnName='" + period + "',Value, null)) as '" + period + "' ";
		}
		query += "from sf_report_history "
				+ "where ReportName = 'Audit Days Snapshot' "
				+ "and Region like '%Australia%' "
				+ "and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and Region like '%Australia%') "
				+ "and (RowName like 'Food%' or RowName like 'MS%') "
				+ "and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support') "
				+ "and ColumnName >= '" + periods[0] + "' and ColumnName <= '" + periods[periodsToReport-1] + "' "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	
	private String getQueryConfirmedAuditDaysMSAndFood() {
		String query = "select "
				+ "'MS and Food' as 'Stream',"
				+ "'Confirmed Audit Days' as 'Metric', 'Days' as 'Unit', 10 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", sum(if(ColumnName='" + period + "',Value, null)) as '" + period + "' ";
		}
		query += "from sf_report_history "
				+ "where ReportName = 'Audit Days Snapshot' "
				+ "and Region like '%Australia%' "
				+ "and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and Region like '%Australia%') "
				+ "and (RowName like 'Food%' or RowName like 'MS%') "
				+ "and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support') "
				+ "and ColumnName >= '" + periods[0] + "' and ColumnName <= '" + periods[periodsToReport-1] + "' "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	private String getQueryCustomerRevenueLostAudits() {
		String query = "select lbr.`Stream`, 'Customer Revenue Lost (Audits)' as 'Metric', '$' as 'Unit', 30 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null)) as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	
	private String getQueryCustomerRevenueLostAuditsMsAndFood() {
		String query = "select 'MS and Food' as 'Stream', 'Customer Revenue Lost (Audits)' as 'Metric', '$' as 'Unit', 30 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null)) as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Metric`";
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryCustomerRevenueLostFees() {
		return getEmptyQuery("Customer Revenue Lost (Fees)", new String[] {"MS", "Food", "MS and Food"},"$",35, "TODO");
	}
	
	private String getQueryCustomerRevenueRetainedAudit() {
		String query = "select lbr.`Stream`, '% Customer Revenue Retained (Audits)' as 'Metric', '%' as 'Unit', 20 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", 1-sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS', "
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') "
					+ ") as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	
	private String getQueryCustomerRevenueRetainedAuditMsAndFood() {
		String query = "select 'MS and Food' as 'Stream', '% Customer Revenue Retained (Audits)' as 'Metric', '%' as 'Unit', 20 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", 1-sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/"
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName in ('MS', 'Food') and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') "
					+ " as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Metric`";
		return query;
	}
	
	private String getQueryCustomerAnnualisedLossAudits() {
		String query = "select lbr.`Stream`, 'Annualised Revenue Lost (Audits)' as 'Metric', '%' as 'Unit', 25 as 'index', 'Auto Generated' as 'Responsibility'";
		int noOfPeriods = 1;
		for (String period : periods) {
			query += ", sum(if(lbr.`Cancelled Period`<='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS', "
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') "
					+ ")/" + noOfPeriods++ + "*12 as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	
	private String getQueryCustomerAnnualisedLossAuditsMsAndFood() {
		String query = "select 'MS and Food' as 'Stream', 'Annualised Revenue Lost (Audits)' as 'Metric', '%' as 'Unit', 22 as 'index', 'Auto Generated' as 'Responsibility'";
		int noOfPeriods = 1;
		for (String period : periods) {
			query += ", sum(if(lbr.`Cancelled Period`<='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/"
					+ "(select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName in ('MS', 'Food') and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') /" + noOfPeriods++ + "*12 as '" + period + "' ";
		}
		query += "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
				+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
				+ "group by `Metric`";
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryCustomerRevenueRetainedAuditPlusFees() {
		return getEmptyQuery("% Customer Revenue Retained (Audit and Fees)", new String[] {"MS", "Food", "MS and Food"},"%",25, "TODO");
	}
	
	private String getQueryAvgUnitAuditPrice() {
		return getEmptyQuery("Avg Audit Day Price", new String[] {"MS", "Food", "MS and Food"},"$",40, "Finance");
	}
	
	private String getQueryNewBusinessAuditMsAndFood() {
		String query = "select 'MS and Food' as 'stream', 'New Business Won (Audits)' as 'metric', '$' as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c>0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryNewBusinessAudit() {
		String query = "select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'New Business Won (Audits)' as 'metric', '$' as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				//+ "left join pricebookentry pbe on oli.PricebookEntryId = pbe.Id "
				//+ "left join product2 p on pbe.Product2Id = p.Id "
				+ "left join standard__c s on oli.Standard__c = s.Id "
				+ "left join program__c pg on s.Program__c = pg.Id "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c>0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryNewBusinessFeesMsAndFood() {
		String query = "select 'MS and Food' as 'stream', 'New Business Won (Fees)' as 'metric', '$' as 'Unit', 55 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c=0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryNewBusinessFees() {
		String query = "select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'New Business Won (Fees)' as 'metric', '$' as 'Unit', 55 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				//+ "left join pricebookentry pbe on oli.PricebookEntryId = pbe.Id "
				//+ "left join product2 p on pbe.Product2Id = p.Id "
				+ "left join standard__c s on oli.Standard__c = s.Id "
				+ "left join program__c pg on s.Program__c = pg.Id "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c=0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryUnitPriceQuotedMsAndFood() {
		String query = "select 'MS and Food' as 'stream', 'Avg Audit Day Price Quoted' as 'Metric', '$' as 'Unit', 60 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null))/sum(if(t.WonPeriod = '" + period + "', oli.Days__c, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c>0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryUnitPriceQuoted() {
		String query = "select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'Avg Audit Day Price Quoted' as 'Metric', '$' as 'Unit', 60 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null))/sum(if(t.WonPeriod = '" + period + "', oli.Days__c, null)) as '" + period + "'";
		}
		query+= " from ("
				+ "select "
				+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
				+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where "
				+ "o.IsDeleted = 0 "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and o.Business_1__c = 'Australia' "
				+ "and o.StageName='Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and o.Status__c = 'Active'"
				+ "group by o.Id) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
				//+ "left join pricebookentry pbe on oli.PricebookEntryId = pbe.Id "
				//+ "left join product2 p on pbe.Product2Id = p.Id "
				+ "left join standard__c s on oli.Standard__c = s.Id "
				+ "left join program__c pg on s.Program__c = pg.Id "
				+ "where oli.IsDeleted=0 "
				+ "and oli.Days__c>0 "
				+ "and oli.First_Year_Revenue__c =1 "
				+ "group by `stream`, `metric`";
		
		return query;
	}
	
	private String getQueryFteUtilisation() {
		String query = "select "
				+ "if (RowName like 'Food%', 'Food', if(RowName like 'MS%', 'MS', 'MS and Food')) as 'Stream', "
				+ "'FTE Auditor Utilisation' as 'metric', '%' as 'Unit', 70 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ", sum(if(ColumnName='" + period + "', Value, null)) as '" + period + "'";
		}
		query += " from ("
				+ "select "
				+ "t.* from ("
				+ "select * from sf_report_history "
				+ "where ReportName='Scheduling Auditors Metrics' "
				+ "and ColumnName >= '" + periods[0] + "' "
				+ "and ColumnName <= '" + periods[periodsToReport-1] + "' "
				+ "and RowName like '%Utilisation' "
				+ "and Region='Australia' "
				+ "order by Date desc) t "
				+ "group by Region,ColumnName,RowName) t2 "
				+ "group by Region,RowName";
		
		return query;
	}
	
	private String getQueryContractUnitCost() {
		return getEmptyQuery("Contractor Auditor Daily Cost", new String[] {"MS", "Food", "MS and Food"},"$",80, "Finance");
	}
	
	private String getQueryFteUnitCost() {
		return getEmptyQuery("FTE Auditor Daily Cost", new String[] {"MS", "Food", "MS and Food"},"$",90, "Finance");
	}
	
	private String getQueryTravelRecovery() {
		return getEmptyQuery("Travel Recovery", new String[] {"MS", "Food", "MS and Food"},"%",100, "Finance");
	}
	
	private String getQueryNoOfPublicSeats() {
		String query = "select 'TIS' as 'Stream', 'No of Registrations (Public)' as 'Metric', '#' as 'Unit', 110 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "',c.Number_Of_Confirmed_attendees__c,null)) as '" + period + "'";
		}
		query += " from training.class__c c "
				+ "inner join training.recordtype rt on rt.Id = c.RecordTypeId "
				+ "where rt.Name in ('Generic Class','Public Class') "
				+ "and c.Class_Status__c not in ('Cancelled') "
				+ "and c.Product_Code__c not in ('RMS01','RMS02','F29 - Do not use','Y34','RMS04','RMS05','NAR','NARev','Y23','21st') "
				+ "and c.Name not like '%Budget%' "
				+ "and c.Name not like '%Conference%' "
				+ "and c.Name not like '%DO NOT USE%'"
				+ "and c.Class_Location__c not in ('Online') "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and c.IsDeleted = 0 "
				+ "group by `Stream`, `Metric`";
		
		return query;
	}
	
	private String getQueryNoOfPublicClasses() {
		String query = "select 'TIS' as 'Stream', 'No of classes (Public)' as 'Metric', '#' as 'Unit', 120 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "',1,null)) as '" + period + "'";
		}
		query += " from training.class__c c "
				+ "inner join training.recordtype rt on rt.Id = c.RecordTypeId "
				+ "where rt.Name in ('Generic Class','Public Class') "
				+ "and c.Class_Status__c not in ('Cancelled') "
				+ "and c.Product_Code__c not in ('RMS01','RMS02','F29 - Do not use','Y34','RMS04','RMS05','NAR','NARev','Y23','21st') "
				+ "and c.Name not like '%Budget%' "
				+ "and c.Name not like '%Conference%' "
				+ "and c.Name not like '%DO NOT USE%'"
				+ "and c.Class_Location__c not in ('Online') "
				+ "and date_format(date_add(c.Class_Begin_Date__c,interval 10 hour), '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(date_add(c.Class_Begin_Date__c,interval 10 hour), '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and c.IsDeleted = 0 "
				+ "group by `Stream`, `Metric`";
		
		return query;
	}
	
	private String getQueryAvgClassSize() {
		String query = "select 'TIS' as 'Stream', 'Average Class Size (Public)' as 'Metric', '#' as 'Unit', 130 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "',c.Number_Of_Confirmed_attendees__c,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "',1,null)) as '" + period + "'";
		}
		query += " from training.class__c c "
				+ "inner join training.recordtype rt on rt.Id = c.RecordTypeId "
				+ "where rt.Name in ('Generic Class','Public Class') "
				+ "and c.Class_Status__c not in ('Cancelled') "
				+ "and c.Product_Code__c not in ('RMS01','RMS02','F29 - Do not use','Y34','RMS04','RMS05','NAR','NARev','Y23','21st') "
				+ "and c.Name not like '%Budget%' "
				+ "and c.Name not like '%Conference%' "
				+ "and c.Name not like '%DO NOT USE%'"
				+ "and c.Class_Location__c not in ('Online') "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and c.IsDeleted = 0 "
				+ "group by `Stream`, `Metric`";
		
		return query;
	}
	
	private String getQueryPublicCourseRunRate() {
		String query = "select 'TIS' as 'Stream', 'Course Run Rate (Public)' as 'Metric', '%' as 'Unit', 140 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "' and c.Class_Status__c not in ('Cancelled'),1,null))/sum(if(date_format(c.Class_Begin_Date__c, '%Y %m') = '" + period + "',1,null)) as '" + period + "'";
		}
		query += " from training.class__c c "
				+ "inner join training.recordtype rt on rt.Id = c.RecordTypeId "
				+ "where rt.Name in ('Generic Class','Public Class') "
				+ "and c.Product_Code__c not in ('RMS01','RMS02','F29 - Do not use','Y34','RMS04','RMS05','NAR','NARev','Y23','21st') "
				+ "and c.Name not like '%Budget%' "
				+ "and c.Name not like '%Conference%' "
				+ "and c.Name not like '%DO NOT USE%'"
				+ "and c.Class_Location__c not in ('Online') "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(c.Class_Begin_Date__c, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and c.IsDeleted = 0 "
				+ "group by `Stream`, `Metric`";
		
		return query;
	}
	
	private String getQueryAvgRevenuePublicSeat() {
		return getEmptyQuery("Avg Revenue per Registration (Public)", new String[] {"TIS"},"$",150, "Finance");
	}
	
	private String getQueryTrainerUtilisation() {
		return getEmptyQuery("FTE Trainers Utilisation", new String[] {"TIS"},"%",160, "Finance");
	}
	
	private String getQueryCustomerSatisfaction() {
		return getEmptyQuery("Customer Satisfaction", new String[] {"MS", "Food", "MS and Food"},"%",170, "Jess?");
	}
	
	private String getQueryOverdueNCRs() {
		return getEmptyQuery("No Of Overdue NCRs", new String[] {"General"},"#",180, "PRC (Alan?)");
	}
	
	private String getQueryNoOfDaysToIssueCertificateMsAndFood() {
		String query = "select 'MS and Food' as 'Stream', 'No Of Days to Issue Certificate' as 'Metric', '#' as 'Unit', 190 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",avg(if (date_format(t.`Completed`, '%Y %m') = '" + period + "', datediff(t.`Completed`, t.`End Last Audit`), null)) as '" + period + "'";
		}
		query += "from ("
				+ "select "
				+ "arg.id as 'ARG_Id',"
				+ "max(wi.End_Service_Date__c) as 'End Last Audit',"
				+ "(arg.Admin_Closed__c) as 'Completed' "
				+ "from audit_report_group__c arg "
				+ "inner join arg_work_item__c argwi on arg.id = argwi.RAudit_Report_Group__c "
				+ "inner join work_item__c wi on wi.Id = argwi.RWork_Item__c "
				+ "where arg.Client_Ownership__c in ('Australia') "
				+ "and arg.IsDeleted = 0 "
				+ "and wi.IsDeleted = 0 "
				+ "and wi.Status__c not in ('Cancelled') "
				+ "and arg.Hold_Reason__c is null "
				+ "group by arg.id) t "
				+ "where date_format(t.`Completed`, '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(t.`Completed`, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and t.`End Last Audit` is not null";
		return query;
	}
	
	private String getQueryNoOfDaysToIssueCertificate() {
		String query = "select if(t.`Revenue Ownerships` like '%Food%', 'Food', 'MS') as 'Stream', 'No Of Days to Issue Certificate' as 'Metric', '#' as 'Unit', 190 as 'index', 'Auto Generated' as 'Responsibility'";
		for (String period : periods) {
			query += ",avg(if (date_format(t.`Completed`, '%Y %m') = '" + period + "', datediff(t.`Completed`, t.`End Last Audit`), null)) as '" + period + "'";
		}
		query += "from ("
				+ "select "
				+ "arg.id as 'ARG_Id',"
				+ "max(wi.End_Service_Date__c) as 'End Last Audit',"
				+ "group_concat(wi.Revenue_Ownership__c) as 'Revenue Ownerships',"
				+ "(arg.Admin_Closed__c) as 'Completed' "
				+ "from audit_report_group__c arg "
				+ "inner join arg_work_item__c argwi on arg.id = argwi.RAudit_Report_Group__c "
				+ "inner join work_item__c wi on wi.Id = argwi.RWork_Item__c "
				+ "where arg.Client_Ownership__c in ('Australia') "
				+ "and arg.IsDeleted = 0 "
				+ "and wi.IsDeleted = 0 "
				+ "and wi.Status__c not in ('Cancelled') "
				+ "and arg.Hold_Reason__c is null "
				+ "group by arg.id) t "
				+ "where date_format(t.`Completed`, '%Y %m') >= '" + periods[0] + "' "
				+ "and date_format(t.`Completed`, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
				+ "and t.`End Last Audit` is not null "
				+ "group by `Stream`, `Metric`";
		return query;
	}
	
	private String getEmptyQuery(String metric, String[] streams, String unit, int index, String responsibility) {
		String query = "select s.Name, '" + metric + "' as 'Metric', '" + unit + "' as 'Unit', " + index + " as 'index', '" + responsibility + "' as 'Responsibility'";
		for (String period : periods) {
			query += ", null as '" + period + "' ";
		}
		String streamsQuery = "";
		for (int i = 0; i < streams.length; i++) {
			if (i==streams.length-1)
				streamsQuery += "select '" + streams[i] + "' as 'Name'";
			else 
				streamsQuery += "select '" + streams[i] + "' as 'Name' union ";
		}
		query += " from (" + streamsQuery + ") s";
		return query;
	}
	
	@Override
	protected String getQuery() {
		String query = "select t.`Responsibility`, t.`Stream`, t.`Metric`, t.`Unit`, t.`" + StringUtils.join(periods,"`,t.`") + "` from ( "
				+ getQueryConfirmedAuditDays() 
				+ " union "
				+ getQueryConfirmedAuditDaysMSAndFood()
				+ " union "
				+ getQueryCustomerRevenueRetainedAudit()
				+ " union "
				+ getQueryCustomerRevenueRetainedAuditMsAndFood()
				+ " union "
				+ getQueryCustomerAnnualisedLossAudits()
				+ " union "
				+ getQueryCustomerAnnualisedLossAuditsMsAndFood()
				+ " union "
				+ getQueryCustomerRevenueLostAudits()
				+ " union "
				+ getQueryCustomerRevenueLostAuditsMsAndFood()
				+ " union "
				+ getQueryAvgUnitAuditPrice()
				+ " union "
				+ getQueryNewBusinessAudit()
				+ " union "
				+ getQueryNewBusinessFees()
				+ " union "
				+ getQueryNewBusinessAuditMsAndFood()
				+ " union "
				+ getQueryNewBusinessFeesMsAndFood()
				+ " union "
				+ getQueryUnitPriceQuoted()
				+ " union "
				+ getQueryUnitPriceQuotedMsAndFood()
				+ " union "
				+ getQueryFteUtilisation()
				+ " union "
				+ getQueryContractUnitCost()
				+ " union "
				+ getQueryFteUnitCost()
				+ " union "
				+ getQueryTravelRecovery()
				+ " union "
				+ getQueryNoOfPublicSeats()
				+ " union "
				+ getQueryNoOfPublicClasses()
				+ " union "
				+ getQueryAvgClassSize()
				+ " union "
				+ getQueryPublicCourseRunRate()
				+ " union "
				+ getQueryAvgRevenuePublicSeat()
				+ " union "
				+ getQueryTrainerUtilisation()
				+ " union "
				+ getQueryCustomerSatisfaction()
				+ " union "
				+ getQueryOverdueNCRs()
				+ " union "
				+ getQueryNoOfDaysToIssueCertificate()
				+ " union "
				+ getQueryNoOfDaysToIssueCertificateMsAndFood()
				+ ") t order by FIELD(`Stream`,'MS and Food', 'Food', 'MS', 'TIS', 'General'), t.`index`";
		return query;
	}

	@Override
	protected String getReportName() {
		
		return "Opex\\AssuranceGlobalMetrics\\AssuranceGlobalMetrics.Australia";
	}
	
	private static String[] getPeriods() {
		String[] returnValue = new String[periodsToReport];
		Calendar aux = Calendar.getInstance();
		aux.setTime(startFy.getTime());
		for(int i=0; i<periodsToReport; i++) {
			returnValue[i] = periodFormatter.format(aux.getTime());
			aux.add(Calendar.MONTH, 1);
		}
		
		return returnValue;
	}

}
