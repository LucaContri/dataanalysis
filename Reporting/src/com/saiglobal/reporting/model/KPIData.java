package com.saiglobal.reporting.model;

import java.util.Calendar;
import java.util.HashMap;

import com.saiglobal.sf.core.model.Region;

public class KPIData {
	public static final String CHART = "chart";
	public static final String TABLE = "table";
	public static final String TABLE2 = "table2";
	public static final String FOOD = "food";
	public static final String MS = "ms";
	public static final String MS_PLUS_FOOD = "ms_plus_food";
	public static final String PS = "ps";
	public Region region;
	
	public KPIData(Region region) {
		this.region = region;
	}
	// Global
	public Calendar lastUpdateReportDate;
	
	// Sales
	public Calendar lastUpdateSales;
	public Calendar lastUpdateSalesPhoneMetrics;
	public HashMap<String, Object[][]> salesPhoneMetrics;
	
	// Back Office
	public Calendar lastUpdateNewBusiness;
	public HashMap<String, Object[][]> oppProcessingDays;
	
	public Calendar lastUpdateScheduling;
	public HashMap<String, HashMap<String, Object[][]>> schedulingConfirmedRatios;
	public HashMap<String, Object[][]> onTargetRatios;
	public HashMap<String, HashMap<String, Object[][]>> schedulingValidated;
	public Calendar lastUpdateSchedulingAuditorsUtilisation;
	public HashMap<String, HashMap<String, Object[][]>> schedulingAuditorsUtilisation;
	
	public Calendar lastUpdateAdmin;
	public Calendar lastUpdateAdminPhoneMetrics;
	public HashMap<String, Object[][]> adminArgProcessing;
	public HashMap<String, Object[][]> adminPhoneMetrics;
	
	public Calendar lastUpdatePrc;
	public HashMap<String, HashMap<String, Object[][]>> prcArgProcessing;
	public Object[][] prcRejections;
	
	public Calendar lastUpdateFinance;
	
	// Delivery
	public Calendar lastUpdateDelivery;
	public HashMap<String, Object[][]> deliveryArgProcessing;
	
	public Calendar lastUpdateClientManagement;
	
}
