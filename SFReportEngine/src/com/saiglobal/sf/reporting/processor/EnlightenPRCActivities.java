package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenPRCActivities extends AbstractQueryReport {

	public EnlightenPRCActivities() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select epa.`Team`, epa.`User`, epa.`Activity`, sum(epa.`Completed`) as 'Completed', epa.`Date/Time`, group_concat(distinct epa.`ARG Names`) as 'Notes' "
				+ "from enlighten_prc_activity epa "
				+ "group by epa.`Team`, epa.`User`, epa.`Activity`;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_Complete_PRC_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
