package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.*;

import java.awt.Color;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.FieldBuilder;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;


public class PlanningDaysReportDaily implements ReportBuilder {
	private DbHelper db_certification;
	private GlobalProperties gp;
	
	private DRDataSource data = null;
	private static final Logger logger = Logger.getLogger(PlanningDaysReportDaily.class);
	private static final Calendar today = new GregorianCalendar();
	private final int currentFY;
	private final Calendar startFY; 
	private final Calendar endNextFY;
	private final Calendar startDate; 
	private final Calendar endDate;
	protected final Calendar reportDate;
	private final String[] periods;
	private static final SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMMM yyyy");
	private static final SimpleDateFormat mysqlPeriodDateFormat = new SimpleDateFormat("yyyy MM");
	private static final SimpleDateFormat periodDateFormat = new SimpleDateFormat("MMM yy");
	protected String operationalOwnershipString;
	protected String revenueOwnershipString;
	protected String historyBusinessUnits;
	protected HashMap<String, String> standard_parents = new HashMap<String, String>();
	protected HashMap<String, Double> billable_expenses_by_standard = new HashMap<String, Double>();
	protected final static double averageMillisPerMonth = 365.24 * 24 * 60 * 60 * 1000 / 12;
		
	public PlanningDaysReportDaily() {
		if (today.get(Calendar.MONTH)>5)
			currentFY = today.get(Calendar.YEAR);
		else
			currentFY = today.get(Calendar.YEAR)-1;
		
		startFY = new GregorianCalendar(currentFY-1,Calendar.JULY,1);
		endNextFY = new GregorianCalendar(currentFY+2,Calendar.JUNE,30);
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		startDate = startFY;
		endDate = endNextFY;
		//startDate = new GregorianCalendar(2014,Calendar.APRIL,1);
		//endDate = new GregorianCalendar(2014,Calendar.APRIL,3);
		
		periods = getAllPeriods();
		ReportRow.getAllDataValues();
		ReportRow.getAllValues();
		
		this.operationalOwnershipString = "'AUS - Management Systems', 'AUS - Food'";
		this.revenueOwnershipString = "'AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD', 'AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW'";
		this.historyBusinessUnits = "'Planning Days - MS - History', 'Planning Days - Food - History'";
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
		
		TextColumnBuilder<String> sourceColumn = col.column("Source", "source", type.stringType()).setFixedWidth(180);//.setStyle(statusStyle);
		
		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(sourceColumn);
		
		FieldBuilder<String> periodField = field("period", type.stringType());
		
		for (String period : periods) {
			try {
				report.addColumn(col.column(periodDateFormat.format(mysqlPeriodDateFormat.parse(period)),   period,  type.doubleType()).setFixedWidth(80).setPattern("#.00"));//.setStyle(dataStyle));
			} catch (ParseException e) {
				logger.error(e);
			}
		}
		
		report
		  .fields(periodField)
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(340, 50)),
					cmp.horizontalList().add(cmp.text(getFileReportNames()[0])).setFixedDimension(340, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Period from " + displayDateFormat.format(startDate.getTime()) + " to " + displayDateFormat.format(endDate.getTime()))).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(reportDate.getTime()) )).setFixedDimension(340, 17))
		  .setDataSource(data);
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() throws Exception {
		data = new DRDataSource();
		try {
			String regionField = "";
			int ifCount = 0;
			for (Region region : Region.saveInHistoryValues()) {
				if (region.isBaseRegion()) {
					regionField += "IF (wi.Revenue_Ownership__c IN (";
					ifCount++;
					for (CompassRevenueOwnership businessUnit : region.getRevenueOwnerships()) {
						regionField += "'" + businessUnit.getName() + "',";
					}
					regionField = Utility.removeLastChar(regionField) + "), '" + region.getName() + "', ";
				}
			}
			regionField += "'Unknown'";
			for (int i=1; i<=ifCount; i++) {
				regionField += ") ";
			}
			regionField += " as 'Region', ";
					
			String revenueQuery = "INSERT INTO sf_report_history (SELECT "
					+ "null as 'Id',"
					+ "'Audit Days Snapshot' as 'ReportName',"
					+ "now() as 'Date',"
					+ regionField
					+ "concat(IF(wi.Revenue_Ownership__c LIKE '%Food%', 'Food', IF(wi.Revenue_Ownership__c LIKE '%Product%', 'ProductService', 'MS')), "
					+ "' - Audit - Days - ', "
					+ "if(wi.Status__c='Open' and wi.Open_Sub_Status__c is not null, wi.Open_Sub_Status__c,''), ' - ',"
					+ "REPLACE(wi.Status__c, 'Scheduled - Offered', 'Scheduled Offered'))  AS 'RowName', "
					+ "DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') as 'ColumnName', "
					+ "SUM(wi.Required_Duration__c)/8 as 'Value' "
					+ "FROM `work_item__c` wi "
					+ "LEFT JOIN `recordtype` rt ON wi.RecordTypeId = rt.Id "
					+ "inner join site_certification_standard_program__c scs on wi.Site_Certification_Standard__c = scs.Id "
					+ "WHERE "
					+ "rt.Name = 'Audit' "
					+ "and wi.IsDeleted=0 "
					+ "and (wi.Status__c ='Open' "
					+ "or (wi.Status__c ='Cancelled' "
					+ "and (scs.De_registered_Type__c not in ('Maintenance') or scs.De_registered_Type__c is null) "
					+ "and ( "
					+ "scs.Site_Certification_Status_Reason__c in ('System failure / Unresolved non conformances', 'Unpaid account', 'Failed product testing', 'Application / Certification abandoned', 'Misuse of Mark', 'Change to other CB (Cost)', 'Change to other CB (Service delivery)', 'Change to other CB (Other)', 'No added value / interest', 'Business / site closed down', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'Company takeover / Liquidation', 'Global certification decision', 'Scheme / Program expired') "
					+ "or  wi.Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status') "
					+ "))) "
					//+ "AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
					+ "AND wi.Work_Item_Date__c >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
					+ "AND wi.Work_Item_Date__c <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
					+ "GROUP BY `Region`, `RowName`, `ColumnName`) "
					+ "UNION "
					+ "(SELECT "
					+ "null as 'Id',"
					+ "'Audit Days Snapshot' as 'ReportName', "
					+ "now() as 'Date',"
					+ regionField
					+ "concat(IF(wi.Revenue_Ownership__c LIKE '%Food%', 'Food', IF(wi.Revenue_Ownership__c LIKE '%Product%', 'ProductService', 'MS')), ' - Audit - Days - ', REPLACE(wi.Status__c, 'Scheduled - Offered', 'Scheduled Offered'))  AS 'RowName', "
					+ "DATE_FORMAT(wird.FStartDate__c, '%Y %m') as 'ColumnName', "
					+ "sum(if(Budget_Days__c is null, wird.Scheduled_Duration__c / 8, wird.Scheduled_Duration__c / 8 + Budget_Days__c)) AS 'Value' "
					+ "FROM "
					+ "`work_item__c` wi "
					+ "LEFT JOIN `work_item_resource__c` wir ON wir.work_item__c = wi.Id "
					+ "LEFT JOIN `work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id "
					+ "LEFT JOIN `recordtype` rt ON wi.RecordTypeId = rt.Id "
					+ "WHERE "
					+ "rt.Name = 'Audit' AND wir.IsDeleted = 0 "
					+ "AND wird.IsDeleted = 0 "
					+ "AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget') "
					//+ "AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%') "
					+ "AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier') "
					+ "and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget') "
					+ "AND wird.FStartDate__c >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
					+ "AND wird.FStartDate__c <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
					+ "GROUP BY `Region`, `RowName`, `ColumnName`)";
					
			
			db_certification.executeStatement(revenueQuery);
			
			/*
			List<String> dataVariables = new ArrayList<String>();

			dataVariables.add("source");
						
			HashMap<String, HashMap<String, Double>> dataMap = new HashMap<String, HashMap<String, Double>>();
			for (String period : periods) {
				HashMap<String, Double> periodData = new HashMap<String, Double>();
				for (ReportRow status : allRows) {
					periodData.put(status.getName(), new Double(0));
				}
				dataMap.put(period, periodData);
				dataVariables.add(period);
			}

			data = new DRDataSource(dataVariables.toArray(new String[dataVariables.size()]));
			
			while (rs.next()) {
				populateDataMap(rs, dataMap);
			}
			
			
			
			// Assign data and save it in history
			for (ReportRow source : dataRows) {
				List<Object> values = new ArrayList<Object>();
				
				values.add(source.getName());
				for (String period : periods) {
					values.add(dataMap.get(period).get(source.getName()));
					// Save for future references
					if (saveInHistory && source.isSaveInHistory())
						db_certification.addToHistory(getFileReportNames()[0], reportDate, source.getName(), period, dataMap.get(period).get(source.getName()).toString());
				}
				data.add(values.toArray());
			}	
			*/		
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
		this.db_certification = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
	}
	
	@SuppressWarnings("unused")
	private void populateDataMap(ResultSet rs, HashMap<String, HashMap<String, Double>> dataMap) throws ParseException {
		try {
			String period = rs.getString("period");
			String sourceString = rs.getString("source");
			ReportRow source = ReportRow.getValueForSqlName(sourceString);
			if (source == null)
				logger.info("Pause");
			HashMap<String, Double> currendPeriodData = dataMap.get(period);
			Double currentValue = currendPeriodData.get(source.getName());
			if (currentValue == null)
				logger.info("Pause");
			currendPeriodData.put(source.getName(), new Double(currentValue.doubleValue() + rs.getDouble("days")));
			dataMap.put(period, currendPeriodData);
		} catch (SQLException e) {
			logger.error(e);
		}
	}
	
	
	private String[] getAllPeriods() {
		List<String> periods = new ArrayList<String>();
		Calendar pointer = new GregorianCalendar(startDate.get(Calendar.YEAR), startDate.get(Calendar.MONTH), startDate.get(Calendar.DAY_OF_MONTH)); 
		String period = null;
		while (pointer.before(endDate)) {
			period = mysqlPeriodDateFormat.format(pointer.getTime());  
			if (!periods.contains(period))
				periods.add(period);
			pointer.add(Calendar.DAY_OF_YEAR, 1);
		}
		return periods.toArray(new String[periods.size()] );
	}
	
	
	public String[] getReportNames() {
		return new String[] {"Financial Visibility\\Audit Days Snapshot"};
	}
	
	public String[] getFileReportNames() {
		return new String[] {"Audit Days Snapshot"};
	}

	public boolean append() {
		return false;
	}

	private enum ReportRow {
		
		// Days measures
		//BudgetFoodDays("Food - Audit - Days - Cancelled", "Food-Audit-Days-Budget", true, true),
		CancelledFoodDays("Food - Audit - Days - Cancelled", "Food-Audit-Days-Cancelled", true, true),
		ConfirmedFoodDays("Food - Audit - Days - Confirmed", "Food-Audit-Days-Confirmed", true, true), 
		ScheduledFoodDays("Food - Audit - Days - Scheduled", "Food-Audit-Days-Scheduled", true, true), 
		ScheduledOfferedFoodDays("Food - Audit - Days - Scheduled Offered", "Food-Audit-Days-Scheduled - Offered", true, true), 
		ServiceChangeFoodDays("Food - Audit - Days - Service Change", "Food-Audit-Days-Service change", true, true),
		OpenFoodDays("Food - Audit - Days - Open", "Food-Audit-Days-Open", true, true),
		InProgressFoodDays("Food - Audit - Days - In Progress", "Food-Audit-Days-In Progress", true, true),
		SubmittedFoodDays("Food - Audit - Days - Submitted", "Food-Audit-Days-Submitted", true, true),
		UnderReviewFoodDays("Food - Audit - Days - Under Review", "Food-Audit-Days-Under Review", true, true),
		SupportFoodDays("Food - Audit - Days - Support", "Food-Audit-Days-Support", true, true),
		CompletedFoodDays("Food - Audit - Days - Completed", "Food-Audit-Days-Completed", true, true),
		InititateServiceFoodDays("Food - Audit - Days - Inititate Service", "Food-Audit-Days-Inititate service", true, true),
		IncompleteFoodDays("Food - Audit - Days - Incomplete", "Food-Audit-Days-Incomplete", true, true),
		UnderReviewRejectedFoodDays("Food - Audit - Days - Under Review - Rejected", "Food-Audit-Days-Under Review - Rejected", true, true),
		CancelledMSDays("MS - Audit - Days - Cancelled", "MS-Audit-Days-Cancelled", true, true),
		//BudgetMSDays("MS - Audit - Days - Cancelled", "MS-Audit-Days-Budget", true, true),
		ConfirmedMSDays("MS - Audit - Days - Confirmed", "MS-Audit-Days-Confirmed", true, true), 
		ScheduledMSDays("MS - Audit - Days - Scheduled", "MS-Audit-Days-Scheduled", true, true), 
		ScheduledOfferedMSDays("MS - Audit - Days - Scheduled Offered", "MS-Audit-Days-Scheduled - Offered", true, true), 
		ServiceChangeMSDays("MS - Audit - Days - Service Change", "MS-Audit-Days-Service change", true, true),
		OpenMSDays("MS - Audit - Days - Open", "MS-Audit-Days-Open", true, true),
		InProgressMSDays("MS - Audit - Days - In Progress", "MS-Audit-Days-In Progress", true, true),
		SubmittedMSDays("MS - Audit - Days - Submitted", "MS-Audit-Days-Submitted", true, true),
		UnderReviewMSDays("MS - Audit - Days - Under Review", "MS-Audit-Days-Under Review", true, true),
		SupportMSDays("MS - Audit - Days - Support", "MS-Audit-Days-Support", true, true),
		CompletedMSDays("MS - Audit - Days - Completed", "MS-Audit-Days-Completed", true, true),
		InititateServiceMSDays("MS - Audit - Days - Inititate Service", "MS-Audit-Days-Inititate service", true, true),
		IncompleteMSDays("MS - Audit - Days - Incomplete", "MS-Audit-Days-Incomplete", true, true),
		UnderReviewRejectedMSDays("MS - Audit - Days - Under Review - Rejected", "MS-Audit-Days-Under Review - Rejected", true, true);
		//BudgetProductServiceDays("Product Service - Audit - Days - Cancelled", "ProductService-Audit-Days-Budget", true, true),
		//CancelledProductServiceDays("Product Service - Audit - Days - Cancelled", "ProductService-Audit-Days-Cancelled", true, true),
		//ConfirmedProductServiceDays("Product Service - Audit - Days - Confirmed", "ProductService-Audit-Days-Confirmed", true, true), 
		//ScheduledProductServiceDays("Product Service - Audit - Days - Scheduled", "ProductService-Audit-Days-Scheduled", true, true), 
		//ScheduledOfferedProductServiceDays("Product Service - Audit - Days - Scheduled Offered", "ProductService-Audit-Days-Scheduled - Offered", true, true), 
		//ServiceChangeProductServiceDays("Product Service - Audit - Days - Service Change", "ProductService-Audit-Days-Service change", true, true),
		//OpenProductServiceDays("Product Service - Audit - Days - Open", "ProductService-Audit-Days-Open", true, true),
		//InProgressProductServiceDays("Product Service - Audit - Days - In Progress", "ProductService-Audit-Days-In Progress", true, true),
		//SubmittedProductServiceDays("Product Service - Audit - Days - Submitted", "ProductService-Audit-Days-Submitted", true, true),
		//UnderReviewProductServiceDays("Product Service - Audit - Days - Under Review", "ProductService-Audit-Days-Under Review", true, true),
		//SupportProductServiceDays("Product Service - Audit - Days - Support", "ProductService-Audit-Days-Support", true, true),
		//CompletedProductServiceDays("Product Service - Audit - Days - Completed", "ProductService-Audit-Days-Completed", true, true),
		//InititateServiceProductServiceDays("Product Service - Audit - Days - Inititate Service", "ProductService-Audit-Days-Inititate service", true, true),
		//IncompleteProductServiceDays("Product Service - Audit - Days - Incomplete", "ProductService-Audit-Days-Incomplete", true, true),
		//UnderReviewRejectedProductServiceDays("Product Service - Audit - Days - Under Review - Rejected", "ProductService-Audit-Days-Under Review - Rejected", true, true);		
		
		String name;
		private String sqlName;
		boolean displayInData;
		boolean saveInHistory;
		ReportRow(String aName, String aSqlName, boolean isDisplayInData, boolean isSaveInHistory) {
			name = aName;
			sqlName = aSqlName;
			displayInData = isDisplayInData;
			saveInHistory = isSaveInHistory;
		}
		
		public String getName() {
			return name;
		}
		
		public static ReportRow getValueForSqlName(String sqlName) {
			for (ReportRow aValue : getAllValues()) {
				if (aValue.sqlName.equalsIgnoreCase(sqlName)) {
					return aValue;
				}
			}
			return null;
		}
		
		public boolean isDisplayInData() {
			return displayInData;
		}
		
		@SuppressWarnings("unused")
		public boolean isSaveInHistory() {
			return saveInHistory;
		}
		
		public static ReportRow[] getAllValues() {
			return ReportRow.values();
		}
		
		public static ReportRow[] getAllDataValues() {
			List<ReportRow> returnValue = new ArrayList<ReportRow>(); 
			for (ReportRow aValue : getAllValues()) {
				if (aValue.isDisplayInData())
					returnValue.add(aValue);
			}
			return returnValue.toArray(new ReportRow[]{});
		}
	}
}
