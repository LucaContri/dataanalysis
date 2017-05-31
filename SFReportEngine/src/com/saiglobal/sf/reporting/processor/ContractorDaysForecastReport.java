package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.awt.Color;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.jasper.constant.JasperProperty;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

public class ContractorDaysForecastReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(ContractorDaysForecastReport.class);
	private static final Calendar today = new GregorianCalendar();
	private static final Calendar startPeriod; 
	private static final Calendar endPeriod;
	private static final String[] periods;
	private static final SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMMM yyyy");
	private static final SimpleDateFormat periodDateFormat = new SimpleDateFormat("yyyy-MM");
	
	static {
		today.set(Calendar.DAY_OF_MONTH, 1);
		startPeriod = today;
		endPeriod = new GregorianCalendar(today.get(Calendar.YEAR)+1,today.get(Calendar.MONTH), today.get(Calendar.DAY_OF_MONTH));
		
		periods = getAllPeriods();
	}
	
	public ContractorDaysForecastReport() {
		
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);
		
		TextColumnBuilder<String> resourceNameColumn = col.column("Resource Name", "resource_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> resourceManagerColumn = col.column("Manager Name", "resource_manager", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> resourceBusinessUnitColumn = col.column("Business Unit", "resource_reporting_business_unit", type.stringType()).setFixedWidth(180);		
		TextColumnBuilder<String> resourceStateColumn = col.column("State", "resource_state", type.stringType()).setFixedWidth(50);
		TextColumnBuilder<Double> resourceWITotalColumn  = col.column("Total Audit Days",   "resource_wi_total",  type.doubleType()).setFixedWidth(100).setPattern("#");
	
		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(resourceBusinessUnitColumn, resourceNameColumn, resourceManagerColumn, resourceStateColumn, resourceWITotalColumn);
			
		for (String period : periods) {
			report.addColumn(col.column("Audit Days " + period,   period,  type.doubleType()).setFixedWidth(50).setPattern("#"));
		}
		
		report
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text("Contractors Days Report - Forecast")).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Period from " + displayDateFormat.format(startPeriod.getTime()) + " to " + displayDateFormat.format(endPeriod.getTime()))).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Source: Calendar Events")).setFixedDimension(360, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "7")
		  .setDataSource(data[0]);
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() {

		String query = "SELECT r.Name as 'ResourceName', r.Resource_Type__c, r.Reporting_Business_Units__c, scs.Name as 'State', um.Name as 'Manager', DATE_FORMAT(t.Date, '%Y-%m') as 'Period', t.Type, sum(t.DurationMin) as 'Minutes', count(distinct t.Date) as 'Days' "
			+ "FROM `Resource__c` r "
			+ "INNER JOIN `User` u ON r.User__c = u.Id "
			+ "INNER JOIN `User` um ON u.ManagerId = um.Id "
			+ "LEFT JOIN `state_code_setup__c` scs ON r.Home_State_Province__c = scs.Id "
			+ "INNER JOIN "
			+ "(SELECT r.Id as 'ResourceId', rt.Name as 'Type', wir.Work_Item_Type__c as 'SubType', e.DurationInMinutes as 'DurationMin', e.ActivityDate as 'Date' "
			+ "FROM `event` e "
			+ "INNER JOIN `user` u ON u.Id = e.OwnerId "
			+ "INNER JOIN `Resource__c` r ON u.Id = r.User__C "
			+ "INNER JOIN `recordtype` rt ON e.RecordTypeId = rt.Id "
			+ "LEFT JOIN `work_item_resource__c` wir ON wir.Id = e.WhatId "
			+ "WHERE "
			+ "e.IsDeleted = 0 "
			+ "AND e.ActivityDate >= '" + Utility.getActivitydateformatter().format(startPeriod.getTime()) + "'" 
			+ "AND e.ActivityDate <= '" + Utility.getActivitydateformatter().format(endPeriod.getTime()) + "'" 
			+ "AND r.Reporting_Business_Units__c like 'AUS%') t ON t.ResourceId = r.Id "
			+ "WHERE "
			+ "Reporting_Business_Units__c like 'AUS%' "
			+ "and r.Resource_Type__c = 'Contractor' "
			+ "and t.Type = 'Work Item Resource' "
			+ "GROUP BY `ResourceName` , `Manager` , r.Resource_Type__c , r.Reporting_Business_Units__c , `State` , r.Resource_Target_Days__c , `Period` , t.Type "
			+ "ORDER BY r.Reporting_Business_Units__c , `ResourceName` , `Period` , t.Type";
		try {
			ResultSet rs = db.executeSelect(query, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("resource_reporting_business_unit");
			variables.add("resource_name"); 
			variables.add("resource_manager");
			variables.add("resource_state");
			variables.add("resource_wi_total");
			
			HashMap<String, Double> periodWiTotals = new HashMap<String, Double>();
			for (String period : periods) {
				periodWiTotals.put(period, new Double(0));
				variables.add(period);
			}
			data = new DRDataSource[] {
					// data[0] - Summary
					new DRDataSource(variables.toArray(new String[variables.size()])) 
					} ;
			
			// Calculate totals 
			String currentResourceName = "";
			String currentResourceManager = "";
			String currentReportingBusinessUnit = "";
			String currentResourceState = "";
			double currentResourceAuditTotal = 0;
			
			while (rs.next()) {
				if (rs.getString("ResourceName").equalsIgnoreCase(currentResourceName)) {	
					String period = rs.getString("Period");
					
					periodWiTotals.put(period, new Double(rs.getDouble("Days") + periodWiTotals.get(period).doubleValue()));
					currentResourceAuditTotal += rs.getDouble("Days");
				
				} else {
					
					if (!currentResourceName.equalsIgnoreCase("")) {
						// Save current
						List<Object> values = new ArrayList<Object>();
						values.add(currentReportingBusinessUnit);
						values.add(currentResourceName);
						values.add(currentResourceManager);
						values.add(currentResourceState);
						values.add(currentResourceAuditTotal);
						for (String period : periods) {
							values.add(periodWiTotals.get(period));
						}
						data[0].add(values.toArray());
					}
					currentResourceName = rs.getString("ResourceName");
					currentResourceManager = rs.getString("Manager");
					currentReportingBusinessUnit = rs.getString("Reporting_Business_Units__c");
					currentResourceState = rs.getString("State");
					for (String period : periods) {
						periodWiTotals.put(period, new Double(0));
					}
					String period = rs.getString("Period");	
					periodWiTotals.put(period, new Double(rs.getDouble("Days") + periodWiTotals.get(period).doubleValue()));
					currentResourceAuditTotal = rs.getDouble("Days");
				}
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
	
	private static String[] getAllPeriods() {
		List<String> periods = new ArrayList<String>();
		Calendar pointer = new GregorianCalendar(startPeriod.get(Calendar.YEAR), startPeriod.get(Calendar.MONTH), startPeriod.get(Calendar.DAY_OF_MONTH)); 
		String period = null;
		while (pointer.before(endPeriod)) {
			period = periodDateFormat.format(pointer.getTime());  
			if (!periods.contains(period))
				periods.add(period);
			pointer.add(Calendar.DAY_OF_YEAR, 1);
		}
		return periods.toArray(new String[periods.size()] ); //Arrays.copyOf(periods.toA, arg1);
	}
	
	public String[] getReportNames() {
		return new String[] {
				"Resource Planning\\Billing\\Contractor Days Forecast"
				};
	}
	
	public boolean append() {
		return false;
	}
}
