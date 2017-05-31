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

import net.sf.dynamicreports.examples.Templates;
import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.report.base.expression.AbstractSimpleExpression;
import net.sf.dynamicreports.report.builder.FieldBuilder;
import net.sf.dynamicreports.report.builder.chart.LineChartBuilder;
import net.sf.dynamicreports.report.builder.chart.MultiAxisChartBuilder;
import net.sf.dynamicreports.report.builder.chart.StackedBarChartBuilder;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.ConditionalStyleBuilder;
import net.sf.dynamicreports.report.builder.style.FontBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.AxisPosition;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.constant.Position;
import net.sf.dynamicreports.report.datasource.DRDataSource;
import net.sf.dynamicreports.report.definition.ReportParameters;


public class PlanningDaysReport implements ReportBuilder {
	private DbHelper db;
	private GlobalProperties gp;
	
	private DRDataSource data = null;
	private DRDataSource dataChart = null;
	private boolean saveInHistory;
	private static final Logger logger = Logger.getLogger(PlanningDaysReport.class);
	private static final Calendar today = new GregorianCalendar();
	private final int currentFY;
	private final Calendar startFY; 
	private final Calendar endFY;
	private final Calendar startPeriod; 
	private final Calendar endPeriod;
	protected final Calendar reportDate;
	private final String[] periods;
	private final ReportRow[] dataRows;
	private final ReportRow[] chartRows;
	private final ReportRow[] allRows;
	private static final SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMMM yyyy");
	private static final SimpleDateFormat mysqlPeriodDateFormat = new SimpleDateFormat("yyyy MM");
	private static final SimpleDateFormat periodDateFormat = new SimpleDateFormat("MMM yy");
	protected String operationalOwnershipString;
	protected String revenueOwnershipString;
	protected String historyBusinessUnits;
	protected int chartYmax;
	
		
	public PlanningDaysReport() {
		if (today.get(Calendar.MONTH)>5)
			currentFY = today.get(Calendar.YEAR);
		else
			currentFY = today.get(Calendar.YEAR)-1;
		
		startFY = new GregorianCalendar(currentFY,6,1);
		endFY = new GregorianCalendar(currentFY+1,5,30);
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		startPeriod = startFY;
		endPeriod = endFY;
		
		// Alternatively for rolling year
		//startPeriod = today;
		//today.add(Calendar.YEAR, 1);
		//endPeriod = new GregorianCalendar(today.get(Calendar.YEAR)+1,today.get(Calendar.MONTH), today.get(Calendar.DAY_OF_MONTH));
		
		periods = getAllPeriods();
		dataRows = ReportRow.getAllDataValues();
		chartRows = ReportRow.getAllChartValues();
		allRows = ReportRow.getAllValues();
		
		this.operationalOwnershipString = "'AUS - Management Systems', 'AUS - Food'";
		this.revenueOwnershipString = "'AUS-Food-NSW/ACT','AUS-Food-VIC/TAS','AUS-Food-QLD','AUS-Food-SA/NT','AUS-Food-WA','AUS-Food-ROW', 'AUS-Global-NSW/ACT','AUS-Global-VIC/TAS','AUS-Global-QLD', 'AUS-Global-SA/NT','AUS-Global-WA','AUS-Global-ROW','AUS-Managed Plus-NSW/ACT','AUS-Managed Plus-VIC/TAS','AUS-Managed Plus-QLD','AUS-Managed Plus-SA/NT','AUS-Managed Plus-WA','AUS-Managed Plus-ROW','AUS-Managed-NSW/ACT','AUS-Managed-VIC/TAS','AUS-Managed-QLD','AUS-Managed-SA/NT','AUS-Managed-WA','AUS-Managed-ROW','AUS-Direct-NSW/ACT','AUS-Direct-VIC/TAS','AUS-Direct-QLD','AUS-Direct-SA/NT','AUS-Direct-WA','AUS-Direct-ROW'";
		this.historyBusinessUnits = "'Planning Days - MS - History', 'Planning Days - Food - History'";
		this.chartYmax = 2200;
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
		FontBuilder boldFont = stl.fontArialBold().setFontSize(12);
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);
		
		ConditionalStyleBuilder budgetCondition = stl.conditionalStyle(new BudgetConditionExpression())
		    	.setBackgroundColor(new Color(255, 255, 0))
		    	.setItalic(true)
		    	.setBold(true);
		ConditionalStyleBuilder headerCondition = stl.conditionalStyle(new HeaderConditionExpression())
		    	.setBold(true)
		    	.setItalic(true);
		ConditionalStyleBuilder claculatedCondition = stl.conditionalStyle(new CalculatedConditionExpression())
		    	.setItalic(true);
		//ConditionalStyleBuilder percentageCondition = stl.conditionalStyle(new PercentageConditionExpression())
		//    	.setPattern("#.# %");
		//onditionalStyleBuilder badCondition = stl.conditionalStyle(new BadConditionExpression())
		//    	.setItalic(true)
		//    	.setBackgroundColor(new Color(255,0,0));
		
		StyleBuilder statusStyle = stl.style()
				.conditionalStyles(headerCondition, budgetCondition, claculatedCondition);
		
		StyleBuilder dataStyle = stl.style()
				.conditionalStyles(headerCondition, budgetCondition, claculatedCondition);
		
		TextColumnBuilder<String> statusColumn = col.column("Status", "status", type.stringType()).setFixedWidth(180).setStyle(statusStyle);
		TextColumnBuilder<Double> totalColumn  = col.column("Total",   "total",  type.percentageType()).setFixedWidth(100).setStyle(dataStyle).setPattern("#");
		
		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(statusColumn);
		
		
		// Chart
		FieldBuilder<String> periodField = field("period", type.stringType());
		LineChartBuilder budgetChart = cht.lineChart()
				.setCategory(periodField)
				.setDataSource(dataChart)
				.setLegendPosition(Position.RIGHT)
				.setValueAxisFormat(
					cht.axisFormat().setLabel("Budget").setRangeMaxValueExpression(chartYmax).setRangeMinValueExpression(0))
				.setCategoryAxisFormat(
					cht.axisFormat().setLabel("Period"));
		
		StackedBarChartBuilder daysChart = cht.stackedBarChart()
				.setCategory(periodField)
				.setDataSource(dataChart)
				.setLegendPosition(Position.RIGHT)
				.setValueAxisFormat(
						cht.axisFormat().setLabel("Days").setRangeMaxValueExpression(chartYmax).setRangeMinValueExpression(0))
				.setCategoryAxisFormat(
					cht.axisFormat().setLabel("Period"));

		for (ReportRow chartSerie : chartRows) {
			if (chartSerie.equals(ReportRow.Budget)) {
				budgetChart.addSerie(cht.serie(field(chartSerie.toString(), type.doubleType())).setLabel(chartSerie.getName()));
			} else {
				daysChart.addSerie(cht.serie(field(chartSerie.toString(), type.doubleType())).setLabel(chartSerie.getName()));
			}
		}
		
		for (String period : periods) {
			try {
				report.addColumn(col.column(periodDateFormat.format(mysqlPeriodDateFormat.parse(period)),   period,  type.doubleType()).setFixedWidth(80).setPattern("#.00").setStyle(dataStyle));
			} catch (ParseException e) {
				logger.error(e);
			}
		}
		report.addColumn(totalColumn);
		
		MultiAxisChartBuilder chart = cht.multiAxisChart();
		chart
			.setTitle(getFileReportNames()[0] + "\n" + Utility.getShortdatetimedisplayformat().format(reportDate.getTime()))
			.setTitleFont(boldFont)
			.setDimension(1200, 600)
			.addChart(budgetChart, AxisPosition.LEFT_OR_TOP)
			.addChart(daysChart, AxisPosition.RIGHT_OR_BOTTOM);
		
		report
		  .fields(periodField)
		  .title(//shows report title
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(340, 50)),
					cmp.horizontalList().add(cmp.text(getFileReportNames()[0])).setFixedDimension(340, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Period from " + displayDateFormat.format(startPeriod.getTime()) + " to " + displayDateFormat.format(endPeriod.getTime()))).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(reportDate.getTime()) )).setFixedDimension(340, 17))
		  .summary(
				  cmp.horizontalList().add(cmp.text("").setHeight(35)),
				  chart)
		  .setDataSource(data);
		
		try {
			report()
			.fields(periodField)
			.setTemplate(Templates.reportTemplate)
			.title(
				Templates.createTitleComponent("MultiAxisChart"),
				cht.multiAxisChart(budgetChart, daysChart),
				cht.multiAxisChart()
				.addChart(budgetChart, AxisPosition.LEFT_OR_TOP)
				.addChart(daysChart, AxisPosition.RIGHT_OR_BOTTOM))
			.pageFooter(Templates.footerComponent)
			.setDataSource(dataChart)
			.show(true);
			
		} catch (Exception e) {
			logger.error(e);
		}
		
		return new JasperReportBuilder[] {report};
	}
	
	public void init() {
		String query = 
				"SELECT t.Status, t.Period, SUM(t.Days) AS 'Days' FROM (" +
				"(SELECT " +
					"c.Operational_Ownership__c as 'BusinessUnit' " +
					", DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' " +
					", 'New Business' AS 'Status' " +
					", sum(wi.Required_Duration__c/8) AS 'Days' " +
				"FROM " + db.getDBTableName("work_item__c") + " wi " +
				"INNER JOIN " + db.getDBTableName("recordtype") + " rt on wi.RecordTypeId = rt.Id " +
				"INNER JOIN " + db.getDBTableName("work_package__c") + " wp on wp.Id = wi.Work_Package__c " +
				"INNER JOIN " + db.getDBTableName("certification__c") + " c on c.Id = wp.Site_Certification__c " +
				"INNER JOIN " +
					"(SELECT scsp.Site_Certification__c, scsp.Status__c FROM " + db.getDBTableName("site_certification_standard_program__c") + " scsp where Status__c IN ('Applicant', 'Customised')) t ON t.Site_Certification__c= c.Id " +
				"WHERE " +
					"wi.Status__c='Open' " +
					"AND rt.Name = 'Audit' " +
					"AND wi.Work_Item_Stage__c IN ('Certification', 'Gap', 'Initial Inspection', 'Stage 1', 'Stage 2') " +
					"AND c.Operational_Ownership__c IN (" + operationalOwnershipString + ") " +
					"GROUP BY c.Operational_Ownership__c, `Period` " +
					"ORDER BY c.Operational_Ownership__c, `Period`) " +
				"UNION " +
					"(SELECT " +
						"IF(wi.Revenue_Ownership__c LIKE 'AUS-Food%', 'AUS - Food', 'AUS - Management Systems') AS 'BusinessUnit' " +
						", DATE_FORMAT(wi.Service_target_date__c,'%Y %m') AS 'Period' " +
						", 'Open' AS 'Status' " +
						", ROUND(SUM(wi.Required_Duration__c/8)) AS 'Days' " +
					"FROM " + db.getDBTableName("work_item__c") + " wi " +
					"INNER JOIN " + db.getDBTableName("recordtype") + " rt on wi.RecordTypeId = rt.Id " +
					"INNER JOIN " + db.getDBTableName("work_package__c") + " wp on wp.Id = wi.Work_Package__c " +
					"INNER JOIN " + db.getDBTableName("certification__c") + " c on c.Id = wp.Site_Certification__c " +
					"WHERE " +
						"wi.Status__c='Open' " +
						"AND rt.Name = 'Audit' " +
						"AND wi.Work_Item_Stage__c NOT IN ('Certification', 'Gap', 'Initial Inspection', 'Stage 1', 'Stage 2') " +
						"AND wi.Revenue_Ownership__c IN (" + revenueOwnershipString + ") " +
					"GROUP BY `BusinessUnit`, `Period` " +
					"ORDER BY `BusinessUnit`, `Period`) " +
				"UNION " +
					"(SELECT " +
						"IF(wi.Revenue_Ownership__c LIKE 'AUS-Food%', 'AUS - Food', 'AUS - Management Systems') AS 'BusinessUnit', " +
						"DATE_FORMAT(wird.FStartDate__c,'%Y %m') as 'Period', " +
						"IF(wi.Status__c = 'Service change', 'Service change', IF(wi.Status__c = 'Scheduled','Scheduled',IF(wi.Status__c='Scheduled - Offered','Scheduled - Offered',IF(wi.Status__c='Budget', 'Budget','Confirmed')))) AS 'Status', " +
						"sum(if (Budget_Days__c is null,wird.Scheduled_Duration__c/8,wird.Scheduled_Duration__c/8+Budget_Days__c) ) AS 'Days' " +
					"FROM " + db.getDBTableName("work_item__c") + " wi " +
					"INNER JOIN " + db.getDBTableName("work_item_resource__c") + " wir ON wir.work_item__c = wi.Id " +
					"INNER JOIN " + db.getDBTableName("work_item_resource_day__c") + " wird ON wird.Work_Item_Resource__c = wir.Id " +
					"INNER JOIN " + db.getDBTableName("recordtype") + " rt on wi.RecordTypeId = rt.Id " +
					"WHERE " +
						"rt.Name = 'Audit' " +
						"AND wir.IsDeleted = 0 " +
						"AND wird.IsDeleted = 0 " +
						"AND wir.Work_Item_Type__c IN ('Audit','Audit Planning','Client Management','Budget') " +
						"AND wi.Status__c IN ('Scheduled','Scheduled - Offered','Confirmed','Service change','In Progress','Submitted','Under Review','Support','Completed','Budget') " +
						"AND wi.Revenue_Ownership__c IN (" + revenueOwnershipString + ") " +
						"AND wir.Role__c NOT IN ('Observer','Verifying Auditor','Verifier') " +
					"GROUP BY `BusinessUnit`, `Period`, `Status` " +
					"ORDER BY `BusinessUnit`, `Status`, `Period`) " +
				"UNION " +
					"(SELECT " +
						"'MS + Food' AS 'BusinessUnit', " +
						"ColumnName AS 'Period', " +
						"CONCAT('Previous-', RowName) AS 'Status' , " +
						"Value AS 'Days' " +
					"FROM " + db.getDBTableName("sf_report_history") + " " +
					"WHERE " +
						"ReportName='" + getFileReportNames()[0] + "' " +
						"AND date = (SELECT Max(Date) FROM " + db.getDBTableName("sf_report_history") + " WHERE ReportName='" + getFileReportNames()[0] + "' GROUP BY ReportName)) " +
				"UNION " +
					"(SELECT " +
						"IF(ReportName LIKE '%Food%', 'Food', 'MS') AS 'BusinessUnit', " +
						"CONCAT(SUBSTRING(ColumnName,1,2), CAST(SUBSTRING(ColumnName,3,2)+1 AS CHAR), SUBSTRING(ColumnName,5,3)) AS 'Period', " +
						"CONCAT('Previous Year-', RowName) AS 'Status' , " +
						"Value AS 'Days' " +
					"FROM " + db.getDBTableName("sf_report_history") + " " +
					"WHERE " +
						"ReportName IN (" + historyBusinessUnits + ") " +
						"AND RowName IN ('Budget', 'Confirmed') " +
						"AND ColumnName >= '" +	mysqlPeriodDateFormat.format(getPreviousPeriod(startPeriod).getTime()) + "' AND ColumnName <= '" + mysqlPeriodDateFormat.format(getPreviousPeriod(endPeriod).getTime()) + "')" +
				") t " +
				"WHERE `Period` >= '" + mysqlPeriodDateFormat.format(startPeriod.getTime()) + "' and `Period` <= '" + mysqlPeriodDateFormat.format(endPeriod.getTime()) + "' " +
				"GROUP BY `Status`, `Period` " +
				"ORDER BY `Status`, `Period`";
		try {
			ResultSet rs = db.executeSelect(query, -1);
			List<String> dataVariables = new ArrayList<String>();
			List<String> chartVariables = new ArrayList<String>();
			dataVariables.add("status");
						
			HashMap<String, HashMap<String, Double>> dataMap = new HashMap<String, HashMap<String, Double>>();
			for (String period : periods) {
				HashMap<String, Double> periodData = new HashMap<String, Double>();
				for (ReportRow status : allRows) {
					periodData.put(status.getName(), new Double(0));
				}
				dataMap.put(period, periodData);
				dataVariables.add(period);
			}
			dataVariables.add("total");
			
			chartVariables.add("period");
			for (ReportRow charRow : chartRows) {
				chartVariables.add(charRow.toString());
			}
			data = new DRDataSource(dataVariables.toArray(new String[dataVariables.size()]));
			dataChart = new DRDataSource(chartVariables.toArray(new String[chartVariables.size()]));
			
			while (rs.next()) {
				populateDataMap(rs, dataMap);
			}

			// Assign dataChart
			for (String period : periods) {
				List<Object> values = new ArrayList<Object>();
				values.add(period);
				for (ReportRow aRow : chartRows) {
					values.add(dataMap.get(period).get(aRow.getName()));
				}
				dataChart.add(values.toArray());
			}
			
			// Assign data and save it in history
			for (ReportRow status : dataRows) {
				List<Object> values = new ArrayList<Object>();
				double statusTotal = 0;
				String statusName = status.getName();
				if (status.equals(ReportRow.PreviousChangesHeader)) {
					try {
						statusName += Utility.getShortdatetimedisplayformat().format(getPreviousReportDate().getTime());
					} catch (Exception e) {
						logger.error(e);
					} 
				} 
				values.add(statusName);
				for (String period : periods) {
					values.add(dataMap.get(period).get(status.getName()));
					statusTotal += dataMap.get(period).get(status.getName()).doubleValue();
					// Save for future references
					if (saveInHistory && status.isSaveInHistory())
						db.addToHistory(getFileReportNames()[0], reportDate, "Australia", status.getName(), period, dataMap.get(period).get(status.getName()).toString());
				}
				values.add(statusTotal);
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
		this.db = db;
	}

	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		this.saveInHistory = gp.isSaveDataToHistory();
	}
	
	private Calendar getPreviousReportDate() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException, ParseException {
		String query = "SELECT Date FROM " + db.getDBTableName("sf_report_history") + " WHERE ReportName='" + getFileReportNames()[0] + "' GROUP BY Date ORDER BY Date DESC";
		ResultSet rs = db.executeSelect(query, -1);
		Calendar retValue = new GregorianCalendar();
		while (rs.next()) {
			if (rs.getRow()==2) {
				retValue.setTime(Utility.getMysqldateformat().parse(rs.getString("Date")));
				break;
			}
		}
		
		return retValue;
	}
	
	private void populateDataMap(ResultSet rs, HashMap<String, HashMap<String, Double>> dataMap) {
		try {
			String period = rs.getString("period");
			String statusString = rs.getString("Status");
			ReportRow status = ReportRow.getValueForSqlName(statusString);
			HashMap<String, Double> currendPeriodData = dataMap.get(period);
			// Status
			currendPeriodData.put(status.getName(), new Double(currendPeriodData.get(status.getName()).doubleValue() + rs.getDouble("Days")));
			// Calculated Fields
			if (status.equals(ReportRow.Confirmed) || status.equals(ReportRow.Scheduled) || status.equals(ReportRow.ScheduledOffered) || status.equals(ReportRow.ServiceChange) || status.equals(ReportRow.Open) || status.equals(ReportRow.NewBusiness)) {
				currendPeriodData.put(ReportRow.TotalAvailable.getName(), new Double(currendPeriodData.get(ReportRow.TotalAvailable.getName()).doubleValue() + rs.getDouble("Days")));				
			}
			if (currendPeriodData.get(ReportRow.Budget.getName()).doubleValue() > 0) {
				currendPeriodData.put(ReportRow.ConfirmedOnBudget.getName(), currendPeriodData.get(ReportRow.Confirmed.getName()).doubleValue()/currendPeriodData.get(ReportRow.Budget.getName()).doubleValue());
			}
			if (currendPeriodData.get(ReportRow.TotalAvailable.getName()).doubleValue() > 0) {
				currendPeriodData.put(ReportRow.ConfirmedOnAvaialble.getName(), currendPeriodData.get(ReportRow.Confirmed.getName()).doubleValue()/currendPeriodData.get(ReportRow.TotalAvailable.getName()).doubleValue());
			}
			currendPeriodData.put(ReportRow.ConfirmedMinusBudget.getName(), currendPeriodData.get(ReportRow.Confirmed.getName()).doubleValue() - currendPeriodData.get(ReportRow.Budget.getName()).doubleValue());
			
			// Change from Previous Year
			currendPeriodData.put(ReportRow.ChangePreviousYear.getName(), currendPeriodData.get(ReportRow.Confirmed.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousYearConfirmed.getName()).doubleValue());
			
			// Changes from previous
			currendPeriodData.put(ReportRow.ChangeBudget.getName(), currendPeriodData.get(ReportRow.Budget.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousBudget.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeConfirmed.getName(), currendPeriodData.get(ReportRow.Confirmed.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousConfirmed.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeConfirmedMinusBudget.getName(), currendPeriodData.get(ReportRow.ConfirmedMinusBudget.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousConfirmedMinusBudget.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeConfirmedOnAvaialble.getName(), currendPeriodData.get(ReportRow.ConfirmedOnAvaialble.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousConfirmedOnAvaialble.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeConfirmedOnBudget.getName(), currendPeriodData.get(ReportRow.ConfirmedOnBudget.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousConfirmedOnBudget.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeNewBusiness.getName(), currendPeriodData.get(ReportRow.NewBusiness.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousNewBusiness.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeOpen.getName(), currendPeriodData.get(ReportRow.Open.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousOpen.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeScheduled.getName(), currendPeriodData.get(ReportRow.Scheduled.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousScheduled.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeScheduledOffered.getName(), currendPeriodData.get(ReportRow.ScheduledOffered.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousScheduledOffered.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeServiceChange.getName(), currendPeriodData.get(ReportRow.ServiceChange.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousServiceChange.getName()).doubleValue());
			currendPeriodData.put(ReportRow.ChangeTotalAvailable.getName(), currendPeriodData.get(ReportRow.TotalAvailable.getName()).doubleValue() - currendPeriodData.get(ReportRow.PreviousTotalAvailable.getName()).doubleValue());
			dataMap.put(period, currendPeriodData);
		} catch (SQLException e) {
			logger.error(e);
		}
	}
	
	
	private String[] getAllPeriods() {
		List<String> periods = new ArrayList<String>();
		Calendar pointer = new GregorianCalendar(startPeriod.get(Calendar.YEAR), startPeriod.get(Calendar.MONTH), startPeriod.get(Calendar.DAY_OF_MONTH)); 
		String period = null;
		while (pointer.before(endPeriod)) {
			period = mysqlPeriodDateFormat.format(pointer.getTime());  
			if (!periods.contains(period))
				periods.add(period);
			pointer.add(Calendar.DAY_OF_YEAR, 1);
		}
		return periods.toArray(new String[periods.size()] ); //Arrays.copyOf(periods.toA, arg1);
	}
	private class BudgetConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			return ((String)reportParameters.getValue("status")).equalsIgnoreCase(ReportRow.Budget.getName());
		}
	}
	
	private class HeaderConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			return ((String)reportParameters.getValue("status")).contains(ReportRow.PreviousChangesHeader.getName()) ||
				   ((String)reportParameters.getValue("status")).contains(ReportRow.PreviousYearChangesHeader.getName());
		}
	}
	
	private class CalculatedConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			return ((String)reportParameters.getValue("status")).contains(ReportRow.TotalAvailable.getName()) ||
				   ((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedOnBudget.getName()) ||
				   ((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedOnAvaialble.getName()) ||
				   ((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedMinusBudget.getName());
		}
	}
	/*
	private class PercentageConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			return ((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedOnBudget.getName()) ||
				   ((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedOnAvaialble.getName());
		}
	}
	
	
	private class BadConditionExpression extends AbstractSimpleExpression<Boolean> {
		private static final long serialVersionUID = 1L;

		@Override
		public Boolean evaluate(ReportParameters reportParameters) {
			return (((String)reportParameters.getValue("status")).contains(ReportRow.ChangeConfirmedOnBudget.getName()) && ((Double)(reportParameters.getValue("days"))<0)) ||
				   (((String)reportParameters.getValue("status")).contains(ReportRow.ChangeConfirmedOnAvaialble.getName()) && ((Double)(reportParameters.getValue("days"))<0))||
				   (((String)reportParameters.getValue("status")).contains(ReportRow.ChangeConfirmedMinusBudget.getName()) && ((Double)(reportParameters.getValue("days"))<0)) ||
				   (((String)reportParameters.getValue("status")).contains(ReportRow.ConfirmedMinusBudget.getName()) && ((Double)(reportParameters.getValue("days"))<0));
		}
	}
	*/
	public String[] getReportNames() {
		return new String[] {"Audit Days Overview\\" + Utility.getPeriodformatter().format(reportDate.getTime()) + "\\Planning Days Report"};
	}
	
	public String[] getFileReportNames() {
		return new String[] {"Planning Days Report"};
	}
	
	private static Calendar getPreviousPeriod(Calendar currentPeriod) {
		Calendar previousPeriod = new GregorianCalendar();
		previousPeriod.setTime(currentPeriod.getTime());
		previousPeriod.add(Calendar.YEAR, -1);
		return previousPeriod;
	}
	
	public boolean append() {
		return false;
	}
	private enum ReportRow {
		Confirmed("Confirmed", "Confirmed", true, true, true), 
		Scheduled("Scheduled", "Scheduled", true, true, true), 
		ScheduledOffered("Scheduled - Offered", "Scheduled - Offered", true, true, true), 
		ServiceChange("Service change", "Service change", true, true, true),
		Open("Open", "Open", true, true, true), 
		NewBusiness("New Business", "New Business", true, true, true), 
		Budget("Budget", "Budget", true, true, true), 
		TotalAvailable("Total Available", "Total Available", true, false, true),
		ConfirmedOnBudget("Confirmed/Budget (%)", "Confirmed/Budget", true, false, true),
		ConfirmedOnAvaialble("Confirmed/Avaialble (%)", "Confirmed/Avaialble", true, false, true),
		ConfirmedMinusBudget("Confirmed minus Budget", "Confirmed - Budget", true, false, true),
		PreviousYearChangesHeader("Changes From Previous Year","", true, false, false),
		PreviousYearConfirmed("Previous Year Confirmed", "Previous Year-Confirmed",true, false, false),
		PreviousYearBudget("Previous Year Budget", "Previous Year-Budget",false, false, false),		
		ChangePreviousYear("Cahnge Confirmed on PY", "Cahnge Confirmed on PY",true, false, false),
		PreviousChangesHeader("Changes From previous report: ","", true, false, false),
		PreviousConfirmed("Previous-Confirmed", "Previous-Confirmed", false, false, false),
		PreviousScheduled("Previous-Scheduled", "Previous-Scheduled", false, false, false), 
		PreviousScheduledOffered("Previous-Scheduled - Offered", "Previous-Scheduled - Offered", false, false, false), 
		PreviousServiceChange("Previous-Service change", "Previous-Service change", false, false, false),
		PreviousOpen("Previous-Open", "Previous-Open", false, false, false), 
		PreviousNewBusiness("Previous-New Business", "Previous-New Business", false, false, false), 
		PreviousBudget("Previous-Budget", "Previous-Budget", false, false, false), 
		PreviousTotalAvailable("Previous-Total Available", "Previous-Total Available", false, false, false),
		PreviousConfirmedOnBudget("Previous-Confirmed/Budget", "Previous-Confirmed/Budget (%)", false, false, false),
		PreviousConfirmedOnAvaialble("Previous-Confirmed/Avaialble", "Previous-Confirmed/Avaialble (%)", false, false, false),
		PreviousConfirmedMinusBudget("Previous-Confirmed - Budget", "Previous-Confirmed minus Budget", false, false, false),
		ChangeConfirmed("Change Confirmed", "Change-Confirmed", true, false, false), 
		ChangeScheduled("Change Scheduled", "Change-Scheduled", true, false, false), 
		ChangeScheduledOffered("Change Scheduled Offered", "Change-Scheduled - Offered", true, false, false), 
		ChangeServiceChange("Change Service Change", "Change-Service change", false, false, false),
		ChangeOpen("Change-Open", "Change Open", true, false, false), 
		ChangeNewBusiness("Change New Business", "Change-New Business", true, false, false), 
		ChangeBudget("Change Budget", "Change-Budget", true, false, false), 
		ChangeTotalAvailable("Change Total Available", "Change-Total Available", true, false, false),
		ChangeConfirmedOnBudget("Change Confirmed/Budget", "Change-Confirmed/Budget", true, false, false),
		ChangeConfirmedOnAvaialble("Change Confirmed/Avaialble", "Change-Confirmed/Avaialble", true, false, false),
		ChangeConfirmedMinusBudget("Change Confirmed minus Budget", "Change-Confirmed - Budget", true, false, false);
		String name;
		private String sqlName;
		boolean displayInData;
		boolean displayInChart;
		boolean saveInHistory;
		ReportRow(String aName, String aSqlName, boolean isDisplayInData, boolean isDisplayInChart, boolean isSaveInHistory) {
			name = aName;
			sqlName = aSqlName;
			displayInData = isDisplayInData;
			displayInChart = isDisplayInChart;
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
		
		public boolean isDisplayInChart() {
			return displayInChart;
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
		
		public static ReportRow[] getAllChartValues() {
			List<ReportRow> returnValue = new ArrayList<ReportRow>(); 
			for (ReportRow aValue : getAllValues()) {
				if (aValue.isDisplayInChart())
					returnValue.add(aValue);
			}
			return returnValue.toArray(new ReportRow[]{});
		}
	}
}
