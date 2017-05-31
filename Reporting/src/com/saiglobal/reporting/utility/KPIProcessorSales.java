package com.saiglobal.reporting.utility;

import java.sql.ResultSet;

import com.saiglobal.sf.core.data.DbHelper;

public class KPIProcessorSales extends AbstractKPIProcessor {

	public KPIProcessorSales(DbHelper db_certification, DbHelper db_tis,int periodsToReport) {
		super(db_certification, db_tis, periodsToReport);
	}
	
	public Object[][] getPhoneMetrics() throws Exception {
		Object[][] returnValue = new Object[periodsToReport+1][5];
		returnValue[0] = new Object[] {"Period", "Handled #", "Abandoned/Interflowed #", "Avg Answering Time (s)", "Avg Handling Time (s)"};
		String query = "select t2.*,"
				+ "round(t2.`Total Handling Time`/t2.`ACD calls handled`,0) as 'Avg Handling Time',"
				+ "round(t2.`Total Answering Time`/t2.`ACD calls handled`,0) as 'Avg Answering Time' "
				+ "from ("
				+ "select t.`Period`,"
				+ "round(sum(t.`ACD calls offered`),0) as 'ACD calls offered',"
				+ "round(sum(t.`ACD calls handled`),0) as 'ACD calls handled',"
				+ "round(sum(t.`Average ACD handling time (sec)`*t.`ACD calls handled`),0) as 'Total Handling Time',"
				+ "round(sum(t.`Average speed of answer (sec)`*t.`ACD calls handled`),0) as 'Total Answering Time' from ("
				+ "select "
				+ "RefDate,"
				+ "RefName,"
				+ "date_format(RefDate, '%Y %m') as 'Period',"
				+ "sum(if (DataSubType='ACD calls handled', refValue,0)) as 'ACD calls handled',"
				+ "sum(if (DataSubType='ACD calls offered', refValue,0)) as 'ACD calls offered',"
				+ "sum(if (DataSubType='Average speed of answer (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average speed of answer (sec)',"
				+ "sum(if (DataSubType='Average ACD handling time (hh:mm:ss)', refValue,null))/0.00001144080897 as 'Average ACD handling time (sec)' "
				+ "from sf_data "
				+ "where DataType='Mitel' "
				+ "and RefName in ('Public Training','In-House','Online Learning','Recognition') "
				+ "and date_format(RefDate, '%Y %m') <= date_format(now(), '%Y %m') "
				+ "and date_format(RefDate, '%Y %m') >= date_format(date_add(now(), interval " + (1-periodsToReport) + " month), '%Y %m') "
				+ "group by RefDate, RefName) t "
				+ "group by t.`Period`) t2";
		
		ResultSet rs = db_certification.executeSelect(query, -1);
		
		while (rs.next()) {
			returnValue[rs.getRow()] = new Object[] {displayMonthFormat.format(mysqlPeriodFormat.parse(rs.getString("Period"))), rs.getInt("ACD calls handled"), rs.getInt("ACD calls offered") - rs.getInt("ACD calls handled"), rs.getInt("Avg Answering Time"), rs.getInt("Avg Handling Time")};
		}
		
		return returnValue;
	}
}
