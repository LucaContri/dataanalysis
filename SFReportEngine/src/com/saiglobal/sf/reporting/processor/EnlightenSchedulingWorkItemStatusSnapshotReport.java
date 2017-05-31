package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.datasource.DRDataSource;

public class EnlightenSchedulingWorkItemStatusSnapshotReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(EnlightenSchedulingWorkItemStatusSnapshotReport.class);
	private static final Calendar today = new GregorianCalendar();
	
	public EnlightenSchedulingWorkItemStatusSnapshotReport() {
		
	}
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		
		TextColumnBuilder<String> siteCertificationColumn = col.column("Site Certification", "site_certification", type.stringType());
		TextColumnBuilder<String> clientSiteColumn = col.column("Client Site", "client_site", type.stringType());
		TextColumnBuilder<String> workPackageColumn = col.column("Work Package", "work_package_name", type.stringType());		
		TextColumnBuilder<String> workItemColumn = col.column("Work Item", "work_item_name", type.stringType());
		TextColumnBuilder<String> schedulingOwnershipColumn  = col.column("Scheduling Ownership",   "scheduling_ownership",  type.stringType());
		TextColumnBuilder<String> schedulerColumn  = col.column("Scheduler",   "scheduler_name",  type.stringType());
		TextColumnBuilder<Date> targetDateColumn  = col.column("Target Date",   "target_date",  type.dateType()).setPattern("dd/MM/yyyy");
		TextColumnBuilder<Date> startDateColumn  = col.column("Start Date",   "start_date",  type.dateType()).setPattern("dd/MM/yyyy");
		TextColumnBuilder<String> statusColumn  = col.column("Status",   "status",  type.stringType());
		TextColumnBuilder<String> openSubStatusColumn  = col.column("Open Substatus",   "open_substatus",  type.stringType());
		TextColumnBuilder<String> complexityColumn  = col.column("Complexity",   "complexity",  type.stringType());
		
		report
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .columns(siteCertificationColumn, clientSiteColumn, workPackageColumn, workItemColumn, schedulingOwnershipColumn, schedulerColumn, targetDateColumn, startDateColumn, statusColumn, openSubStatusColumn, complexityColumn)
		  .setDataSource(data[0]);
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() {

		String query = "select c.Name as 'SiteCertName', c.Client_Site_NOLINK__c as 'ClientSite', wp.Name as 'WorkPackageName', wi.Name as 'WorkItemName', wi.Scheduling_Ownership__c as 'SchedulingOwnership', u.Name as 'SchedulerName', wi.Service_Target_date__c as 'TargetDate', wi.work_item_Date__c as 'StartDate', wi.Status__c as 'Status', wi.Open_Sub_Status__c as 'OpenSubStatus', wi.Scheduling_Complexity__c "
				+ "from work_item__c wi "
				+ "inner join work_package__c wp on wi.Work_Package__c = wp.Id "
				+ "inner join certification__c c on wp.Site_Certification__c = c.Id "
				+ "inner join user u on c.Scheduler__c = u.Id "
				+ "where wi.Scheduling_Ownership__c like 'AUS%' "
				+ "and Service_Target_date__c<=date_add(now(), INTERVAL 13 MONTH) "
				+ "and wi.Status__c in ('Open', 'Scheduled', 'Scheduled - Offered', 'Service change')";
		try {
			ResultSet rs = db.executeSelect(query, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("site_certification");
			variables.add("client_site"); 
			variables.add("work_package_name");
			variables.add("work_item_name");
			variables.add("scheduling_ownership");
			variables.add("scheduler_name");
			variables.add("target_date");
			variables.add("start_date");
			variables.add("status");
			variables.add("open_substatus");
			variables.add("complexity");
			
			data = new DRDataSource[] {
					// data[0] - Summary
					new DRDataSource(variables.toArray(new String[variables.size()])) 
					} ;
			
			while (rs.next()) {
				// Save current
				List<Object> values = new ArrayList<Object>();
				values.add(rs.getString("SiteCertName"));
				values.add(rs.getString("ClientSite"));
				values.add(rs.getString("WorkPackageName"));
				values.add(rs.getString("WorkItemName"));
				values.add(rs.getString("SchedulingOwnership"));
				values.add(rs.getString("SchedulerName"));
				Date targetDate = null;
				Date startDate = null;
				try {
					targetDate = Utility.getActivitydateformatter().parse(rs.getString("TargetDate"));
					startDate = Utility.getActivitydateformatter().parse(rs.getString("StartDate"));
				} catch (ParseException pe) {
					logger.error("", pe);
				}
				values.add(targetDate);
				values.add(startDate);
				values.add(rs.getString("Status"));
				values.add(rs.getString("OpenSubStatus"));
				values.add(rs.getString("Scheduling_Complexity__c"));
				
				data[0].add(values.toArray());
			}
		
		} catch (SQLException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		} catch (ClassNotFoundException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		} catch (IllegalAccessException e) {
			logger.error("", e);	
			Utility.handleError(gp, e);		
		} catch (InstantiationException e) {
			logger.error("", e);
			Utility.handleError(gp, e);
		}
	}
	
	public void setDb(DbHelper db) {
		this.db = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}
	
	public String[] getReportNames() {
		return new String[] {
				"\\Enlighten\\SchedulingWIP_" + Utility.getActivitydateformatter().format(today.getTime())
				};
	}
	
	public boolean append() {
		return false;
	}
}
