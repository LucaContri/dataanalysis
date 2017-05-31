package com.saiglobal.sf.reporting.processor;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

public interface ReportBuilder {
	
	public boolean append();
	public boolean concatenatedReports();
	public JasperReportBuilder[] generateReports();
	
	public void setDb(DbHelper db);
	
	public void setProperties(GlobalProperties gp);
	
	public void init() throws Exception, Throwable;
	
	public String[] getReportNames();
}
