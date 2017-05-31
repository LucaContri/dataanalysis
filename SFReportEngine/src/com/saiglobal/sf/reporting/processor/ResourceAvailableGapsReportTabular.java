package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.awt.Color;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.TimeZone;

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

public class ResourceAvailableGapsReportTabular implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	private SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy");
	private DRDataSource data = null;
	private static final Logger logger = Logger.getLogger(ResourceAvailableGapsReportTabular.class);
	
	public ResourceAvailableGapsReportTabular() {
		
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
			//resource_name", "resource_type", "resource_state", "period", "gaps"	
		TextColumnBuilder<String> resourceNameColumn = col.column("Resource Name", "resource_name", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> reportingBusinessUnitNameColumn = col.column("Reporting Business Unit", "reporting_business_unit", type.stringType()).setFixedWidth(180);
		TextColumnBuilder<String> resourceTypeColumn = col.column("Resource Type", "resource_type", type.stringType()).setFixedWidth(100);
		TextColumnBuilder<String> resourceWorkTypeColumn = col.column("Work Type", "reource_work_type", type.stringType()).setFixedWidth(100);
		TextColumnBuilder<String> resourceStateColumn = col.column("State", "resource_state", type.stringType()).setFixedWidth(50);
		TextColumnBuilder<Date> gapColumn  = col.column("Gap",   "period",  type.dateType()).setFixedWidth(180).setPattern("dd/MM/yyyy");

		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .columns(resourceNameColumn, reportingBusinessUnitNameColumn, resourceTypeColumn, resourceWorkTypeColumn, resourceStateColumn, gapColumn)
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text("Resource Availability Report - as " + Utility.getShortdatetimedisplayformat().format(new Date()))).setFixedDimension(360, 17).setStyle(boldStyle))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "5")
		  .setDataSource(data);
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() {
		//String query = "select r.Id, r.Name, u.Name, e.StartDateTime, e.EndDateTime, e.Subject, e.Description, u.TimeZoneSidKey from " + db.getLocalTableName("event") + " e inner join " + db.getLocalTableName("user") + " u on u.Id = e.OwnerId inner join " + db.getLocalTableName("Resource__c") + " r on u.Id = r.User__C where e.StartDateTime>DATE_SUB(NOW(),INTERVAL 1 DAY) AND e.StartDateTime<DATE_ADD(NOW(),INTERVAL 1 YEAR) AND r.Reporting_Business_Units__c like 'AUS%' order by r.Name, e.StartDateTime";
		String query = "select r.Id, r.Work_Type__c, e.StartDateTime, e.EndDateTime, u.TimeZoneSidKey from " + db.getDBTableName("event") + " e inner join " + db.getDBTableName("user") + " u on u.Id = e.OwnerId inner join " + db.getDBTableName("Resource__c") + " r on u.Id = r.User__C WHERE r.Status__c='Active' AND r.Active_User__c='Yes' AND e.IsDeleted=0 AND e.StartDateTime>DATE_SUB(NOW(),INTERVAL 1 DAY) AND e.StartDateTime<DATE_ADD(NOW(),INTERVAL 1 YEAR) AND (r.Reporting_Business_Units__c like 'AUS-Man%' OR r.Reporting_Business_Units__c like 'AUS-Food%' OR r.Reporting_Business_Units__c like 'AUS-Dir%') order by r.Name, r.Id, e.StartDateTime";
		try {
			ResultSet rs = db.executeSelect(query, -1);
			HashMap<String, HashMap<String, String>> allGaps = new HashMap<String, HashMap<String, String>>();
			HashMap<String, String> currentResourceGaps = new HashMap<String, String>();
			String previousResourceId = "";
			String currentResourceId = "";
			Calendar previousEventEnd = new GregorianCalendar();
			Calendar currentEventStart = new GregorianCalendar();
			Date now = new Date();
			currentEventStart.setTime(now);
			previousEventEnd.setTime(now);
			TimeZone tz = TimeZone.getDefault();
			while (rs.next()) {
				currentResourceId = rs.getString("r.Id");
				if (rs.isFirst())
					previousResourceId = currentResourceId;
				currentEventStart.setTimeInMillis(rs.getTimestamp("e.StartDateTime").getTime() + tz.getOffset(rs.getTimestamp("e.StartDateTime").getTime()));
				if (currentResourceId.compareTo(previousResourceId)==0) {
					currentResourceGaps = addGaps(previousEventEnd, currentEventStart, currentResourceGaps);
				} else {
					// Check for gaps until the end of the period (1 year from now)
					currentEventStart.setTime(now);
					currentEventStart.add(Calendar.YEAR, 1);
					currentResourceGaps = addGaps(previousEventEnd, currentEventStart, currentResourceGaps);
					
					// Add gaps to allGaps
					allGaps.put(previousResourceId, currentResourceGaps);
					
					// Update for new resource
					tz = TimeZone.getTimeZone(rs.getString("u.TimeZoneSidKey"));
					currentEventStart.setTimeZone(tz);
					previousEventEnd.setTimeZone(tz);
					previousResourceId =  currentResourceId;
					currentResourceGaps = new HashMap<String, String>();
					
					// Checks for gaps since the beginning (now)
					currentEventStart.setTimeInMillis(rs.getTimestamp("e.StartDateTime").getTime() + tz.getOffset(rs.getTimestamp("e.StartDateTime").getTime()));
					previousEventEnd.setTimeInMillis(now.getTime() + tz.getOffset(now.getTime()));
					currentResourceGaps = addGaps(previousEventEnd, currentEventStart, currentResourceGaps);
				}
				previousEventEnd.setTimeInMillis(rs.getTimestamp("e.EndDateTime").getTime() + tz.getOffset(rs.getTimestamp("e.EndDateTime").getTime()));
			}
			// Add last resource
			// Check for gaps until the end of the period (1 year from now)
			currentEventStart.setTime(now);
			currentEventStart.add(Calendar.YEAR, 1);
			currentResourceGaps = addGaps(previousEventEnd, currentEventStart, currentResourceGaps);
			allGaps.put(previousResourceId, currentResourceGaps);
						
			// Cycle through map to create data source
			data = new DRDataSource("resource_name", "reporting_business_unit", "resource_type", "reource_work_type", "resource_state", "period", "gaps");
			for (String resourceId : allGaps.keySet()) {
				rs = db.executeSelect("select r.Name, r.Work_Type__c, r.Reporting_Business_Units__c, r.Resource_Type__c, ccs.Name, scs.Name from " + db.getDBTableName("Resource__c") + " r left join " + db.getDBTableName("user") + " u on u.Id = r.User__c LEFT JOIN " + db.getDBTableName("country_code_setup__c") + " ccs on r.Home_Country1__c=ccs.Id LEFT JOIN " + db.getDBTableName("State_Code_Setup__c") + " scs on r.Home_State_Province__c=scs.Id where r.Id='" + resourceId + "'", -1);
				while (rs.next()) {
					for (String period : allGaps.get(resourceId).keySet()) {
						Date periodDate = null;
						try {
							 periodDate = df.parse(period);
						} catch (ParseException e) {
							logger.error("", e);
						}
						data.add(rs.getString("r.Name"), rs.getString("r.Reporting_Business_Units__c"), rs.getString("r.Resource_Type__c"), rs.getString("r.Work_Type__c"), rs.getString("scs.Name"), periodDate, allGaps.get(resourceId).get(period));
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
	
	private HashMap<String, String> addGaps(Calendar previousEventEnd, Calendar currentEventStart, HashMap<String, String> currentResourceGaps) {
		previousEventEnd.add(Calendar.DATE, 1);
        while(currentEventStart.after(previousEventEnd)) {
        	if((previousEventEnd.get(Calendar.DAY_OF_WEEK)!=Calendar.SUNDAY) && (previousEventEnd.get(Calendar.DAY_OF_WEEK)!=Calendar.SATURDAY)) {
            	String monthName = df.format(previousEventEnd.getTime());
            	String currentMonthDates = currentResourceGaps.get(monthName);
            	if (currentMonthDates == null)
					currentMonthDates = "" + previousEventEnd.get(Calendar.DAY_OF_MONTH);
				else 
					currentMonthDates += ", " + previousEventEnd.get(Calendar.DAY_OF_MONTH);
            	currentResourceGaps.put(monthName, currentMonthDates);
            }
        	previousEventEnd.add(Calendar.DATE, 1);
        }
        return currentResourceGaps;
	}
	
	public void setDb(DbHelper db) {
		this.db = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}
		
	public String[] getReportNames() {
		return new String[] {"Resource Planning\\Resource Availability\\Resource Availability Report Tabular"};
	}
	
	public boolean append() {
		return false;
	}
}
