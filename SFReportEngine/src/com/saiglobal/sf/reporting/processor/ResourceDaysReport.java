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
import net.sf.dynamicreports.report.base.expression.AbstractSimpleExpression;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.ConditionalStyleBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;
import net.sf.dynamicreports.report.definition.ReportParameters;


public class ResourceDaysReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource[] data = null;
	private static final Logger logger = Logger.getLogger(ResourceDaysReport.class);
	protected static final Calendar today = new GregorianCalendar();
	protected static int currentFY;
	protected static Calendar startFY; 
	protected static Calendar endFY;
	protected static Calendar startPeriod; 
	protected static Calendar endPeriod;
	protected static String[] periods;
	private static String currentPeriod;
	private static final SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd");
	private static final SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMMM yyyy");
	private static final SimpleDateFormat periodDateFormat = new SimpleDateFormat("yyyy-MM");
	private static final int hoursPerDay = 8;
	
	public ResourceDaysReport() {
		if (today.get(Calendar.MONTH)>5)
			currentFY = today.get(Calendar.YEAR);
		else
			currentFY = today.get(Calendar.YEAR)-1;
		
		currentPeriod = periodDateFormat.format(today.getTime());
		
		startFY = new GregorianCalendar(currentFY,6,1);
		endFY = new GregorianCalendar(currentFY+1,5,30);
		
		//startFY = new GregorianCalendar(2012,Calendar.SEPTEMBER,1);
		//endFY = new GregorianCalendar(2014,6,30);
		
		startPeriod = startFY;
		endPeriod = endFY;
		
		// Alternatively for rolling year
		//startPeriod = today;
		//today.add(Calendar.YEAR, 1);
		//endPeriod = new GregorianCalendar(today.get(Calendar.YEAR)+1,today.get(Calendar.MONTH), today.get(Calendar.DAY_OF_MONTH));
		
		periods = getAllPeriods();
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
		
		JasperReportBuilder report2 = report();
		
		ConditionalStyleBuilder utilizationOverCondition = stl.conditionalStyle(new UtilizationOverConditionExpression())
		    	.setBackgroundColor(new Color(204, 0, 0));
		
		ConditionalStyleBuilder utilizationThirdCondition = stl.conditionalStyle(new UtilizationThirdConditionExpression())
		    	.setBackgroundColor(new Color(255, 102, 0));
		
		ConditionalStyleBuilder utilizationSeconfCondition = stl.conditionalStyle(new UtilizationSecondConditionExpression())
		    	.setBackgroundColor(new Color(255, 204, 153));
		
		ConditionalStyleBuilder utilizationFirstCondition = stl.conditionalStyle(new UtilizationFirstConditionExpression())
		    	.setBackgroundColor(new Color(51, 204, 0));
		
		StyleBuilder utilizationStyle = stl.style()
				.conditionalStyles(utilizationOverCondition, utilizationThirdCondition, utilizationSeconfCondition, utilizationFirstCondition);
		
		TextColumnBuilder<String> resourceNameColumn = col.column("Resource Name", "resource_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> resourceManagerColumn = col.column("Manager Name", "resource_manager", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> resourceTypeColumn = col.column("Resource Type", "resource_type", type.stringType()).setFixedWidth(100);
		TextColumnBuilder<String> resourceBusinessUnitColumn = col.column("Business Unit", "resource_reporting_business_unit", type.stringType()).setFixedWidth(180);		
		TextColumnBuilder<String> resourceStateColumn = col.column("State", "resource_state", type.stringType()).setFixedWidth(50);
		TextColumnBuilder<Double> resourceTargetColumn  = col.column("Target (day)",   "resource_target",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceWITotalColumn  = col.column("WI Total (day)",   "resource_wi_total",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceWITotalToDateColumn  = col.column("WI To Date Total (day)",   "resource_wi_to_date_total",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceAuditTotalColumn  = col.column("Audit Total (day)",   "resource_audit_total",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceTravelTotalColumn  = col.column("Travel (day)",   "resource_travel_total",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceBOPTotalColumn  = col.column("BOP Total (day)",   "resource_bop_total",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		TextColumnBuilder<Double> resourceUtilizationColumn  = col.column("Utilization (WI Total/Target %)",   "resource_utilization",  type.percentageType()).setFixedWidth(100).setPattern("#").setStyle(utilizationStyle);

		// Used in reports 2
		TextColumnBuilder<String> periodColumn = col.column("Period", "period", type.stringType()).setFixedWidth(100);
		TextColumnBuilder<String> typeColumn = col.column("Type", "type", type.stringType()).setFixedWidth(200);
		TextColumnBuilder<String> subTypeColumn = col.column("Sub Type", "sub_type", type.stringType()).setFixedWidth(200);
		TextColumnBuilder<Double> daysColumn  = col.column("Total (days)",   "days",  type.doubleType()).setFixedWidth(100).setPattern("0.0");
		
		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(resourceBusinessUnitColumn, resourceNameColumn, resourceManagerColumn, resourceTypeColumn, resourceStateColumn, resourceTargetColumn, resourceUtilizationColumn, resourceWITotalColumn, resourceWITotalToDateColumn, resourceAuditTotalColumn, resourceTravelTotalColumn, resourceBOPTotalColumn);
			
		for (String period : periods) {
			report.addColumn(col.column("WI Total " + period,   period,  type.doubleType()).setFixedWidth(50).setPattern("0.0"));
		}
		
		report2
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(resourceBusinessUnitColumn, resourceNameColumn, resourceManagerColumn, resourceTypeColumn, resourceStateColumn, resourceTargetColumn, periodColumn, typeColumn, subTypeColumn, daysColumn);
		
		report
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text(getFileReportNames()[0])).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Period from " + displayDateFormat.format(startPeriod.getTime()) + " to " + displayDateFormat.format(endPeriod.getTime()))).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "6")
		  .setDataSource(data[0]);
		
		report2
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text(getFileReportNames()[1])).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Period from " + displayDateFormat.format(startPeriod.getTime()) + " to " + displayDateFormat.format(endPeriod.getTime()))).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "6")
		  .setDataSource(data[1]);
		
		return new JasperReportBuilder[] {report, report2};
	}
	
	public void init() {

		String query = 
			"SELECT " +
				"r.Name as 'ResourceName', r.Resource_Type__c, r.Reporting_Business_Units__c, scs.Name as 'State', r.Resource_Target_Days__c " +
				", um.Name as 'Manager' " +
				", DATE_FORMAT(t.Date, '%Y-%m') as 'Period', t.Type, t.SubType, sum(t.DurationMin) as 'Minutes' " +
				"FROM " + db.getDBTableName("Resource__c") + " r " +
				"INNER JOIN " + db.getDBTableName("User") + " u on r.User__c = u.Id " +
				"INNER JOIN " + db.getDBTableName("User") + " um on u.ManagerId = um.Id " +
				"LEFT JOIN " + db.getDBTableName("state_code_setup__c") + " scs on r.Home_State_Province__c = scs.Id " +
				"INNER JOIN ( " +
					"SELECT r.Id as 'ResourceId', rt.Name as 'Type', if (wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c , wir.Work_Item_Type__c) as 'SubType', e.DurationInMinutes as 'DurationMin', e.ActivityDate as 'Date' " + 
					"FROM " + db.getDBTableName("event") + " e " + 
					"INNER JOIN " + db.getDBTableName("user") + " u on u.Id = e.OwnerId " + 
					"INNER JOIN " + db.getDBTableName("Resource__c") + " r on u.Id = r.User__C " +
					"INNER JOIN " + db.getDBTableName("recordtype") + " rt on e.RecordTypeId = rt.Id " +
					"LEFT JOIN " + db.getDBTableName("work_item_resource__c") + " wir on wir.Id = e.WhatId " +
					"LEFT JOIN " + db.getDBTableName("blackout_period__c") + " bop on bop.Id = e.WhatId " +
					//"WHERE e.ActivityDate>=NOW() AND e.ActivityDate<=DATE_ADD(NOW(),INTERVAL 1 YEAR) AND r.Reporting_Business_Units__c like 'AUS%') " +
					"WHERE e.IsDeleted=0 AND e.ActivityDate>='" + mysqlDateFormat.format(startPeriod.getTime()) + "' AND e.ActivityDate<='" + mysqlDateFormat.format(endPeriod.getTime()) + "' AND r.Reporting_Business_Units__c like 'AUS%') " +
					"t ON t.ResourceId = r.Id " +
				"WHERE Reporting_Business_Units__c like 'AUS%' " + 
				"GROUP BY `ResourceName`, `Manager`, r.Resource_Type__c, r.Reporting_Business_Units__c, `State`, r.Resource_Target_Days__c, `Period`, t.Type, t.Subtype " +
				"ORDER BY r.Reporting_Business_Units__c, `ResourceName`, `Period`, t.Type, t.Subtype";
		try {
			ResultSet rs = db.executeSelect(query, -1);
			List<String> variables = new ArrayList<String>();
			variables.add("resource_reporting_business_unit");
			variables.add("resource_name"); 
			variables.add("resource_manager");
			variables.add("resource_type");
			variables.add("resource_state");
			variables.add("resource_target");
			variables.add("resource_utilization");
			variables.add("resource_wi_total");
			variables.add("resource_wi_to_date_total");
			variables.add("resource_audit_total");
			variables.add("resource_travel_total");
			variables.add("resource_bop_total");
			
			HashMap<String, Double> periodWiTotals = new HashMap<String, Double>();
			for (String period : periods) {
				periodWiTotals.put(period, new Double(0));
				variables.add(period);
			}
			data = new DRDataSource[] {
					// data[0] - Summary
					new DRDataSource(variables.toArray(new String[variables.size()])), 
					// data[1] - Details
					new DRDataSource("resource_reporting_business_unit", "resource_name", "resource_manager", "resource_type", "resource_state", "resource_target", "period", "type", "sub_type", "days")} ;
			
			
			// Calculate totals 
			String currentResourceName = "";
			String currentResourceManager = "";
			String currentResourceType = "";
			String currentReportingBusinessUnit = "";
			String currentResourceState = "";
			double currentResourceTarget = 0;
			double currentResourceWiToDateTotal = 0;
			double currentResourceAuditTotal = 0;
			double currentResourceTravelTotal = 0;
			double currentResourceBOPTotal = 0;
			
			while (rs.next()) {
				data[1].add(rs.getString("Reporting_Business_Units__c"), rs.getString("ResourceName"), rs.getString("Manager"), rs.getString("Resource_Type__c"), rs.getString("State"), rs.getDouble("Resource_Target_Days__c"), rs.getString("Period"), rs.getString("Type"), rs.getString("SubType"), rs.getDouble("Minutes")/60/hoursPerDay);
				if (rs.getString("ResourceName").equalsIgnoreCase(currentResourceName)) {
					if (rs.getString("Type").contains("Work")) {
						String period = rs.getString("Period");
						if (period.compareTo(currentPeriod)<=0) {
							currentResourceWiToDateTotal += rs.getDouble("Minutes")/60/hoursPerDay;
						}
						periodWiTotals.put(period, new Double(rs.getDouble("Minutes")/60/hoursPerDay + periodWiTotals.get(period).doubleValue()));
						// WI
						if ((rs.getString("SubType")!= null) && (rs.getString("SubType").contains("Travel"))) {
							// Travel
							currentResourceTravelTotal += rs.getDouble("Minutes")/60/hoursPerDay;
						} else {
							// Audit
							currentResourceAuditTotal += rs.getDouble("Minutes")/60/hoursPerDay;
						}
					} else {
						// BOP
						currentResourceBOPTotal += rs.getDouble("Minutes")/60/hoursPerDay;
					}
				} else {
					
					if (!currentResourceName.equalsIgnoreCase("")) {
						// Save current
						double utilization = 0;
						if (currentResourceTarget!=0)
							utilization = (currentResourceTravelTotal+currentResourceAuditTotal)/currentResourceTarget*100;
						List<Object> values = new ArrayList<Object>();
						values.add(currentReportingBusinessUnit);
						values.add(currentResourceName);
						values.add(currentResourceManager);
						values.add(currentResourceType);
						values.add(currentResourceState);
						values.add(currentResourceTarget);
						values.add(utilization);
						values.add(currentResourceTravelTotal+currentResourceAuditTotal);
						values.add(currentResourceWiToDateTotal);
						values.add(currentResourceAuditTotal);
						values.add(currentResourceTravelTotal);
						values.add(currentResourceBOPTotal);
						for (String period : periods) {
							values.add(periodWiTotals.get(period));
						}
						data[0].add(values.toArray());
					}
					currentResourceName = rs.getString("ResourceName");
					currentResourceManager = rs.getString("Manager");
					currentResourceType = rs.getString("Resource_Type__c");
					currentReportingBusinessUnit = rs.getString("Reporting_Business_Units__c");
					currentResourceState = rs.getString("State");
					currentResourceTarget = rs.getDouble("Resource_Target_Days__c");
					for (String period : periods) {
						periodWiTotals.put(period, new Double(0));
					}
					currentResourceWiToDateTotal = 0;
					if (rs.getString("Type").contains("Work")) {
						// WI
						String period = rs.getString("Period");
						if (period.compareTo(currentPeriod)<=0) {
							currentResourceWiToDateTotal += rs.getDouble("Minutes")/60/hoursPerDay;
						}
						periodWiTotals.put(period, new Double(rs.getDouble("Minutes")/60/hoursPerDay + periodWiTotals.get(period).doubleValue()));
						if ((rs.getString("SubType")!= null) && (rs.getString("SubType").contains("Travel"))) {
							// Travel
							currentResourceTravelTotal = rs.getDouble("Minutes")/60/hoursPerDay;
							currentResourceAuditTotal = 0;
							currentResourceBOPTotal = 0;
						} else {
							// Audit
							currentResourceAuditTotal = rs.getDouble("Minutes")/60/hoursPerDay;
							currentResourceTravelTotal = 0;
							currentResourceBOPTotal = 0;
						}
					} else {
						// BOP
						currentResourceBOPTotal = rs.getDouble("Minutes")/60/hoursPerDay;
						currentResourceAuditTotal = 0;
						currentResourceTravelTotal = 0;
					}		
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
	
	protected static String[] getAllPeriods() {
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
	
	private class UtilizationOverConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			Double wiTotalHours = reportParameters.getValue("resource_wi_total");
			Double resourceTarget = reportParameters.getValue("resource_target");
			return (resourceTarget>0) && (wiTotalHours > resourceTarget);
		}
	}
	
	private class UtilizationThirdConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			Double wiTotalHours = reportParameters.getValue("resource_wi_total");
			Double resourceTarget = reportParameters.getValue("resource_target");
			return (resourceTarget>0) && (wiTotalHours > resourceTarget/3*2);
		}
	}
	
	private class UtilizationSecondConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			Double wiTotalHours = reportParameters.getValue("resource_wi_total");
			Double resourceTarget = reportParameters.getValue("resource_target");
			return (resourceTarget>0) && (wiTotalHours > resourceTarget/3);
		}
	}
	
	private class UtilizationFirstConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			//Double wiTotalHours = reportParameters.getValue("resource_wi_total");
			Double resourceTarget = reportParameters.getValue("resource_target");
			return resourceTarget>0;
		}
	}
	
	public String[] getReportNames() {
		return new String[] {
				"Resource Days Summary\\" + Utility.getPeriodformatter().format(new Date()) + "\\Resource Days Report CFY - Summary", 
				"Resource Days Summary\\" + Utility.getPeriodformatter().format(new Date()) + "\\Resource Days Report CFY - Details"
				};
	}

	public String[] getFileReportNames() {
		return new String[] {
				"Resource Days Report CFY - Summary", 
				"Resource Days Report CFY - Details"
				};
	}
	public boolean append() {
		return false;
	}
}
