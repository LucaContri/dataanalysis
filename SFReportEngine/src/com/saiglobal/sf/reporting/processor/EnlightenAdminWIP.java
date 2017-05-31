package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenAdminWIP extends AbstractQueryReport {

	public EnlightenAdminWIP() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select `Team`, '' as 'User', `Activity`, sum(`WIP`) as 'WIP', `Date/Time` "
				+ "from Enlighten_Admin_WIP "
				+ "group by `Team`, `Activity`";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_WIP_Admin_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
