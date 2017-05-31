package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.Utility;

public class AssuranceGlobalMetricsMultiRegion extends AbstractQueryReport {

	private static final Calendar startFy;
	private static final Calendar endFy;
	private static final Calendar startPreviousFy;
	private static final Calendar endPreviousFy;
	private static final int periodsToReport;
	private static final String[] periods;
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	private Region[] regions;
	private boolean expandRegions = false;
	
	public AssuranceGlobalMetricsMultiRegion() {
		this.numericPattern = "#,###,###.0000";
		this.columnWidth = new int[] {150,80,220,50,80,80,80,80,80,80,80,80,80,80,80,80};
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
		//startFy.set(2014, Calendar.JULY, 1);
		//endFy.set(2015, Calendar.JUNE, 30);
		// End Manual override
		
		startPreviousFy.setTime(startFy.getTime());
		startPreviousFy.add(Calendar.YEAR, -1);
		endPreviousFy.setTime(endFy.getTime());
		endPreviousFy.add(Calendar.YEAR, -1);
		
		periodsToReport = 12; // Full Financial Year
		periods = getPeriods();
	}
	
	private String getQueryConfirmedAuditDays() {
		String query = "";
		for (Region region : regions) {
			query += getQueryConfirmedAuditDays(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryConfirmedAuditDays(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			String regionWhere = " Region in ('" + StringUtils.join(region.getNames(), "', '") + "') ";
			query += "select '" + region.getName() + "' as 'DisplayRegion', "
					+ "if(RowName like 'Food%', 'Food', if(RowName like 'Product%', 'PS','MS')) as 'DisplayStream',"
					+ "'Confirmed Audit Days' as 'Metric', 'Days' as 'Unit', 10 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(ColumnName='" + period + "',Value, null)) as '" + period + "' ";
			}
			query += "from sf_report_history "
					+ "where ReportName = 'Audit Days Snapshot' "
					+ "and " + regionWhere
					+ "and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and " + regionWhere + ") "
					+ "and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support') "
					+ "and ColumnName >= '" + periods[0] + "' and ColumnName <= '" + periods[periodsToReport-1] + "' "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryConfirmedAuditDays(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryConfirmedAuditDaysMSAndFood() {
		String query = "";
		for (Region region : regions) {
			query += getQueryConfirmedAuditDaysMSAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryConfirmedAuditDaysMSAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			String regionWhere = " Region in ('" + StringUtils.join(region.getNames(), "', '") + "') ";
			query += "select '" + region.getName() + "' as 'DisplayRegion', "
					+ "'MS and Food' as 'DisplayStream',"
					+ "'Confirmed Audit Days' as 'Metric', 'Days' as 'Unit', 10 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(ColumnName='" + period + "',Value, null)) as '" + period + "' ";
			}
			query += "from sf_report_history "
					+ "where ReportName = 'Audit Days Snapshot' "
					+ "and " + regionWhere
					+ "and Date = (select max(Date) from sf_report_history where ReportName = 'Audit Days Snapshot' and " + regionWhere + ") "
					+ "and (RowName like 'Food%' or RowName like 'MS%') "
					+ "and (RowName like '%Confirmed' or RowName like '%In Progress' or RowName like '%Complete%' or RowName like '%Under Review%' or RowName like '%Submitted' or RowName like '%Support') "
					+ "and ColumnName >= '" + periods[0] + "' and ColumnName <= '" + periods[periodsToReport-1] + "' "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryConfirmedAuditDaysMSAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostAudits() {
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueLostAudits(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryCustomerRevenueLostAudits(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhere = " lbr.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', lbr.`Stream` as 'DisplayStream', 'Customer Revenue Lost (Audits)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"lbr.CurrencyIsoCode") + " as 'CurrencyUnit', 30 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`" + (region.isMultiCurrency()?"/ct.ConversionRate":"") + ", null)) as '" + period + "' ";
			}
			query += "from lost_business_revenue_multi_region lbr "
					+ (region.isMultiCurrency()?"left join currencytype ct on lbr.CurrencyIsoCode = ct.IsoCode ":"")
					+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
					+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
					+ "and " + regionWhere
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueLostAudits(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostAuditsMSAndFood() {
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueLostAuditsMSAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostAuditsMSAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhere = " lbr.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', "
					+ "'MS and Food' as 'DisplayStream',"
					+ "'Customer Revenue Lost (Audits)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"lbr.CurrencyIsoCode") + " as 'CurrencyUnit', 30 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`" + (region.isMultiCurrency()?"/ct.ConversionRate":"") + ", null)) as '" + period + "' ";
			}
			query += "from lost_business_revenue_multi_region lbr "
					+ (region.isMultiCurrency()?"left join currencytype ct on lbr.CurrencyIsoCode = ct.IsoCode ":"")
					+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
					+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
					+ "and " + regionWhere
					+ "and lbr.`Stream` in ('MS', 'Food') "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueLostAuditsMSAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostFees() {
		//return getEmptyQuery("Customer Revenue Lost (Fees)", new String[] {"MS", "Food", "MS and Food"},"$",35, "Auto Generated");
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueLostFees(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostFees(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhere = " dscs.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', dscs.`Stream` as 'DisplayStream', 'Customer Revenue Lost (Fee)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"dscs.CurrencyIsoCode") + " as 'CurrencyUnit', 35 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(date_format(dscs.`DeRegistered Date`, '%Y %m')='" + period + "', dscs.`EffectivePrice`" + (region.isMultiCurrency()?"/ct.ConversionRate":"") + ", null)) as '" + period + "' ";
			}
			query += "from deregistered_site_cert_standard_with_effective_price_mr dscs "
					+ (region.isMultiCurrency()?"left join currencytype ct on dscs.CurrencyIsoCode = ct.IsoCode ":"")
					+ "where date_format(dscs.`DeRegistered Date`, '%Y %m')>='" + periods[0] + "' "
					+ "and date_format(dscs.`DeRegistered Date`, '%Y %m')<='" + periods[periodsToReport-1] + "' "
					+ "and " + regionWhere
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueLostFees(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostFeesMSAndFood() {
		//return getEmptyQuery("Customer Revenue Lost (Fees)", new String[] {"MS", "Food", "MS and Food"},"$",35, "Auto Generated");
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueLostFeesMSAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryCustomerRevenueLostFeesMSAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhere = " dscs.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', 'MS and Food' as 'DisplayStream', 'Customer Revenue Lost (Fee)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"dscs.CurrencyIsoCode") + " as 'CurrencyUnit', 35 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", sum(if(date_format(dscs.`DeRegistered Date`, '%Y %m')='" + period + "', dscs.`EffectivePrice`" + (region.isMultiCurrency()?"/ct.ConversionRate":"") + ", null)) as '" + period + "' ";
			}
			query += "from deregistered_site_cert_standard_with_effective_price_mr dscs "
					+ (region.isMultiCurrency()?"left join currencytype ct on dscs.CurrencyIsoCode = ct.IsoCode ":"")
					+ "where date_format(dscs.`DeRegistered Date`, '%Y %m')>='" + periods[0] + "' "
					+ "and date_format(dscs.`DeRegistered Date`, '%Y %m')<='" + periods[periodsToReport-1] + "' "
					+ "and " + regionWhere
					+ "and dscs.`Stream` in ('MS', 'Food') "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueLostFeesMSAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryCustomerRevenueRetainedAudit() {
		//return getEmptyQuery("% Customer Revenue Retained (Audit)", new String[] {"MS", "Food"},"%",25, "TODO (Waiting for Finance PS Data");
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueRetainedAudit(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryCustomerRevenueRetainedAudit(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhereSub = " `Region` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			String regionWhere = " lbr.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', lbr.`Stream` as 'DisplayStream', '% Customer Revenue Retained (Audits)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"lbr.CurrencyIsoCode") + " as 'CurrencyUnit', 20 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", 1-sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS', "
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
						+ "if( lbr.`Stream`='Food'," 
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'PS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') "
						+ ")) as '" + period + "' ";
				
			}
			query += "from lost_business_revenue_multi_region lbr "
					+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
					+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
					+ "and " + regionWhere
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueRetainedAudit(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryCustomerRevenueRetainedAuditMsAndFood() {
		//return getEmptyQuery("% Customer Revenue Retained (Audit)", new String[] {"MS", "Food"},"%",25, "TODO (Waiting for Finance PS Data");
		String query = "";
		for (Region region : regions) {
			query += getQueryCustomerRevenueRetainedAuditMsAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryCustomerRevenueRetainedAuditMsAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			
			String regionWhereSub = " `Region` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			String regionWhere = " lbr.`Revenue_Ownership__c` in ('" + StringUtils.join(region.getRevenueOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', 'MS and Food' as 'DisplayStream', '% Customer Revenue Retained (Audits)' as 'Metric', " + (region.isMultiCurrency()?"'AUD'":"lbr.CurrencyIsoCode") + " as 'CurrencyUnit', 20 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ", 1-sum(if(lbr.`Cancelled Period`='" + period + "', lbr.`Quantity`*lbr.`EffectivePrice`, null))/if( lbr.`Stream`='MS', "
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
						+ "if( lbr.`Stream`='Food'," 
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'), "
						+ "(select sum(RefValue) from sf_data where " + regionWhereSub + " and DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'PS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "') "
						+ ")) as '" + period + "' ";
				
			}
			query += "from lost_business_revenue_multi_region lbr "
					+ "where lbr.`Cancelled Period`>='" + periods[0] + "' "
					+ "and lbr.`Cancelled Period`<='" + periods[periodsToReport-1] + "' "
					+ "and lbr.`Stream` not in ('PS')"
					+ "and " + regionWhere
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `CurrencyUnit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryCustomerRevenueRetainedAuditMsAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryCustomerRevenueRetainedAuditPlusFees() {
		return getEmptyQuery("% Customer Revenue Retained (Audit and Fees)", new String[] {"MS", "Food", "MS and Food"},"%",25, "TODO (Waiting for Finance PS Data");
	}
	
	@SuppressWarnings("unused")
	private String getQueryAvgUnitAuditPrice() {
		return getEmptyQuery("Avg Audit Day Price", new String[] {"MS", "Food", "MS and Food"},"$",40, "Finance");
	}
	
	private String getQueryNewBusiness() {
		String query = "";
		for (Region region : regions) {
			query += getQueryNewBusiness(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryNewBusiness(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " o.`Business_1__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', if (pg.Business_Line__c like '%Food%', 'Food', if (pg.Business_Line__c like '%Product%','PS','MS')) as 'DisplayStream', if(oli.Days__c=0, 'New Business Won (Fees)', 'New Business Won (Audits)') as 'metric', t.CurrencyIsoCode as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
			}
			query += "from ("
							+ "select "
							+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
							+ "o.CurrencyIsoCode, "
							+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
							+ "from opportunity o "
							+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
							+ "where "
							+ "o.IsDeleted = 0 "
							+ "and " + regionWhere
							+ "and o.StageName='Closed Won' "
							+ "and oh.Field = 'StageName' "
							+ "and oh.NewValue = 'Closed Won' "
							+ "and o.Status__c = 'Active'"
							+ "group by o.Id) t "
							+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
							+ "left join standard__c s on oli.Standard__c = s.Id "
							+ "left join program__c pg on s.Program__c = pg.Id "
							+ "where oli.IsDeleted = 0 "
							+ "and oli.First_Year_Revenue__c = 1 "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryNewBusiness(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryNewBusinessMSAndFood() {
		String query = "";
		for (Region region : regions) {
			query += getQueryNewBusinessMSAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryNewBusinessMSAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " o.`Business_1__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', 'MS And Food' as 'DisplayStream', if(oli.Days__c=0, 'New Business Won (Fees)', 'New Business Won (Audits)') as 'metric', t.CurrencyIsoCode as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null)) as '" + period + "'";
			}
			query += "from ("
							+ "select "
							+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
							+ "o.CurrencyIsoCode, "
							+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
							+ "from opportunity o "
							+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
							+ "where "
							+ "o.IsDeleted = 0 "
							+ "and " + regionWhere
							+ "and o.StageName='Closed Won' "
							+ "and oh.Field = 'StageName' "
							+ "and oh.NewValue = 'Closed Won' "
							+ "and o.Status__c = 'Active'"
							+ "group by o.Id) t "
							+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
							+ "left join standard__c s on oli.Standard__c = s.Id "
							+ "left join program__c pg on s.Program__c = pg.Id "
							+ "where pg.Business_Line__c not like '%Product%' "
							+ "and oli.IsDeleted = 0 "
							+ "and oli.First_Year_Revenue__c = 1 "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryNewBusinessMSAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryUnitPriceQuoted() {
		String query = "";
		for (Region region : regions) {
			query += getQueryUnitPriceQuoted(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryUnitPriceQuoted(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " o.`Business_1__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', if (pg.Business_Line__c like '%Food%', 'Food', if (pg.Business_Line__c like '%Product%','PS','MS')) as 'DisplayStream', 'Avg Audit Day Price Quoted' as 'metric', t.CurrencyIsoCode as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				// TODO: Hack for Product Service
				query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null))/sum(if(t.WonPeriod = '" + period + "', oli.Days__c, null)) as '" + period + "'";
			}
			query += "from ("
							+ "select "
							+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
							+ "o.CurrencyIsoCode, "
							+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
							+ "from opportunity o "
							+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
							+ "where "
							+ "o.IsDeleted = 0 "
							+ "and " + regionWhere
							+ "and o.StageName='Closed Won' "
							+ "and oh.Field = 'StageName' "
							+ "and oh.NewValue = 'Closed Won' "
							+ "and o.Status__c = 'Active'"
							+ "group by o.Id) t "
							+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
							+ "left join standard__c s on oli.Standard__c = s.Id "
							+ "left join program__c pg on s.Program__c = pg.Id "
							+ "where oli.Days__c>0 "
							+ "and oli.IsDeleted = 0 "
							+ "and oli.First_Year_Revenue__c = 1 "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryUnitPriceQuoted(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryUnitPriceQuotedMsAndFood() {
		String query = "";
		for (Region region : regions) {
			query += getQueryUnitPriceQuotedMsAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	private String getQueryUnitPriceQuotedMsAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " o.`Business_1__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', 'MS And Food' as 'DisplayStream', 'Avg Audit Day Price Quoted' as 'metric', t.CurrencyIsoCode as 'Unit', 60 as 'index', 'Auto Generated' as 'Responsibility'";
			for (String period : periods) {
				query += ",sum(if(t.`WonPeriod` = '" + period + "', oli.TotalPrice, null))/sum(if(t.WonPeriod = '" + period + "', oli.Days__c, null)) as '" + period + "'";
			}
			query += "from ("
							+ "select "
							+ "if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '" + periods[0] + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '" + periods[periodsToReport-1] + "', o.Id,null) as 'Opp Id', "
							+ "o.CurrencyIsoCode, "
							+ "date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' "
							+ "from opportunity o "
							+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
							+ "where "
							+ "o.IsDeleted = 0 "
							+ "and " + regionWhere
							+ "and o.StageName='Closed Won' "
							+ "and oh.Field = 'StageName' "
							+ "and oh.NewValue = 'Closed Won' "
							+ "and o.Status__c = 'Active'"
							+ "group by o.Id) t "
							+ "left join opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` "
							+ "left join standard__c s on oli.Standard__c = s.Id "
							+ "left join program__c pg on s.Program__c = pg.Id "
							+ "where pg.Business_Line__c not like '%Product%' "
							+ "and oli.Days__c>0 "
							+ "and oli.IsDeleted = 0 "
							+ "and oli.First_Year_Revenue__c = 1 "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryUnitPriceQuotedMsAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryFteUtilisation() {
		String query = "";
		for (Region region : regions) {
			query += getQueryFteUtilisation(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryFteUtilisation(Region region, boolean expand) {
		String query = "";
		//if (!expand || region.subRegions == null || region.subRegions.size()==0) {
		
			query = "select ";
					if (expand) {
						query += "Region as 'DisplayRegion', ";
					} else {
						query += "'" + region.getName() + "' as 'DisplayRegion', ";
					}
					query += "if (RowName like 'Food%', 'Food', if(RowName like 'MS%', 'MS', 'MS and Food')) as 'DisplayStream', "
					+ "'FTE Auditor Utilisation' as 'metric', '%' as 'Unit', 70 as 'index', 'Auto Generated' as 'Responsibility'";
			String regionWhere = " Region in ('" + StringUtils.join(region.getNames(), "', '") + "') ";
			for (String period : periods) {
				query += ", sum(if(ColumnName='" + period + "', Value, null)) as '" + period + "'";
			}
			query += " from ("
					+ "select "
					+ "t.* from ("
					+ "select * from sf_report_history "
					+ "where "
					+ regionWhere
					+ "and ReportName='Scheduling Auditors Metrics' "
					+ "and ColumnName >= '" + periods[0] + "' "
					+ "and ColumnName <= '" + periods[periodsToReport-1] + "' "
					+ "and RowName like '%Utilisation' "
					+ "order by Date desc) t "
					+ "group by Region,ColumnName,RowName) t2 "
					+ "group by Region,RowName";
		//} else {
		//	for (int i=0; i<region.subRegions.size(); i++) {
		//		query += getQueryFteUtilisation(region.subRegions.get(i), expand) + " UNION ";
		//	}
		//}
		
		
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
	
	@SuppressWarnings("unused")
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
				+ "group by `Stream`, `Metric`, `Unit`";
		
		return query;
	}
	
	@SuppressWarnings("unused")
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
				+ "group by `Stream`, `Metric`, `Unit`";
		
		return query;
	}
	
	@SuppressWarnings("unused")
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
				+ "group by `Stream`, `Metric`, `Unit`";
		
		return query;
	}
	
	@SuppressWarnings("unused")
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
				+ "group by `Stream`, `Metric`, `Unit`";
		
		return query;
	}
	
	@SuppressWarnings("unused")
	private String getQueryAvgRevenuePublicSeat() {
		return getEmptyQuery("Avg Revenue per Registration (Public)", new String[] {"TIS"},"$",150, "Finance");
	}
	
	@SuppressWarnings("unused")
	private String getQueryTrainerUtilisation() {
		return getEmptyQuery("FTE Trainers Utilisation", new String[] {"TIS"},"%",160, "Finance");
	}
	
	private String getQueryCustomerSatisfaction() {
		return getEmptyQuery("Customer Satisfaction", new String[] {"MS", "Food", "MS and Food"},"%",170, "Jess?");
	}
	
	private String getQueryOverdueNCRs() {
		return getEmptyQuery("No Of Overdue NCRs", new String[] {"General"},"#",180, "PRC (Alan?)");
	}
	
	
	private String getQueryNoOfDaysToIssueCertificate() {
		String query = "";
		for (Region region : regions) {
			query += getQueryNoOfDaysToIssueCertificate(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryNoOfDaysToIssueCertificate(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " arg.`Client_Ownership__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', if(t.`Revenue Ownerships` like '%Food%', 'Food', if(t.`Revenue Ownerships` like '%Product%','PS','MS')) as 'DisplayStream', 'No Of Days to Issue Certificate' as 'Metric', '#' as 'Unit', 190 as 'index', 'Auto Generated' as 'Responsibility'";
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
					+ "where " + regionWhere
					+ "and arg.IsDeleted = 0 "
					+ "and wi.IsDeleted = 0 "
					+ "and wi.Status__c not in ('Cancelled') "
					+ "and arg.Hold_Reason__c is null "
					+ "group by arg.id) t "
					+ "where date_format(t.`Completed`, '%Y %m') >= '" + periods[0] + "' "
					+ "and date_format(t.`Completed`, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
					+ "and t.`End Last Audit` is not null "
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";

		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryNoOfDaysToIssueCertificate(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getQueryNoOfDaysToIssueCertificateMsAndFood() {
		String query = "";
		for (Region region : regions) {
			query += getQueryNoOfDaysToIssueCertificateMsAndFood(region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		logger.info(query);
		return query;
	}
	
	private String getQueryNoOfDaysToIssueCertificateMsAndFood(Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {			
			String regionWhere = " arg.`Client_Ownership__c` in ('" + StringUtils.join(region.getClientOwnerships(), "', '") + "') ";
			query = "select '" + region.getName() + "' as 'DisplayRegion', 'MS and Food' as 'DisplayStream', 'No Of Days to Issue Certificate' as 'Metric', '#' as 'Unit', 190 as 'index', 'Auto Generated' as 'Responsibility'";
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
					+ "where " + regionWhere
					+ "and arg.IsDeleted = 0 "
					+ "and wi.IsDeleted = 0 "
					+ "and wi.Status__c not in ('Cancelled') "
					+ "and arg.Hold_Reason__c is null "
					+ "group by arg.id) t "
					+ "where date_format(t.`Completed`, '%Y %m') >= '" + periods[0] + "' "
					+ "and date_format(t.`Completed`, '%Y %m') <= '" + periods[periodsToReport-1] + "' "
					+ "and t.`End Last Audit` is not null "
					+ "and t.`Revenue Ownerships` not like '%Product%'"
					+ "group by `DisplayRegion`, `DisplayStream`, `Metric`, `Unit`" + " UNION ";

		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getQueryNoOfDaysToIssueCertificateMsAndFood(region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	private String getEmptyQuery(String metric, String[] streams, String unit, int index, String responsibility) {
		String query = "";
		for (Region region : regions) {
			query += getEmptyQuery(metric, streams, unit, index, responsibility, region, expandRegions) + " UNION ";
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;	
	}
	
	private String getEmptyQuery(String metric, String[] streams, String unit, int index, String responsibility, Region region, boolean expand) {
		String query = "";
		if (!expand || region.subRegions == null || region.subRegions.size()==0) {
			query = "select '" + region.getName() + "' as 'DisplayRegion', s.Name as 'DisplayStream', '" + metric + "' as 'Metric', '" + unit + "' as 'Unit', " + index + " as 'index', '" + responsibility + "' as 'Responsibility'";
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
			query += " from (" + streamsQuery + ") s" + " UNION ";
		} else {
			for (int i=0; i<region.subRegions.size(); i++) {
				query += getEmptyQuery(metric, streams, unit, index, responsibility, region.subRegions.get(i), expand) + " UNION ";
			}
		}
		query += ";";
		query = query.replaceAll(" UNION ;", "");
		return query;
	}
	
	@Override
	protected void initialiseQuery() {
		if (gp.getCustomParameter("regions") == null) {
			regions = new Region[] {Region.AUSTRALIA_MS_AND_FOOD};
		} else {
			String[] regionsStrings = gp.getCustomParameter("regions").split(",");
			regions = new Region[regionsStrings.length];
			for (int i=0; i<regionsStrings.length; i++) {
				regions[i] = Region.valueOf(regionsStrings[i]);
			}
		}
		
		if (gp.getCustomParameter("expandRegions") != null && gp.getCustomParameter("expandRegions").equalsIgnoreCase("true")) {
			expandRegions = true;
		}
		
		try {
			db.executeStatement("LOCK TABLES sf_lost_business_audits_multi_region WRITE, lost_business_audits_multi_region_v2 WRITE;");
			db.executeStatement("TRUNCATE sf_lost_business_audits_multi_region;");
			db.executeStatement("INSERT INTO sf_lost_business_audits_multi_region SELECT * FROM lost_business_audits_multi_region_v2;");
			db.executeStatement("UNLOCK TABLES;");
		} catch (Exception e) {
			Utility.handleError(gp, e);
		}
	}
	
	@Override
	protected String getQuery() {
		String query = "select t.`DisplayRegion` as 'Region', t.`DisplayStream` as 'Stream', t.`Metric`, t.`Unit`, t.`" + StringUtils.join(periods,"`,t.`") + "` from ( "
				+ getQueryFteUtilisation()
				+ " union "
				+ getQueryConfirmedAuditDays() 
				+ " union "
				+ getQueryConfirmedAuditDaysMSAndFood()
				+ " union "
				//+ getQueryCustomerRevenueRetainedAudit()
				//+ " union "
				//+ getQueryCustomerRevenueRetainedAuditMsAndFood()
				//+ " union "
				//+ getQueryCustomerRevenueRetainedAuditPlusFees()
				//+ " union "
				+ getQueryCustomerRevenueLostAudits()
				+ " union "
				+ getQueryCustomerRevenueLostAuditsMSAndFood()
				+ " union "
				+ getQueryCustomerRevenueLostFees()
				+ " union "
				+ getQueryCustomerRevenueLostFeesMSAndFood()
				+ " union "
				//+ getQueryAvgUnitAuditPrice()
				//+ " union "
				+ getQueryNewBusiness()
				+ " union "
				+ getQueryNewBusinessMSAndFood()
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
				//+ getQueryNoOfPublicSeats()
				//+ " union "
				//+ getQueryNoOfPublicClasses()
				//+ " union "
				//+ getQueryAvgClassSize()
				//+ " union "
				//+ getQueryPublicCourseRunRate()
				//+ " union "
				//+ getQueryAvgRevenuePublicSeat()
				//+ " union "
				//+ getQueryTrainerUtilisation()
				//+ " union "
				+ getQueryCustomerSatisfaction()
				+ " union "
				+ getQueryOverdueNCRs()
				+ " union "
				+ getQueryNoOfDaysToIssueCertificate()
				+ " union "
				+ getQueryNoOfDaysToIssueCertificateMsAndFood()
				+ ") t order by `Region`, FIELD(`Stream`,'MS and Food', 'Food', 'MS', 'PS', 'TIS', 'General'), t.`index`";
				
		System.out.println(query);
		return query;
	}

	@Override
	protected String getReportName() {
		
		return "Opex\\AssuranceGlobalMetrics\\AssuranceGlobalMetrics." + StringUtils.join(regions,".").toLowerCase();
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
