package com.saiglobal.sf.reporting.processor;

import java.util.Calendar;

import com.saiglobal.sf.core.utility.Utility;

public class AuditorPersonalisedSLAReport extends AbstractQueryReport {

	private static final int FROM_MONTHS_BEFORE = 6;
	private String auditor = null;
	private Calendar dateFrom = null;
	private Calendar dateTo = null;
	
	public AuditorPersonalisedSLAReport() {
		setHeader(false);
		
	}
	
	@Override
	protected void setCurrentDataSource() {
		this.gp.setCurrentDataSource("analytics");
	}
	
	@Override
	protected void initialiseQuery() throws Exception {
		auditor  = this.gp.getCustomParameter("auditor");
		dateTo = Calendar.getInstance();
		dateTo.set(Calendar.DATE, dateTo.getActualMaximum(Calendar.DATE));
		dateFrom = Calendar.getInstance();
		dateFrom.add(Calendar.MONTH, -FROM_MONTHS_BEFORE);
		dateFrom.set(Calendar.DATE, 1);
	}
	
	@Override
	protected String getQuery() {
		if (auditor == null)
			return "";
		
		return "call GetAuditorMetricsForPeriod('" + auditor + "', '" + Utility.getActivitydateformatter().format(dateFrom.getTime())+ "', '" + Utility.getActivitydateformatter().format(dateTo.getTime())+ "');";
	}

	@Override
	protected String getReportName() {
		return "Auditors\\" + auditor + ".SLAReport";
	}
	
	@Override
	protected String getTitle() {
		return auditor + " SLA and Backlogs Report";
	}
}
