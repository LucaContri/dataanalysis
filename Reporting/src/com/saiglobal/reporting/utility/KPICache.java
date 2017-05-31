package com.saiglobal.reporting.utility;

import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.HashMap;
import java.util.concurrent.Semaphore;

import com.saiglobal.reporting.model.KPIData;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Region;

public class KPICache {
	private static HashMap<Region, KPICache> reference= new HashMap<Region, KPICache>();
	private static final int refreshIntervalHrs = 24*7;
	private DbHelper db_certification = null;
	private DbHelper db_tis = null;
	private KPIData data;
	private Semaphore update = new Semaphore(1);
	private static final SimpleDateFormat periodFormat = new SimpleDateFormat("yyyy-MM");
	private static final NumberFormat df = DecimalFormat.getInstance();
	private String[] periods;
	private static final int periodsToReport = 6;
	
	private KPICache(DbHelper db_certification, DbHelper db_tis, Region region) {
		this.db_certification = db_certification;
		this.db_tis = db_tis;
		data = new KPIData(region);
		df.setMinimumFractionDigits(2);
		df.setMaximumFractionDigits(2);
		df.setRoundingMode(RoundingMode.HALF_UP);
		
		// Init Periods to report - last 6 months?
		
		Calendar today = Calendar.getInstance();
		today.add(Calendar.MONTH, -periodsToReport+1);
		periods = new String[periodsToReport];
		for (int i=0; i<periodsToReport; i++) {
			periods[i] = periodFormat.format(today.getTime());
			today.add(Calendar.MONTH, 1);
		}
		
	}

	public static KPICache getInstance(DbHelper db_certification, DbHelper db_tis, Region region) {
		if (region == null) {
			return null;
		}
		if( reference == null) {
			reference = new HashMap<Region, KPICache>();
		}
		if (!reference.containsKey(region)) {
			synchronized (  KPICache.class) {
			  	reference.put(region, new KPICache(db_certification, db_tis, region));
			}
		}
		return  reference.get(region);
	}

	public KPIData getAllDataArray(boolean forceRefresh) throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		try {
			update.acquire();
			if(data.region.isEnabled() && (data.lastUpdateReportDate == null || data.lastUpdateReportDate.before(intervalBefore) || forceRefresh)) {
				updateAllData();		
				this.data.lastUpdateReportDate = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return data;
	}
	
	private void updateAllData() throws Exception {
		// Sales
		updateSales();
		
		// Back Office
		updateNewBusiness();
		updateScheduling();
		updateAdministration();
		updatePrcData();
		updateFinance();
		
		// Delivery
		updateDelivery();
		updateClientManagement();
	}
	
	private void updateSales() throws Exception {
		KPIProcessorSales processor = new KPIProcessorSales(db_certification, db_tis, periodsToReport);
		
		try {
			this.data.salesPhoneMetrics = new HashMap<String, Object[][]>();
			this.data.salesPhoneMetrics.put(KPIData.CHART, processor.getPhoneMetrics());
			this.data.salesPhoneMetrics.put(KPIData.TABLE, transposeMatrix(this.data.salesPhoneMetrics.get(KPIData.CHART)));
			
			this.data.lastUpdateSalesPhoneMetrics = processor.getPhoneMetricsLastUpdate();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updateNewBusiness() throws Exception {
		KPIProcessorNewBusiness processor = new KPIProcessorNewBusiness(db_certification, db_tis, periodsToReport);
		
		try {
			this.data.oppProcessingDays = new HashMap<String, Object[][]>();
			this.data.oppProcessingDays.put(KPIData.CHART, processor.getNBProcessingDays());
			this.data.oppProcessingDays.put(KPIData.TABLE, transposeMatrix(this.data.oppProcessingDays.get(KPIData.CHART)));
			
			this.data.lastUpdateNewBusiness = Calendar.getInstance();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updateScheduling() throws Exception {
		KPIProcessorScheduling processor = new KPIProcessorScheduling(db_certification, db_tis, periodsToReport);
		
		try {
			// Scheduling - Confirmed, Scheduled & Open Ratios
			this.data.schedulingConfirmedRatios = new HashMap<String, HashMap<String, Object[][]>>();
			this.data.schedulingConfirmedRatios.put(KPIData.CHART, processor.getConfirmedOpenRatios());
			HashMap<String, Object[][]> tableData = new HashMap<String, Object[][]>();
			for (String stream : this.data.schedulingConfirmedRatios.get(KPIData.CHART).keySet()) {
				tableData.put(stream, transposeMatrix(this.data.schedulingConfirmedRatios.get(KPIData.CHART).get(stream)));
			}
			this.data.schedulingConfirmedRatios.put(KPIData.TABLE, tableData);
			
			//this.data.onTargetRatios = new HashMap<String, Object[][]>();
			//this.data.onTargetRatios.put(KPIData.CHART, processor.getOnTargetRatios());
			//this.data.onTargetRatios.put(KPIData.TABLE, transposeMatrix(this.data.onTargetRatios.get(KPIData.CHART)));
			
			//HashMap<String, Object[][]> validatedData = processor.getDataValidated();
			this.data.schedulingValidated= new HashMap<String, HashMap<String, Object[][]>>();
			this.data.schedulingValidated.put(KPIData.TABLE, new HashMap<String, Object[][]>());
			this.data.schedulingValidated.put(KPIData.CHART, processor.getDataValidated());
			for (String stream : this.data.schedulingValidated.get(KPIData.CHART).keySet()) {
				this.data.schedulingValidated.get(KPIData.TABLE).put(stream, transposeMatrix(this.data.schedulingValidated.get(KPIData.CHART).get(stream)));
				//this.data.schedulindValidated.get(KPIData.CHART).put(stream, transposeMatrix(transposeMatrix(validatedData.get(stream))));
			}

			for(int i=1; i<this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD).length; i++) {
				double den = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][1] + (double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][2]);
				if (den==0) {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][1] = null;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][2] = null;
				} else {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][1] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][1]) / den * 100;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][2] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.FOOD)[i][2]) / den * 100;
				}
				den = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][1] + (double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][2]);
				if (den==0) {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][1] = null;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][2] = null;
				} else {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][1] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][1]) / den * 100;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][2] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.MS)[i][2]) / den * 100;
				}
				den = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][1] + (double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][2]);
				if (den==0) {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][1] = null;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][2] = null;
				} else {
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][1] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][1]) / den * 100;
					this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][2] = ((double) this.data.schedulingValidated.get(KPIData.CHART).get(KPIData.PS)[i][2]) / den * 100;
				}
			}
			
			// Scheduling - Auditors Utilisation
			this.data.schedulingAuditorsUtilisation = new HashMap<String, HashMap<String, Object[][]>>();
			this.data.schedulingAuditorsUtilisation.put(KPIData.CHART, processor.getAuditorsUtilisation());
			HashMap<String, Object[][]> tableData2 = new HashMap<String, Object[][]>();
			for (String stream : this.data.schedulingAuditorsUtilisation.get(KPIData.CHART).keySet()) {
				tableData2.put(stream, transposeMatrix(this.data.schedulingAuditorsUtilisation.get(KPIData.CHART).get(stream)));
			}
			this.data.schedulingAuditorsUtilisation.put(KPIData.TABLE, tableData2);
			this.data.lastUpdateSchedulingAuditorsUtilisation = processor.getAuditorsUtilisationLastUpdate();
						
			this.data.lastUpdateScheduling = Calendar.getInstance();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updateAdministration() throws Exception {
		KPIProcessorAdmin processor = new KPIProcessorAdmin(db_certification, db_tis, periodsToReport);
		
		try {
			this.data.adminArgProcessing = new HashMap<String, Object[][]>();
			this.data.adminArgProcessing.put(KPIData.CHART, processor.getARGProcessingDays());
			this.data.adminArgProcessing.put(KPIData.TABLE, transposeMatrix(this.data.adminArgProcessing.get(KPIData.CHART)));
			
			this.data.adminPhoneMetrics = new HashMap<String, Object[][]>();
			this.data.adminPhoneMetrics.put(KPIData.CHART, processor.getPhoneMetrics());
			this.data.adminPhoneMetrics.put(KPIData.TABLE, transposeMatrix(this.data.adminPhoneMetrics.get(KPIData.CHART)));
			
			this.data.lastUpdateAdminPhoneMetrics = processor.getPhoneMetricsLastUpdate();
			
			this.data.lastUpdateAdmin = Calendar.getInstance();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updatePrcData() throws Exception {
		KPIProcessorPRC processor = new KPIProcessorPRC(db_certification, db_tis, periodsToReport);
		
		try {
			this.data.prcArgProcessing = new HashMap<String, HashMap<String, Object[][]>>();
			this.data.prcArgProcessing.put(KPIData.CHART, processor.getARGProcessingDays());
			HashMap<String, Object[][]> tableData = new HashMap<String, Object[][]>();
			for (String stream : this.data.prcArgProcessing.get(KPIData.CHART).keySet()) {
				tableData.put(stream, transposeMatrix(this.data.prcArgProcessing.get(KPIData.CHART).get(stream)));
			}
			this.data.prcArgProcessing.put(KPIData.TABLE, tableData);
			
			this.data.prcRejections = processor.getRejectionsByAuditorPeriod();
			this.data.lastUpdatePrc = Calendar.getInstance();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updateFinance() throws Exception {
		// TODO: To be implemented
	}
	
	private void updateDelivery() throws Exception {
		KPIProcessorDelivery processor = new KPIProcessorDelivery(db_certification, db_tis, periodsToReport);
		
		try {
			this.data.deliveryArgProcessing = new HashMap<String, Object[][]>();
			this.data.deliveryArgProcessing.put(KPIData.CHART, processor.getARGProcessingDays());
			this.data.deliveryArgProcessing.put(KPIData.TABLE, transposeMatrix(this.data.deliveryArgProcessing.get(KPIData.CHART)));
			
			this.data.lastUpdateDelivery = Calendar.getInstance();
		} catch (Exception e) {
			throw e;
		}
	}
	
	private void updateClientManagement() throws Exception {
		// TODO: To be implemented
	}
	
	private static Object[][] transposeMatrix(Object [][] m){
		Object[][] temp = new Object[m[0].length][m.length];
        for (int i = 0; i < m.length; i++)
            for (int j = 0; j < m[0].length; j++)
            	temp[j][i] = m[i][j];
        return temp;
    }
}
