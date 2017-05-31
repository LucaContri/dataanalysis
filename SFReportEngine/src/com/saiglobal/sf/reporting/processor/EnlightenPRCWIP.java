package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenPRCWIP extends AbstractQueryReport {

	public EnlightenPRCWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select epw.`Team`, '' as 'User', epw.`Activity`, sum(epw.`WIP`) as 'WIP', epw.`Date/Time` "
				+ "from enlighten_prc_wip epw "
				+ "group by epw.`Team`, epw.`Activity`;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_PRC_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}

}
