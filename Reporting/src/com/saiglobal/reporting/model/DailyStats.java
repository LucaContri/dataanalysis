package com.saiglobal.reporting.model;

import java.util.Calendar;
import java.util.HashMap;

import com.saiglobal.sf.core.model.Region;

public class DailyStats {
	public static final String FOOD = "food";
	public static final String MS = "ms";
	public static final String MS_PLUS_FOOD = "ms_plus_food";
	
	public Region region;
	public Calendar lastUpdateReportDate;
	public Calendar yesterdayReportDate;
	public Calendar weekStartReportDate;
	public Calendar monthStartReportDate;
	public String lastUpdateReportDateText;
	public String yesterdayReportDateText;
	public String weekStartReportDateText;
	public String monthStartReportDateText;
	public Object[][] msAuditDaysChartData;
	public Object[][] msAuditDaysTableData;
	public Object[][] msOpenSubStatusTableData;
	public Object[][] msAuditDaysChangesDailyTableData;
	public Object[][] msAuditDaysChangesWeeklyTableData;
	public Object[][] msAuditDaysChangesMonthlyTableData;
	public Object[][] foodAuditDaysChartData;
	public Object[][] foodAuditDaysTableData;
	public Object[][] foodOpenSubStatusTableData;
	public Object[][] foodAuditDaysChangesDailyTableData;
	public Object[][] foodAuditDaysChangesWeeklyTableData;
	public Object[][] foodAuditDaysChangesMonthlyTableData;
	public Object[][] bothAuditDaysChartData;
	public Object[][] bothAuditDaysTableData;
	public Object[][] bothOpenSubStatusTableData;
	public Object[][] bothAuditDaysChangesDailyTableData;
	public Object[][] bothAuditDaysChangesWeeklyTableData;
	public Object[][] bothAuditDaysChangesMonthlyTableData;
	
	public Calendar lastUpdateSalesDate;
	public String lastUpdateSalesDateText;
	public Object[][] opportunityTableData;
	public Object[][] opportunityTableWeeklyData;
	public Object[][] opportunityTableMonthlyData;
	public Object[][] opportunityDeliveryTableData;
	public Object[][] opportunityDeliveryWeeklyTableData;
	public Object[][] opportunityDeliveryMonthlyTableData;
	public Object[][] opportunityChartData;
	public Object[][] opportunityChartWeeklyData;
	public Object[][] opportunityChartMonthlyData;
	public Object[][] opportunityDeliveryChartData;
	public Object[][] opportunityDeliveryWeeklyChartData;
	public Object[][] opportunityDeliveryMonthlyChartData;

	public double opportunityFabRatioTableData;
	public double opportunityFabRatioWeeklyTableData;
	public double opportunityFabRatioMonthlyTableData;
	public Object[][] opportunityTopAmountsTableData;
	
	public Calendar netOpportunitiesDate;
	public String netOpportunitiesDateText;
	public HashMap<String, Object[][]> netOpportunityChartData;
	public HashMap<String, Object[][]> netOpportunityTableData;
	public HashMap<String, Object[][]> churnRatioTableData;
	public HashMap<String, Object[][]> shrinkageRatioTableData;
	
	public Calendar lastUpdateTISDate;
	public String lastUpdateTISDateText;
	public Object[][] tisPublicYearlyPeriodTotalsChartData;
	public Object[][] tisPublicYearlyPeriodTotalsTableData;
	public Object[][] tisPublicYearlyRunningTotalsChartData;
	public Object[][] tisPublicYearlyRunningTotalsTableData;
	public Object[][] tisPublicMonthlyChartData;
	public Object[][] tisPublicMonthlyTableData;
	
	public Object[][] tisElearningYearlyPeriodTotalsChartData;
	public Object[][] tisElearningYearlyPeriodTotalsTableData;
	public Object[][] tisElearningYearlyRunningTotalsChartData;
	public Object[][] tisElearningYearlyRunningTotalsTableData;
	public Object[][] tisElearningMonthlyChartData;
	public Object[][] tisElearningMonthlyTableData;
	
	public Object[][] tisInHousePeriodTotalsChartData;
	public Object[][] tisInHousePeriodTotalsTableData;
	public Object[][] tisInHouseRunningTotalsChartData;
	public Object[][] tisInHouseRunningTotalsTableData;
	
	public DailyStats(Region region) {
		this.region = region;
	}
}
