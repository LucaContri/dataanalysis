package com.saiglobal.reporting.utility;

import java.math.RoundingMode;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.Semaphore;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.reporting.model.DailyStats;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.Utility;

public class DailyStatsCache {
	private static HashMap<Region, DailyStatsCache> reference= new HashMap<Region, DailyStatsCache>();
	private static final int refreshAuditDaysIntervalHrs = 23;
	private static final int refreshSalesIntervalHrs = 23;
	private static final int refreshTISIntervalHrs = 23;
	private int noOfMonths = 6;
	private DbHelper db_certification = null;
	private DbHelper db_tis = null;
	private DailyStats data;
	private Semaphore updateDays = new Semaphore(1);
	private Semaphore updateSales = new Semaphore(1);
	private Semaphore updateTis = new Semaphore(1);
	private static final SimpleDateFormat dateTimeFormat = new SimpleDateFormat("dd/MM/yyyy - HH:mm:ss");
	private static final SimpleDateFormat displayDateTimeFormat = new SimpleDateFormat("dd MMM yy @ HH:mm");
	private static final SimpleDateFormat periodFormat = new SimpleDateFormat("yyyy MM");
	private static final SimpleDateFormat displayPeriodFormat = new SimpleDateFormat("MMM yy");
	private static final SimpleDateFormat displayMonthFormat = new SimpleDateFormat("MMMM");
	private static final NumberFormat df = DecimalFormat.getInstance();
	
	private static final String[] daySuffixes =
	  //    0     1     2     3     4     5     6     7     8     9
	     { "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th",
	  //    10    11    12    13    14    15    16    17    18    19
	       "th", "th", "th", "th", "th", "th", "th", "th", "th", "th",
	  //    20    21    22    23    24    25    26    27    28    29
	       "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th",
	  //    30    31
	       "th", "st" };
	
	private DailyStatsCache(DbHelper db_certification, DbHelper db_tis, Region region) {
		this.db_certification = db_certification;
		this.db_tis = db_tis;
		data = new DailyStats(region);
		df.setMinimumFractionDigits(2);
		df.setMaximumFractionDigits(2);
		df.setRoundingMode(RoundingMode.HALF_UP);
	}

	public static DailyStatsCache getInstance(DbHelper db_certification, DbHelper db_tis, Region region) {
		if (region == null) {
			return null;
		}
		if( reference == null) {
			reference = new HashMap<Region, DailyStatsCache>();
		}
		if (!reference.containsKey(region)) {
			synchronized (  DailyStatsCache.class) {
			  	reference.put(region, new DailyStatsCache(db_certification, db_tis, region));
			}
		}
		return  reference.get(region);
	}

	public DailyStats getAllDataArray(boolean forceRefresh, int monthsToReport) throws Exception {
		if (noOfMonths != monthsToReport)
			forceRefresh = true;
		noOfMonths = monthsToReport;
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshAuditDaysIntervalHrs);
		
		try {
			updateDays.acquire();
			if(data.region.isEnabled() && data.region.reportAuditDays() && (data.lastUpdateReportDate == null || data.lastUpdateReportDate.before(intervalBefore) || forceRefresh)) {
					updateAuditDays(); 
			}
		} catch (Exception e) {
			throw e;
		} finally {
			updateDays.release();
		}
		
		intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshSalesIntervalHrs);

		try {
			updateSales.acquire();
			if(data.region.isEnabled() && data.region.reportOpportunities() && (data.lastUpdateSalesDate == null || data.lastUpdateSalesDate.before(intervalBefore) || forceRefresh) && hasSalesData()) {
				updateSalesData();
				//updateNetOpportunities();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			updateSales.release();
		}
		
		intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshTISIntervalHrs);
		
		try {
			updateTis.acquire();
			if(data.region.isEnabled() && data.region.reportTraining() && (data.lastUpdateTISDate == null || data.lastUpdateTISDate.before(intervalBefore) || forceRefresh)) {
					updateTisData();	
			}
		} catch (Exception e) {
			throw e;
		} finally {
			updateTis.release();
		}
		
		return data;
	}
	
	private void updateChangesDays() throws Exception {
		// Changes since yesterday
		Calendar yesterdayReportDate = getYesterdayReportDate(data.lastUpdateReportDate);
		Calendar weekStartReportDate = getBeginOfWeekReportDate(data.lastUpdateReportDate);
		Calendar monthStartReportDate = getBeginOfMonthReportDate(data.lastUpdateReportDate);
		if ((yesterdayReportDate == null) || (weekStartReportDate == null) || (monthStartReportDate == null))
			return;
		Object[][][] yesterdayData = getAuditDaysbyReportDate(yesterdayReportDate, true, false);
		Object[][][] weekStartData = getAuditDaysbyReportDate(weekStartReportDate, true, false);
		Object[][][] monthStartData = getAuditDaysbyReportDate(monthStartReportDate, true, false);
		
		data.msAuditDaysChangesDailyTableData = new Object[noOfMonths+1][5];
		data.foodAuditDaysChangesDailyTableData = new Object[noOfMonths+1][5];
		data.msAuditDaysChangesWeeklyTableData= new Object[noOfMonths+1][5];
		data.foodAuditDaysChangesWeeklyTableData = new Object[noOfMonths+1][5];
		data.msAuditDaysChangesMonthlyTableData = new Object[noOfMonths+1][5];
		data.foodAuditDaysChangesMonthlyTableData = new Object[noOfMonths+1][5];
		
		// headers
		data.msAuditDaysChangesDailyTableData[0] = yesterdayData[0][0];
		data.foodAuditDaysChangesDailyTableData[0] = yesterdayData[1][0];
		data.msAuditDaysChangesWeeklyTableData[0] = weekStartData[0][0];
		data.foodAuditDaysChangesWeeklyTableData[0] = weekStartData[1][0];
		data.msAuditDaysChangesMonthlyTableData[0] = monthStartData[0][0];
		data.foodAuditDaysChangesMonthlyTableData[0] = monthStartData[1][0];
		data.msAuditDaysChangesDailyTableData[0][0] = data.foodAuditDaysChangesDailyTableData[0][0] = 
				data.msAuditDaysChangesWeeklyTableData[0][0] = data.foodAuditDaysChangesWeeklyTableData[0][0] = 
				data.msAuditDaysChangesMonthlyTableData[0][0] = data.foodAuditDaysChangesMonthlyTableData[0][0] = "Status";
		
		for (int i=1; i<data.msAuditDaysChartData.length; i++) {
			data.msAuditDaysChangesDailyTableData[i][0] = data.msAuditDaysChangesWeeklyTableData[i][0] = data.msAuditDaysChangesMonthlyTableData[i][0] = data.msAuditDaysChartData[i][0];
			data.foodAuditDaysChangesDailyTableData[i][0] = data.foodAuditDaysChangesWeeklyTableData[i][0] = data.foodAuditDaysChangesMonthlyTableData[i][0] = data.foodAuditDaysChartData[i][0];

			for (int j=1; j<data.msAuditDaysChartData[i].length-1; j++) {
				data.msAuditDaysChangesDailyTableData[i][j] = ((int) data.msAuditDaysChartData[i][j]) - ((int) yesterdayData[0][i][j]);
				data.foodAuditDaysChangesDailyTableData[i][j] = ((int) data.foodAuditDaysChartData[i][j]) - ((int) yesterdayData[1][i][j]);
				data.msAuditDaysChangesWeeklyTableData[i][j] = ((int) data.msAuditDaysChartData[i][j]) - ((int) weekStartData[0][i][j]);
				data.foodAuditDaysChangesWeeklyTableData[i][j] = ((int) data.foodAuditDaysChartData[i][j]) - ((int) weekStartData[1][i][j]);
				data.msAuditDaysChangesMonthlyTableData[i][j] = ((int) data.msAuditDaysChartData[i][j]) - ((int) monthStartData[0][i][j]);
				data.foodAuditDaysChangesMonthlyTableData[i][j] = ((int) data.foodAuditDaysChartData[i][j]) - ((int) monthStartData[1][i][j]);
			}
		}
		// Transpose matrixes for table visualisation
		data.msAuditDaysChangesDailyTableData = transposeMatrix(data.msAuditDaysChangesDailyTableData);		
		data.foodAuditDaysChangesDailyTableData = transposeMatrix(data.foodAuditDaysChangesDailyTableData);
		data.msAuditDaysChangesWeeklyTableData = transposeMatrix(data.msAuditDaysChangesWeeklyTableData);		
		data.foodAuditDaysChangesWeeklyTableData = transposeMatrix(data.foodAuditDaysChangesWeeklyTableData);
		data.msAuditDaysChangesMonthlyTableData = transposeMatrix(data.msAuditDaysChangesMonthlyTableData);		
		data.foodAuditDaysChangesMonthlyTableData = transposeMatrix(data.foodAuditDaysChangesMonthlyTableData);
		
		data.yesterdayReportDate = yesterdayReportDate;
		data.yesterdayReportDateText = displayDateTimeFormat.format(data.yesterdayReportDate.getTime());
		data.weekStartReportDate = weekStartReportDate;
		data.weekStartReportDateText = displayDateTimeFormat.format(data.weekStartReportDate.getTime());
		data.monthStartReportDate = monthStartReportDate;
		data.monthStartReportDateText = displayDateTimeFormat.format(data.monthStartReportDate.getTime());
	}
	
	private boolean hasSalesData() throws Exception {
		String query = "select count(Id) from opportunity where  Business_1__c in ('" + StringUtils.join(this.data.region.getClientOwnerships(), "', '") + "') ";
		return db_certification.executeScalarInt(query)>0;
		
	}
	
	@SuppressWarnings("unused")
	private void updateNetOpportunities() throws Exception {
		Calendar today = Calendar.getInstance();
		Calendar auxStart = Calendar.getInstance();
		//auxStart.set(2013, Calendar.JULY, 1);
		Calendar auxStop = Calendar.getInstance();
		if (auxStart.get(Calendar.MONTH)<Calendar.JULY) {
			auxStart.set(auxStart.get(Calendar.YEAR)-1, Calendar.JULY, 1);
			auxStop.set(auxStop.get(Calendar.YEAR), Calendar.JUNE, 30);
		} else {
			auxStart.set(auxStart.get(Calendar.YEAR), Calendar.JULY, 1);
			auxStop.set(auxStop.get(Calendar.YEAR)+1, Calendar.JUNE, 30);
		}
		
		data.netOpportunityChartData = getNetOpportunitiesForPeriod(auxStart, auxStop);
		data.netOpportunityTableData = new HashMap<String, Object[][]>();
		data.churnRatioTableData = new HashMap<String, Object[][]>();
		data.shrinkageRatioTableData = new HashMap<String, Object[][]>();
		
		data.netOpportunityTableData.put(DailyStats.MS, transposeMatrix(data.netOpportunityChartData.get(DailyStats.MS)));
		data.netOpportunityTableData.put(DailyStats.FOOD, transposeMatrix(data.netOpportunityChartData.get(DailyStats.FOOD)));
		data.netOpportunityTableData.put(DailyStats.MS_PLUS_FOOD, transposeMatrix(data.netOpportunityChartData.get(DailyStats.MS_PLUS_FOOD)));
		
		data.churnRatioTableData.put(DailyStats.MS, new Object[2][data.netOpportunityTableData.get(DailyStats.MS)[0].length]);
		data.churnRatioTableData.put(DailyStats.FOOD, new Object[2][data.netOpportunityTableData.get(DailyStats.FOOD)[0].length]);
		data.churnRatioTableData.put(DailyStats.MS_PLUS_FOOD, new Object[2][data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[0].length]);
		data.shrinkageRatioTableData.put(DailyStats.MS, new Object[2][data.netOpportunityTableData.get(DailyStats.MS)[0].length]);
		data.shrinkageRatioTableData.put(DailyStats.FOOD, new Object[2][data.netOpportunityTableData.get(DailyStats.FOOD)[0].length]);
		data.shrinkageRatioTableData.put(DailyStats.MS_PLUS_FOOD, new Object[2][data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[0].length]);
		
		data.churnRatioTableData.get(DailyStats.MS)[1][0] = "Churn Ratio";
		data.churnRatioTableData.get(DailyStats.FOOD)[1][0] = "Churn Ratio";
		data.churnRatioTableData.get(DailyStats.MS_PLUS_FOOD)[1][0] = "Churn Ratio";
		data.churnRatioTableData.get(DailyStats.MS)[0] = data.netOpportunityTableData.get(DailyStats.MS)[0];
		data.churnRatioTableData.get(DailyStats.FOOD)[0] = data.netOpportunityTableData.get(DailyStats.FOOD)[0];
		data.churnRatioTableData.get(DailyStats.MS_PLUS_FOOD)[0] = data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[0];
		data.shrinkageRatioTableData.get(DailyStats.MS)[1][0] = "Shrinkage Ratio";
		data.shrinkageRatioTableData.get(DailyStats.FOOD)[1][0] = "Shrinkage Ratio";
		data.shrinkageRatioTableData.get(DailyStats.MS_PLUS_FOOD)[1][0] = "Shrinkage Ratio";
		data.shrinkageRatioTableData.get(DailyStats.MS)[0] = data.netOpportunityTableData.get(DailyStats.MS)[0];
		data.shrinkageRatioTableData.get(DailyStats.FOOD)[0] = data.netOpportunityTableData.get(DailyStats.FOOD)[0];
		data.shrinkageRatioTableData.get(DailyStats.MS_PLUS_FOOD)[0] = data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[0];
		
		HashMap<String, Double> previousFyAuditRevenues = getPreviousYearAuditRevenues(auxStart);
		
		for (int j=1; j<data.netOpportunityTableData.get(DailyStats.MS)[0].length; j++) {
			data.churnRatioTableData.get(DailyStats.MS)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.MS)[3][j])/previousFyAuditRevenues.get(DailyStats.MS);
			data.churnRatioTableData.get(DailyStats.FOOD)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.FOOD)[3][j])/previousFyAuditRevenues.get(DailyStats.FOOD);
			data.churnRatioTableData.get(DailyStats.MS_PLUS_FOOD)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[3][j])/previousFyAuditRevenues.get(DailyStats.MS_PLUS_FOOD);
			data.shrinkageRatioTableData.get(DailyStats.MS)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.MS)[5][j]+(double)data.netOpportunityTableData.get(DailyStats.MS)[6][j])/previousFyAuditRevenues.get(DailyStats.MS);
			data.shrinkageRatioTableData.get(DailyStats.FOOD)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.FOOD)[5][j]+(double)data.netOpportunityTableData.get(DailyStats.FOOD)[6][j])/previousFyAuditRevenues.get(DailyStats.FOOD);
			data.shrinkageRatioTableData.get(DailyStats.MS_PLUS_FOOD)[1][j] = ((double)data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[5][j]+(double)data.netOpportunityTableData.get(DailyStats.MS_PLUS_FOOD)[6][j])/previousFyAuditRevenues.get(DailyStats.MS_PLUS_FOOD);
		}
		
		data.netOpportunitiesDate= today;
		data.netOpportunitiesDateText = displayDateTimeFormat.format(data.lastUpdateSalesDate.getTime());
	}
	
	private HashMap<String, Double> getPreviousYearAuditRevenues(Calendar auxStart) throws Exception {
		HashMap<String, Double> retValue = new HashMap<String, Double>();
		Calendar startPreviousFy = Calendar.getInstance();
		Calendar endPreviousFy = Calendar.getInstance();
		if (auxStart.get(Calendar.MONTH)<Calendar.JULY) {
			endPreviousFy.set(auxStart.get(Calendar.YEAR)-1,Calendar.JUNE,30);
			startPreviousFy.set(auxStart.get(Calendar.YEAR)-2,Calendar.JULY,1);
		} else {
			startPreviousFy.set(auxStart.get(Calendar.YEAR)-1,Calendar.JULY,1);
			endPreviousFy.set(auxStart.get(Calendar.YEAR),Calendar.JUNE,30);
		}
		
		retValue.put(DailyStats.MS, Double.parseDouble(db_certification.executeScalar("select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'")));
		retValue.put(DailyStats.FOOD, Double.parseDouble(db_certification.executeScalar("select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'")));
		retValue.put(DailyStats.MS_PLUS_FOOD, Double.parseDouble(db_certification.executeScalar("select sum(RefValue) from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName in ('MS', 'Food') and RefDate >= '" + Utility.getActivitydateformatter().format(startPreviousFy.getTime()) + "' and RefDate <= '" + Utility.getActivitydateformatter().format(endPreviousFy.getTime()) + "'")));
		
		return retValue;
	}
	
	private HashMap<String, Object[][]> getNetOpportunitiesForPeriod(Calendar startDate, Calendar endDate) throws Exception {
		HashMap<String, Object[][]> retValue = new HashMap<String, Object[][]>();
		Object[][] netOppDataMs = new Object[getPeriodsBetween(startDate, endDate).size()+1][6];
		netOppDataMs[0] = new Object[] {"Period", "New Business (Audits)","New Business (Fees)", "Lost Revenues (Audits)", "Lost Revenues (Fees)", "Shrinkage (Frequency)", "Shrinkage (Duration)", "Net Amount"};
		Object[][] netOppDataFood = new Object[getPeriodsBetween(startDate, endDate).size()+1][6];
		netOppDataFood[0] = new Object[] {"Period", "New Business (Audits)","New Business (Fees)", "Lost Revenues (Audits)", "Lost Revenues (Fees)", "Shrinkage (Frequency)", "Shrinkage (Duration)", "Net Amount"};
		Object[][] netOppDataMsAndFood = new Object[getPeriodsBetween(startDate, endDate).size()+1][6];
		netOppDataMsAndFood[0] = new Object[] {"Period", "New Business (Audits)","New Business (Fees)", "Lost Revenues (Audits)", "Lost Revenues (Fees)", "Shrinkage (Frequency)", "Shrinkage (Duration)", "Net Amount"};
		
		String query = "select t.Period,"
				+ "sum(if (t.`Type` = 'New Business Won (Audit)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - New Business Won (Audit)',"
				+ "sum(if (t.`Type` = 'New Business Won (Fees)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - New Business Won (Fees)',"
				+ "sum(if (t.`Type` = 'Revenue Lost (Audit)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - Revenue Lost (Audit)',"
				+ "sum(if (t.`Type` = 'Shrinkage (Frequency)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - Shrinkage (Frequency)',"
				+ "sum(if (t.`Type` = 'Shrinkage (Duration)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - Shrinkage (Duration)',"
				+ "sum(if (t.`Type` = 'Revenue Lost (Fees)' and t.`Stream`='MS', t.`Amount`, null)) as 'MS - Revenue Lost (Fees)',"
				+ "sum(if (t.`Type` = 'New Business Won (Audit)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - New Business Won (Audit)',"
				+ "sum(if (t.`Type` = 'New Business Won (Fees)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - New Business Won (Fees)',"
				+ "sum(if (t.`Type` = 'Revenue Lost (Audit)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - Revenue Lost (Audit)',"
				+ "sum(if (t.`Type` = 'Shrinkage (Frequency)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - Shrinkage (Frequency)',"
				+ "sum(if (t.`Type` = 'Shrinkage (Duration)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - Shrinkage (Duration)',"
				+ "sum(if (t.`Type` = 'Revenue Lost (Fees)' and t.`Stream`='Food', t.`Amount`, null)) as 'Food - Revenue Lost (Fees)' "
				+ "from ("
				+ "select "
				+ "if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'Stream',"
				+ "if(oli.Days__c>0, 'New Business Won (Audit)', 'New Business Won (Fees)') as 'Type', "
				+ "t.`Period`, "
				+ "sum(if(oli.IsDeleted=0 and oli.First_Year_Revenue__c=1, oli.`TotalPrice`, null)) as 'Amount' "
				+ "from "
				+ "(select * from ("
				+ "select "
				+ "o.Id, "
				+ "date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR),'%Y %m') as 'Period', "
				+ "o.Total_First_Year_Revenue__c "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where o.Business_1__c in ('Australia') "
				//+ "and o.Manual_Certification_Finalised__c=0 "
				+ "and o.IsDeleted = 0 "
				+ "and o.Status__c = 'Active' "
				+ "and o.StageName = 'Closed Won' "
				+ "and oh.Field = 'StageName' "
				+ "and oh.NewValue = 'Closed Won' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by o.Id) t2 "
				+ "where t2.`Period` >= '" + periodFormat.format(startDate.getTime()) + "' "
				+ "and t2.`Period` <= '" + periodFormat.format(endDate.getTime()) + "' ) t "
				+ "left join opportunitylineitem oli on oli.OpportunityId = t.Id "
				+ "left join standard__c s on oli.Standard__c = s.Id "
				+ "left join program__c pg on s.Program__c = pg.Id "
				+ "group by `Stream`,`Type`, t.`Period`"
				+ "UNION "
				+ "select lbr.`Stream` as 'Stream',"
				+ "'Revenue Lost (Audit)' as 'Type', "
				+ "lbr.`Cancelled Period` as `Period`, "
				+ "sum(lbr.`Quantity`*lbr.`EffectivePrice`) as 'Amount' "
				+ "from lost_business_revenue lbr "
				+ "where lbr.`Cancelled Period`>='" + periodFormat.format(startDate.getTime()) + "'	"
				+ "and lbr.`Cancelled Period`<='" + periodFormat.format(endDate.getTime()) + "'	"
				+ "and (lbr.`Revenue_Ownership__c` LIKE 'AUS-Food%' OR lbr.Revenue_Ownership__c LIKE 'AUS-Global%' OR lbr.Revenue_Ownership__c LIKE 'AUS-Managed%' OR lbr.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				+ "group by `Stream`, `Type`, `Period` "
				+ "union "
				+ "select "
				+ "dscs.`Stream` as 'Stream',"
				+ "'Revenue Lost (Fees)' as 'Type',"
				+ "date_format(dscs.`DeRegistered Date`, '%Y %m') as 'Period',"
				+ "sum(dscs.`EffectivePrice`) as 'Amount' "
				+ "from deregistered_site_cert_standard_with_effective_price dscs "
				+ "where date_format(dscs.`DeRegistered Date`, '%Y %m') >= '" + periodFormat.format(startDate.getTime()) + "' "
				+ "and date_format(dscs.`DeRegistered Date`, '%Y %m') <= '" + periodFormat.format(endDate.getTime()) + "' "
				+ "group by `Stream` , `Period` "
				+ "UNION "
				+ "select scar.`Stream` as 'Stream',"
				+ "'Shrinkage (Frequency)' as 'Type', "
				+ "scar.`Cancelled Period` as `Period`, "
				+ "sum(scar.`Quantity`*scar.`EffectivePrice`) as 'Amount' "
				+ "from shrinkage_cancelled_audits_revenue scar "
				+ "where scar.`Cancelled Period`>='" + periodFormat.format(startDate.getTime()) + "'	"
				+ "and scar.`Cancelled Period`<='" + periodFormat.format(endDate.getTime()) + "'	"
				+ "group by `Stream`, `Type`, `Period` "
				+ "UNION "
				+ "select srar.`Stream` as 'Stream',"
				+ "'Shrinkage (Duration)' as 'Type', "
				+ "srar.`Shrinkage Period` as `Period`, "
				+ "sum(srar.`Quantity`*srar.`EffectivePrice`) as 'Amount' "
				+ "from shrinkage_reduced_audits_revenue srar "
				+ "where srar.`Shrinkage Period`>='" + periodFormat.format(startDate.getTime()) + "'	"
				+ "and srar.`Shrinkage Period`<='" + periodFormat.format(endDate.getTime()) + "'	"
				+ "group by `Stream`, `Type`, `Period`";
				//+ "select "
				//+ "t3.`Stream` as 'Stream',"
				//+ "'Revenue Lost (Fees)' as 'Type', "
				//+ "date_format(t3.`DeRegistered Date`, '%Y %m') as 'Period', sum(t3.`EffectivePrice`) as 'Amount' from ("
				//+ "select t2.*, if(t2.`Site Cert Effective Pricing` is not null, t2.`Site Cert Effective Pricing`, if(t2.`Site Cert Pricing` is not null, t2.`Site Cert Pricing`, t2.`ListPrice`))*if(t2.`Recurring_Fee_Frequency__c`='Monthly', 12,if(t2.`Recurring_Fee_Frequency__c`='3 Months', 4,if(t2.`Recurring_Fee_Frequency__c`='6 Month', 2,1))) as 'EffectivePrice' "
				//+ "from ("
				//+ "select t.*,"
				//+ "if(cp.IsDeleted = 0 and cp.Sales_Price_Start_Date__c<= t.`DeRegistered Date` and cp.Sales_Price_End_Date__c>= t.`DeRegistered Date`, cp.FSales_Price__c, null) as 'Site Cert Pricing',"
				//+ "if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=t.`DeRegistered Date` and cep.New_End_Date__c>=t.`DeRegistered Date`, if(cep.Adjustment_Type__c='Percentage', t.`ListPrice`*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', t.`ListPrice` + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing' "
				//+ "from ("
				//+ "select "
				//+ "if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'Stream',"
				//+ "scsp.Site_Certification__c, p.Name, p.Id as 'ProductId', min(scsph.CreatedDate) as 'DeRegistered Date',ig.Recurring_Fee_Frequency__c, pbe.UnitPrice as 'ListPrice' "
				//+ "from site_certification_standard_program__c scsp "
				//+ "inner join certification__c site on scsp.Site_Certification__c = site.Id "
				//+ "inner join product2 p on site.Registration_Fee_Product__c = p.Id "
				//+ "left join standard__c s on p.Standard__c = s.Id "
				//+ "left join program__c pg on s.Program__c = pg.Id "
				//+ "inner join Invoice_Group__c ig on site.Invoice_Group_Registration__c = ig.Id "
				//+ "inner join site_certification_standard_program__history scsph on scsph.ParentId = scsp.Id "
				//+ "inner join pricebookentry pbe ON pbe.Product2Id = p.Id "
				//+ "where scsp.De_registered_Type__c in ('Client Initiated','SAI Initiated') "
				//+ "and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue') "
				//+ "and scsp.Status__c='De-registered' "
				//+ "and scsph.Field='Status__c' "
				//+ "and scsph.NewValue='De-registered' "
				//+ "and scsph.CreatedDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				//+ "and scsph.CreatedDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				//+ "and scsp.IsDeleted=0 "
				//+ "and scsph.IsDeleted=0 "
				//+ "and (site.Revenue_Ownership__c LIKE 'AUS-Food%' OR site.Revenue_Ownership__c LIKE 'AUS-Global%' OR site.Revenue_Ownership__c LIKE 'AUS-Managed%' OR site.Revenue_Ownership__c LIKE 'AUS-Direct%') "
				//+ "and pbe.Pricebook2Id = '01s90000000568BAAQ' "
				//+ "and pbe.CurrencyIsoCode = 'AUD' "
				//+ "and pbe.isDeleted = 0 "
				//+ "group by scsp.Site_certification__c) t "
				//+ "left join certification_pricing__c cp ON cp.Product__c = t.`ProductId` and cp.Certification__c = t.Site_Certification__c "
				//+ "left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c "
				//+ "order by t.Site_certification__c, cep.New_Start_Date__c desc, cep.CreatedDate desc) t2 "
				//+ "group by t2.Site_certification__c) t3 "
				//+ "group by `Stream`,`Period` ";
				for (String period : getPeriodsBetween(startDate, endDate)) {
					query+= "union select 'Dummy', 'Dummy', '" + period + "', null ";
				}
				query +=  ") t group by t.`Period` order by t.`Period`";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		while (rs.next()) {
			netOppDataMs[rs.getRow()] = new Object[] {displayPeriodFormat.format(periodFormat.parse(rs.getString("Period"))), 
					rs.getDouble("MS - New Business Won (Audit)"), 
					rs.getDouble("MS - New Business Won (Fees)"), 
					-rs.getDouble("MS - Revenue Lost (Audit)"), 
					-rs.getDouble("MS - Revenue Lost (Fees)"),
					-rs.getDouble("MS - Shrinkage (Frequency)"),
					-rs.getDouble("MS - Shrinkage (Duration)"),
					rs.getDouble("MS - New Business Won (Audit)")+rs.getDouble("MS - New Business Won (Fees)")-rs.getDouble("MS - Revenue Lost (Audit)")-rs.getDouble("MS - Revenue Lost (Fees)") - rs.getDouble("MS - Shrinkage (Frequency)") - rs.getDouble("MS - Shrinkage (Duration)")};
			
			netOppDataFood[rs.getRow()] = new Object[] {displayPeriodFormat.format(periodFormat.parse(rs.getString("Period"))), 
					rs.getDouble("Food - New Business Won (Audit)"), 
					rs.getDouble("Food - New Business Won (Fees)"), 
					-rs.getDouble("Food - Revenue Lost (Audit)"), 
					-rs.getDouble("Food - Revenue Lost (Fees)"),
					-rs.getDouble("Food - Shrinkage (Frequency)"),
					-rs.getDouble("Food - Shrinkage (Duration)"),
					rs.getDouble("Food - New Business Won (Audit)")+rs.getDouble("Food - New Business Won (Fees)")-rs.getDouble("Food - Revenue Lost (Audit)")-rs.getDouble("Food - Revenue Lost (Fees)") - rs.getDouble("Food - Shrinkage (Frequency)") - rs.getDouble("Food - Shrinkage (Duration)")};
			
			netOppDataMsAndFood[rs.getRow()] = new Object[] {displayPeriodFormat.format(periodFormat.parse(rs.getString("Period"))), 
					rs.getDouble("MS - New Business Won (Audit)") + rs.getDouble("Food - New Business Won (Audit)"), 
					rs.getDouble("MS - New Business Won (Fees)") + rs.getDouble("Food - New Business Won (Fees)"), 
					-rs.getDouble("MS - Revenue Lost (Audit)") -rs.getDouble("Food - Revenue Lost (Audit)"), 
					-rs.getDouble("MS - Revenue Lost (Fees)") -rs.getDouble("Food - Revenue Lost (Fees)"),
					-rs.getDouble("MS - Shrinkage (Frequency)") -rs.getDouble("Food - Shrinkage (Frequency)"),
					-rs.getDouble("MS - Shrinkage (Duration)") -rs.getDouble("Food - Shrinkage (Duration)"),		
					rs.getDouble("MS - New Business Won (Audit)")+rs.getDouble("MS - New Business Won (Fees)")-rs.getDouble("MS - Revenue Lost (Audit)")-rs.getDouble("MS - Revenue Lost (Fees)") - rs.getDouble("MS - Shrinkage (Frequency)") - rs.getDouble("MS - Shrinkage (Duration)")
					+rs.getDouble("Food - New Business Won (Audit)")+rs.getDouble("Food - New Business Won (Fees)")-rs.getDouble("Food - Revenue Lost (Audit)")-rs.getDouble("Food - Revenue Lost (Fees)") - rs.getDouble("Food - Shrinkage (Frequency)") - rs.getDouble("Food - Shrinkage (Duration)")};
		}
		
		retValue.put(DailyStats.FOOD, netOppDataFood);
		retValue.put(DailyStats.MS, netOppDataMs);
		retValue.put(DailyStats.MS_PLUS_FOOD, netOppDataMsAndFood);
		return retValue;
		
	}
	
	private List<String> getPeriodsBetween(Calendar startDate, Calendar endDate) {
		List<String> periods = new ArrayList<String>();
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDate.getTime());
		while (aux.before(endDate)) {
			periods.add(periodFormat.format(aux.getTime()));
			aux.add(Calendar.MONTH,  1);
		}
		return periods;
	}
	
	private void updateSalesData() throws Exception {
		Calendar today = Calendar.getInstance();
		Calendar auxStart = Calendar.getInstance();
		Calendar auxStop = Calendar.getInstance();
		
		data.opportunityTableData = new Object[5][7];
		data.opportunityTableWeeklyData = new Object[5][7];
		data.opportunityTableMonthlyData = new Object[5][7];
		data.opportunityTableData[0] = data.opportunityTableWeeklyData[0] = data.opportunityTableMonthlyData[0] 
				= new Object[] {"Period", "New", "Duration Review", "Proposal Sent", "Neg./Review", "Won", "Lost"};
		data.opportunityChartData = new Object[2][7];
		data.opportunityChartWeeklyData = new Object[2][7];
		data.opportunityChartMonthlyData = new Object[2][7];
		data.opportunityChartData[0] = data.opportunityChartWeeklyData[0] = data.opportunityChartMonthlyData[0] = data.opportunityTableData[0];
		data.opportunityDeliveryMonthlyChartData = data.opportunityDeliveryWeeklyChartData = data.opportunityDeliveryChartData = new Object[2][9];
		data.opportunityDeliveryMonthlyChartData[0] = data.opportunityDeliveryWeeklyChartData[0] = data.opportunityDeliveryChartData[0] = new Object[9];
		data.opportunityDeliveryMonthlyChartData[0][0] = data.opportunityDeliveryWeeklyChartData[0][0] = data.opportunityDeliveryChartData[0][0] = "Period";
		data.opportunityDeliveryMonthlyChartData[1][0] = data.opportunityDeliveryWeeklyChartData[1][0] = data.opportunityDeliveryChartData[1][0] = "Amount";
		
		auxStart.setTime(today.getTime());
		auxStop.setTime(today.getTime());
		auxStart.add(Calendar.DATE, -1);
		auxStop.add(Calendar.DATE, -1);
		Object[][] auxArray = getOpportunityChangedForPeriod("Yesterday", auxStart, auxStop);
		data.opportunityTableData[1] = auxArray[0];
		data.opportunityTableData[2] = auxArray[1];
		data.opportunityTableData[3] = auxArray[2];
		data.opportunityTableData[4] = auxArray[3];
		data.opportunityChartData[1] = auxArray[0];
		data.opportunityDeliveryTableData = getOpportunityClosedWonForPeriod(auxStart, auxStop);
		for(int i=0; i<data.opportunityDeliveryTableData[1].length; i++) {
			data.opportunityDeliveryChartData[0][i+1] = data.opportunityDeliveryTableData[0][i];
			data.opportunityDeliveryChartData[1][i+1] = data.opportunityDeliveryTableData[1][i];
		}
		data.opportunityDeliveryChartData = transposeMatrix(data.opportunityDeliveryChartData);
		
		auxStart.setTime(today.getTime());
		auxStop.setTime(today.getTime());
		auxStart.set(Calendar.DAY_OF_WEEK, 2);
		auxStop.set(Calendar.DAY_OF_WEEK, 7);
		Object[][] auxArray2 = getOpportunityChangedForPeriod("This Week", auxStart, auxStop);
		data.opportunityTableWeeklyData[1] = auxArray2[0];
		data.opportunityTableWeeklyData[2] = auxArray2[1];
		data.opportunityTableWeeklyData[3] = auxArray2[2];
		data.opportunityTableWeeklyData[4] = auxArray2[3];
		data.opportunityChartWeeklyData[1] = auxArray2[0];
		data.opportunityDeliveryWeeklyTableData = getOpportunityClosedWonForPeriod(auxStart, auxStop);
		for(int i=0; i<data.opportunityDeliveryWeeklyTableData[1].length; i++) {
			data.opportunityDeliveryWeeklyChartData[0][i+1] = data.opportunityDeliveryWeeklyTableData[0][i];
			data.opportunityDeliveryWeeklyChartData[1][i+1] = data.opportunityDeliveryWeeklyTableData[1][i];
		}
		data.opportunityDeliveryWeeklyChartData = transposeMatrix(data.opportunityDeliveryWeeklyChartData);
		
		auxStart.setTime(today.getTime());
		auxStop.setTime(today.getTime());
		auxStart.set(Calendar.DAY_OF_MONTH, 1);
		auxStop.set(Calendar.DAY_OF_MONTH, today.getActualMaximum(Calendar.DAY_OF_MONTH));
		Object[][] auxArray3 = getOpportunityChangedForPeriod("This Month", auxStart, auxStop);
		data.opportunityTableMonthlyData[1] = auxArray3[0];
		data.opportunityTableMonthlyData[2] = auxArray3[1];
		data.opportunityTableMonthlyData[3] = auxArray3[2];
		data.opportunityTableMonthlyData[4] = auxArray3[3];
		data.opportunityChartMonthlyData[1] = auxArray3[0];
		data.opportunityDeliveryMonthlyTableData = getOpportunityClosedWonForPeriod(auxStart, auxStop);
		for(int i=0; i<data.opportunityDeliveryMonthlyTableData[1].length; i++) {
			data.opportunityDeliveryMonthlyChartData[0][i+1] = data.opportunityDeliveryMonthlyTableData[0][i];
			data.opportunityDeliveryMonthlyChartData[1][i+1] = data.opportunityDeliveryMonthlyTableData[1][i];
		}
		data.opportunityDeliveryMonthlyChartData = transposeMatrix(data.opportunityDeliveryMonthlyChartData);
		
		// Calculate FABs
		if (((double)data.opportunityTableData[1][5])==0)
			data.opportunityFabRatioTableData = 0.0;
		else
			data.opportunityFabRatioTableData = Double.valueOf(df.format(((double)data.opportunityTableData[1][1])/((double)data.opportunityTableData[1][5]))); 
		
		if (((double)data.opportunityTableWeeklyData[1][5])==0)
			data.opportunityFabRatioWeeklyTableData = 0.0;
		else
			data.opportunityFabRatioWeeklyTableData = Double.valueOf(df.format(((double)data.opportunityTableWeeklyData[1][1])/((double)data.opportunityTableWeeklyData[1][5])));
		
		if (((double)data.opportunityTableMonthlyData[1][5])==0)
			data.opportunityFabRatioMonthlyTableData = 0.0;
		else
			data.opportunityFabRatioMonthlyTableData = Double.valueOf(df.format(((double)data.opportunityTableMonthlyData[1][1])/((double)data.opportunityTableMonthlyData[1][5])));
		
		//data.opportunityTableData = transposeMatrix(data.opportunityTableData);
		data.opportunityChartData = transposeMatrix(data.opportunityChartData);
		//data.opportunityTableWeeklyData = transposeMatrix(data.opportunityTableWeeklyData);
		data.opportunityChartWeeklyData = transposeMatrix(data.opportunityChartWeeklyData);
		//data.opportunityTableMonthlyData = transposeMatrix(data.opportunityTableMonthlyData);
		data.opportunityChartMonthlyData = transposeMatrix(data.opportunityChartMonthlyData);
		
		data.opportunityTopAmountsTableData = getTopOpportunityTableData();
		data.lastUpdateSalesDate = today;
		data.lastUpdateSalesDateText = displayDateTimeFormat.format(data.lastUpdateSalesDate.getTime());
	}
	
	private Object[][] getTopOpportunityTableData() throws Exception {
		List<Object[]> opportunityData = new ArrayList<Object[]>();
		
		String query = "select * from top_opportunities_tis_and_cert t order by t.Amount desc;";
		ResultSet rs = db_certification.executeSelect(query, -1);
		opportunityData.add(new Object[] {"Stream", "Created", "By", "Name", "Amount", "Stage", "Probability", "Exp. Close"});
		while (rs.next()) {
			opportunityData.add(new Object[] {
				rs.getString("Stream"),
				rs.getString("CreatedOn"),
				rs.getString("CreatedBy"),
				rs.getString("OppName"),
				rs.getDouble("Amount"),
				rs.getString("Stage"),
				rs.getString("Probability"),
				rs.getString("CloseDate"),
				//rs.getString("LastModifiedOn")
			});
		}
		return opportunityData.toArray(new Object[opportunityData.size()][]);
	}
	
	private Object[][] getOpportunityChangedForPeriod(String label, Calendar startDate, Calendar endDate) throws Exception {

		Object[][] opportunityData = new Object[4][8];
		opportunityData[0] = new Object[] {"Amount", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
		opportunityData[1] = new Object[] {"Count", 0, 0, 0, 0, 0, 0};
		opportunityData[2][0] = "Days Won";
		opportunityData[3][0] = "Days Cancelled";
		String businessWhere = " o.Business_1__c in ('" + StringUtils.join(this.data.region.getClientOwnerships(), "', '") + "') ";
		
		//TODO: Add multi-currency support
		/*
		 * If Region is multi-currency => Convert all to default currency
		 * 	else => Convert all to region currency
		 */
		String query = "select t2.Stage as 'Stage', sum(t2.FirstYearRevenues) as 'FirstYearRevenues', sum(t2.OppCount) as 'OppCount', sum(t2.Days) as 'Days' from ("
				+ "(select t.Stage,"
				+ "sum(if(oli.IsDeleted = 0 and oli.First_Year_Revenue__c = 1, oli.`TotalPrice`, null)) as 'FirstYearRevenues',"
				+ "count(distinct t.Id) as 'OppCount',"
				+ "sum(oli.Days__c) as 'Days' "
				+ "from"
				+ "(select "
				+ "if(date_format(date_add(min(oh.CreatedDate), INTERVAL 11 HOUR), '%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and date_format(date_add(min(oh.CreatedDate), INTERVAL 11 HOUR), '%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "',o.Id,null) as 'Id', "
				+ "if (oh.NewValue = 'Needs Analysis', 'New', oh.NewValue) as 'Stage' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh on oh.OpportunityId = o.Id "
				+ "where " + businessWhere
				+ "and o.IsDeleted = 0 "
				+ "and o.Status__c = 'Active' "
				+ "and oh.Field = 'StageName' "
				+ "and o.StageName not in ('Budget') "
				//+ "and oh.NewValue in ('Closed Won') "
				//+ "and o.StageName = 'Closed Won' "
				//+ "and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by o.Id, `Stage`) t "
				+ "left join opportunitylineitem oli ON oli.OpportunityId = t.Id "
				+ "group by t.Stage) "
				//+ "UNION "
				//+ "(select t.Stage,"
				//+ "sum(if(oli.IsDeleted = 0 and oli.First_Year_Revenue__c = 1, oli.`TotalPrice`, null)) as 'FirstYearRevenues',"
				//+ "count(distinct t.Id) as 'OppCount',"
				//+ "sum(oli.Days__c) as 'Days' "
				//+ "from"
				//+ "(select "
				//+ "o.Id, "
				//+ "if (oh.NewValue = 'Needs Analysis', 'New', oh.NewValue) as 'Stage' "
				//+ "from opportunity o "
				//+ "inner join opportunityfieldhistory oh on oh.OpportunityId = o.Id "
				//+ "where " + businessWhere
				//+ "and o.IsDeleted = 0 "
				//+ "and o.Status__c = 'Active' "
				//+ "and o.StageName not in ('Budget')"
				//+ "and oh.Field = 'StageName' "
				//+ "and oh.NewValue not in ('Closed Won') "
				//+ "and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				//+ "group by o.Id, `Stage`) t "
				//+ "left join opportunitylineitem oli ON oli.OpportunityId = t.Id "
				//+ "group by t.Stage) "
				+ "UNION "
				+ "(select 'New' as 'Stage' "
				+ ", sum(o.Total_First_Year_Revenue__c) as 'FirstYearRevenues' "
				+ ", count(o.Id) as 'OppCount' "
				+ ", 0 as 'Days' "
				+ "from opportunity o "
				+ "where " + businessWhere
				+ "and o.IsDeleted = 0 "
				+ "and o.Status__c = 'Active' "
				+ "and o.StageName not in ('Budget') "
				+ "and date_format(date_add(o.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and date_format(date_add(o.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by `Stage`)) t2 "
				+ "group by t2.Stage";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		
		while (rs.next()) {
			if (rs.getString("Stage").equalsIgnoreCase("New")) {
				opportunityData[0][1] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][1] = (int) Math.round(rs.getDouble("OppCount"));
				continue;
			}
			if (rs.getString("Stage").equalsIgnoreCase("Sales Duration Review")) {
				opportunityData[0][2] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][2] = (int) Math.round(rs.getDouble("OppCount"));
				continue;
			}
			if (rs.getString("Stage").equalsIgnoreCase("Proposal Sent")) {
				opportunityData[0][3] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][3] = (int) Math.round(rs.getDouble("OppCount"));
				continue;
			}
			if (rs.getString("Stage").equalsIgnoreCase("Negotiation/Review")) {
				opportunityData[0][4] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][4] = (int) Math.round(rs.getDouble("OppCount"));
				continue;
			}
			if (rs.getString("Stage").equalsIgnoreCase("Closed Won")) {
				opportunityData[0][5] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][5] = (int) Math.round(rs.getDouble("OppCount"));
				opportunityData[2][5] = (int) Math.round(rs.getDouble("Days"));
				continue;
			}
			if (rs.getString("Stage").equalsIgnoreCase("Closed Lost")) {
				opportunityData[0][6] = rs.getDouble("FirstYearRevenues");
				opportunityData[1][6] = (int) Math.round(rs.getDouble("OppCount"));
				continue;
			}
		}
		
		return opportunityData;
	}
	
	private String[] getCurrentPeriods(Calendar date) {
		String[] currentPeriods = new String[6];
		Calendar aux = Calendar.getInstance();
		aux.setTime(date.getTime());
		for (int i=0; i<6; i++) {
			currentPeriods[i] = displayPeriodFormat.format(aux.getTime());
			aux.add(Calendar.MONTH, +1);
		}
		return currentPeriods;
	}
	
	private Object[][] getOpportunityClosedWonForPeriod(Calendar startDate, Calendar endDate) throws Exception {

		Object[][] opportunityData = new Object[2][8];
		String[] currentPeriods = getCurrentPeriods(startDate);
 		// header
		opportunityData[0] = new Object[] {"Previous Periods", currentPeriods[0], currentPeriods[1], currentPeriods[2], currentPeriods[3], currentPeriods[4], currentPeriods[5], "Next Periods"};
		opportunityData[1] = new Object[] {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
		String businessWhere = " o.Business_1__c in ('" + StringUtils.join(this.data.region.getClientOwnerships(), "', '") + "') ";
		
		//TODO: Add multi-currency support
		/*
		 * If Region is multi-currency => Convert all to default currency
		 * 	else => Convert all to region currency
		 */
		String query = "select "
				+ "ifnull(date_format(o.Proposed_Delivery_Date__c, '%Y %m'), date_format(o.CloseDate, '%Y %m')) as 'ProposedDeliverMonth',"
				+ "sum(if(oli.IsDeleted = 0 and oli.First_Year_Revenue__c = 1, oli.`TotalPrice`, null)) as 'FirstYearRevenues' "
				+ "from opportunity o "
				+ "left join opportunitylineitem oli ON oli.OpportunityId = o.Id "
				+ "where o.Id IN ("
				+ "select "
				+ "if (date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "',o.Id,null) as 'Id' "
				+ "from opportunity o "
				+ "inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id "
				+ "where " + businessWhere
				+ "and o.IsDeleted = 0 "
				+ "and o.Status__c = 'Active' "
				+ "and o.StageName = 'Closed Won' "
				+ "and oh.NewValue = 'Closed Won' "
				+ "and oh.Field = 'StageName' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				//+ "and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by o.Id)"
				+ "group by `ProposedDeliverMonth`";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		
		while (rs.next()) {
			if (rs.getString("ProposedDeliverMonth").compareTo( periodFormat.format(displayPeriodFormat.parse(currentPeriods[0])) )<0) {
				opportunityData[1][0] = ((double)opportunityData[1][0]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[0])))) {
				opportunityData[1][1] = ((double)opportunityData[1][1]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[1])))) {
				opportunityData[1][2] = ((double)opportunityData[1][2]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[2])))) {
				opportunityData[1][3] = ((double)opportunityData[1][3]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[3])))) {
				opportunityData[1][4] = ((double)opportunityData[1][4]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[4])))) {
				opportunityData[1][5] = ((double)opportunityData[1][5]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").equalsIgnoreCase(periodFormat.format(displayPeriodFormat.parse(currentPeriods[5])))) {
				opportunityData[1][6] = ((double)opportunityData[1][6]) + rs.getDouble("FirstYearRevenues");
				continue;
			}
			if (rs.getString("ProposedDeliverMonth").compareTo(periodFormat.format(displayPeriodFormat.parse(currentPeriods[5])))>0) {
				opportunityData[1][7] = ((double)opportunityData[1][7]) + rs.getDouble("FirstYearRevenues");
				continue;
			}	
		}
		
		return opportunityData;
	}
	private void updateTisInHouse(Calendar today) throws Exception {
		Calendar startDate = Calendar.getInstance();
		Calendar endDate = Calendar.getInstance();
		if (today.get(Calendar.MONTH)>Calendar.JUNE) {
			startDate.set(Calendar.YEAR, today.get(Calendar.YEAR));
			endDate.set(Calendar.YEAR, today.get(Calendar.YEAR)+1);
		} else {
			startDate.set(Calendar.YEAR, today.get(Calendar.YEAR)-1);
			endDate.set(Calendar.YEAR, today.get(Calendar.YEAR));
		}
		startDate.set(Calendar.MONTH, Calendar.JULY);
		startDate.set(Calendar.DAY_OF_MONTH, 1);
		endDate.set(Calendar.MONTH, Calendar.JUNE);
		endDate.set(Calendar.DAY_OF_MONTH, 30);
		startDate.set(Calendar.HOUR, 0);
		startDate.set(Calendar.MINUTE, 0);
		startDate.set(Calendar.SECOND, 0);
		endDate.set(Calendar.HOUR, 0);
		endDate.set(Calendar.MINUTE, 0);
		endDate.set(Calendar.SECOND, 0);
		
		data.tisInHouseRunningTotalsChartData = getTisInHouse(startDate, endDate);
		data.tisInHouseRunningTotalsTableData = new Object[13][3];
		data.tisInHousePeriodTotalsTableData = new Object[13][3];
		//data.tisInHouseRunningTotalsTableData[0] = new Object[] {"Period","In House","In House (to be invoiced)", "Budget"};
		data.tisInHouseRunningTotalsTableData[0] = new Object[] {"Period","In House", "Budget"};
		int monthPointer = 1;
		for (int i=1; i<data.tisInHouseRunningTotalsChartData.length; i++) {
			if (data.tisInHouseRunningTotalsChartData[i][0] != null) {
				if ((i+1)<data.tisInHouseRunningTotalsChartData.length && data.tisInHouseRunningTotalsChartData[i+1][0] != null) {
					Calendar nextDay = Calendar.getInstance();
					nextDay.setTime(Utility.getActivitydateformatter().parse(((String) data.tisInHouseRunningTotalsChartData[i+1][0])));
					if (nextDay.get(Calendar.DAY_OF_MONTH) == 1) {
						data.tisInHouseRunningTotalsTableData[monthPointer] = new Object[] {
								displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) data.tisInHouseRunningTotalsChartData[i][0]))), // Period 
								data.tisInHouseRunningTotalsChartData[i][1], // In House
								//data.tisInHouseRunningTotalsChartData[i][2], // In House - Projected
								data.tisInHouseRunningTotalsChartData[i][2]  // Budget
						};
						monthPointer++;
					}
				} else {
					data.tisInHouseRunningTotalsTableData[monthPointer] = new Object[] {
							displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) data.tisInHouseRunningTotalsChartData[i][0]))), // Period 
							data.tisInHouseRunningTotalsChartData[i][1], // In House
							//data.tisInHouseRunningTotalsChartData[i][2], // In House - Projected
							data.tisInHouseRunningTotalsChartData[i][2]  // Budget
					};
				}
				data.tisInHouseRunningTotalsChartData[i][0] = Utility.getShortdatedisplayformat().format(Utility.getActivitydateformatter().parse(((String) data.tisInHouseRunningTotalsChartData[i][0])));
			}
		}
		
		data.tisInHousePeriodTotalsTableData[0] = data.tisInHouseRunningTotalsTableData[0]; 
		for (int p=1; p<data.tisInHouseRunningTotalsTableData.length; p++ ) {
			for (int c=0; c<data.tisInHouseRunningTotalsTableData[p].length; c++) {
				if (c==0) {
					// This is the row header... just copy it
					data.tisInHousePeriodTotalsTableData[p][c] = data.tisInHouseRunningTotalsTableData[p][c];
				} else {
					data.tisInHousePeriodTotalsTableData[p][c] = ((Double) data.tisInHouseRunningTotalsTableData[p][c]) - (p==1?0.0:((Double) data.tisInHouseRunningTotalsTableData[p-1][c]));
				}
			}
		}
		
		data.tisInHousePeriodTotalsChartData = data.tisInHousePeriodTotalsTableData;
		//data.tisInHouseRunningTotalsChartData = transposeMatrix(data.tisInHousePeriodTotalsTableData);
	}
	
	private void updateTisPublicYearly(Calendar today) throws Exception {
		Calendar startDate = Calendar.getInstance();
		Calendar endDate = Calendar.getInstance();
		if (today.get(Calendar.MONTH)>Calendar.JUNE) {
			startDate.set(Calendar.YEAR, today.get(Calendar.YEAR));
			endDate.set(Calendar.YEAR, today.get(Calendar.YEAR)+1);
		} else {
			startDate.set(Calendar.YEAR, today.get(Calendar.YEAR)-1);
			endDate.set(Calendar.YEAR, today.get(Calendar.YEAR));
		}
		startDate.set(Calendar.MONTH, Calendar.JULY);
		startDate.set(Calendar.DAY_OF_MONTH, 1);
		endDate.set(Calendar.MONTH, Calendar.JUNE);
		endDate.set(Calendar.DAY_OF_MONTH, 30);
		startDate.set(Calendar.HOUR, 0);
		startDate.set(Calendar.MINUTE, 0);
		startDate.set(Calendar.SECOND, 0);
		startDate.set(Calendar.MILLISECOND, 0);
		endDate.set(Calendar.HOUR, 0);
		endDate.set(Calendar.MINUTE, 0);
		endDate.set(Calendar.SECOND, 0);
		endDate.set(Calendar.MILLISECOND, 0);
		
		data.tisPublicYearlyRunningTotalsChartData = new Object[daysBetween(startDate, endDate)+2][5];
		data.tisPublicYearlyRunningTotalsTableData = new Object[13][5];
		data.tisPublicYearlyPeriodTotalsChartData = new Object[daysBetween(startDate, endDate)+2][5];
		data.tisPublicYearlyPeriodTotalsTableData = new Object[13][5];
		
		data.tisElearningYearlyRunningTotalsChartData = new Object[daysBetween(startDate, endDate)+2][4];
		data.tisElearningYearlyRunningTotalsTableData = new Object[13][4];
		data.tisElearningYearlyPeriodTotalsChartData = new Object[daysBetween(startDate, endDate)+2][4];
		data.tisElearningYearlyPeriodTotalsTableData = new Object[13][4];
		
		Object[][] publicData = new Object[5][daysBetween(startDate, endDate)+3];
		data.tisPublicYearlyRunningTotalsTableData[0] = data.tisPublicYearlyPeriodTotalsTableData[0] = new Object[] {"Period", "Actual", "Projection", "Budget", "Forecast"};
		data.tisElearningYearlyRunningTotalsTableData[0] = data.tisElearningYearlyPeriodTotalsTableData[0] = new Object[] {"Period", "Actual", "Budget", "Forecast"};
		
		Object[][] eLearningData = transposeMatrix(getTisELearning(startDate, endDate));
		Object[][] faceToFaceData = transposeMatrix(getTisFaceToFace(startDate, endDate));
		Object[][] faceToFaceProjectionData = transposeMatrix(getTisFaceToFaceProjection(startDate, endDate));
		publicData[0] = faceToFaceData[0];
		publicData[1] = faceToFaceData[1];
		publicData[2] = faceToFaceProjectionData[1];
		publicData[3] = faceToFaceData[2];
		publicData[4] = faceToFaceData[3];
		
		int monthPointer = 1;
		for (int i=1; i<publicData[0].length; i++) {
			if (publicData[0][i] != null) {
				if ((i+1)<publicData[0].length && publicData[0][i+1] != null) {
					Calendar nextDay = Calendar.getInstance();
					nextDay.setTime(Utility.getActivitydateformatter().parse(((String) publicData[0][i+1])));
					if (nextDay.get(Calendar.DAY_OF_MONTH) == 1) {
						data.tisPublicYearlyRunningTotalsTableData[monthPointer] = new Object[] {
								displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) publicData[0][i]))), // Period 
								publicData[1][i], // Face To Face
								publicData[2][i], // Face To Face - Projection
								publicData[3][i], // Budget
								publicData[4][i] // Forecast
						};
						data.tisElearningYearlyRunningTotalsTableData[monthPointer] = new Object[] {
								displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) eLearningData[0][i]))), // Period 
								eLearningData[1][i], // eLearning
								eLearningData[2][i], // Budget
								eLearningData[3][i], // Forecast
						};
						
						data.tisPublicYearlyPeriodTotalsTableData[monthPointer][0] = data.tisPublicYearlyRunningTotalsTableData[monthPointer][0]; 
						for (int j=1; j<data.tisPublicYearlyRunningTotalsTableData[monthPointer].length; j++ ) {
							data.tisPublicYearlyPeriodTotalsTableData[monthPointer][j] = ((Double) data.tisPublicYearlyRunningTotalsTableData[monthPointer][j]) - (monthPointer==1?0.0:((Double) data.tisPublicYearlyRunningTotalsTableData[monthPointer-1][j]));
						}
						data.tisElearningYearlyPeriodTotalsTableData[monthPointer][0] = data.tisElearningYearlyRunningTotalsTableData[monthPointer][0]; 
						for (int j=1; j<data.tisElearningYearlyRunningTotalsTableData[monthPointer].length; j++ ) {
							data.tisElearningYearlyPeriodTotalsTableData[monthPointer][j] = ((Double) data.tisElearningYearlyRunningTotalsTableData[monthPointer][j]) - (monthPointer==1?0.0:((Double) data.tisElearningYearlyRunningTotalsTableData[monthPointer-1][j]));
						}
					
						monthPointer++;
					}
				} else {
					data.tisPublicYearlyRunningTotalsTableData[monthPointer] = new Object[] {
							displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) publicData[0][i]))), // Period 
							publicData[1][i], // Face To Face
							publicData[2][i], // Face To Face - Projection
							publicData[3][i], // Budget
							publicData[4][i] // Forecast
					};
					data.tisElearningYearlyRunningTotalsTableData[monthPointer] = new Object[] {
							displayPeriodFormat.format(Utility.getActivitydateformatter().parse(((String) eLearningData[0][i]))), // Period 
							eLearningData[1][i], // eLearning
							eLearningData[2][i], // Budget
							eLearningData[3][i], // Forecast
					};
					
					data.tisPublicYearlyPeriodTotalsTableData[monthPointer][0] = data.tisPublicYearlyRunningTotalsTableData[monthPointer][0]; 
					for (int j=1; j<data.tisPublicYearlyRunningTotalsTableData[monthPointer].length; j++ ) {
						data.tisPublicYearlyPeriodTotalsTableData[monthPointer][j] = ((Double) data.tisPublicYearlyRunningTotalsTableData[monthPointer][j]) - (monthPointer==1?0.0:((Double) data.tisPublicYearlyRunningTotalsTableData[monthPointer-1][j]));
					}
					data.tisElearningYearlyPeriodTotalsTableData[monthPointer][0] = data.tisElearningYearlyRunningTotalsTableData[monthPointer][0]; 
					for (int j=1; j<data.tisElearningYearlyRunningTotalsTableData[monthPointer].length; j++ ) {
						data.tisElearningYearlyPeriodTotalsTableData[monthPointer][j] = ((Double) data.tisElearningYearlyRunningTotalsTableData[monthPointer][j]) - (monthPointer==1?0.0:((Double) data.tisElearningYearlyRunningTotalsTableData[monthPointer-1][j]));
					}
				}
				publicData[0][i] = Utility.getShortdatedisplayformat().format(Utility.getActivitydateformatter().parse(((String) publicData[0][i])));
				eLearningData[0][i] = Utility.getShortdatedisplayformat().format(Utility.getActivitydateformatter().parse(((String) eLearningData[0][i])));
			}
		}
		
		data.tisPublicYearlyRunningTotalsChartData = transposeMatrix(publicData);
		data.tisElearningYearlyRunningTotalsChartData = transposeMatrix(eLearningData);
		data.tisPublicYearlyRunningTotalsChartData[0] = new Object[] {"Period", "Actual", "Projection", "Budget", "Forecast"};
		data.tisElearningYearlyRunningTotalsChartData[0] = new Object[] {"Period", "Actual", "Budget", "Forecast"};
		
		data.tisPublicYearlyPeriodTotalsChartData = data.tisPublicYearlyPeriodTotalsTableData;
		data.tisElearningYearlyPeriodTotalsChartData = data.tisElearningYearlyPeriodTotalsTableData;
		//data.tisPublicYearlyPeriodTotalsChartData[0] = new Object[] {"Period", "Actual", "Projection", "Budget", "Forecast"};
		//data.tisElearningYearlyPeriodTotalsChartData[0] = new Object[] {"Period", "Actual", "Budget", "Forecast"};
	}
	
	private void updateTisPublicAndElearningMonthly(Calendar today) throws Exception {
		Calendar startDate = Calendar.getInstance();
		Calendar endDate = Calendar.getInstance();
		startDate.setTime(today.getTime());
		endDate.setTime(today.getTime());
		endDate.add(Calendar.MONTH, 0);
		startDate.set(Calendar.DAY_OF_MONTH, 1);
		endDate.set(Calendar.DAY_OF_MONTH, endDate.getActualMaximum(Calendar.DAY_OF_MONTH));
		startDate.set(Calendar.HOUR, 0);
		startDate.set(Calendar.MINUTE, 0);
		startDate.set(Calendar.SECOND, 0);
		startDate.set(Calendar.MILLISECOND, 0);
		endDate.set(Calendar.HOUR, 0);
		endDate.set(Calendar.MINUTE, 0);
		endDate.set(Calendar.SECOND, 0);
		endDate.set(Calendar.MILLISECOND, 0);
		
		data.tisElearningMonthlyChartData = getTisELearning(startDate, endDate);
		Object[][] tisFaceToFaceData = transposeMatrix(getTisFaceToFace(startDate, endDate));
		Object[][] tisFaceToFaceProjectionData = transposeMatrix(getTisFaceToFaceProjection(startDate, endDate));
		Object[][] auxData = new Object[5][tisFaceToFaceData.length];
		auxData[0] = tisFaceToFaceData[0];
		auxData[1] = tisFaceToFaceData[1];
		auxData[2] = tisFaceToFaceProjectionData[1];
		auxData[3] = tisFaceToFaceData[2];
		auxData[4] = tisFaceToFaceData[3];
		data.tisPublicMonthlyChartData = transposeMatrix(auxData);
		
		for (int i=1; i<data.tisElearningMonthlyChartData.length; i++) {
			if (data.tisElearningMonthlyChartData[i][0] != null) {
				Calendar day = Calendar.getInstance();
				day.setTime(Utility.getActivitydateformatter().parse(((String) data.tisElearningMonthlyChartData[i][0])));
				data.tisPublicMonthlyChartData[i][0] = data.tisElearningMonthlyChartData[i][0] = day.get(Calendar.DAY_OF_MONTH) + daySuffixes[day.get(Calendar.DAY_OF_MONTH)];
				data.tisPublicMonthlyChartData[i][2] = (double) data.tisPublicMonthlyChartData[i][2];// - (double) data.tisElearningMonthlyChartData[i][2];
			}
		}
		
		data.tisPublicMonthlyTableData = new Object[5][data.tisPublicMonthlyChartData.length];
		data.tisElearningMonthlyTableData = new Object[4][data.tisElearningMonthlyChartData.length];
		
		Object[][] eLearningData = transposeMatrix(data.tisElearningMonthlyChartData);
		Object[][] publicData = transposeMatrix(data.tisPublicMonthlyChartData);
		data.tisPublicMonthlyTableData[0] = publicData[0];
		data.tisPublicMonthlyTableData[1] = publicData[1];
		data.tisPublicMonthlyTableData[2] = publicData[2];
		data.tisPublicMonthlyTableData[3] = publicData[3];
		data.tisPublicMonthlyTableData[4] = publicData[4];
		data.tisPublicMonthlyTableData[2][0] = "Projections";
		data.tisPublicMonthlyTableData[3][0] = "Budget";
		data.tisPublicMonthlyTableData[4][0] = "Forecast";
		
		data.tisElearningMonthlyTableData[0] = eLearningData[0];
		data.tisElearningMonthlyTableData[1] = eLearningData[1];
		data.tisElearningMonthlyTableData[2] = eLearningData[2];
		data.tisElearningMonthlyTableData[3] = eLearningData[3];
		data.tisElearningMonthlyTableData[2][0] = "Budget-eLearning";
		data.tisElearningMonthlyTableData[3][0] = "Forecast-eLearning";
	}
	
	private Object[][] getTisELearning(Calendar startDate, Calendar endDate) throws Exception {

		int daysInPeriod = daysBetween(startDate, endDate) +1;
		Object[][] retValue = new Object[daysInPeriod+1][4];
		retValue[0] = new Object[] {"Date", "eLearning", "Budget", "Forecast"};
		
		String query =  "select t.Date, sum(t.Amount) as 'Amount' from ("
				+ "(select "
				+ "i.Id,"
				+ "date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', "
				+ "if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' "
				+ "from registration__c r "
				+ "inner join recordtype rt on r.RecordTypeId = rt.Id "
				+ "inner join invoice_ent__c i ON i.Registration__c = r.Id "
				+ "inner join invoice_ent__history ih on ih.ParentId = i.id "
				+ "where "
				+ "r.Course_Type__c = 'eLearning' "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and ih.Field='Processed__c' and ih.NewValue='true' "
				+ "and ih.CreatedDate  >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and ih.CreatedDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by i.Id) "
				+ "union "
				+ "(select "
				+ "pa.id,"
				+ "date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', "
				+ "if(pa.GST_Exempt__c, pa.Total_Amount__c, pa.Total_Amount__c/1.1) as 'Amount' "
				+ "from registration__c r "
				+ "inner join recordtype rt on r.RecordTypeId = rt.Id "
				+ "inner join invoice_ent__c pa ON pa.Registration__c = r.Id "
				+ "inner join invoice_ent__c i ON i.Prior_Adjustment__c = pa.Name "
				+ "inner join invoice_ent__history ih on ih.ParentId = i.id "
				+ "where "
				+ "r.Course_Type__c = 'eLearning' "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and ih.Field='Processed__c' and ih.NewValue='true' "
				+ "and i.Invoice_Type__c = 'ARB'"
				+ "and ih.CreatedDate  >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and ih.CreatedDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by i.Id)) t "
				+ "where t.Date >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and t.Date <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "group by t.`Date` order by t.`Date`";
		HashMap<String, Double> progressiveTotal = new HashMap<String, Double>();
		ResultSet rs = db_tis.executeSelect(query, -1);
		double currentTotal = 0.0;
		while(rs.next()) {
			progressiveTotal.put(rs.getString("Date"), new Double(rs.getDouble("Amount") + currentTotal));
			currentTotal += rs.getDouble("Amount");
		}
		currentTotal = 0.0;
		double progressiveBudget = 0.0;
		double progressiveForecast = 0.0;
		int budgetMontlyPointer = 0;
		Double[] budgets = getTisOnlineBudgetforPeriod(startDate, endDate);
		Double[] forecasts = getTisOnlineForecastforPeriod(startDate, endDate);
		double dailyBudget = 0.0;
		double dailyForecast = 0.0;
		int pointer = 1;
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDate.getTime());
		
		while (!aux.after(endDate)) {
			if (aux.get(Calendar.DAY_OF_MONTH)==1) {
				if (budgetMontlyPointer<budgets.length) {
					dailyBudget = budgets[budgetMontlyPointer]/aux.getActualMaximum(Calendar.DAY_OF_MONTH);
				} else {
					dailyBudget = 0;
				}
				if (budgetMontlyPointer<forecasts.length) {
					dailyForecast = forecasts[budgetMontlyPointer]/aux.getActualMaximum(Calendar.DAY_OF_MONTH);
				} else {
					dailyForecast = 0;
				}
				budgetMontlyPointer++;
			}
			progressiveBudget += dailyBudget;
			progressiveForecast += dailyForecast;
			if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(aux.getTime()))) {
				currentTotal = progressiveTotal.get(Utility.getActivitydateformatter().format(aux.getTime())).doubleValue();
			}
			retValue[pointer] = new Object[] {Utility.getActivitydateformatter().format(aux.getTime()), currentTotal, progressiveBudget, progressiveForecast};
			
			pointer++;
			aux.add(Calendar.DAY_OF_MONTH, 1);
		}
		
		return retValue;
		
		
	}
	
	private Object[][] getTisInHouse(Calendar startDate, Calendar endDate) throws Exception {
		int totalDays = daysBetween(startDate, endDate)+1;
		Object[][] retValue = new Object[totalDays+1][3];
		//retValue[0] = new Object[] {"Date", "InHouse", "InHouse (to be invoiced)", "Budget", "Forecast"};
		retValue[0] = new Object[] {"Date", "InHouse", "Budget"};
		
		HashMap<String, Double> progressiveTotal = new HashMap<String, Double>();
		HashMap<String, Double> progressiveTotalNotInvoiced = new HashMap<String, Double>();
		String query = "select "
				//+ "ihe.Invoicing_Complete__c, "
				+ "1 as 'Invoicing_Complete__c', "
				+ "sum(if(ihe.Invoicing_Complete__c=1,ihe.Total_Amount_Invoiced__c, ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c)) as 'Amount', "
				+ "date_format(date_add(c.Class_Begin_Date__c, interval 11 hour),'%Y-%m-%d') as 'Class_Begin_Date__c', "
				+ "date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') as 'Class_End_Date__c' "
				+ "from In_House_Event__c ihe "
				+ "inner join training.class__c c on ihe.Class__c = c.Id "
				+ "inner join RecordType rt on c.RecordTypeId = rt.Id "
				+ "where "
				+ "ihe.Status__c not in ('Cancelled','Postponed') "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and c.Class_Status__c not in ('Cancelled','Postponed') "
				+ "and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and date_format(date_add(c.Class_Begin_Date__c, interval 11 hour),'%Y-%m-%d') <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "and (c.Name not like '%Actual%' and c.Name not like '%Budget%') "
				+ " AND c.RecordTypeId = '012200000000YGcAAM' " // In House Class (exclude TIS AMERICA)
				//+ "and ihe.Invoicing_Complete__c=1 "
				//+ "group by ihe.Invoicing_Complete__c, c.Class_Begin_Date__c, c.Class_End_Date__c "
				+ "group by ihe.id "
				+ "order by c.Class_Begin_Date__c";
		
		ResultSet rs = db_tis.executeSelect(query, -1);
		while (rs.next()) {
			if (rs.getBoolean("Invoicing_Complete__c")) {
				if (rs.getString("Class_Begin_Date__c").equalsIgnoreCase(rs.getString("Class_End_Date__c"))) {
					if (progressiveTotal.containsKey(rs.getString("Class_Begin_Date__c")))
						progressiveTotal.put(rs.getString("Class_Begin_Date__c"), progressiveTotal.get(rs.getString("Class_Begin_Date__c")) + rs.getDouble("Amount"));
					else
						progressiveTotal.put(rs.getString("Class_Begin_Date__c"), rs.getDouble("Amount"));
				} else {
					Calendar classStart = new GregorianCalendar();
					Calendar classEnd = new GregorianCalendar();
					classStart.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_Begin_Date__c")));
					classEnd.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_End_Date__c")));
					double dailyAmount = rs.getDouble("Amount")/(daysBetween(classStart, classEnd)+1);
					while(classStart.compareTo(classEnd)<=0) {
						if (classStart.compareTo(endDate)<=0) {
							if (classStart.compareTo(startDate)>=0) {
								if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(classStart.getTime())))
									progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), progressiveTotal.get(Utility.getActivitydateformatter().format(classStart.getTime())) + dailyAmount);
								else
									progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), dailyAmount);
								
							}
							
							classStart.add(Calendar.DAY_OF_MONTH, 1);
						} else {
							break;
						}
					}
				}
			} else {
				if (rs.getString("Class_Begin_Date__c").equalsIgnoreCase(rs.getString("Class_End_Date__c"))) {
					if (progressiveTotalNotInvoiced.containsKey(rs.getString("Class_Begin_Date__c")))
						progressiveTotalNotInvoiced.put(rs.getString("Class_Begin_Date__c"), progressiveTotalNotInvoiced.get(rs.getString("Class_Begin_Date__c")) + rs.getDouble("Amount"));
					else
						progressiveTotalNotInvoiced.put(rs.getString("Class_Begin_Date__c"), rs.getDouble("Amount"));
				} else {
					Calendar classStart = new GregorianCalendar();
					Calendar classEnd = new GregorianCalendar();
					classStart.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_Begin_Date__c")));
					classEnd.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_End_Date__c")));
					double dailyAmount = rs.getDouble("Amount")/(daysBetween(classStart, classEnd)+1);
					while(!classStart.after(classEnd)) {
						if (!classStart.after(endDate)) {
							if (!classStart.before(startDate)) {
								if (progressiveTotalNotInvoiced.containsKey(Utility.getActivitydateformatter().format(classStart.getTime())))
									progressiveTotalNotInvoiced.put(Utility.getActivitydateformatter().format(classStart.getTime()), progressiveTotalNotInvoiced.get(Utility.getActivitydateformatter().format(classStart.getTime())) + dailyAmount);
								else
									progressiveTotalNotInvoiced.put(Utility.getActivitydateformatter().format(classStart.getTime()), dailyAmount);
							}
							classStart.add(Calendar.DAY_OF_MONTH, 1);
						} else {
							break;
						}
					}
				}
			}
		}
		
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDate.getTime());
		double runningTotal = 0.0;
		@SuppressWarnings("unused")
		double runningTotalNotInvoiced = 0.0;
		double runningBudget = 0.0;
		@SuppressWarnings("unused")
		double runningForecast = 0.0;
		int budgetMonthPointer = 0;
		int daysInMonth = aux.getActualMaximum(Calendar.DAY_OF_MONTH);
		Double[] budgets = getTisInHouseBudgetforPeriod(startDate, endDate);
		Double[] forecasts = getTisInHouseForecastforPeriod(startDate, endDate);
		double dailyBudget = 0;//budgets[budgetMonthPointer]/daysInMonth;
		double dailyForecast = 0;//forecasts[budgetMonthPointer]/daysInMonth;
		if (budgetMonthPointer<budgets.length) {
			dailyBudget = budgets[budgetMonthPointer]/daysInMonth;
		}
		if (budgetMonthPointer<forecasts.length) {
			dailyForecast = forecasts[budgetMonthPointer]/daysInMonth;
		}
		int pointer = 1;
		while (!aux.after(endDate)) {
			if (1==aux.get(Calendar.DAY_OF_MONTH)) {
				daysInMonth = aux.getActualMaximum(Calendar.DAY_OF_MONTH);
				if (budgetMonthPointer<budgets.length) {
					dailyBudget = budgets[budgetMonthPointer]/daysInMonth;
				} else {
					dailyBudget = 0;
				}
				if (budgetMonthPointer<forecasts.length) {
					dailyForecast = forecasts[budgetMonthPointer]/daysInMonth;
				} else {
					dailyForecast = 0;
				}
				budgetMonthPointer++;
			}
			if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(aux.getTime()))) {
				runningTotal += progressiveTotal.get(Utility.getActivitydateformatter().format(aux.getTime()));
			}
			if (progressiveTotalNotInvoiced.containsKey(Utility.getActivitydateformatter().format(aux.getTime()))) {
				runningTotalNotInvoiced += progressiveTotalNotInvoiced.get(Utility.getActivitydateformatter().format(aux.getTime()));
			}
			runningBudget += dailyBudget;
			runningForecast += dailyForecast;
			//retValue[pointer] = new Object[] {Utility.getActivitydateformatter().format(aux.getTime()), runningTotal, runningTotalNotInvoiced, runningBudget, runningForecast};
			retValue[pointer] = new Object[] {Utility.getActivitydateformatter().format(aux.getTime()), runningTotal, runningBudget};
			
			pointer++;
			aux.add(Calendar.DAY_OF_MONTH, 1);
		}
		
		return retValue;
	}
	
	private double[] getRegDistribution() {
		// Position in the array represents no of weeks to class start
		//return new double[] {0.990250896, 0.951971326, 0.829964158, 0.70781362, 0.594551971, 0.480573477, 0.374767025, 0.295770609, 0.233978495, 0.187670251, 0.150967742, 0.118853047, 0.090609319, 0.070537634, 0.05562724, 0.043727599};
		return new double[] {1.068188891, 1.058177803, 0.998907286, 0.884679724, 0.803900093, 0.674354289, 0.572016638, 0.539201598, 0.481150167, 0.410933119, 0.37798909, 0.360670189, 0.351046102, 0.339644956, 0.310629897, 0.306053881};

	}
	
	private Object[][] getTisFaceToFaceProjection(Calendar startDate, Calendar endDate) throws Exception {
		
		int totalDays = daysBetween(startDate, endDate)+1;
		Object[][] retValue = new Object[totalDays+1][2];
		retValue[0] = new Object[] {"Date", "Projection"};
		
		HashMap<String, Double> progressiveTotal = new HashMap<String, Double>();
		String query = "select "
				+ "c.Class_Begin_Date__c, "
				+ "c.Class_End_Date__c, "
				+ "c.Number_of_Confirmed_Attendees__c, "
				+ "c.Course_Base_Price__c, "
				+ "c.Maximum_Attendee__c, "
				+ "c.Minimim_Attendee__c, "
				+ "round(datediff(c.Class_Begin_Date__c, now())/7,0) as 'weeksToStart' "
				+ "from Class__c c "
				+ "inner join RecordType rt on c.RecordTypeId = rt.Id "
				+ "where c.Class_Status__c not in ('Cancelled', 'Full') "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and c.Class_Begin_Date__c >= date_add(now(), INTERVAL 1 WEEK) "
				+ "and c.Class_Begin_Date__c <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "and c.Name not like '%Actual%' and c.Name not like '%Budget%' "
				//+ "and c.Number_of_Confirmed_Attendees__c>=c.Minimim_Attendee__c "
				+ "and c.Number_of_Confirmed_Attendees__c>0 "
				+ "and c.Class_Type__c = 'Public Class' "
				+ "and c.Class_Location__c not in ('Online')";

		double[] registrationCumulativeDistribution = getRegDistribution();
		ResultSet rs = db_tis.executeSelect(query, -1);
		while (rs.next()) {
			if (rs.getInt("weeksToStart")>=registrationCumulativeDistribution.length) {
				// Ignore.  A forecast on this would not be accurate
				continue;
			}
			int additionalAttendees = ((int) Math.min(rs.getInt("Number_of_Confirmed_Attendees__c")/registrationCumulativeDistribution[rs.getInt("weeksToStart")], rs.getInt("Maximum_Attendee__c")))- rs.getInt("Number_of_Confirmed_Attendees__c");
			double additionalAmount = rs.getDouble("Course_Base_Price__c") *additionalAttendees;
			if (rs.getString("Class_Begin_Date__c").equalsIgnoreCase(rs.getString("Class_End_Date__c"))) {
				if (progressiveTotal.containsKey(rs.getString("Class_Begin_Date__c")))
					progressiveTotal.put(rs.getString("Class_Begin_Date__c"), progressiveTotal.get(rs.getString("Class_Begin_Date__c")) + additionalAmount);
				else
					progressiveTotal.put(rs.getString("Class_Begin_Date__c"), additionalAmount);
			} else {
				Calendar classStart = new GregorianCalendar();
				Calendar classEnd = new GregorianCalendar();
				classStart.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_Begin_Date__c")));
				classEnd.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_End_Date__c")));
				double dailyAmount = additionalAmount/(daysBetween(classStart, classEnd)+1);
				while(!classStart.after(classEnd)) {
					if (!classStart.after(endDate)) {
						if (!classStart.before(startDate)) {
							if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(classStart.getTime())))
								progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), progressiveTotal.get(Utility.getActivitydateformatter().format(classStart.getTime())) + dailyAmount);
							else
								progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), dailyAmount);
						}
						classStart.add(Calendar.DAY_OF_MONTH, 1);
					} else {
						break;
					}
				}
			}
		}
		
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDate.getTime());
		double runningTotal = 0.0;
		int pointer = 1;
		while (!aux.after(endDate)) {
			
			if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(aux.getTime()))) {
				runningTotal += progressiveTotal.get(Utility.getActivitydateformatter().format(aux.getTime()));
			}
			retValue[pointer] = new Object[] {Utility.getActivitydateformatter().format(aux.getTime()), runningTotal};
			
			pointer++;
			aux.add(Calendar.DAY_OF_MONTH, 1);
		}
		
		return retValue;
	}
	
	private Object[][] getTisFaceToFace(Calendar startDate, Calendar endDate) throws Exception {
		
		int totalDays = daysBetween(startDate, endDate)+1;
		Object[][] retValue = new Object[totalDays+1][4];
		retValue[0] = new Object[] {"Date", "Face To Face", "Budget", "Forecast"};
		
		HashMap<String, Double> progressiveTotal = new HashMap<String, Double>();
		
		String query = "select * from ("
				+ "(select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from ("
				+ "select "
				+ "date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', "
				+ "i.Total_Amount__c/1.1 as 'Amount' "
				+ "from registration__c r "
				+ "inner join recordtype rt on r.RecordTypeId = rt.Id "
				+ "inner join invoice_ent__c i ON i.Registration__c = r.Id "
				+ "left join invoice_ent__history ih on ih.ParentId = i.id "
				+ "where "
				+ "(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and i.Bill_Type__c = 'ADF' "
				+ "and r.NZ_AFS__c = 0 "
				+ "and r.Coles_Brand_Employee__c = 0 "
				+ "and r.Error__c = 0 "
				+ "and r.Status__c not in ('Pending') "
				+ "and i.Processed__c = 1 "
				+ "and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) "
				+ "group by i.Id) t "
				+ "where "
				+ "t.`Date`>= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and t.`Date`<= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "and t.`Amount` is not null "
				+ "group by t.`Date` "
				+ "order by t.`Date`) "
				+ "union (select t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from ( "
				+ "select "
				+ "date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', "
				+ "if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', "
				+ "if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', "
				+ "if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' "
				+ "from registration__c r "
				+ "inner join recordtype rt on r.RecordTypeId = rt.Id "
				+ "inner join invoice_ent__c i ON i.Registration__c = r.Id "
				+ "left join invoice_ent__history ih on ih.ParentId = i.id "
				+ "where "
				+ "(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and i.Bill_Type__c not in ('ADF') "
				+ "and r.NZ_AFS__c = 0 "
				+ "and r.Coles_Brand_Employee__c = 0 "
				+ "and r.Error__c = 0 "
				+ "and r.Status__c not in ('Pending') "
				+ "and i.Processed__c = 1 "
				+ "and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) "
				+ "group by i.Id) t "
				+ "where "
				+ "t.`Date`>= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and t.`Date`<= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "and (t.`Date` >= t.Class_Begin_Date__c or t.Class_Begin_Date__c is null) "
				+ "and t.`Amount` is not null "
				+ "group by t.`Date` "
				+ "order by t.`Date`"
				+ ") union "
				+ "(select t.Class_Begin_Date__c, t.Class_End_Date__c, sum(t.Amount) as 'Amount' from ( "
				+ "select "
				+ "date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', "
				+ "if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', "
				+ "if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', "
				+ "if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount' "
				+ "from registration__c r "
				+ "inner join recordtype rt on r.RecordTypeId = rt.Id "
				+ "inner join invoice_ent__c i ON i.Registration__c = r.Id "
				+ "left join invoice_ent__history ih on ih.ParentId = i.id "
				+ "where "
				+ "(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) "
				+ "and rt.Name not like 'TIS - AMER%' "
				+ "and i.Bill_Type__c not in ('ADF') "
				+ "and r.NZ_AFS__c = 0 "
				+ "and r.Coles_Brand_Employee__c = 0 "
				+ "and r.Error__c = 0 "
				+ "and r.Status__c not in ('Pending') "
				+ "and i.Processed__c = 1 "
				+ "and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) "
				+ "group by i.Id) t "
				+ "where "
				+ "t.`Date` < t.Class_Begin_Date__c "
				+ "and t.Class_Begin_Date__c <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "and t.Class_End_Date__c >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and t.`Amount` is not null "
				+ "group by t.Class_Begin_Date__c, t.Class_End_Date__c "
				+ "order by t.Class_Begin_Date__c)) t2 "
				+ "order by t2.Class_Begin_Date__c";
		
		ResultSet rs = db_tis.executeSelect(query, -1);
		while (rs.next()) {
			if (rs.getString("Class_Begin_Date__c").equalsIgnoreCase(rs.getString("Class_End_Date__c"))) {
				if (progressiveTotal.containsKey(rs.getString("Class_Begin_Date__c")))
					progressiveTotal.put(rs.getString("Class_Begin_Date__c"), progressiveTotal.get(rs.getString("Class_Begin_Date__c")) + rs.getDouble("Amount"));
				else
					progressiveTotal.put(rs.getString("Class_Begin_Date__c"), rs.getDouble("Amount"));
			} else {
				Calendar classStart = new GregorianCalendar();
				Calendar classEnd = new GregorianCalendar();
				classStart.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_Begin_Date__c")));
				classEnd.setTime(Utility.getActivitydateformatter().parse(rs.getString("Class_End_Date__c")));
				double dailyAmount = rs.getDouble("Amount")/(daysBetween(classStart, classEnd)+1);
				while(!classStart.after(classEnd)) {
					if (!classStart.after(endDate)) {
						if (!classStart.before(startDate)) {
							if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(classStart.getTime())))
								progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), progressiveTotal.get(Utility.getActivitydateformatter().format(classStart.getTime())) + dailyAmount);
							else
								progressiveTotal.put(Utility.getActivitydateformatter().format(classStart.getTime()), dailyAmount);
						}
						classStart.add(Calendar.DAY_OF_MONTH, 1);
					} else {
						break;
					}
				}
			}
		}
		
		Calendar aux = Calendar.getInstance();
		aux.setTime(startDate.getTime());
		double runningTotal = 0.0;
		double runningBudget = 0.0;
		double runningForecast = 0.0;
		int budgetMonthPointer = 0;
		int daysInMonth = aux.getActualMaximum(Calendar.DAY_OF_MONTH);
		Double[] budgets = getTisPublicBudgetforPeriod(startDate, endDate);
		Double[] forecasts = getTisPublicForecastforPeriod(startDate, endDate);
		double dailyBudget = 0;
		if (budgetMonthPointer<budgets.length) {
			dailyBudget = budgets[budgetMonthPointer]/daysInMonth;
		}
		double dailyForecast = 0;
		if (budgetMonthPointer<forecasts.length) {
			dailyForecast = forecasts[budgetMonthPointer]/daysInMonth;
		}
		int pointer = 1;
		while (!aux.after(endDate)) {
			if (1==aux.get(Calendar.DAY_OF_MONTH)) {
				daysInMonth = aux.getActualMaximum(Calendar.DAY_OF_MONTH);
				if (budgetMonthPointer<budgets.length) {
					dailyBudget = budgets[budgetMonthPointer]/daysInMonth;
				} else {
					dailyBudget = 0;
				}
				if (budgetMonthPointer<forecasts.length) {
					dailyForecast = forecasts[budgetMonthPointer]/daysInMonth;
				} else {
					dailyForecast = 0;
				}
				budgetMonthPointer++;
			}
			if (progressiveTotal.containsKey(Utility.getActivitydateformatter().format(aux.getTime()))) {
				runningTotal += progressiveTotal.get(Utility.getActivitydateformatter().format(aux.getTime()));
			}
			runningBudget += dailyBudget;
			runningForecast += dailyForecast;
			retValue[pointer] = new Object[] {Utility.getActivitydateformatter().format(aux.getTime()), runningTotal, runningBudget, runningForecast};
			
			pointer++;
			aux.add(Calendar.DAY_OF_MONTH, 1);
		}
		return retValue;
	}
	
	private static int daysBetween(Calendar from, Calendar to){
		from.set(Calendar.HOUR, 0);
		from.set(Calendar.MINUTE, 0);
		from.set(Calendar.SECOND, 0);
		from.set(Calendar.MILLISECOND, 0);
		to.set(Calendar.HOUR, 0);
		to.set(Calendar.MINUTE, 0);
		to.set(Calendar.SECOND, 0);
		to.set(Calendar.MILLISECOND, 0);
		int days = (int)(0.99 + (to.getTimeInMillis() - from.getTimeInMillis()) / (1000.0 * 60.0 * 60.0 * 24.0));
		
		System.out.println("from: " + Utility.getMysqldateformat().format(from.getTime()) + " - " + from.getTimeInMillis());
		System.out.println("to: " + Utility.getMysqldateformat().format(to.getTime()) + " - " + to.getTimeInMillis());
		System.out.println("Days Between: " + days);
		
		return days;
	}
	
	private void updateTisData() throws Exception {
		Calendar today = Calendar.getInstance();
		
		updateTisPublicYearly(today);
		//updateTisEearningYearly(today);
		
		updateTisPublicAndElearningMonthly(today);
		
		updateTisInHouse(today);
		
		data.lastUpdateTISDate = today;
		data.lastUpdateTISDateText = displayDateTimeFormat.format(data.lastUpdateTISDate.getTime());
		
	}
	
	private Double[] getTisOnlineForecastforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='eLearning' "
				+ "and RefName='forecast' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private Double[] getTisOnlineBudgetforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='eLearning' "
				+ "and RefName='budget' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private Double[] getTisPublicBudgetforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='public' "
				+ "and RefName='budget' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private Double[] getTisInHouseBudgetforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='inhouse' "
				+ "and RefName='budget' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";

		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private Double[] getTisPublicForecastforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='public' "
				+ "and RefName='forecast' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private Double[] getTisInHouseForecastforPeriod(Calendar startDate, Calendar endDate) throws NumberFormatException, InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		Double[] retValue = null;
		String query = "select "
				+ "RefValue as 'amount'"
				+ "from sf_data "
				+ "where DataType='Training' "
				+ "and DataSubType='inhouse' "
				+ "and RefName='forecast' "
				+ "and RefDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "and RefDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "order by RefDate";

		ResultSet rs = db_certification.executeSelect(query, -1);
		rs.last();
		retValue = new Double[rs.getRow()];
		rs.beforeFirst();
		while (rs.next()) {
			retValue[rs.getRow()-1] = rs.getDouble("amount");
		}
		return retValue;
	}
	
	private void updateAuditDays() throws Exception {
		Calendar localLastUpdate = getLatestReportDate();
		if (localLastUpdate == null)
			return;
		Object[][][] latestData = getAuditDaysbyReportDate(localLastUpdate, true, true);
		data.msAuditDaysChartData = latestData[0];
		data.foodAuditDaysChartData = latestData[1];
		
		// Create table data
		data.msAuditDaysTableData = new Object[noOfMonths+1][12];
		data.foodAuditDaysTableData = new Object[noOfMonths+1][12];
		data.msOpenSubStatusTableData = getAuditDaysOpenSubStatus(localLastUpdate, "MS");
		data.foodOpenSubStatusTableData = getAuditDaysOpenSubStatus(localLastUpdate, "Food");
		data.bothOpenSubStatusTableData = getAuditDaysOpenSubStatus(localLastUpdate, "MS,Food");
		
		for (int i=0; i<data.msAuditDaysChartData.length; i++) {
			for (int j=0; j<data.msAuditDaysChartData[i].length; j++) {
				data.msAuditDaysTableData[i][j] = data.msAuditDaysChartData[i][j];
				data.foodAuditDaysTableData[i][j] = data.foodAuditDaysChartData[i][j];
			}
		}
		data.msAuditDaysTableData[0][6] = data.foodAuditDaysTableData[0][6] = "Days Available";
		data.msAuditDaysTableData[0][7] = data.foodAuditDaysTableData[0][7] = "Confirmed minus Budget";
		data.msAuditDaysTableData[0][8] = data.foodAuditDaysTableData[0][8] = "Available minus Budget";
		data.msAuditDaysTableData[0][9] = data.foodAuditDaysTableData[0][9] = "Forecast minus Budget";
		data.msAuditDaysTableData[0][10] = data.foodAuditDaysTableData[0][10] = "Confirmed/Forecast";
		data.msAuditDaysTableData[0][11] = data.foodAuditDaysTableData[0][11] = "Confirmed/Budget";
		data.msAuditDaysTableData[0][0] = data.foodAuditDaysTableData[0][0] = "Status";
		
		// Calculated fields for table data
		for (int i=1; i<data.msAuditDaysChartData.length; i++) {
			// Total Available
			data.msAuditDaysTableData[i][6] = ((int) data.msAuditDaysTableData[i][1]) + ((int) data.msAuditDaysTableData[i][2]) + ((int) data.msAuditDaysTableData[i][3]);
			data.foodAuditDaysTableData[i][6] = ((int) data.foodAuditDaysTableData[i][1]) + ((int) data.foodAuditDaysTableData[i][2]) + ((int) data.foodAuditDaysTableData[i][3]);
			
			// Confirmed - Budget
			data.msAuditDaysTableData[i][7] = ((int) data.msAuditDaysTableData[i][1]) - ((int) data.msAuditDaysTableData[i][4]);
			data.foodAuditDaysTableData[i][7] = ((int) data.foodAuditDaysTableData[i][1]) - ((int) data.foodAuditDaysTableData[i][4]);
			
			// Available - Budget
			data.msAuditDaysTableData[i][8] = ((int) data.msAuditDaysTableData[i][6]) - ((int) data.msAuditDaysTableData[i][4]);
			data.foodAuditDaysTableData[i][8] = ((int) data.foodAuditDaysTableData[i][6]) - ((int) data.foodAuditDaysTableData[i][4]);
			
			// Forecast - Budget
			data.msAuditDaysTableData[i][9] = ((int) data.msAuditDaysTableData[i][5]) - ((int) data.msAuditDaysTableData[i][4]);
			data.foodAuditDaysTableData[i][9] = ((int) data.foodAuditDaysTableData[i][5]) - ((int) data.foodAuditDaysTableData[i][4]);
			
			// Confirmed/Forecast
			data.msAuditDaysTableData[i][10] = String.format("%,.2f%%", (double) ((int) data.msAuditDaysTableData[i][1]) / ((int) data.msAuditDaysTableData[i][5])*100);
			data.foodAuditDaysTableData[i][10] = String.format("%,.2f%%", (double) ((int) data.foodAuditDaysTableData[i][1]) / ((int) data.foodAuditDaysTableData[i][5])*100);
						
			// Confirmed/Budget
			data.msAuditDaysTableData[i][11] = String.format("%,.2f%%", (double) ((int) data.msAuditDaysTableData[i][1]) / ((int) data.msAuditDaysTableData[i][4])*100);
			data.foodAuditDaysTableData[i][11] = String.format("%,.2f%%", (double) ((int) data.foodAuditDaysTableData[i][1]) / ((int) data.foodAuditDaysTableData[i][4])*100);
			
		}
		
		data.msAuditDaysTableData = transposeMatrix(data.msAuditDaysTableData);		
		data.foodAuditDaysTableData = transposeMatrix(data.foodAuditDaysTableData);
		
		if (localLastUpdate != null) {
			data.lastUpdateReportDate = localLastUpdate;
			data.lastUpdateReportDateText = displayDateTimeFormat.format(data.lastUpdateReportDate.getTime());
		}
		
		updateChangesDays();
		
		calculateMSPlusFood();
	}
	
	private Object[][] getAuditDaysOpenSubStatus(Calendar reportDate, String stream) throws Exception {
		if (reportDate == null) {
			return null;
		}
		return Utility.resultSetToObjectArray(db_certification.executeSelect(getAuditDaysOpenSubStatusQuery(reportDate, stream), -1), true);
	}
	
	private String getAuditDaysOpenSubStatusQuery(Calendar reportDate, String stream) {
		String streamWhere = "`Revenue Stream` in ('MS', 'Food')";
		String regionWhere = " Region in ('" + StringUtils.join(this.data.region.getNames(), "', '") + "') ";
		if (stream != null) {			
			if (stream.toLowerCase().contains("ms") && !stream.toLowerCase().contains("food")) {
				streamWhere = "`Revenue Stream` in ('MS')";
			} else if (!stream.toLowerCase().contains("ms") && stream.toLowerCase().contains("food")) { 
				streamWhere = "`Revenue Stream` in ('Food')";
			}
		}
		
		String query = "select `Sub-Status` ";
		String[] periods = getPeriods();
		String[] monthsNames = getMonthsNames();
		for (int i=0; i<periods.length; i++) {
			query += ", round(sum(if (`Period` = '" + periods[i] + "', `Days`,0)),0) as '" + monthsNames[i] + "' ";
		}
		query += "from ("
				+ "SELECT `Period`, `Revenue Stream`, if(`Audit Status`='Open', if(`Audit Open SubStatus` is null, '(none)',`Audit Open SubStatus`),`Audit Status`) as 'Sub-Status', sum(`Value`) as 'Days'  "
				+ "FROM salesforce.financial_visisbility "
				+ "where "
				+ "`Report Date-Time` = '" + dateTimeFormat.format(reportDate.getTime()) + "'"
				+ "and " + regionWhere
				+ "and " + streamWhere
				+ "and `Audit Status` in ('Open', 'Service Change') "
				+ "and `Period`>='" + periods[0] + "' "
				+ "and `Period`<='" + periods[periods.length-1] + "' "
				+ "and `Type` = 'Days' "
				+ "group by `Period`, `Revenue Stream`, `Sub-Status`) t "
				+ "group by `Sub-Status`;";
		
		return query;
	}
	
	private void calculateMSPlusFood() {
		if ((data.msAuditDaysChartData==null) || (data.msAuditDaysTableData==null))
			return;
		data.bothAuditDaysChartData = new Object[data.msAuditDaysChartData.length][data.msAuditDaysChartData[0].length];
		data.bothAuditDaysTableData = new Object[data.msAuditDaysTableData.length][data.msAuditDaysTableData[0].length];
		
		for (int i=0; i<data.msAuditDaysChartData.length; i++) {
			for (int j=0; j<data.msAuditDaysChartData[i].length; j++) {
				if (i==0 || j==0)
					data.bothAuditDaysChartData[i][j] = data.msAuditDaysChartData[i][j];
				else
					data.bothAuditDaysChartData[i][j] = ((int) data.msAuditDaysChartData[i][j]) + ((int) data.foodAuditDaysChartData[i][j]);
			}
		}
		
		for (int i=0; i<data.msAuditDaysTableData.length; i++) {
			for (int j=0; j<data.msAuditDaysTableData[i].length; j++) {
				if (i==0 || j==0)
					data.bothAuditDaysTableData[i][j] = data.msAuditDaysTableData[i][j];
				else
					if ((i!=10) && (i!=11))
						data.bothAuditDaysTableData[i][j] = ((int) data.msAuditDaysTableData[i][j]) + ((int) data.foodAuditDaysTableData[i][j]);
			}
		}
		// Confirmed/Budget and Confirmed/Forecast
		for (int j=1; j<data.msAuditDaysTableData[10].length; j++) {
			data.bothAuditDaysTableData[10][j] = String.format("%,.2f%%", (double) ((int) data.bothAuditDaysTableData[1][j]) / ((int) data.bothAuditDaysTableData[5][j])*100);
			data.bothAuditDaysTableData[11][j] = String.format("%,.2f%%", (double) ((int) data.bothAuditDaysTableData[1][j]) / ((int) data.bothAuditDaysTableData[4][j])*100);
		}
		
		if ((data.msAuditDaysChangesDailyTableData == null) || (data.msAuditDaysChangesWeeklyTableData==null) || (data.msAuditDaysChangesMonthlyTableData==null))
			return;
		data.bothAuditDaysChangesDailyTableData = new Object[data.msAuditDaysChangesDailyTableData.length][data.msAuditDaysChangesDailyTableData[0].length];
		data.bothAuditDaysChangesWeeklyTableData= new Object[data.msAuditDaysChangesWeeklyTableData.length][data.msAuditDaysChangesWeeklyTableData[0].length];
		data.bothAuditDaysChangesMonthlyTableData= new Object[data.msAuditDaysChangesMonthlyTableData.length][data.msAuditDaysChangesMonthlyTableData[0].length];
		
		for (int i=0; i<data.msAuditDaysChangesDailyTableData.length; i++) {
			for (int j=0; j<data.msAuditDaysChangesDailyTableData[i].length; j++) {
				if (i==0 || j==0)
					data.bothAuditDaysChangesDailyTableData[i][j] = data.msAuditDaysChangesDailyTableData[i][j];
				else
					data.bothAuditDaysChangesDailyTableData[i][j] = ((int) data.msAuditDaysChangesDailyTableData[i][j]) + ((int) data.foodAuditDaysChangesDailyTableData[i][j]);
			}
		}
		
		for (int i=0; i<data.msAuditDaysChangesWeeklyTableData.length; i++) {
			for (int j=0; j<data.msAuditDaysChangesWeeklyTableData[i].length; j++) {
				if (i==0 || j==0)
					data.bothAuditDaysChangesWeeklyTableData[i][j] = data.msAuditDaysChangesWeeklyTableData[i][j];
				else
					data.bothAuditDaysChangesWeeklyTableData[i][j] = ((int) data.msAuditDaysChangesWeeklyTableData[i][j]) + ((int) data.foodAuditDaysChangesWeeklyTableData[i][j]);
			}
		}
		
		for (int i=0; i<data.msAuditDaysChangesMonthlyTableData.length; i++) {
			for (int j=0; j<data.msAuditDaysChangesMonthlyTableData[i].length; j++) {
				if (i==0 || j==0)
					data.bothAuditDaysChangesMonthlyTableData[i][j] = data.msAuditDaysChangesMonthlyTableData[i][j];
				else
					data.bothAuditDaysChangesMonthlyTableData[i][j] = ((int) data.msAuditDaysChangesMonthlyTableData[i][j]) + ((int) data.foodAuditDaysChangesMonthlyTableData[i][j]);
			}
		}
	}
	
	private Object[][][] getAuditDaysbyReportDate(Calendar reportDate, boolean includeBudget, boolean includeForecast) throws Exception {
		if (reportDate == null) {
			return null;
		}
		int dataWidth = includeBudget?6:5;
		Object[][] msAuditDaysData = new Object[noOfMonths+1][dataWidth];
		Object[][] foodAuditDaysData = new Object[noOfMonths+1][dataWidth];
		String regionWhere = " Region in ('" + StringUtils.join(this.data.region.getNames(), "', '") + "') ";
		String query = "SELECT * from ("
				+ "(select  "
				+ "'" + this.data.region.getName() + "' as 'Region2',"
				+ "`t`.`Report Date-Time` as 'Report-Date-Time', "
				+ "`t`.`Revenue Stream` as 'RevenueStream',"
				+ "`t`.`Month Name` AS `MonthName`,"
				+ "`t`.`Period` as 'Period',"
				+ "if((`t`.`Audit Status` in ('Cancelled')),"
				+ "'Cancelled',"
				+ "if((`t`.`Audit Status` in ('Open' , 'Service Change')),"
				+ "'Open',"
				+ "if(`t`.`Audit Status` in ('Scheduled', 'Scheduled Offered'), 'Scheduled', 'Confirmed'))) AS `SimpleStatus`,"
				+ "sum(`t`.`Value`) AS `Value` "
				+ "from `financial_visisbility` `t` "
				+ "where (`t`.`Type` = 'Days') "
				+ "and " + regionWhere
				+ "and `t`.`Revenue Stream` IN ('MS', 'Food') "
				+ "and `t`.`Source` = 'Audit' "
				+ "and `t`.`Audit Status` not in ('Cancelled') "
				+ "and `t`.`Period` >= date_format(now(), '%Y %m') and `t`.`Period` <= date_format(date_add(now(), interval " + (noOfMonths-1) + " month), '%Y %m' ) "
				//+ "and `t`.`Period` >= '" + periodFormat.format(reportDate.getTime()) + "' and `t`.`Period` <= date_format(date_add('" + Utility.getActivitydateformatter().format(reportDate.getTime()) + "', interval " + (noOfMonths-1) + " month), '%Y %m' ) "
				+ "and `t`.`Report Date-Time` = '" + dateTimeFormat.format(reportDate.getTime()) + "'"
				+ "group by `Region2`, `RevenueStream`, `Period`, `SimpleStatus` "
				+ "order by `Region2`, `RevenueStream`, `t`.`Period`, `SimpleStatus`) "
				//+ "UNION "
				//+ "(select "
				//+ "'0' as 'Report-Date-Time', "
				//+ "IF(wi.Revenue_Ownership__c LIKE 'AUS-Food%', 'Food', if (wi.Revenue_Ownership__c LIKE 'AUS-Product%', 'PS', 'MS')) AS 'RevenueStream', "
				//+ "monthname(wird.FStartDate__c) as 'MonthName', "
				//+ "date_format(wird.FStartDate__c, '%Y %m') as 'Period', "
				//+ "'Budget' as 'SimpleStatus', "
				//+ "sum(wird.Budget_Days__c) as 'Value' "
				//+ "from work_item__c wi "
				//+ "inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id "
				//+ "inner join work_item_resource_day__c wird on wird.Work_Item_Resource__c = wir.Id "
				//+ "inner join recordtype rt on wi.RecordTypeId = rt.Id "
				//+ "where rt.Name = 'Audit' "
				//+ "AND wir.IsDeleted = 0 "
				//+ "AND wird.IsDeleted = 0 "
				//+ "AND wir.Work_Item_Type__c = 'Budget' "
				//+ "AND wi.Status__c = 'Budget' "
				//+ "AND( wi.Revenue_Ownership__c like 'AUS-Food%' or wi.Revenue_Ownership__c like 'AUS-Manage%' or wi.Revenue_Ownership__c like 'AUS-Global%' ) "
				//+ "and date_format(wird.FStartDate__c, '%Y %m') >= date_format(now(), '%Y %m') and date_format(wird.FStartDate__c, '%Y %m') <= date_format(date_add(now(), interval " + (noOfMonths-1) + " month), '%Y %m') "
				//+ "group by `RevenueStream`, `Period`, `SimpleStatus`) "
				+ "UNION "
				+ "(select "
				+ "'" + this.data.region.getName() + "' as 'Region2',"
				+ "'0' as 'Report-Date-Time', "
				+ "DataSubType AS 'RevenueStream', "
				+ "monthname(RefDate) as 'MonthName', "
				+ "date_format(RefDate, '%Y %m') as 'Period', "
				+ "RefName as 'SimpleStatus', "
				+ "sum(RefValue) as 'Value' "
				+ "from sf_data "
				+ "where DataType in ('Audit Days Forecast Calculated', 'Audit Days Budget') "
				+ "and " + regionWhere
				+ "and date_format(RefDate, '%Y %m') >= date_format(now(), '%Y %m') and date_format(RefDate, '%Y %m') <= date_format(date_add(now(), interval " + (noOfMonths-1) + " month), '%Y %m') "
				+ "and current=1 "
				+ "group by `Region2`, `RevenueStream`, `Period`, `SimpleStatus`)) t "
				+ "group by `Region2`, `RevenueStream`, `Period`, `SimpleStatus` "
				+ "order by `Region2`, `RevenueStream`, `Period`, `SimpleStatus`";
		
		// header
		int index = 1;
		if (includeForecast) {
			if (includeBudget) {
				msAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Budget", "Forecast Calc."};
				foodAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Budget", "Forecast Calc."};
				for (String monthName : getMonthsNames()) {
					msAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0, 0};
					foodAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0, 0};
					index++;
				}
			} else {
				msAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Forecast Calc."};
				foodAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Forecast Calc."};
				for (String monthName : getMonthsNames()) {
					msAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0};
					foodAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0};
					index++;
				}
			}
		} else {
			if (includeBudget) {
				msAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Budget"};
				foodAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open", "Budget"};
				for (String monthName : getMonthsNames()) {
					msAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0};
					foodAuditDaysData[index] = new Object[] {monthName, 0, 0, 0, 0};
					index++;
				}
			} else {
				msAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open"};
				foodAuditDaysData[0] = new Object[] {"Month", "Confirmed", "Scheduled", "Open"};
				for (String monthName : getMonthsNames()) {
					msAuditDaysData[index] = new Object[] {monthName, 0, 0, 0};
					foodAuditDaysData[index] = new Object[] {monthName, 0, 0, 0};
					index++;
				}
			}
		}
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		Object[] monthData = null;
		String currentStream = "";
		String currentMonth = "";
		int rowIndex = 0;
		while (rs.next()) {
			if (!rs.getString("RevenueStream").equalsIgnoreCase(currentStream)) {
				if (rowIndex>0)
					if (currentStream.equalsIgnoreCase("MS"))
						msAuditDaysData[getMonthIndex((String)monthData[0])] = monthData;
					else
						foodAuditDaysData[getMonthIndex((String)monthData[0])] = monthData;
				currentStream = rs.getString("RevenueStream");
				rowIndex = 0;
			}
			if (!rs.getString("MonthName").equalsIgnoreCase(currentMonth)) {
				if (rowIndex>0)
					if (currentStream.equalsIgnoreCase("MS"))
						msAuditDaysData[getMonthIndex((String)monthData[0])] = monthData;
					else
						foodAuditDaysData[getMonthIndex((String)monthData[0])] = monthData;
				rowIndex++;
				monthData = new Object[] {"",0,0,0,0,0};
				currentMonth = rs.getString("MonthName");
				monthData[0] = currentMonth;
				//monthData[5] = 0;
			}
			if (rs.getString("SimpleStatus").equalsIgnoreCase("Confirmed")) {
				monthData[1] = (int) Math.round(rs.getDouble("Value"));
				continue;
			}
			if (rs.getString("SimpleStatus").equalsIgnoreCase("Scheduled")) {
				monthData[2] = (int) Math.round(rs.getDouble("Value"));
				continue;
			}
			if (rs.getString("SimpleStatus").equalsIgnoreCase("Open")) {
				monthData[3] = (int) Math.round(rs.getDouble("Value"));
				continue;
			}
			if (rs.getString("SimpleStatus").equalsIgnoreCase("Budget") && includeBudget) {
				monthData[4] = (int) Math.round(rs.getDouble("Value"));
				continue;
			}
			if (rs.getString("SimpleStatus").equalsIgnoreCase("Forecast") && includeForecast) {
				if (includeBudget)
					monthData[5] = (int) Math.round(rs.getDouble("Value"));
				else
					monthData[4] = (int) Math.round(rs.getDouble("Value"));
				continue;
			}
		}
		
		if (monthData != null) {
			if (currentStream.equalsIgnoreCase("MS"))
				msAuditDaysData[getMonthIndex(currentMonth)] = monthData;
			else
				foodAuditDaysData[getMonthIndex(currentMonth)] = monthData;
		}
		return new Object[][][] {msAuditDaysData, foodAuditDaysData};
	}
	
	private String[] getMonthsNames() {
		String[] monthsNames = new String[noOfMonths];
		Calendar aux = Calendar.getInstance();
		if (this.data.lastUpdateReportDate != null)
			aux.setTime(this.data.lastUpdateReportDate.getTime());
		for (int i=0; i<noOfMonths; i++) {
			monthsNames[i] = displayMonthFormat.format(aux.getTime());
			aux.add(Calendar.MONTH, 1);
		}
		return monthsNames;
	}
	
	private String[] getPeriods() {
		String[] monthsNames = new String[noOfMonths];
		Calendar aux = Calendar.getInstance();
		if (this.data.lastUpdateReportDate != null)
			aux.setTime(this.data.lastUpdateReportDate.getTime());
		for (int i=0; i<noOfMonths; i++) {
			monthsNames[i] = periodFormat.format(aux.getTime());
			aux.add(Calendar.MONTH, 1);
		}
		return monthsNames;
	}
	
	private int getMonthIndex(String monthName) {
		int index = 1;
		for (String aMonthName : getMonthsNames()) {
			if (aMonthName.equalsIgnoreCase(monthName))
				return index;
			index++;
		}
		return -1;
	}
	
	private static Object[][] transposeMatrix(Object [][] m){
		Object[][] temp = new Object[m[0].length][m.length];
        for (int i = 0; i < m.length; i++)
            for (int j = 0; j < m[0].length; j++)
            	temp[j][i] = m[i][j];
        return temp;
    }
	
	private Calendar getLatestReportDate() throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String lastReport = db_certification.executeScalar("select max(date) from sf_report_history where ReportName='Audit Days Snapshot'");
		Date lastReportDate = mysqlDateFormat.parse(lastReport);
		Calendar lastReportCalendar = Calendar.getInstance();
		lastReportCalendar.setTime(lastReportDate);
		return lastReportCalendar;
	}
	
	private Calendar getBeginOfMonthReportDate(Calendar today) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar aux = Calendar.getInstance();
		aux.setTime(today.getTime());
		aux.set(Calendar.DAY_OF_MONTH, 1);
		String startMonthReport = db_certification.executeScalar("select max(date) from sf_report_history where ReportName='Audit Days Snapshot' and date_format(date, '%Y-%m-%d') = '" + Utility.getActivitydateformatter().format(aux.getTime()) + "'");
		if (startMonthReport!=null) {
			Date startMonthReportDate = mysqlDateFormat.parse(startMonthReport);
			Calendar startMonthReportCalendar = Calendar.getInstance();
			startMonthReportCalendar.setTime(startMonthReportDate);
			return startMonthReportCalendar;
		}
		return null;
	}
	
	private Calendar getBeginOfWeekReportDate(Calendar today) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar aux = Calendar.getInstance();
		aux.setTime(today.getTime());
		aux.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY);
		String startWeekReport = db_certification.executeScalar("select max(date) from sf_report_history where ReportName='Audit Days Snapshot' and date_format(date, '%Y-%m-%d') = '" + Utility.getActivitydateformatter().format(aux.getTime()) + "'");
		if (startWeekReport!=null) {
			Date startWeekReportDate = mysqlDateFormat.parse(startWeekReport);
			Calendar startWeekReportCalendar = Calendar.getInstance();
			startWeekReportCalendar.setTime(startWeekReportDate);
			return startWeekReportCalendar;
		}
		return null;
	}
	
	private Calendar getYesterdayReportDate(Calendar today) throws Exception {
		SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar aux = Calendar.getInstance();
		aux.setTime(today.getTime());
		aux.add(Calendar.DATE, -1);
		String yesterdayReport = db_certification.executeScalar("select max(date) from sf_report_history where ReportName='Audit Days Snapshot' and date_format(date, '%Y-%m-%d') = '" + Utility.getActivitydateformatter().format(aux.getTime()) + "'");
		if (yesterdayReport != null) {
			Date yesterdayReportDate = mysqlDateFormat.parse(yesterdayReport);
			Calendar yesterdayReportCalendar = Calendar.getInstance();
			yesterdayReportCalendar.setTime(yesterdayReportDate);
			return yesterdayReportCalendar;
		} 
		return null;
	}
}
