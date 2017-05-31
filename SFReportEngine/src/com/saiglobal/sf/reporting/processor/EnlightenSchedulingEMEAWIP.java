package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class EnlightenSchedulingEMEAWIP extends AbstractQueryReport {
	private SimpleDateFormat format;
	private SimpleDateFormat formatExcel;
	public EnlightenSchedulingEMEAWIP() {
		setHeader(false);
		format = new SimpleDateFormat("yyyy-MM-dd");
		formatExcel = new SimpleDateFormat("dd/MM/yyyy");
		TimeZone tzLondon = TimeZone.getTimeZone("Europe/London");
		format.setTimeZone(tzLondon);
		formatExcel.setTimeZone(tzLondon);
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("analytics");
	}
	
	@Override
	protected String getQuery() {
		return "SELECT 'Scheduling EMEA' as 'Team', '' AS 'User', `Activity`, COUNT(*) AS 'WIP', '" + formatExcel.format(reportDate.getTime()) + "' AS 'Date/Time' "
				+ "FROM `sla_scheduling_backlog` "
				+ "WHERE `Region` like 'EMEA - UK' "
				+ "GROUP BY `Activity`";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_Scheduling_EMEA_" + format.format(reportDate.getTime());
	}

}
