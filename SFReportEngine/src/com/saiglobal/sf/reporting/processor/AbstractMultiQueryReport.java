package com.saiglobal.sf.reporting.processor;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.reporting.data.DbHelper;

public abstract class AbstractMultiQueryReport implements ReportBuilder {
	protected DbHelper db;
	protected GlobalProperties gp;
	protected static final Logger logger = Logger.getLogger(AbstractMultiQueryReport.class);
	protected boolean append = false;
	protected AbstractQueryReport[] reports = null;
	
	public boolean concatenatedReports() {
		return true;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		List<JasperReportBuilder> reportbuilders = new ArrayList<JasperReportBuilder>();
		for (AbstractQueryReport report : reports) {
			JasperReportBuilder[] individualReportBuilders = report.generateReports();
			if ((individualReportBuilders != null) && (individualReportBuilders.length > 0) && individualReportBuilders[0] != null) 
				reportbuilders.add(individualReportBuilders[0]);
		}
		return reportbuilders.toArray(new JasperReportBuilder[reportbuilders.size()]);
	}
			
	@Override
	public void setDb(DbHelper db) {
		this.db = db;
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}
	
	@Override
	public void init() throws Throwable {
		reports = getReports();
		for (AbstractQueryReport report : reports) {
			report.setDb(db);
			report.setProperties(gp);
			report.init();
		}
	}

	@Override
	public String[] getReportNames() {
		List<String> reportNames = new ArrayList<String>();
		for (AbstractQueryReport report : reports) {
			if ((report.getReportNames() != null) && (report.getReportNames().length > 0) && (report.getReportNames()[0] != null)) 
				reportNames.add(report.getReportNames()[0]);
			else 
				reportNames.add("");
		}
		return reportNames.toArray(new String[reportNames.size()]);
	}
	
	protected abstract AbstractQueryReport[] getReports();
}
