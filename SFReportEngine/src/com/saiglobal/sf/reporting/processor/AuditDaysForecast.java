package com.saiglobal.sf.reporting.processor;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.GregorianCalendar;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

public class AuditDaysForecast implements ReportBuilder {
	private DbHelper db_certification;
	private final Calendar today = new GregorianCalendar();
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy MM");
	private static final int noPeriodsToForecast = 6; // including current period
	private static final int noOfPastPeriodsToUseInForecast = 3;  // forecast is based on average of last 'n' available periods
	private String[] periods;
	
	public boolean concatenatedReports() {
		return false;
	}
	
	public AuditDaysForecast() {
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

	@Override
	public void init() throws Exception {
		// 1) Calculate forecast factors and save in temporary table		
		String drop = "drop temporary table if exists forecasting_factors";
		db_certification.executeStatement(drop);
		
		String create = "CREATE TEMPORARY TABLE IF NOT EXISTS forecasting_factors AS "
				+ "select t2.*, t2.`Days`/t2.`Final Days` as 'Percentace Final' from ("
				+ "select t.*, "
				+ "str_to_date(concat(t.Period, ' 1'), '%Y %m %d') as 'Period 1st', "
				+ "date_add(str_to_date(concat(t.Period, ' 1'), '%Y %m %d'), interval mod(9-dayofweek(str_to_date(concat(t.Period, ' 1'), '%Y %m %d')),7) day) as 'Period 1st Monday', "
				+ "datediff(date_add(str_to_date(concat(t.Period, ' 1'), '%Y %m %d'), interval mod(9-dayofweek(str_to_date(concat(t.Period, ' 1'), '%Y %m %d')),7) day), t.`Snapshot Date`) as 'Days to Period 1st Monday',"
				+ "datediff(date_add(str_to_date(concat(t.Period, ' 1'), '%Y %m %d'), interval mod(9-dayofweek(str_to_date(concat(t.Period, ' 1'), '%Y %m %d')),7) day), t.`Snapshot Date`)/7 as 'Weeks to Period 1st Monday', "
				+ "if(t.`Period`<'2014 07',"
				+ "(select Value from sf_report_history where ReportName in (concat('Planning Days Report - ', t.Stream)) and RowName in ('Total Available') and ColumnName = t.`Period` order by Date desc limit 1), "
				+ "(select sum(value) from sf_report_history where ReportName='Audit Days Snapshot' and Date = (select max(Date) from sf_report_history where ReportName='Audit Days Snapshot') and Region like 'Australia%' and ColumnName=t.`Period` and RowName like concat(t.`Stream`,'%') and RowName not like '%Cancelled')) as 'Final Days' "
				+ "from ("
				+ "(select Date as 'Snapshot Date', 'Food' as 'Stream', 'Available' as 'Metric', ColumnName as 'Period', Value as 'Days' "
				+ "from sf_report_history where ReportName in ('Planning Days Report - Food') "
				+ "and RowName in ('Total Available') "
				+ "and Date > '2013-11-01' "
				+ "and Date < '2014-07-01') "
				+ "union "
				+ "(select str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date', 'Food' as 'Stream', 'Available' as 'Metric', Period, sum(Value) as 'Days' "
				+ "from financial_visisbility "
				+ "where `Region` like 'Australia%' "
				+ "and `Revenue Stream` in ('Food') "
				+ "and `Period`>'2014 06' "
				+ "and `Period` < '" + periods[0] + "' "
				+ "and `Audit Status` not in ('Cancelled') "
				+ "and dayofweek(str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') ) = 2 "
				+ "and str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')>'2014-04-07 12:00:00' "
				+ "group by `Snapshot Date`, `Period`) "
				+ "union "
				+ "(select Date as 'Snapshot Date', 'MS' as 'Stream', 'Available' as 'Metric', ColumnName as 'Period', Value as 'Days' "
				+ "from sf_report_history where ReportName in ('Planning Days Report - MS') "
				+ "and RowName in ('Total Available') "
				+ "and Date > '2013-11-01' "
				+ "and Date < '2014-07-01') "
				+ "union "
				+ "(select str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date', 'MS' as 'Stream', 'Available' as 'Metric', Period, sum(Value) as 'Days' "
				+ "from financial_visisbility "
				+ "where `Region` like 'Australia%' "
				+ "and `Revenue Stream` in ('MS') "
				+ "and `Period`>'2014 06' "
				+ "and `Period` < '" + periods[0] + "' "
				+ "and `Audit Status` not in ('Cancelled') "
				+ "and dayofweek(str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') ) = 2 "
				+ "and str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')>'2014-04-07 12:00:00' "
				+ "and str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') not in ('2014-05-05 14:06:21','2014-06-10 01:00:05', '2014-04-07 11:19:55','2014-04-07 11:28:49','2014-06-04 11:23:05','2014-06-04 14:43:35','2014-06-13 10:17:59','2014-06-13 13:27:38') "
				+ "group by `Snapshot Date`, `Period`)) t "
				+ "where t.`Period` < '" + periods[0] + "' "
				+ ") t2;";
		
		db_certification.executeStatement(create);
		
		// 2) For each period, calculate forecast days based on forecast factors at 1)
		
		for (String period : periods) {
			// Forecast current period MS
			String queryMS = "select ("
					+ "(select sum(value) from sf_report_history  "
					+ "where ReportName='Audit Days Snapshot' "
					+ "and Date = (select max(Date) from sf_report_history where ReportName='Audit Days Snapshot') "
					+ "and Region like 'Australia%' "
					+ "and ColumnName='" + period + "' "
					+ "and RowName like 'MS%' "
					+ "and RowName not like '%Cancelled') "
					+ "/"
					+ "(select avg(t.`Percentace Final`) from ("
					+ "select * from forecasting_factors ff "
					+ "where ff.`Weeks to Period 1st Monday` = " + getWeeksToFirstMondayOfPeriod(period) + " "
					+ "and ff.`Stream`='MS' "
					+ "order by ff.`Period` desc "
					+ "limit " + noOfPastPeriodsToUseInForecast
					+ ") t)) as 'Forecast'";
			int forecastMS = db_certification.executeScalarInt(queryMS);
			
			// Forecast current period Food
			String queryFood = "select ("
					+ "(select sum(value) from sf_report_history  "
					+ "where ReportName='Audit Days Snapshot' "
					+ "and Date = (select max(Date) from sf_report_history where ReportName='Audit Days Snapshot') "
					+ "and Region like 'Australia%' "
					+ "and ColumnName='" + period + "' "
					+ "and RowName like 'Food%' "
					+ "and RowName not like '%Cancelled') "
					+ "/"
					+ "(select avg(t.`Percentace Final`) from ("
					+ "select * from forecasting_factors ff "
					+ "where ff.`Weeks to Period 1st Monday` = " + getWeeksToFirstMondayOfPeriod(period) + " "
					+ "and ff.`Stream`='Food' "
					+ "order by ff.`Period` desc "
					+ "limit " + noOfPastPeriodsToUseInForecast
					+ ") t)) as 'Forecast'";
			int forecastFood = db_certification.executeScalarInt(queryFood);
			
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

	private int getWeeksToFirstMondayOfPeriod(String period) throws ParseException {
		int MILLIS_IN_WEEK = 1000 * 60 * 60 * 24 * 7;
		Calendar aux = Calendar.getInstance();
	    aux.setTime(periodFormatter.parse(period));
	    while (aux.get(Calendar.DAY_OF_WEEK) != 2) {
	        aux.add(Calendar.DATE, 1);
	    }
	    return (int) Math.round(((double)aux.getTimeInMillis()-(double)today.getTimeInMillis())/MILLIS_IN_WEEK);
	}
	
	public boolean append() {
		return false;
	}
}
