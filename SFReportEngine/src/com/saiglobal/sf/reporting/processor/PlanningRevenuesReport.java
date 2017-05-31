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

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.reporting.data.DbHelper;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.builder.FieldBuilder;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;


public class PlanningRevenuesReport implements ReportBuilder {
	private DbHelper db_certification;
	//private DbHelper db_tis;
	private GlobalProperties gp;
	
	private DRDataSource data = null;
	private boolean saveInHistory;
	private static final Logger logger = Logger.getLogger(PlanningRevenuesReport.class);
	private static final Calendar today = new GregorianCalendar();
	private final int currentFY;
	private final Calendar startFY; 
	private final Calendar endNextFY;
	private final Calendar startDate; 
	private final Calendar endDate;
	protected final Calendar reportDate;
	private final String[] periods;
	private final ReportRow[] dataRows;
	private final ReportRow[] allRows;
	private static final SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMMM yyyy");
	private static final SimpleDateFormat mysqlPeriodDateFormat = new SimpleDateFormat("yyyy MM");
	private static final SimpleDateFormat periodDateFormat = new SimpleDateFormat("MMM yy");
	protected String operationalOwnershipString;
	protected String revenueOwnershipString;
	protected String historyBusinessUnits;
	protected HashMap<String, String> standard_parents = new HashMap<String, String>();
	protected HashMap<String, Double> billable_expenses_by_standard = new HashMap<String, Double>();
	protected final static double averageMillisPerMonth = 365.24 * 24 * 60 * 60 * 1000 / 12;
		
	public PlanningRevenuesReport() {
		if (today.get(Calendar.MONTH)>5)
			currentFY = today.get(Calendar.YEAR);
		else
			currentFY = today.get(Calendar.YEAR)-1;
		
		startFY = new GregorianCalendar(currentFY,Calendar.JULY,1);
		endNextFY = new GregorianCalendar(currentFY+2,Calendar.JUNE,30);
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		startDate = startFY;
		endDate = endNextFY;
		//startDate = new GregorianCalendar(2014,Calendar.APRIL,1);
		//endDate = new GregorianCalendar(2014,Calendar.APRIL,3);
		
		periods = getAllPeriods();
		dataRows = ReportRow.getAllDataValues();
		allRows = ReportRow.getAllValues();
		
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
		ResultSet rs = null;
		
		try {
			// Create temporary HashTable for standard relationships
			String standard_parents_query = "select s.Name as 'Standard', ps.Name as 'Parent' "
					+ "from standard__c s  "
					+ "inner join standard__c ps on s.Parent_Standard__c = ps.Id "
					+ "where s.Parent_Standard__c is not null ";
			
			rs = db_certification.executeSelect(standard_parents_query, -1);
			
			while (rs.next()) {
				standard_parents.put(rs.getString("Standard"), rs.getString("Parent"));
			}
			
			// Get Average Billable Expense by Standard
			String billableExpenseQuery = "SELECT totExp.RowName, if (totDays.Value>0, totExp.Value / totDays.Value,0) as 'AvgBillableExpPerDay' "
					+ "FROM sf_report_history totExp "
					+ "left join sf_report_history totDays on totExp.ReportName=totExp.ReportName AND totExp.RowName = totDays.RowName "
					+ "WHERE totExp.ReportName = 'StandardProfitabilityAnalysis' AND totExp.ColumnName='resourceExpensesBillable' and totDays.ColumnName = 'TotalAuditDays'";
			rs = db_certification.executeSelect(billableExpenseQuery, -1);
			
			while (rs.next()) {
				billable_expenses_by_standard.put(rs.getString("RowName"), rs.getDouble("AvgBillableExpPerDay"));
			}
			
			// Step 1 - Recurrent Business
			String revenueQuery = "select * from ("
					+ "select "
					//+ "t.Operational_Ownership__c as 'BusinessUnit', "
					+ "t.Revenue_Ownership__c as 'BusinessUnit', "
					+ "t.SiteCertification, "
					+ "t.Period as 'period', "
					+ "t.WorkItemId as 'WorkItemId', "
					+ "t.WorkItemName as 'WorkItem', "
					+ "t.Service_target_date__c as 'TargetDate', "
					+ "t.RequiredDays as 'days', "
					//+ "concat(if (t.Operational_Ownership__c='AUS - Management Systems', 'MS', if (t.Operational_Ownership__c='AUS - Food', 'Food','ProductService')), '-Audit-',t.WorkItemStatus) as 'source', "
					+ "concat(if(t.Revenue_Ownership__c like 'AUS-Food%', 'Food', if(t.Revenue_Ownership__c like 'AUS-Product', 'ProductService', 'MS')), '-Audit-', t.WorkItemStatus) as 'source', "
					+ "t.Primary_Standard__c, "
					+ "t.Work_Item_Stage__c as 'Reason', "
					+ "t.Work_Package_Type__c as 'WorkPackageType', "
					+ "t.SampleSite, "
					+ "t.StandardName, "
					+ "p.Id as 'ProductId', "
					+ "p.Name as 'ProductName', "
					+ "p.UOM__c as 'Unit', "
					+ "if (p.UOM__c='DAY',t.Days,if(p.UOM__c='HFD', t.HalfDays, t.Hours)) as 'Quantity', "
					+ "pbe.UnitPrice as 'ListPrice',  "
					+ "if (cep.New_Price__c is null, pbe.UnitPrice, cep.New_Price__c) as 'EffectivePrice',"
					+ "(if (p.UOM__c='DAY',t.Days,if(p.UOM__c='HFD', t.HalfDays, t.Hours)) * if (cep.New_Price__c is null, pbe.UnitPrice, cep.New_Price__c)) as 'amount' "
					+ "from product2 p "
					+ "inner join (select "
					+ "floor(wi.Required_Duration__c/8) as 'Days' , "
					+ "floor((wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8))/4) as 'HalfDays', "
					+ "(wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8) - 4*floor((wi.Required_Duration__c - 8*floor(wi.Required_Duration__c/8))/4)) as 'Hours',"
					+ "wi.Primary_Standard__c, s.Id, sp.Name as 'StandardName', sp.Id as 'StandardId' , wp.Site_Certification__c , wi.Work_Item_Date__c, wi.Id as 'WorkItemId', wi.Name as 'WorkItemName',"
					//+ "c.Operational_Ownership__c, "
					+ "wi.Revenue_Ownership__c, "
					+ "c.Name as 'SiteCertification',"
					+ "DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') AS 'Period',"
					+ "wi.Service_target_date__c,"
					+ "wi.Work_Item_Stage__c,"
					+ "wi.Work_Package_Type__c,"
					+ "wi.Required_Duration__c / 8 AS 'RequiredDays',"
					+ "wi.Status__c as 'WorkItemStatus',"
					+ "if (c.FSample_Site__c like '%checkbox_checked%', true, false) as 'SampleSite' "
					+ "from work_item__c wi "
					+ "inner join standard__c s on s.Name = wi.Primary_Standard__c "
					+ "inner join standard__c sp on sp.Id = s.Parent_Standard__c "
					+ "inner join work_package__c wp on wp.Id = wi.Work_Package__c "
					+ "INNER JOIN recordtype rt ON wi.RecordTypeId = rt.Id "
					+ "INNER JOIN certification__c c ON c.Id = wp.Site_Certification__c "
					+ "where "
					+ "wi.Work_Item_Date__c>='" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
					+ "and wi.Work_Item_Date__c<='" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
					+ "and rt.Name = 'Audit' "
					//+ "AND c.Operational_Ownership__c IN ('AUS - Management Systems' , 'AUS - Food', 'AUS - Product Services') "
					+ "AND (wi.Revenue_Ownership__c like 'AUS-Food%' or wi.Revenue_Ownership__c like 'AUS-Managed%' or wi.Revenue_Ownership__c like 'AUS-Direct%' or wi.Revenue_Ownership__c like 'AUS-Product%') "
					+ "AND c.Status__c = 'Active' "
					//+ "AND wi.Status__c NOT IN ( 'Cancelled')"
					+ ") t on t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c "
					+ "inner join pricebookentry pbe on pbe.Product2Id = p.Id "
					+ "left join certification_pricing__c cp on cp.Product__c = p.Id and cp.Certification__c=t.Site_Certification__c "
					+ "left join certification_effective_price__c cep on cp.Id = cep.Certification_Pricing__c "
					+ "Where p.Category__c = 'Audit' "
					+ "and pbe.Pricebook2Id='01s90000000568BAAQ' "
					+ "and (cp.Status__c ='Active' or cp.Status__c is null) "
					+ "and (if (cep.New_Start_Date__c is not null,cep.New_Start_Date__c<=t.Work_Item_Date__c,1)) "
					+ "and (if (cep.New_End_Date__c is not null,cep.New_End_Date__c>=t.Work_Item_Date__c,1)) "
					+ "and if (p.UOM__c='DAY',t.Days,if(p.UOM__c='HFD', t.HalfDays, t.Hours))>0 "
					+ "order by `WorkItemId`, `ProductId`, cep.LastModifiedDate desc ) t2 "
					+ "group by `WorkItemId`, `ProductId`";
			
			rs = db_certification.executeSelect(revenueQuery, -1);
		
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
			/*
			// 2a) Get Historical Fees (Registration and Royalty) by Business Unit
			String pastFeesQuery = "select "
					+ "if((ili.Revenue_Ownership__c) like '%Food%', 'Food-Registration-Fee', if((ili.Revenue_Ownership__c) like '%Product Services%', 'ProductService-Registration-Fee', 'MS-Registration-Fee')) as 'source', "
					+ "date_format(i.From_Date__c, '%Y %m') as 'from_period', "
					+ "date_format(i.To_Date__c, '%Y %m') as 'to_period', "
					+ "sum(ili.Total_Line_Amount__c) as 'amount' "
					+ "from invoice__c i "
					+ "inner join invoice_group__c ig ON i.invoice_group__c = ig.Id "
					+ "inner join recordtype rt ON ig.RecordTypeId = rt.Id "
					+ "inner join invoice_line_item__c ili ON ili.invoice__c = i.Id "
					+ "where "
					+ "rt.Name in ('Registration') "
					+ "and !(i.From_Date__c > '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' or i.To_Date__c < '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "') "
					//+ "and ((i.From_Date__c >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and i.From_Date__c  < least(now(), '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "')) or (i.To_Date__c >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and i.To_Date__c < least(now(), '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "'))) "
					+ "and i.Status__c not in ('Cancelled') "
					+ "and i.Client_Ownership__c in ('Australia' , 'Product Services') "
					+ "group by source , from_period, to_period";
			*/
			//rs = db_certification.executeSelect(pastFeesQuery, -1);
			//while (rs.next()) {
				//populateDataMap(rs, dataMap);
			//}
			/*
			// 2b) Get Upcoming Fees (Registration and Royalty) by Business Unit
			String upcomingFeeQuery = "select t2.source, t2.from_period, sum(t2.amount_monthly) as 'amount_monthly' from ( "
					+ "select t.source, t.from_period, t.amount_monthly from ( "
					+ "select "
					+ "rmcl.Site_Certification_Standard__c,"
					+ "if(sc.Revenue_Ownership__c like '%Food%','Food-Registration-Fee-Upcoming',if(sc.Revenue_Ownership__c like '%Product Services%','ProductService-Registration-Fee-Upcoming','MS-Registration-Fee-Upcoming')) as 'source', "
					+ "rmcl.Site_Cert_Amount__c/replace(ig.Recurring_Fee_Frequency__c,' Months', '') as 'amount_monthly',"
					+ "date_format(ig.Next_Invoice_Date__c, '%Y %m') as 'from_period' "
					+ "from report_master_client_listing__c rmcl "
					+ "inner join site_certification_standard_program__c scs ON rmcl.Site_Certification_Standard__c = scs.Id "
					+ "inner join certification__c sc ON scs.Site_Certification__c = sc.Id "
					+ "inner join invoice_group__c ig ON sc.Invoice_Group_Registration__c = ig.Id "
					+ "where "
					+ "scs.Status__c in ('Registered' , 'Under Suspension', 'On Hold') "
					+ "and ig.Client_Ownership__c in ('Australia' , 'Product Services') "
					+ "and rmcl.Auditable_Site__c = 'Y' "
					+ "and ig.Next_Invoice_Date__c > now() "
					+ "and rmcl.IsDeleted=0 "
					+ "and rmcl.Site_Cert_Amount__c>0 "
					+ "order by Site_Certification_Standard__c, Run_Number__c desc) t "
					+ "group by t.Site_Certification_Standard__c, t.from_period) t2 "
					+ "group by t2.source, t2.from_period";
			*/
			//rs = db_certification.executeSelect(upcomingFeeQuery, -1);
			//while (rs.next()) {
				//populateDataMap(rs, dataMap);
			//}
			/*
			// 3) Get TIS Registration
			String tisRegistrationsPublic = "select "
					+ "'Registrations-Public' as 'source', "
					+ "date_format(r.Census_Bill_Date__c, '%Y %m') as 'period', "
					+ "sum(r.SubTotal_Amount__c) as 'amount' "
					+ "from training.registration__c r "
					+ "where r.Status__c='Confirmed' and r.IsDeleted=0 and Class_Type__c='Public Class' "
					+ "and r.Census_Bill_Date__c>='" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' and r.Census_Bill_Date__c<='" + Utility.getActivitydateformatter().format(endDate.getTime()) + "'  "
					+ "group by `source`, `period`";
			*/
			//rs = db_tis.executeSelect(tisRegistrationsPublic, -1);
			//while (rs.next()) {
				//populateDataMap(rs, dataMap);
			//}
			/*
			// 4) TIS In house Events Revenues
			String tisInHouseEvents = "select "
					+ "'Registrations-InHouse' as 'source' "
					+ "date_format(ihe.In_House_Event_Date__c, '%Y %m') as 'period', "
					+ "sum(ihe.Invoice_Amount_1__c) as 'amount', "
					+ "sum(ihe.TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c) as 'TOTAL_COURSE_TO_BE_INVOICED_ex_GST__c' "
					+ "from training.in_house_event__c ihe "
					+ "where "
					+ "ihe.Event_Location__c = 'AUSTRALIA' "
					+ "and ihe.Event_Type__c = 'Course' "
					+ "group by `Period`";
			*/
			//rs = db_tis.executeSelect(tisInHouseEvents, -1);
			//while (rs.next()) {
				//populateDataMap(rs, dataMap);
			//}
			
			// Assign data and save it in history
			for (ReportRow source : dataRows) {
				List<Object> values = new ArrayList<Object>();
				
				values.add(source.getName());
				for (String period : periods) {
					values.add(dataMap.get(period).get(source.getName()));
					// Save for future references
					if (saveInHistory && source.isSaveInHistory())
						db_certification.addToHistory(getFileReportNames()[0], reportDate, "Australia", source.getName(), period, dataMap.get(period).get(source.getName()).toString());
				}
				data.add(values.toArray());
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
		this.db_certification = db;
		
		// Set up additional db handler for tis database
		GlobalProperties tisProperties = Utility.getProperties("C:\\SAI\\Properties\\global.config.training.properties");
		try {
			//this.db_tis = new DbHelper(tisProperties);
		} catch (Exception e) {
			Utility.handleError(tisProperties, e);
		}
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		this.saveInHistory = gp.isSaveDataToHistory();
	}
	
	private static long getNoOfPeriods(String fromPeriod, String toPeriod) throws ParseException {
		if (fromPeriod.equalsIgnoreCase(toPeriod))
			return 1;
		return Math.round((mysqlPeriodDateFormat.parse(toPeriod).getTime() - mysqlPeriodDateFormat.parse(fromPeriod).getTime()) / averageMillisPerMonth);
	}
	
	private void populateDataMap(ResultSet rs, HashMap<String, HashMap<String, Double>> dataMap) throws ParseException {
		try {
			if (rs.getString("source").endsWith("Fee")) {
				// Past fees
				String fromPeriod = rs.getString("from_period");
				String toPeriod = rs.getString("to_period");
				long noOfPeriods = getNoOfPeriods(fromPeriod, toPeriod);
				String sourceString = rs.getString("source");
				ReportRow source = ReportRow.getValueForSqlName(sourceString);
				for (String period : periods) {
					if (period.compareTo(fromPeriod)>=0) {
						if (period.compareTo(toPeriod)<=0) {
							HashMap<String, Double> currendPeriodData = dataMap.get(period);
							currendPeriodData.put(source.getName(), new Double(currendPeriodData.get(source.getName()).doubleValue() + rs.getDouble("amount")/noOfPeriods));
							dataMap.put(period, currendPeriodData);
						} else {
							break;
						}
					}
				}
				
			} else if (rs.getString("source").endsWith("-Upcoming")) {
				// Upcoming fees
				String fromPeriod = rs.getString("from_period");
				String sourceString = rs.getString("source").replace("-Upcoming", "");
				ReportRow source = ReportRow.getValueForSqlName(sourceString);
				for (String period : periods) {
					if (period.compareTo(fromPeriod)>=0) {
						HashMap<String, Double> currendPeriodData = dataMap.get(period);
						try {
							currendPeriodData.put(source.getName(), new Double(currendPeriodData.get(source.getName()).doubleValue() + rs.getDouble("amount_monthly")));
						} catch (NullPointerException npe) {
							logger.error("", npe);
						}
						dataMap.put(period, currendPeriodData);
					}
				}
				
			} else {
				String period = rs.getString("period");
				String sourceString = rs.getString("source");
				ReportRow source = ReportRow.getValueForSqlName(sourceString);
				HashMap<String, Double> currendPeriodData = dataMap.get(period);
				// Status
				currendPeriodData.put(source.getName(), new Double(currendPeriodData.get(source.getName()).doubleValue() + rs.getDouble("amount")));
				// Calculated Fields
				if (!source.equals(ReportRow.FeesFood) && !source.equals(ReportRow.FeesMS) && !source.equals(ReportRow.FeesProductService) && !source.equals(ReportRow.ExpensesFood) && !source.equals(ReportRow.ExpensesMS) && !source.equals(ReportRow.ExpensesProductService) && !source.equals(ReportRow.TISPublicRegistrations) && !source.equals(ReportRow.TISInHouseRegistrations)) {
					// We have an audit, let's calculate the Average Billable Expenses
					double amount = 0;
					if (standard_parents.containsKey(rs.getString("Primary_Standard__c")) && billable_expenses_by_standard.containsKey(standard_parents.get(rs.getString("Primary_Standard__c")))) {
						double rowDays = 0;
						if (rs.getString("Unit").equalsIgnoreCase("DAY"))
							rowDays = rs.getDouble("Quantity");
						if (rs.getString("Unit").equalsIgnoreCase("HFD"))
							rowDays = rs.getDouble("Quantity")/2;
						if (rs.getString("Unit").equalsIgnoreCase("HR"))
							rowDays = rs.getDouble("Quantity")/8;
						amount += billable_expenses_by_standard.get(standard_parents.get(rs.getString("Primary_Standard__c"))).doubleValue()*rowDays;
						
						if (source.getName().contains("Product Service"))
							currendPeriodData.put(ReportRow.ExpensesProductService.getName(), new Double(currendPeriodData.get(ReportRow.ExpensesProductService.getName()).doubleValue() + amount));
						else if (source.getName().contains("Food"))
							currendPeriodData.put(ReportRow.ExpensesFood.getName(), new Double(currendPeriodData.get(ReportRow.ExpensesFood.getName()).doubleValue() + amount));
						else 
							currendPeriodData.put(ReportRow.ExpensesMS.getName(), new Double(currendPeriodData.get(ReportRow.ExpensesMS.getName()).doubleValue() + amount));
					}
					
					// Add audit days
					Double currentValue = currendPeriodData.get(source.getName().replaceFirst("Audit -", "Audit - Days -"));
					double addValue = rs.getDouble("days");
					currendPeriodData.put(source.getName().replaceFirst("Audit -", "Audit - Days -"), new Double(currentValue.doubleValue() + addValue));
				}
				
				dataMap.put(period, currendPeriodData);
			}
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
		return new String[] {"Financial Visibility\\Planning Revenues Report"};
	}
	
	public String[] getFileReportNames() {
		return new String[] {"Planning Revenues Report"};
	}

	public boolean append() {
		return false;
	}
	
	private enum ReportRow {
		CancelledFood("Food - Audit - Cancelled", "Food-Audit-Cancelled", true, true), 
		ConfirmedFood("Food - Audit - Confirmed", "Food-Audit-Confirmed", true, true), 
		ScheduledFood("Food - Audit - Scheduled", "Food-Audit-Scheduled", true, true), 
		ScheduledOfferedFood("Food - Audit - Scheduled Offered", "Food-Audit-Scheduled - Offered", true, true), 
		ServiceChangeFood("Food - Audit - Service Change", "Food-Audit-Service change", true, true),
		OpenFood("Food - Audit - Open", "Food-Audit-Open", true, true),
		InProgressFood("Food - Audit - In Progress", "Food-Audit-In Progress", true, true),
		SubmittedFood("Food - Audit - Submitted", "Food-Audit-Submitted", true, true),
		UnderReviewFood("Food - Audit - Under Review", "Food-Audit-Under Review", true, true),
		SupportFood("Food - Audit - Support", "Food-Audit-Support", true, true),
		CompletedFood("Food - Audit - Completed", "Food-Audit-Completed", true, true),
		ExpensesFood("Food - Audit - Expenses", "Food-Expenses", true, true),
		FeesFood("Food - Registration - Fee", "Food-Registration-Fee", true, true),
		InititateServiceFood("Food - Audit - Inititate Service", "Food-Audit-Inititate service", true, true),
		IncompleteFood("Food - Audit - Incomplete", "Food-Audit-Incomplete", true, true),
		UnderReviewRejectedFood("Food - Audit - Under Review - Rejected", "Food-Audit-Under Review - Rejected", true, true),
		CancelledMS("MS - Audit - Cancelled", "MS-Audit-Cancelled", true, true),
		ConfirmedMS("MS - Audit - Confirmed", "MS-Audit-Confirmed", true, true), 
		ScheduledMS("MS - Audit - Scheduled", "MS-Audit-Scheduled", true, true), 
		ScheduledOfferedMS("MS - Audit - Scheduled Offered", "MS-Audit-Scheduled - Offered", true, true), 
		ServiceChangeMS("MS - Audit - Service Change", "MS-Audit-Service change", true, true),
		OpenMS("MS - Audit - Open", "MS-Audit-Open", true, true),
		InProgressMS("MS - Audit - In Progress", "MS-Audit-In Progress", true, true),
		SubmittedMS("MS - Audit - Submitted", "MS-Audit-Submitted", true, true),
		UnderReviewMS("MS - Audit - Under Review", "MS-Audit-Under Review", true, true),
		SupportMS("MS - Audit - Support", "MS-Audit-Support", true, true),
		CompletedMS("MS - Audit - Completed", "MS-Audit-Completed", true, true),
		InititateServiceMS("MS - Audit - Inititate Service", "MS-Audit-Inititate service", true, true),
		IncompleteMS("MS - Audit - Incomplete", "MS-Audit-Incomplete", true, true),
		UnderReviewRejectedMS("MS - Audit - Under Review - Rejected", "MS-Audit-Under Review - Rejected", true, true),
		ExpensesMS("MS - Audit - Expenses", "MS-Expenses", true, true),
		FeesMS("MS - Registration - Fee", "MS-Registration-Fee", true, true),
		CancelledProductService("Product Service - Audit - Cancelled", "ProductService-Audit-Cancelled", true, true),
		ConfirmedProductService("Product Service - Audit - Confirmed", "ProductService-Audit-Confirmed", true, true), 
		ScheduledProductService("Product Service - Audit - Scheduled", "ProductService-Audit-Scheduled", true, true), 
		ScheduledOfferedProductService("Product Service - Audit - Scheduled Offered", "ProductService-Audit-Scheduled - Offered", true, true), 
		ServiceChangeProductService("Product Service - Audit - Service Change", "ProductService-Audit-Service change", true, true),
		OpenProductService("Product Service - Audit - Open", "ProductService-Audit-Open", true, true),
		InProgressProductService("Product Service - Audit - In Progress", "ProductService-Audit-In Progress", true, true),
		SubmittedProductService("Product Service - Audit - Submitted", "ProductService-Audit-Submitted", true, true),
		UnderReviewProductService("Product Service - Audit - Under Review", "ProductService-Audit-Under Review", true, true),
		SupportProductService("Product Service - Audit - Support", "ProductService-Audit-Support", true, true),
		CompletedProductService("Product Service - Audit - Completed", "ProductService-Audit-Completed", true, true),
		InititateServiceProductService("Product Service - Audit - Inititate Service", "ProductService-Audit-Inititate service", true, true),
		IncompleteProductService("Product Service - Audit - Incomplete", "ProductService-Audit-Incomplete", true, true),
		UnderReviewRejectedProductService("Product Service - Audit - Under Review - Rejected", "ProductService-Audit-Under Review - Rejected", true, true),
		ExpensesProductService("Product Service - Audit - Expenses", "ProductService-Expenses", true, true),
		FeesProductService("Product Service - Registration - Fee", "ProductService-Registration-Fee", true, true),
		TISPublicRegistrations("TIS - Registrations - Public", "Registrations-Public", true, true),
		TISInHouseRegistrations("TIS - Registrations - InHouse", "Registrations-InHouse", true, true),
		
		// Days measures
		CancelledFoodDays("Food - Audit - Days - Cancelled", "Food-Audit-Days- Cancelled", true, true),
		ConfirmedFoodDays("Food - Audit - Days - Confirmed", "Food-Audit-Days- Confirmed", true, true), 
		ScheduledFoodDays("Food - Audit - Days - Scheduled", "Food-Audit-Days- Scheduled", true, true), 
		ScheduledOfferedFoodDays("Food - Audit - Days - Scheduled Offered", "Food-Audit-Days- Scheduled - Offered", true, true), 
		ServiceChangeFoodDays("Food - Audit - Days - Service Change", "Food-Audit-Days- Service change", true, true),
		OpenFoodDays("Food - Audit - Days - Open", "Food-Audit-Days- Open", true, true),
		InProgressFoodDays("Food - Audit - Days - In Progress", "Food-Audit-Days- In Progress", true, true),
		SubmittedFoodDays("Food - Audit - Days - Submitted", "Food-Audit-Days- Submitted", true, true),
		UnderReviewFoodDays("Food - Audit - Days - Under Review", "Food-Audit-Days- Under Review", true, true),
		SupportFoodDays("Food - Audit - Days - Support", "Food-Audit-Days- Support", true, true),
		CompletedFoodDays("Food - Audit - Days - Completed", "Food-Audit-Days- Completed", true, true),
		InititateServiceFoodDays("Food - Audit - Days - Inititate Service", "Food-Audit-Days- Inititate service", true, true),
		IncompleteFoodDays("Food - Audit - Days - Incomplete", "Food-Audit-Days- Incomplete", true, true),
		UnderReviewRejectedFoodDays("Food - Audit - Days - Under Review - Rejected", "Food-Audit-Days- Under Review - Rejected", true, true),
		CancelledMSDays("MS - Audit - Days - Cancelled", "MS-Audit-Days- Cancelled", true, true),
		ConfirmedMSDays("MS - Audit - Days - Confirmed", "MS-Audit-Days- Confirmed", true, true), 
		ScheduledMSDays("MS - Audit - Days - Scheduled", "MS-Audit-Days- Scheduled", true, true), 
		ScheduledOfferedMSDays("MS - Audit - Days - Scheduled Offered", "MS-Audit-Days- Scheduled - Offered", true, true), 
		ServiceChangeMSDays("MS - Audit - Days - Service Change", "MS-Audit-Days- Service change", true, true),
		OpenMSDays("MS - Audit - Days - Open", "MS-Audit-Days- Open", true, true),
		InProgressMSDays("MS - Audit - Days - In Progress", "MS-Audit-Days- In Progress", true, true),
		SubmittedMSDays("MS - Audit - Days - Submitted", "MS-Audit-Days- Submitted", true, true),
		UnderReviewMSDays("MS - Audit - Days - Under Review", "MS-Audit-Days- Under Review", true, true),
		SupportMSDays("MS - Audit - Days - Support", "MS-Audit-Days- Support", true, true),
		CompletedMSDays("MS - Audit - Days - Completed", "MS-Audit-Days- Completed", true, true),
		InititateServiceMSDays("MS - Audit - Days - Inititate Service", "MS-Audit-Days- Inititate service", true, true),
		IncompleteMSDays("MS - Audit - Days - Incomplete", "MS-Audit-Days- Incomplete", true, true),
		UnderReviewRejectedMSDays("MS - Audit - Days - Under Review - Rejected", "MS-Audit-Days- Under Review - Rejected", true, true),
		CancelledProductServiceDays("Product Service - Audit - Days - Cancelled", "ProductService-Audit-Days- Cancelled", true, true),
		ConfirmedProductServiceDays("Product Service - Audit - Days - Confirmed", "ProductService-Audit-Days- Confirmed", true, true), 
		ScheduledProductServiceDays("Product Service - Audit - Days - Scheduled", "ProductService-Audit-Days- Scheduled", true, true), 
		ScheduledOfferedProductServiceDays("Product Service - Audit - Days - Scheduled Offered", "ProductService-Audit-Days- Scheduled - Offered", true, true), 
		ServiceChangeProductServiceDays("Product Service - Audit - Days - Service Change", "ProductService-Audit-Days- Service change", true, true),
		OpenProductServiceDays("Product Service - Audit - Days - Open", "ProductService-Audit-Days- Open", true, true),
		InProgressProductServiceDays("Product Service - Audit - Days - In Progress", "ProductService-Audit-Days- In Progress", true, true),
		SubmittedProductServiceDays("Product Service - Audit - Days - Submitted", "ProductService-Audit-Days- Submitted", true, true),
		UnderReviewProductServiceDays("Product Service - Audit - Days - Under Review", "ProductService-Audit-Days- Under Review", true, true),
		SupportProductServiceDays("Product Service - Audit - Days - Support", "ProductService-Audit-Days- Support", true, true),
		CompletedProductServiceDays("Product Service - Audit - Days - Completed", "ProductService-Audit-Days- Completed", true, true),
		InititateServiceProductServiceDays("Product Service - Audit - Days - Inititate Service", "ProductService-Audit-Days- Inititate service", true, true),
		IncompleteProductServiceDays("Product Service - Audit - Days - Incomplete", "ProductService-Audit-Days- Incomplete", true, true),
		UnderReviewRejectedProductServiceDays("Product Service - Audit - Days - Under Review - Rejected", "ProductService-Audit-Days- Under Review - Rejected", true, true);		
		
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
