package com.saiglobal.sf.reporting.processor;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

public class EnlightenPRCEMEAWIP extends AbstractQueryReport {
	private SimpleDateFormat format;
	private SimpleDateFormat formatExcel;
	public EnlightenPRCEMEAWIP() {
		setHeader(false);
		format = new SimpleDateFormat("yyyy-MM-dd");
		formatExcel = new SimpleDateFormat("dd/MM/yyyy");
		TimeZone tzLondon = TimeZone.getTimeZone("Europe/London");
		format.setTimeZone(tzLondon);
		formatExcel.setTimeZone(tzLondon);
	}
	
	@Override
	protected String getQuery() {
		return "select epw.`Team`, '' as 'User', epw.`Activity`, sum(epw.`WIP`) as 'WIP', '" + formatExcel.format(reportDate.getTime()) + "' as 'Date/Time', group_concat(distinct epw.`ARG Names`) as 'Notes' "
				+ "from enlighten_prc_emea_wip epw "
				+ "group by epw.`Team`, epw.`Activity`;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_PRC_EMEA_" + format.format(reportDate.getTime());
	}

}
