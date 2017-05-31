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

public class WorkItemsDemandSummaryReportOld implements ReportBuilder {
	
	protected DbHelper db;
	protected GlobalProperties gp;
	protected DRDataSource dataSummary = null;
	protected static final Logger logger = Logger.getLogger(WorkItemsDemandSummaryReportOld.class);
	protected static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy-MM");
	protected static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	protected static final SimpleDateFormat daysFormatter = new SimpleDateFormat("dd");
	protected final Calendar startPeriod; 
	protected final Calendar endPeriod;
	
	protected final Calendar reportDate;
	protected ScheduleParameters parameters;
	protected ProcessorRule[] businessRules;
	
	public WorkItemsDemandSummaryReportOld() {
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		startPeriod = new GregorianCalendar(2013, Calendar.JULY, 1);
		endPeriod = new GregorianCalendar(2014, Calendar.JUNE, 30);
		
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
		TextColumnBuilder<String> resourceReportingBusinessUnitColumn  = col.column("Reporting Business Unit",   "resource_reporting_business_unit",  type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<Double> countFTEColoumn = col.column("Count FTE", "count_fte", type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<Double> countContractorsColoumn = col.column("Count Contractors", "count_contractors", type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight);
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
				  requiredDurationColumn,
				  resourceReportingBusinessUnitColumn,
				  countFTEColoumn,
				  countContractorsColoumn
				  );
		  
		reportSummary.title(
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(360, 50)),
					cmp.horizontalList().add(cmp.text(getReportNames()[0])).setFixedDimension(360, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Work items demand/supply - summary.")),
					cmp.horizontalList().add(cmp.text("Period from " + Utility.getShortdatedisplayformat().format(startPeriod.getTime()) + " to " + Utility.getShortdatedisplayformat().format(endPeriod.getTime()))).setFixedDimension(360, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(360, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "6")
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
		dataVariablesSummary.add("resource_reporting_business_unit");
		dataVariablesSummary.add("count_fte");
		dataVariablesSummary.add("count_contractors");
		
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
			HashMap<RowKey, RowSummaryData> summaryDataMap = new HashMap<RowKey, RowSummaryData>();
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
				
				RowSummaryData data = null;
				for (CompassRevenueOwnership businessUnit : parameters.getReportingBusinessUnits()) {
					RowKey key = new RowKey(workItem.getRevenueOwnership().getName(), periodFormatter.format(workItem.getStartDate()), workItem.getPrimaryStandard().getCompetencyName(), familyStandardSet, codesSet, businessUnit.getName());					 
					if (summaryDataMap.containsKey(key)) {
						data = summaryDataMap.get(key);
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
						data = new RowSummaryData(fteCount, contractorCount, 0);
					}
					data.addDays(workItem.getRequiredDuration()/8);
					summaryDataMap.put(key, data);
				}
			}
			
			
			// 4) Write data summary
			for (RowKey key : summaryDataMap.keySet()) {
				RowSummaryData data = summaryDataMap.get(key);
				dataSummary.add(
						key.getRevenueOwnership(), 
						key.getPeriod(), 
						key.getPrimaryStandard(),
						key.getFamilyStandardAsString(),
						key.getCodesAsString(),
						data.getDays(),
						key.getReportingBusinessUnit(),
						data.getFteCount(),
						data.getContractorCount()
						);
			}
			
		} catch (Exception e) {
			logger.error("",e);
		}
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {
				"Resource Planning\\Demand Supply\\Work Items Demand Summary"
				};
	}
	public boolean append() {
		return false;
	}
}

class RowKey {
	private final String revenueOwnership;
	private final String period;
	private final String primaryStandard;
	private final TreeSet<String> familyOfStandard;
	private final TreeSet<String> codes;
	private final String reportingBusinessUnit;
	
	public RowKey(String ro, String p, String ps, TreeSet<String> fos, TreeSet<String> c, String rbu) {
		revenueOwnership = ro;
		period = p;
		primaryStandard = ps;
		if (fos == null)
			familyOfStandard = new TreeSet<String>();
		else 
			familyOfStandard = fos;
		if (c == null) 
			codes = new TreeSet<String>();
		else
			codes = c;
		reportingBusinessUnit = rbu;
	}
	
	public String getReportingBusinessUnit() {
		return reportingBusinessUnit;
	}
	
	public String getRevenueOwnership() {
		return revenueOwnership;
	}

	public String getPeriod() {
		return period;
	}

	public String getPrimaryStandard() {
		return primaryStandard;
	}

	public TreeSet<String> getFamilyOfStandard() {
		return familyOfStandard;
	}

	public TreeSet<String> getCodes() {
		return codes;
	}
	
	@Override
	public boolean equals(Object o) {
		return ((o instanceof RowKey) 
			&& (revenueOwnership.equals(((RowKey)o).getRevenueOwnership()))
			&& (period.equals(((RowKey)o).getPeriod()))
			&& (primaryStandard.equals(((RowKey)o).getPrimaryStandard()))
			&& (familyOfStandard.equals(((RowKey)o).getFamilyOfStandard()))
			&& (codes.equals(((RowKey)o).getCodes()))
			&& (reportingBusinessUnit.equals(((RowKey)o).getReportingBusinessUnit()))
		);
	}
	
	@Override
	public int hashCode() {
		String all = revenueOwnership + period + primaryStandard;
		for (String aStd : familyOfStandard) {
			all += aStd;
		}
		for (String aCode : codes) {
			all += aCode;
		}
		all += reportingBusinessUnit;
		return all.hashCode();
	}
	
	public String getFamilyStandardAsString() {
		String familyOfStandardsString = "";
		for (String aStd : familyOfStandard) {
			familyOfStandardsString += aStd + "\n";
		}
		return familyOfStandardsString;
	}
	
	public String getCodesAsString() {
		String codesString = "";
		for (String aCode : codes) {
			codesString += aCode + "\n";
		}
		return codesString;
	}
}

class RowSummaryData {
	double fteCount;
	double contractorCount;
	double days;
	
	public RowSummaryData(double fteCount, double contractorCount, double days) {
		this.contractorCount = contractorCount;
		this.fteCount = fteCount;
		this.days = days;
	}
	public double getFteCount() {
		return fteCount;
	}
	public void setFteCount(double fteCount) {
		this.fteCount = fteCount;
	}
	public double getContractorCount() {
		return contractorCount;
	}
	public void setContractorCount(double contractorCount) {
		this.contractorCount = contractorCount;
	}
	public double getDays() {
		return days;
	}
	public void setDays(double days) {
		this.days = days;
	}
	
	public void addDays(double days) {
		this.days += days;
	}
}