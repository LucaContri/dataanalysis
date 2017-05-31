package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.Utility;

public class EnlightenPRCELTRejections extends AbstractQueryReport {

	public EnlightenPRCELTRejections() {
		setHeader(false);
	}
	
	@Override
	protected String getQuery() {
		return "select * from enlighten_prc_elt_rejections;";
	}

	@Override
	protected String getReportName() {
		return "\\Enlighten\\Enlighten_ELT_PRC_" + Utility.getActivitydateformatter().format(reportDate.getTime());
	}
}
