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

public class EnlightenSchedulingWorkItemStatusChangesReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(EnlightenSchedulingWorkItemStatusChangesReport.class);
	private static final Calendar today = new GregorianCalendar();
	
	public EnlightenSchedulingWorkItemStatusChangesReport() {
		
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		
		TextColumnBuilder<String> editedByColumn = col.column("Edited By", "edited_by", type.stringType());
		TextColumnBuilder<Date> editDateColumn = col.column("Edit Date", "edit_date", type.dateType()).setPattern("dd/MM/yyyy HH:mm");
		TextColumnBuilder<String> fieldEventColumn = col.column("Field/Event", "field_event", type.stringType());		
		TextColumnBuilder<String> oldValueColumn = col.column("Old Value", "old_value", type.stringType());
		TextColumnBuilder<String> newValueColumn  = col.column("New Value",   "new_value",  type.stringType());
		TextColumnBuilder<String> workItemNameColumn  = col.column("Work Item",   "work_item_name",  type.stringType());
		TextColumnBuilder<String> createdByColumn  = col.column("Created By",   "created_by",  type.stringType());
		TextColumnBuilder<String> complexityColumn  = col.column("Complexity",   "complexity",  type.stringType());
		
		report
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .columns(editedByColumn, editDateColumn, fieldEventColumn, oldValueColumn, newValueColumn, workItemNameColumn, createdByColumn, complexityColumn)
		  .setDataSource(data[0]);
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() {
		//today.set(Calendar.YEAR, 2014);
		//today.set(Calendar.MONTH, Calendar.SEPTEMBER);
		//today.set(Calendar.DAY_OF_MONTH, 21);
		
		String query = "select u.Name as 'EditedBy', DATE_ADD(wih.CreatedDate, INTERVAL 11 HOUR) as 'EditDate', wih.Field , wih.OldValue, if (wih.Field='created','Open',wih.NewValue) as 'NewValue', wi.Name as 'WorkItemName', cb.Name as 'CreatedBy', wi.Scheduling_Complexity__c "
				+ "from work_item__history wih "
				+ "inner join user u on wih.CreatedById = u.Id "
				+ "inner join work_item__c wi on wi.Id = wih.ParentId "
				+ "inner join user cb on wi.CreatedById = cb.Id "
				+ "where wih.Field in ('Status__c',  'Open_Sub_Status__c', 'created') "
				+ "and date_format(DATE_ADD(wih.CreatedDate, INTERVAL 11 HOUR), '%Y-%m-%d')='" + Utility.getActivitydateformatter().format(today.getTime()) + "'";

		try {
			ResultSet rs = db.executeSelect(query, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("edited_by");
			variables.add("edit_date"); 
			variables.add("field_event");
			variables.add("old_value");
			variables.add("new_value");
			variables.add("work_item_name");
			variables.add("created_by");
			variables.add("complexity");
			
			data = new DRDataSource[] {
					// data[0] - Summary
					new DRDataSource(variables.toArray(new String[variables.size()])) 
					} ;
			
			while (rs.next()) {
				// Save current
				List<Object> values = new ArrayList<Object>();
				values.add(rs.getString("EditedBy"));
				Date editDate = null;
				try {
					editDate = Utility.getMysqldateformat().parse(rs.getString("EditDate"));
				} catch (ParseException pe) {
					logger.error("", pe);
				}
				values.add(editDate);
				values.add(rs.getString("wih.Field"));
				values.add(rs.getString("wih.OldValue"));
				values.add(rs.getString("NewValue"));
				values.add(rs.getString("WorkItemName"));
				values.add(rs.getString("CreatedBy"));
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
				"\\Enlighten\\SchedulingComplete_" + Utility.getActivitydateformatter().format(today.getTime())
				};
	}
	
	public boolean append() {
		return false;
	}
}
