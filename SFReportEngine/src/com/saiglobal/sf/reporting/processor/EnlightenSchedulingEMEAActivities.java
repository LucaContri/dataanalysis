package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class EnlightenSchedulingEMEAActivities extends AbstractQueryReport {
	private SimpleDateFormat format;
	private SimpleDateFormat formatExcel;
	public EnlightenSchedulingEMEAActivities() {
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
		return "select 'Scheduling EMEA' as 'Team', `Owner` as 'User', `Activity`, count(*) as 'Completed', '" + formatExcel.format(reportDate.getTime()) + "' as 'Date/Time', group_concat(distinct Id) as 'Notes' "
				+ "from sla_scheduling_completed "
				+ "where `To` > date_add(utc_timestamp(), interval -1 day) "
				//+ "and Region like 'EMEA - UK' "
				+ "group by `User`, `Activity`";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_Scheduling_EMEA_" + format.format(reportDate.getTime());
	}
}
