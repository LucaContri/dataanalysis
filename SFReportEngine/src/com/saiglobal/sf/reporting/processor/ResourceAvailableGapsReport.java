package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.sql.ResultSet;
import java.sql.SQLException;
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

import net.sf.dynamicreports.examples.Templates;
import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.base.expression.AbstractSimpleExpression;
import net.sf.dynamicreports.report.builder.ReportTemplateBuilder;
import net.sf.dynamicreports.report.builder.crosstab.CrosstabBuilder;
import net.sf.dynamicreports.report.builder.crosstab.CrosstabColumnGroupBuilder;
import net.sf.dynamicreports.report.builder.crosstab.CrosstabMeasureBuilder;
import net.sf.dynamicreports.report.builder.crosstab.CrosstabRowGroupBuilder;
import net.sf.dynamicreports.report.constant.Calculation;
import net.sf.dynamicreports.report.datasource.DRDataSource;
import net.sf.dynamicreports.report.definition.ReportParameters;


public class ResourceAvailableGapsReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	private SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-MMM");
	private DRDataSource data = null;
	private static final Logger logger = Logger.getLogger(ResourceAvailableGapsReport.class);
	
	public ResourceAvailableGapsReport() {
		
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();

/*		CrosstabRowGroupBuilder<String> rowCountryGroup = ctab.rowGroup("resource_country", String.class)
				.setHeaderWidth(80)
				.setShowTotal(false);*/
		CrosstabRowGroupBuilder<String> rowStateGroup = ctab.rowGroup("resource_state", String.class)
				.setHeaderWidth(100)
				.setShowTotal(false);
		CrosstabRowGroupBuilder<String> rowNameGroup = ctab.rowGroup("resource_name", String.class)
			.setHeaderWidth(100)
			.setShowTotal(false);
		CrosstabRowGroupBuilder<String> rowBusinessUnitGroup = ctab.rowGroup("reporting_business_unit", String.class)
				.setHeaderWidth(100)
				.setShowTotal(false);
		CrosstabRowGroupBuilder<String> rowTypeGroup = ctab.rowGroup("resource_type", String.class)
			.setHeaderWidth(100)
			.setShowTotal(false);
		CrosstabRowGroupBuilder<String> rowWorkTypeGroup = ctab.rowGroup("resource_work_type", String.class)
				.setHeaderWidth(100)
				.setShowTotal(false);

		CrosstabColumnGroupBuilder<String> columnPeriodGroup = ctab.columnGroup(new PeriodExpression())
				.setShowTotal(false);

		CrosstabMeasureBuilder<String> gapsMeasure = ctab.measure("gaps", String.class, Calculation.FIRST);

		//rowStateGroup.orderBy(quantityMeasure);
		
		//ConditionalStyleBuilder condition1 = stl.conditionalStyle(cnd.greater(unitPriceMeasure, 50000)).setForegroundColor(Color.GREEN);
		//ConditionalStyleBuilder condition2 = stl.conditionalStyle(cnd.smaller(unitPriceMeasure, 300)).setForegroundColor(Color.RED);

		//StyleBuilder unitPriceStyle = stl.style()
		//	.setBorder(stl.pen1Point().setLineColor(Color.BLACK))
		//	.conditionalStyles(condition1, condition2);
		//unitPriceMeasure.setStyle(unitPriceStyle);

		CrosstabBuilder crosstab = ctab.crosstab()
			//.headerCell(cmp.text("Name").setStyle(Templates.columnStyle))
			//.headerCell(cmp.text("Type").setStyle(Templates.columnStyle))
			//.addHeaderCell(cmp.text("State").setStyle(Templates.boldCenteredStyle))
			.rowGroups(rowNameGroup, rowBusinessUnitGroup, rowTypeGroup, rowWorkTypeGroup, rowStateGroup)
			.columnGroups(columnPeriodGroup)
			.measures(gapsMeasure);

		ReportTemplateBuilder template = Templates.reportTemplate;
		template.setIgnorePageWidth(true);
		template.setIgnorePagination(true);

		report
			.fields(field("period", String.class))
			//.setPageFormat(PageType.A0, PageOrientation.LANDSCAPE)
			.setTemplate(template)
			//.title(Templates.createTitleComponent("Resource Availability"))
			.title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(300, 50)),
					cmp.horizontalList().add(cmp.text("Resource Availability Report - as " + Utility.getShortdatetimedisplayformat().format(new Date()))).setFixedDimension(300, 17))
			.summary(crosstab)
			//.pageFooter(Templates.footerComponent)
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
			data = new DRDataSource("resource_name", "reporting_business_unit", "resource_type", "resource_work_type", "resource_state", "period", "gaps");
			for (String resourceId : allGaps.keySet()) {
				rs = db.executeSelect("select r.Name, r.Work_Type__c, r.Reporting_Business_Units__c, r.Resource_Type__c, ccs.Name, scs.Name from " + db.getDBTableName("Resource__c") + " r left join " + db.getDBTableName("user") + " u on u.Id = r.User__c LEFT JOIN " + db.getDBTableName("country_code_setup__c") + " ccs on r.Home_Country1__c=ccs.Id LEFT JOIN " + db.getDBTableName("State_Code_Setup__c") + " scs on r.Home_State_Province__c=scs.Id where r.Id='" + resourceId + "'", -1);
				while (rs.next()) {
					for (String period : allGaps.get(resourceId).keySet()) {
						data.add(rs.getString("r.Name"), rs.getString("r.Reporting_Business_Units__c"), rs.getString("r.Resource_Type__c"), rs.getString("r.Work_Type__c"), rs.getString("scs.Name"), period, allGaps.get(resourceId).get(period));
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
	
	private class PeriodExpression extends AbstractSimpleExpression<String> {
		private static final long serialVersionUID = 1L;

		@Override
		public String evaluate(ReportParameters reportParameters) {
			return reportParameters.getValue("period");
		}
	}
	
	public String[] getReportNames() {
		return new String[] {"Resource Planning\\Resource Availability\\Resource Availability Report Crosstab"};
	}
	
	public boolean append() {
		return false;
	}
}
