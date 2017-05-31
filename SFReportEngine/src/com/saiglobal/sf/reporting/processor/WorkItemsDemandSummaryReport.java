package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;
import java.util.TreeSet;

import org.apache.log4j.Logger;

import net.sf.dynamicreports.jasper.builder.JasperReportBuilder;
import net.sf.dynamicreports.jasper.constant.JasperProperty;
import net.sf.dynamicreports.report.builder.column.TextColumnBuilder;
import net.sf.dynamicreports.report.builder.style.StyleBuilder;
import net.sf.dynamicreports.report.constant.HorizontalAlignment;
import net.sf.dynamicreports.report.datasource.DRDataSource;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfWorkItemDateSelectType;
import com.saiglobal.sf.core.model.SfWorkItemStatus;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.schedule.BusinessRule_Capability;
import com.saiglobal.sf.core.schedule.ProcessorRule;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class WorkItemsDemandSummaryReport implements ReportBuilder {
	
	protected DbHelper db;
	protected GlobalProperties gp;
	protected DRDataSource dataSummary = null;
	protected static final Logger logger = Logger.getLogger(WorkItemsDemandSummaryReport.class);
	protected static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy-MM");
	protected static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	protected static final SimpleDateFormat daysFormatter = new SimpleDateFormat("dd");
	private static final Calendar today = new GregorianCalendar();
	private final int currentFY;
	private final Calendar startFY; 
	private final Calendar endFY;
	private String regions =  "NSW/ACT, QLD, SA/NT, VIC/TAS, WA, ROW";
	protected final Calendar startPeriod; 
	protected final Calendar endPeriod;
	
	protected final Calendar reportDate;
	protected ScheduleParameters parameters;
	protected ProcessorRule[] businessRules;
	
	public WorkItemsDemandSummaryReport() {
		if (today.get(Calendar.MONTH)>5)
			currentFY = today.get(Calendar.YEAR);
		else
			currentFY = today.get(Calendar.YEAR)-1;
		
		startFY = new GregorianCalendar(currentFY,Calendar.JULY,1);
		endFY = new GregorianCalendar(currentFY+1,Calendar.JUNE,30);
		
		reportDate = new GregorianCalendar();
		startPeriod = startFY;
		endPeriod = endFY;
		//startPeriod = new GregorianCalendar(2013, Calendar.JULY, 1);
		//endPeriod = new GregorianCalendar(2014, Calendar.JUNE, 30);
		
		// Input parameters
		parameters = new ScheduleParameters();
		parameters.setBatchId(getReportNames()[0]);
		parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.AUSManagedNSWACT,
				CompassRevenueOwnership.AUSManagedQLD,
				CompassRevenueOwnership.AUSManagedSANT,
				CompassRevenueOwnership.AUSManagedVICTAS,
				CompassRevenueOwnership.AUSManagedWA,
				CompassRevenueOwnership.AUSManagedPlusNSWACT,
				CompassRevenueOwnership.AUSManagedPlusQLD,
				CompassRevenueOwnership.AUSManagedPlusSANT,
				CompassRevenueOwnership.AUSManagedPlusVICTAS,
				CompassRevenueOwnership.AUSManagedPlusWA,
				CompassRevenueOwnership.AUSGlobalNSWACT,
				CompassRevenueOwnership.AUSGlobalQLD,
				CompassRevenueOwnership.AUSGlobalROW,
				CompassRevenueOwnership.AUSGlobalSANT,
				CompassRevenueOwnership.AUSGlobalVICTAS,
				CompassRevenueOwnership.AUSGlobalWA,
				CompassRevenueOwnership.AUSDirectNSWACT,
				CompassRevenueOwnership.AUSDirectQLD,
				CompassRevenueOwnership.AUSDirectSANT,
				CompassRevenueOwnership.AUSDirectVICTAS,
				CompassRevenueOwnership.AUSDirectWA,
				CompassRevenueOwnership.AUSFoodNSWACT,
				CompassRevenueOwnership.AUSFoodQLD,
				CompassRevenueOwnership.AUSFoodSANT,
				CompassRevenueOwnership.AUSFoodSANT,
				CompassRevenueOwnership.AUSFoodVICTAS,
				CompassRevenueOwnership.AUSFoodWA});
		
		//parameters.setRevenueOwnership(new SfBusinessUnit[] {
		//		SfBusinessUnit.AUSManagedNSWACT});
		
		parameters.setRepotingBusinessUnits(parameters.getRevenueOwnership());
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open,
				SfWorkItemStatus.Complete,
				SfWorkItemStatus.Completed,
				SfWorkItemStatus.Confirmed,
				SfWorkItemStatus.InProgress,
				SfWorkItemStatus.Scheduled,
				SfWorkItemStatus.ScheduledOffered,
				SfWorkItemStatus.Servicechange,
				SfWorkItemStatus.UnderReview
				});
		parameters.setResourceCompetencyRanks(new SfResourceCompetencyRankType[] {
				SfResourceCompetencyRankType.LeadAuditor, SfResourceCompetencyRankType.Auditor
		});
		TimeZone tz = TimeZone.getTimeZone("Australia/Sydney");
		parameters.setTimeZone(tz);
		parameters.setWorkItemDateSelectType(SfWorkItemDateSelectType.SERVICE_DATE);
		parameters.setStartDate(startPeriod.getTime());
		parameters.setEndDate(endPeriod.getTime());
		parameters.setCalendarStartDate(startPeriod.getTime());
		parameters.setCalendarEndDate(endPeriod.getTime());
		parameters.setLoadCalendar(false);
		parameters.setLoadCompetencies(false);
	}
	
	public boolean concatenatedReports() {
		return false;
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder reportSummary = report();
		int rowHeight = 53;
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);

		TextColumnBuilder<String> revenueOwnershipColumn = col.column("Revenue Ownership", "revenue_ownership", type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<Double> requiredDurationColumn  = col.column("Days",   "required_duration",  type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight).setPattern("0.0");
		TextColumnBuilder<String> primaryStandardColumn = col.column("Primary Standard", "primary_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> familyStandardColumn = col.column("Family of Standard", "family_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);		
		TextColumnBuilder<String> codesColumn = col.column("Codes", "codes", type.stringType()).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> resourceReportingBusinessUnitColumn  = col.column("Reporting Business Unit",   "resource_reporting_business_unit",  type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		//TextColumnBuilder<Double> countFTEColoumn = col.column("Count FTE", "count_fte", type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight);
		//TextColumnBuilder<Double> countContractorsColoumn = col.column("Count Contractors", "count_contractors", type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<String> periodColumn  = col.column("Period",   "period",  type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		
		// Report Summary
		reportSummary
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(
				  revenueOwnershipColumn,
				  periodColumn,
				  primaryStandardColumn,
				  familyStandardColumn,
				  codesColumn,
				  requiredDurationColumn
				  //resourceReportingBusinessUnitColumn,
				  //countFTEColoumn,
				  //countContractorsColoumn
				  );
		
		// Add variable columns
		for (CompassRevenueOwnership businessUnit : parameters.getReportingBusinessUnits()) {
			reportSummary.addColumn(col.column("FTE - " + businessUnit.getName(),   "FTE_" + businessUnit.toString(),  type.doubleType()).setFixedWidth(100).setPattern("#").setFixedHeight(rowHeight));
			reportSummary.addColumn(col.column("Contractor - " + businessUnit.getName(),   "Contractor_" + businessUnit.toString(),  type.doubleType()).setFixedWidth(100).setPattern("#").setFixedHeight(rowHeight));
		}
		
		reportSummary.title(
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text(getReportNames()[0])).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Work items demand/supply - summary.")),
					cmp.horizontalList().add(cmp.text("Period from " + Utility.getShortdatedisplayformat().format(startPeriod.getTime()) + " to " + Utility.getShortdatedisplayformat().format(endPeriod.getTime()))).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Regions: " + regions)).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "7")
		  .setDataSource(dataSummary);
		
		return new JasperReportBuilder[] {
				reportSummary
				};
	}

	@Override
	public void setDb(com.saiglobal.sf.reporting.data.DbHelper db) {
		this.db = db;
		try {
			businessRules = new ProcessorRule[] {
					new BusinessRule_Capability(db, parameters.getResourceCompetencyRanks()),
					};
		} catch (Exception e) {
			logger.error(e);
		}
	}

	@Override
	public void setProperties(GlobalProperties gp) {
		this.gp = gp;
		if (gp.hasCustomParameter("region")) {
			String region = gp.getCustomParameter("region");
			List<CompassRevenueOwnership> businessUnits = CompassRevenueOwnership.getBusinessUnitsForRegion(region, "Product");
			parameters.setRevenueOwnership(businessUnits.toArray(new CompassRevenueOwnership[businessUnits.size()]));
			regions = region;
		}
	}

	@Override
	public void init() {
		List<String> dataVariablesSummary = new ArrayList<String>();
		
		dataVariablesSummary.add("revenue_ownership");
		dataVariablesSummary.add("period");
		dataVariablesSummary.add("primary_standard");
		dataVariablesSummary.add("family_standard");
		dataVariablesSummary.add("codes");
		dataVariablesSummary.add("required_duration");
		//dataVariablesSummary.add("resource_reporting_business_unit");
		//dataVariablesSummary.add("count_fte");
		//dataVariablesSummary.add("count_contractors");
		for (CompassRevenueOwnership businessUnit : parameters.getReportingBusinessUnits()) {
			dataVariablesSummary.add("FTE_" + businessUnit.toString());
			dataVariablesSummary.add("Contractor_" + businessUnit.toString());
		}
		
		dataSummary = new DRDataSource(dataVariablesSummary.toArray(new String[dataVariablesSummary.size()]));
		
		try {
			// 1) Work Items Selection
			List<WorkItem> workItems = db.getWorkItemBatch(parameters);
			
			// 2) Resources Selection
			HashMap<String, Resource> resourceData = new HashMap<String, Resource>();
			for (Resource resource : db.getResourceBatch(parameters)) {
				resourceData.put(resource.getId(), resource);
			}
			
			HashMap<String, HashMap<String, Resource>> workItemResources = new HashMap<String, HashMap<String,Resource>>();
			
			for (WorkItem  workItem : workItems) {
				// Filter Resources
				HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
				for (Resource resource : resourceData.values()) {
					filteredResources.put(resource.getId(), resource);
				}
				for (ProcessorRule businessRule : businessRules) {
					filteredResources = businessRule.filter(workItem, filteredResources);
					if (filteredResources.size()==0)
						break;
				}
				workItemResources.put(workItem.getId(), filteredResources);
			}

			// 3) Write data details
			HashMap<RowKey, HashMap<String, RowSummaryData>> summaryDataResourceMap = new HashMap<RowKey, HashMap<String, RowSummaryData>>();
			HashMap<RowKey, Double> summaryDataDaysMap = new HashMap<RowKey, Double>();
			for (WorkItem  workItem : workItems) {
				TreeSet<String> familyStandardSet = new TreeSet<String>();
				TreeSet<String> codesSet = new TreeSet<String>();
				
				for (Competency competency : workItem.getRequiredCompetencies()) {
					if (competency.getType().equals(CompetencyType.CODE)) {
						codesSet.add(competency.getCompetencyName());
					} else {
						if (!competency.getType().equals(CompetencyType.PRIMARYSTANDARD)) {
							familyStandardSet.add(competency.getCompetencyName());
						}
					}
				}
				
				HashMap<String, RowSummaryData> data = null;
				RowKey key = new RowKey(workItem.getRevenueOwnership().getName(), periodFormatter.format(workItem.getStartDate()), workItem.getPrimaryStandard().getCompetencyName(), familyStandardSet, codesSet, "");
				for (CompassRevenueOwnership businessUnit : parameters.getReportingBusinessUnits()) {
					RowSummaryData businessUnitData = null;
					if (summaryDataResourceMap.containsKey(key)) {
						data = summaryDataResourceMap.get(key);
					} else {
						data = new HashMap<String, RowSummaryData>();
					}
					if (data.containsKey(businessUnit.getName())) {
						businessUnitData = data.get(businessUnit.getName());
					} else {
						double fteCount = 0;
						double contractorCount = 0;
						if (workItemResources.get(workItem.getId()).size()>0) {
							for (String resourceId : workItemResources.get(workItem.getId()).keySet()) {
								Resource resource = resourceData.get(resourceId);
								if (resource.getReportingBusinessUnit().equalsIgnoreCase(businessUnit.getName())) {
									if (resource.getType().equals(SfResourceType.Employee))
										fteCount += 1;
									if (resource.getType().equals(SfResourceType.Contractor))
										contractorCount += 1;
								}
							}
						}
						businessUnitData = new RowSummaryData(fteCount, contractorCount, 0);
					}
					summaryDataDaysMap.put(key, new Double(workItem.getRequiredDuration()/8));
					data.put(businessUnit.getName(), businessUnitData);
					summaryDataResourceMap.put(key, data);
				}
			}
			
			
			// 4) Write data summary
			for (RowKey key : summaryDataResourceMap.keySet()) {
				HashMap<String, RowSummaryData> data = summaryDataResourceMap.get(key);
				List<Object> dataValues = new ArrayList<Object>();
				dataValues.add(key.getRevenueOwnership());
				dataValues.add(key.getPeriod());
				dataValues.add(key.getPrimaryStandard());
				dataValues.add(key.getFamilyStandardAsString());
				dataValues.add(key.getCodesAsString());
				dataValues.add(summaryDataDaysMap.get(key).doubleValue());
				
				for (CompassRevenueOwnership businessUnit : parameters.getReportingBusinessUnits()) {
					RowSummaryData businessUnitData = data.get(businessUnit.getName());
					dataValues.add(businessUnitData.getFteCount());
					dataValues.add(businessUnitData.getContractorCount());
				}
				
				dataSummary.add(dataValues.toArray());
			}
			
		} catch (Exception e) {
			logger.error("",e);
		}
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {
				"Resource Planning\\Demand Supply\\Work Items Demand Summary-" + regions.replaceAll("/", "-")
				};
	}
	public boolean append() {
		return false;
	}
}