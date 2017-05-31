package com.saiglobal.reporting.utility;

import java.text.SimpleDateFormat;
import java.util.Calendar;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public abstract class AbstractKPIProcessor {
	protected static final SimpleDateFormat mysqlPeriodFormat = new SimpleDateFormat("yyyy MM");
	protected static final SimpleDateFormat displayMonthFormat = new SimpleDateFormat("MMMM");	
	protected DbHelper db_certification = null;
	protected DbHelper db_tis = null;
	protected final int periodsToReport;
	
	public AbstractKPIProcessor(DbHelper db_certification, DbHelper db_tis, int periodsToReport) {
		this.db_certification = db_certification;
		this.db_tis = db_tis;
		this.periodsToReport = periodsToReport;
	}
	
	public Calendar getPhoneMetricsLastUpdate() throws Exception {
		String lastUpdateString = db_certification.executeScalar("select date_format(max(RefDate), '%Y-%m-%d') from sf_data where DataType='Mitel'");
		Calendar lastUpdate = Calendar.getInstance();
		lastUpdate.setTime(Utility.getActivitydateformatter().parse(lastUpdateString));
		return lastUpdate;
	}
}
