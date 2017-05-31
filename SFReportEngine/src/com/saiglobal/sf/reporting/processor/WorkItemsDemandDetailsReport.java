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

public class WorkItemsDemandDetailsReport implements ReportBuilder {
	
	protected DbHelper db;
	protected GlobalProperties gp;
	protected DRDataSource dataDetails = null;
	protected static final Logger logger = Logger.getLogger(WorkItemsDemandDetailsReport.class);
	protected static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy-MM");
	protected static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	protected static final SimpleDateFormat daysFormatter = new SimpleDateFormat("dd");
	private static final Calendar today = new GregorianCalendar();
	private final int currentFY;
	private final Calendar startFY; 
	private final Calendar endFY;
	private String regions =  "NSW/ACT QLD SA/NT VIC/TAS WA ROW";
	protected final Calendar startPeriod; 
	protected final Calendar endPeriod;
	
	protected final Calendar reportDate;
	protected ScheduleParameters parameters;
	protected ProcessorRule[] businessRules;
	
	public WorkItemsDemandDetailsReport() {
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
				CompassRevenueOwnership.AUSFoodWA
				});
		
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
		JasperReportBuilder reportDetails = report();
		//JasperReportBuilder reportSummary = report();
		int rowHeight = 53;
		StyleBuilder boldStyle         = stl.style().bold();
		StyleBuilder boldCenteredStyle = stl.style(boldStyle).setHorizontalAlignment(HorizontalAlignment.CENTER);
		StyleBuilder columnTitleStyle  = stl.style(boldCenteredStyle)
                .setBorder(stl.pen1Point())
                .setBackgroundColor(Color.LIGHT_GRAY);

		TextColumnBuilder<String> revenueOwnershipColumn = col.column("Revenue Ownership", "revenue_ownership", type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<String> workItemColumn = col.column("Work Item", "work_item_name", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> workItemTypeColumn = col.column("Work Item Type", "work_item_type", type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<String> workItemStatusColumn = col.column("Status", "work_item_status", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<Date> serviceStartDateColumn = col.column("Start Date", "service_start_date", type.dateType()).setPattern("dd/MM/yyyy").setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<Double> requiredDurationColumn  = col.column("Days",   "required_duration",  type.doubleType()).setFixedWidth(100).setFixedHeight(rowHeight).setPattern("0.0");
		TextColumnBuilder<String> primaryStandardColumn = col.column("Primary Standard", "primary_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> familyStandardColumn = col.column("Family of Standard", "family_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);		
		TextColumnBuilder<String> codesColumn = col.column("Codes", "codes", type.stringType()).setFixedHeight(rowHeight);
		TextColumnBuilder<String> preferredResourceColumn  = col.column("Preferred Resource",   "preferred_resource",  type.stringType()).setFixedWidth(120).setFixedHeight(rowHeight);
		TextColumnBuilder<String> resourceColumn  = col.column("Resource",   "resource_name",  type.stringType()).setFixedWidth(120).setFixedHeight(rowHeight);
		TextColumnBuilder<String> resourceTypeColumn  = col.column("Type",   "resource_type",  type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> resourceStateColumn  = col.column("State",   "resource_state",  type.stringType()).setFixedWidth(50).setFixedHeight(rowHeight);
		TextColumnBuilder<String> resourceSchedulerColumn  = col.column("Scheduler",   "resource_scheduler",  type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight);
		TextColumnBuilder<String> clientNameColumn  = col.column("Client Name",   "client_name",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> siteLocationColumn  = col.column("Site Location",   "client_site_location",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);

		// Report Details
		reportDetails
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(
				  workItemColumn, 
				  workItemTypeColumn,
				  workItemStatusColumn,
				  serviceStartDateColumn,
				  requiredDurationColumn,
				  clientNameColumn,
				  siteLocationColumn,
				  preferredResourceColumn,
				  resourceColumn,
				  resourceTypeColumn,
				  resourceStateColumn,
				  resourceSchedulerColumn,
				  revenueOwnershipColumn,
				  primaryStandardColumn,
				  familyStandardColumn,
				  codesColumn
				  );
		  
		reportDetails.title(
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(340, 50)),
					cmp.horizontalList().add(cmp.text(getReportNames()[0])).setFixedDimension(340, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Work items demand/supply - details.")),
					cmp.horizontalList().add(cmp.text("Period from " + Utility.getShortdatedisplayformat().format(startPeriod.getTime()) + " to " + Utility.getShortdatedisplayformat().format(endPeriod.getTime()))).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Regions: " + regions)).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(340, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "7")
		  .setDataSource(dataDetails);
		
		return new JasperReportBuilder[] {
				reportDetails
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
		
		List<String> dataVariablesDetails = new ArrayList<String>();
		
		dataVariablesDetails.add("work_item_name");
		dataVariablesDetails.add("work_item_type");
		dataVariablesDetails.add("work_item_status");
		dataVariablesDetails.add("service_start_date");
		dataVariablesDetails.add("required_duration");
		dataVariablesDetails.add("client_name");
		dataVariablesDetails.add("client_site_location");
		dataVariablesDetails.add("preferred_resource");
		dataVariablesDetails.add("resource_name");
		dataVariablesDetails.add("resource_type");
		dataVariablesDetails.add("resource_state");
		dataVariablesDetails.add("resource_scheduler");
		dataVariablesDetails.add("revenue_ownership");
		dataVariablesDetails.add("primary_standard");
		dataVariablesDetails.add("family_standard");
		dataVariablesDetails.add("codes");
		
		dataDetails = new DRDataSource(dataVariablesDetails.toArray(new String[dataVariablesDetails.size()]));
		
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
			for (WorkItem  workItem : workItems) {
				TreeSet<String> familyStandardSet = new TreeSet<String>();
				TreeSet<String> codesSet = new TreeSet<String>();
				String familyStandard = "";
				String codes = "";
				for (Competency competency : workItem.getRequiredCompetencies()) {
					if (competency.getType().equals(CompetencyType.CODE)) {
						codes += competency.getCompetencyName() + "\n";
						codesSet.add(competency.getCompetencyName());
					} else {
						if (!competency.getType().equals(CompetencyType.PRIMARYSTANDARD)) {
							familyStandard += competency.getCompetencyName() + "\n";
							familyStandardSet.add(competency.getCompetencyName());
						}
					}
				}
				
				String preferredResourcesString = "";
				if (workItem.getPreferredResourceIds() != null) { 	
					for (String resourceId : workItem.getPreferredResourceIds()) {
						if (resourceId == null)
							continue;
						Resource resource = resourceData.get(resourceId);
						if (resource == null) {
							ScheduleParameters param = new ScheduleParameters();
							param.setResourceIds(new String[] {resourceId});
							param.setCalendarStartDate(startPeriod.getTime());
							param.setCalendarEndDate(endPeriod.getTime());
							List<Resource> resourceList = db.getResourceBatch(param);
							if ((resourceList != null) && (resourceList.size()==1)) {
								resource = resourceList.get(0);
								resourceData.put(resourceId, resource);
							}
						}
						
						if (resource != null)
							preferredResourcesString += resource.getName() + "\n";
						else 
							preferredResourcesString += resourceId + "\n";
						
					}
				}
				
				// Write data details
				if (workItemResources.get(workItem.getId()).size()>0) {
					for (String resourceId : workItemResources.get(workItem.getId()).keySet()) {
						Resource resource = resourceData.get(resourceId);
						
						List<Object> values = new ArrayList<Object>();

						values.add(workItem.getName());
						if (workItem.getType() != null)
							values.add(workItem.getType().getName());
						else
							values.add("");
						values.add(workItem.getSfStatus().getName());
						values.add(workItem.getStartDate()); 
						values.add(workItem.getRequiredDuration()/8);
						if (workItem.getClient()!=null)
							values.add(workItem.getClient().getName());
						else 
							values.add("");
						if (workItem.getClientSite()!=null)
							values.add(workItem.getClientSite().getFullAddress());
						else 
							values.add("");
						values.add(preferredResourcesString); 
						values.add(resource.getName()); 
						if (resource.getType()!=null)
							values.add(resource.getType().getName());
						else
							values.add("");
						if (resource.getOffice().getLocation() != null)
							values.add(resource.getOffice().getLocation().getState());
						else 
							values.add("");
						
						if (workItem.getSchedulerName()!=null)
							values.add(workItem.getSchedulerName());
						else
							values.add("");
						
						if (workItem.getRevenueOwnership()!=null)
							values.add(workItem.getRevenueOwnership().getName());
						else
							values.add("");
						if (workItem.getPrimaryStandard()!=null)
							values.add(workItem.getPrimaryStandard().getCompetencyName()); 
						else 
							values.add("");
						values.add(familyStandard); 
						values.add(codes); 
						//values.add(workItem.getSiteCertification().getName());
						
						dataDetails.add(values.toArray(new Object[values.size()]));
					}
				} else {
					List<Object> values = new ArrayList<Object>();
					
					values.add(workItem.getName());
					if (workItem.getType() != null)
						values.add(workItem.getType().getName());
					else
						values.add("");
					values.add(workItem.getSfStatus().getName());
					values.add(workItem.getStartDate()); 
					values.add(workItem.getRequiredDuration()/8);
					if (workItem.getClient()!=null)
						values.add(workItem.getClient().getName());
					else 
						values.add("");
					if (workItem.getClientSite()!=null)
						values.add(workItem.getClientSite().getFullAddress());
					else 
						values.add("");
					values.add(preferredResourcesString); 
					values.add("");
					values.add("");
					values.add("");
					if (workItem.getSchedulerName()!=null)
						values.add(workItem.getSchedulerName());
					else
						values.add("");
					if (workItem.getRevenueOwnership()!=null)
						values.add(workItem.getRevenueOwnership().getName());
					else
						values.add("");
					if (workItem.getPrimaryStandard()!=null)
						values.add(workItem.getPrimaryStandard().getCompetencyName()); 
					else 
						values.add("");
					values.add(familyStandard); 
					values.add(codes); 
					//values.add(workItem.getClientSite().getFullAddress());
					
					dataDetails.add(values.toArray(new Object[values.size()]));
				}
			}
		} catch (Exception e) {
			logger.error("",e);
		}
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {
				"Resource Planning\\Demand Supply\\Work Items Demand Details-" + regions.replaceAll("/", "-")
				};
	}
	public boolean append() {
		return false;
	}
}