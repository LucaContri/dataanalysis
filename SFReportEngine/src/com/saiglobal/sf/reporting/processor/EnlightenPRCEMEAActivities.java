package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class EnlightenPRCEMEAActivities extends AbstractQueryReport {
	private SimpleDateFormat format;
	private SimpleDateFormat formatExcel;
	public EnlightenPRCEMEAActivities() {
		setHeader(false);
		format = new SimpleDateFormat("yyyy-MM-dd");
		formatExcel = new SimpleDateFormat("dd/MM/yyyy");
		TimeZone tzLondon = TimeZone.getTimeZone("Europe/London");
		format.setTimeZone(tzLondon);
		formatExcel.setTimeZone(tzLondon);
	}
	
	@Override
	protected String getQuery() {
		return "select epa.`Team`, epa.`User`, epa.`Activity`, sum(epa.`Completed`) as 'Completed', '" + formatExcel.format(reportDate.getTime()) + "' as 'Date/Time', group_concat(distinct epa.`ARG Names`) as 'Notes' "
				+ "from enlighten_prc_emea_activity epa "
				+ "group by epa.`Team`, epa.`User`, epa.`Activity`;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_PRC_EMEA_" + format.format(reportDate.getTime());
	}
}
