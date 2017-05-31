package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.GregorianCalendar;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

public class AuditDaysForecastV2 implements ReportBuilder {
	private DbHelper db_certification;
	private final Calendar today = new GregorianCalendar();
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	private static final int noPeriodsToForecast = 6; // including current period
	private static final int noOfPastPeriodsToUseInForecast = 3;  // forecast is based on average of last 'n' available periods
	private String[] periods;
	
	public boolean concatenatedReports() {
		return false;
	}
	
	public AuditDaysForecastV2() {
		periods = getPeriods();
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		return new JasperReportBuilder[0];
	}

	@Override
	public void setDb(DbHelper db) {
		this.db_certification = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
	}

	private String getQuery(String period, String stream) {
		// Calculate forecasting factors on the fly
		return "select "
				// Current (latest) available days for period
				+ "(select sum(Value) as 'Available Days' "
				+ "from financial_visisbility_latest "
				+ "where `Region` like 'Australia%' "
				+ "and `Revenue Stream` = '" + stream + "' "
				+ "and `Period` = '" + period + "' "
				+ "and `Audit Status` not in ('Cancelled') "
				+ "and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null)) "
				+ "/"
				// Forecasting factor
				+ "(select avg(t1.`Available Days`/t2.`Final Confirmed`) from ("
				+ "select str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date', `Period`, sum(Value) as 'Available Days' "
				+ "from financial_visisbility "
				+ "where `Region` like 'Australia%' "
				+ "and `Revenue Stream` = '" + stream + "' "
				+ "and `Period` < '" + period + "' "
				+ "and `Period` < date_format(now(), '%Y %m') "
				+ "and `Audit Status` not in ('Cancelled') "
				+ "and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null) "
				+ "and datediff(str_to_date(concat(`Period`, ' 01'), '%Y %m %d'), str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')) = datediff(str_to_date('" + period + "01', '%Y %m %d'),now()) "
				+ "group by `Snapshot Date`, `Period` order by `Period` desc limit " + noOfPastPeriodsToUseInForecast + ") t1 "
				+ "left join ( "
				+ "select ColumnName as `Period`, sum(value) as 'Final Confirmed' from sf_report_history "
				+ "where ReportName='Audit Days Snapshot' "
				+ "and Date = (select max(Date) from sf_report_history where ReportName='Audit Days Snapshot') "
				+ "and Region like 'Australia%' "
				+ "and ColumnName < '" + period + "' "
				+ "and ColumnName < date_format(now(), '%Y %m') "
				+ "and RowName like '" + stream + "%' "
				+ "and (RowName not like '%Open%' and RowName not like '%Service Change%' and RowName not like '%Scheduled%' and RowName not like '%Cancelled%') "
				+ "group by `Period`) t2 on t2.`Period` = t1.`Period`) as 'Forecast'";
	}
	@Override
	public void init() throws Exception {
		
		
		// 2) For each period, calculate forecast days
		
		for (String period : periods) {
			// Forecast current period MS
			int forecastMS = db_certification.executeScalarInt(getQuery(period, "MS"));
			
			// Forecast current period Food
			int forecastFood = db_certification.executeScalarInt(getQuery(period, "Food"));
			
			// 3) Insert in sf_data with new "Audit Days Forecast Calculated" and mark old ones as not current
			int oldIdMS = db_certification.executeScalarInt("select Id from sf_data "
					+ "where Region ='Australia - MS' "
					+ "and DataType='Audit Days Forecast Calculated' "
					+ "and RefName='Forecast' "
					+ "and date_format(RefDate, '%Y %m') ='" + period + "' "
					+ "and current=1");
			
			db_certification.executeStatement("insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue, current) "
					+ "VALUES ('" + Utility.getMysqldateformat().format(today.getTime()) + "', 'Australia - MS', 'Audit Days Forecast Calculated', 'MS', 'Forecast', '" + Utility.getActivitydateformatter().format(periodFormatter.parse(period)) + "', " + forecastMS + ", 1)");
			
			if (oldIdMS>=0)
				db_certification.executeStatement("update sf_data set current = 0 where id=" + oldIdMS);
			
			int oldIdFood = db_certification.executeScalarInt("select Id from sf_data "
					+ "where Region ='Australia - Food' "
					+ "and DataType='Audit Days Forecast Calculated' "
					+ "and RefName='Forecast' "
					+ "and date_format(RefDate, '%Y %m') ='" + period + "' "
					+ "and current=1");
			
			db_certification.executeStatement("insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue, current) "
					+ "VALUES ('" + Utility.getMysqldateformat().format(today.getTime()) + "', 'Australia - Food', 'Audit Days Forecast Calculated', 'Food', 'Forecast', '" + Utility.getActivitydateformatter().format(periodFormatter.parse(period)) + "', " + forecastFood + ", 1)");
			
			if (oldIdFood>=0)
				db_certification.executeStatement("update sf_data set current = 0 where id=" + oldIdFood);
		}
		 

	}

	@Override
	public String[] getReportNames() {
		return new String[0];
	}
	
	private String[] getPeriods() {
		String[] periods = new String[noPeriodsToForecast];
		Calendar aux = new GregorianCalendar();
		aux.setTime(today.getTime());
		periods[0] = periodFormatter.format(aux.getTime());
		for (int i=1; i<noPeriodsToForecast; i++) {
			aux.add(Calendar.MONTH, 1);
			periods[i] = periodFormatter.format(aux.getTime()); 
		}
		return periods;
	}
	
	public boolean append() {
		return false;
	}
}
