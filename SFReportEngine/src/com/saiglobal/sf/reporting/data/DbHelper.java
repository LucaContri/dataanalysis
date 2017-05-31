package com.saiglobal.sf.reporting.data;

import java.sql.SQLException;

import com.saiglobal.sf.core.utility.GlobalProperties;

public class DbHelper extends com.saiglobal.sf.core.data.DbHelper {

	public DbHelper(GlobalProperties cmd) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		super(cmd);
		//executeStatement(getSFTableReportHistorySql());
	}
	
	public String getLatestAsStringFrom(String reportName, String rowName, String columnName) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		String query = 
				"SELECT Value FROM " + getDBTableName(ReportHistoryTableName) + " WHERE " +
					"ReportName = '" + reportName + "' AND " +
					"RowName = '" + rowName + "' AND " +
					"ColumnName = '" + columnName + "' " +
				"ORDER BY Date DESC";
		return executeScalar(query);
	}
	
	public double getLatestAsDoubleFrom(String reportName, String rowName, String columnName) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		return Double.parseDouble(getLatestAsStringFrom(reportName, rowName, columnName));
	}
	
	public int getLatestAsIntFrom(String reportName, String rowName, String columnName) throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		return Integer.parseInt(getLatestAsStringFrom(reportName, rowName, columnName));
	}
}
