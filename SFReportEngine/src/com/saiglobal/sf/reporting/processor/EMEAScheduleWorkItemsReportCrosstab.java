package com.saiglobal.sf.reporting.processor;

import static net.sf.dynamicreports.report.builder.DynamicReports.cmp;
import static net.sf.dynamicreports.report.builder.DynamicReports.col;
import static net.sf.dynamicreports.report.builder.DynamicReports.report;
import static net.sf.dynamicreports.report.builder.DynamicReports.stl;
import static net.sf.dynamicreports.report.builder.DynamicReports.type;

import java.awt.Color;
//import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;

import org.apache.commons.lang.StringUtils;
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
//import com.saiglobal.sf.core.schedule.BusinessRule_Availability;
import com.saiglobal.sf.core.schedule.BusinessRule_Capability;
import com.saiglobal.sf.core.schedule.BusinessRule_SameCountry;
import com.saiglobal.sf.core.schedule.ProcessorRule;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class EMEAScheduleWorkItemsReportCrosstab implements ReportBuilder {
	
	protected DbHelper db;
	protected GlobalProperties gp;
	protected DRDataSource data = null;
	protected static final Logger logger = Logger.getLogger(EMEAScheduleWorkItemsReportCrosstab.class);
	protected static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy-MM");
	protected static final SimpleDateFormat periodDisplayFormatter = new SimpleDateFormat("MMM yy");
	protected static final SimpleDateFormat daysFormatter = new SimpleDateFormat("dd");
	protected final Calendar startPeriod; 
	protected final Calendar endPeriod;
	protected final int availabilityWindowBefore;
	protected final int availabilityWindowAfter;
	protected final Calendar calendarStartPeriod; 
	protected final Calendar calendarEndPeriod;
	protected final String[] periods;
	
	protected final Calendar reportDate;
	protected ScheduleParameters parameters;
	protected ProcessorRule[] businessRules;
	
	public boolean concatenatedReports() {
		return false;
	}
	
	public EMEAScheduleWorkItemsReportCrosstab() {
		reportDate = new GregorianCalendar();
		reportDate.setTime(new Date());
		reportDate.add(Calendar.MONTH, -1);
		startPeriod = new GregorianCalendar(reportDate.get(Calendar.YEAR), reportDate.get(Calendar.MONTH), reportDate.get(Calendar.DAY_OF_MONTH));
		startPeriod.set(Calendar.DAY_OF_MONTH, startPeriod.getActualMinimum(Calendar.DAY_OF_MONTH));
		//TEST
		//startPeriod = new GregorianCalendar(2014,Calendar.APRIL,23);
		//reportDate.add(Calendar.YEAR, 1);
		reportDate.add(Calendar.MONTH, 6);
		endPeriod = new GregorianCalendar(reportDate.get(Calendar.YEAR), reportDate.get(Calendar.MONTH), reportDate.get(Calendar.DAY_OF_MONTH));
		endPeriod.set(Calendar.DAY_OF_MONTH, endPeriod.getActualMaximum(Calendar.DAY_OF_MONTH));
		//endPeriod = new GregorianCalendar(2014, Calendar.APRIL, 24);
		reportDate.setTime(new Date());
		availabilityWindowAfter = 2;
		availabilityWindowBefore = 0;
		calendarStartPeriod =  new GregorianCalendar();
		calendarEndPeriod =  new GregorianCalendar();
		calendarStartPeriod.setTime(startPeriod.getTime());
		calendarEndPeriod.setTime(endPeriod.getTime());
		calendarEndPeriod.add(Calendar.MONTH, availabilityWindowAfter);
		calendarEndPeriod.set(Calendar.DAY_OF_MONTH, calendarEndPeriod.getActualMaximum(Calendar.DAY_OF_MONTH));
		calendarStartPeriod.add(Calendar.MONTH, -availabilityWindowBefore);
		calendarStartPeriod.set(Calendar.DAY_OF_MONTH, calendarStartPeriod.getActualMinimum(Calendar.DAY_OF_MONTH));
		
		periods = getAllPeriods();
		
		// Input parameters
		parameters = new ScheduleParameters();
		parameters.setBatchId(getReportNames()[0]);
		parameters.setRevenueOwnership(new CompassRevenueOwnership[] {
				CompassRevenueOwnership.EMEACzechRepublic,
				CompassRevenueOwnership.EMEAFrance,
				CompassRevenueOwnership.EMEAGermany,
				CompassRevenueOwnership.EMEAIreland,
				CompassRevenueOwnership.EMEAItaly,
				CompassRevenueOwnership.EMEAPoland,
				CompassRevenueOwnership.EMEARussia,
				CompassRevenueOwnership.EMEASouthAfrica,
				CompassRevenueOwnership.EMEASpain,
				CompassRevenueOwnership.EMEATurkey,
				CompassRevenueOwnership.EMEAUK,
				CompassRevenueOwnership.EMEASweden,
				CompassRevenueOwnership.EMEAEgypt,
				
				CompassRevenueOwnership.RBUEMEAMS,
				CompassRevenueOwnership.RBUMSEMEA,
				CompassRevenueOwnership.RBUMSRUSSIA,
				CompassRevenueOwnership.RBUMSSOUTHAFRICA,
				CompassRevenueOwnership.RBUMSTURKEY,
				CompassRevenueOwnership.RBURUSSIAMS,
				CompassRevenueOwnership.RBUTURKEYMS
				});
		
		parameters.setRepotingBusinessUnits(parameters.getRevenueOwnership());
		parameters.setResourceTypes(new SfResourceType[] {SfResourceType.Employee, SfResourceType.Contractor});
		parameters.setWorkItemsStatus(new SfWorkItemStatus[] {
				SfWorkItemStatus.Open,
				//SfWorkItemStatus.Scheduled,
				//SfWorkItemStatus.ScheduledOffered 
				});
		parameters.setResourceCompetencyRanks(new SfResourceCompetencyRankType[] {
				SfResourceCompetencyRankType.LeadAuditor, SfResourceCompetencyRankType.Auditor
		});
		TimeZone tz = TimeZone.getTimeZone("England/London");
		parameters.setTimeZone(tz);
		parameters.setWorkItemDateSelectType(SfWorkItemDateSelectType.SERVICE_DATE);
		parameters.setStartDate(startPeriod.getTime());
		parameters.setEndDate(endPeriod.getTime());
		parameters.setLoadCalendar(false);
		parameters.setLoadCompetencies(false);
		parameters.setCalendarStartDate(calendarStartPeriod.getTime());
		parameters.setCalendarEndDate(calendarEndPeriod.getTime());
	}
	
	@Override
	public JasperReportBuilder[] generateReports() {
		JasperReportBuilder report = report();
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
		TextColumnBuilder<String> openStatusSubTypeColumn = col.column("Open Status SubType", "open_status_subtype", type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<Date> serviceTargetDateColumn = col.column("Start Date", "service_target_date", type.dateType()).setFixedWidth(80).setFixedHeight(rowHeight).setPattern("dd/MM/yyyy");
		TextColumnBuilder<Date> serviceNominatedDateColumn = col.column("Nominated Date", "service_nominated_date", type.dateType()).setFixedWidth(80).setFixedHeight(rowHeight).setPattern("dd/MM/yyyy");
		TextColumnBuilder<Double> requiredDurationColumn  = col.column("Required Duration",   "required_duration",  type.doubleType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<Double> approvedDurationColumn  = col.column("Approved modified Duration",   "approved_duration",  type.doubleType()).setFixedWidth(80).setFixedHeight(rowHeight);
		TextColumnBuilder<String> primaryStandardColumn = col.column("Primary Standard", "primary_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> familyStandardColumn = col.column("Family of Standard", "family_standard", type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);		
		TextColumnBuilder<String> codesColumn = col.column("Codes", "codes", type.stringType()).setFixedHeight(rowHeight);
		TextColumnBuilder<String> preferredResourceColumn  = col.column("Preferred Resource",   "preferred_resource",  type.stringType()).setFixedWidth(120).setFixedHeight(rowHeight);
		TextColumnBuilder<String> resourceColumn  = col.column("Resource",   "resource_name",  type.stringType()).setFixedWidth(120).setFixedHeight(rowHeight);
		TextColumnBuilder<String> selectedResourceColumn  = col.column("Selected Resource",   "selected_resource_name",  type.stringType()).setFixedWidth(120).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> resourceTypeColumn  = col.column("Type",   "resource_type",  type.stringType()).setFixedWidth(80).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> resourceStateColumn  = col.column("State",   "resource_state",  type.stringType()).setFixedWidth(50).setFixedHeight(rowHeight);
		TextColumnBuilder<String> commentsColumn  = col.column("Comments",   "comments",  type.stringType()).setFixedWidth(180).setFixedHeight(40).setFixedHeight(rowHeight);
		TextColumnBuilder<String> siteCertificationColumn  = col.column("Site Certification",   "site_certification_name",  type.stringType()).setFixedWidth(90).setFixedHeight(rowHeight);
		TextColumnBuilder<String> clientNameColumn  = col.column("Client Name",   "client_name",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> siteLocationColumn  = col.column("Site Location",   "client_site_location",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> siteContactColumn  = col.column("Site Contact",   "contact_name",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> siteContactPhoneColumn  = col.column("Site Contact Phone",   "contact_phone",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> siteContactTitleColumn  = col.column("Site Contact Title",   "contact_title",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		//TextColumnBuilder<String> siteContactEmailColumn  = col.column("Site Contact Email",   "contact_email",  type.stringType()).setFixedWidth(180).setFixedHeight(rowHeight);
		TextColumnBuilder<String> siteContactsColumn  = col.column("Site Contacts",   "contacts",  type.stringType()).setFixedWidth(360).setFixedHeight(rowHeight);

		report
		  .setColumnTitleStyle(columnTitleStyle)
		  .setIgnorePageWidth(true)
		  .setIgnorePagination(true)
		  .setSubtotalStyle(boldStyle)
		  .highlightDetailEvenRows()
		  .columns(
				  clientNameColumn,
				  siteLocationColumn,
				  workItemColumn, 
				  workItemTypeColumn,
				  workItemStatusColumn,
				  openStatusSubTypeColumn,
				  serviceTargetDateColumn, 
				  serviceNominatedDateColumn,
				  requiredDurationColumn, 
				  approvedDurationColumn,
				  preferredResourceColumn,
				  resourceColumn,
				  selectedResourceColumn,
				  //resourceTypeColumn,
				  //resourceStateColumn,
				  revenueOwnershipColumn,
				  primaryStandardColumn,
				  familyStandardColumn,
				  codesColumn,
				  commentsColumn,
				  siteCertificationColumn,
				  siteContactsColumn
				  //siteContactColumn,
				  //siteContactTitleColumn,
				  //siteContactEmailColumn,
				  //siteContactPhoneColumn
				  );
		/*  
		for (String period : periods) {
			try {
				report.addColumn(col.column(periodDisplayFormatter.format(periodFormatter.parse(period)), period, type.stringType()).setFixedWidth(100).setFixedHeight(rowHeight));
			} catch (ParseException e) {
				logger.error(e);
			}
		}
		
		report
			.addColumn(revenueOwnershipColumn)
			.addColumn(primaryStandardColumn) 
			.addColumn(familyStandardColumn)
			.addColumn(codesColumn) 
			.addColumn(commentsColumn) 
			.addColumn(siteCertificationColumn) 
			.addColumn(clientNameColumn) 
			.addColumn(siteLocationColumn);
		*/	  
		report.title(
					cmp.horizontalList().add(cmp.image(getClass().getResourceAsStream("sai_logo.gif")).setFixedDimension(340, 50)),
					cmp.horizontalList().add(cmp.text(getReportNames()[0])).setFixedDimension(340, 17).setStyle(boldStyle),
					cmp.horizontalList().add(cmp.text("Revenue Ownership: EMEA*")),
					cmp.horizontalList().add(cmp.text("Period from " + Utility.getShortdatedisplayformat().format(startPeriod.getTime()) + " to " + Utility.getShortdatedisplayformat().format(endPeriod.getTime()))).setFixedDimension(340, 17),
					cmp.horizontalList().add(cmp.text("Updated as " + Utility.getShortdatetimedisplayformat().format(new Date()) )).setFixedDimension(340, 17))
		  .addProperty(JasperProperty.EXPORT_XLS_FREEZE_ROW, "6")
		  .setDataSource(data);
		
		return new JasperReportBuilder[] {report};
	}

	@Override
	public void setDb(com.saiglobal.sf.reporting.data.DbHelper db) {
		this.db = db;
		try {
			businessRules = new ProcessorRule[] {
					new BusinessRule_SameCountry(db),
					new BusinessRule_Capability(db, parameters.getResourceCompetencyRanks()),
					//new BusinessRule_Availability(db, availabilityWindowBefore, availabilityWindowAfter),
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
		List<String> dataVariables = new ArrayList<String>();
		
		dataVariables.add("client_name");
		dataVariables.add("client_site_location");
		dataVariables.add("work_item_name");
		dataVariables.add("work_item_type");
		dataVariables.add("work_item_status");
		dataVariables.add("open_status_subtype");
		dataVariables.add("service_target_date");
		dataVariables.add("service_nominated_date");
		dataVariables.add("required_duration");
		dataVariables.add("approved_duration");
		dataVariables.add("preferred_resource");
		dataVariables.add("resource_name");
		dataVariables.add("selected_resource_name");
		//dataVariables.add("resource_type");
		//dataVariables.add("resource_state");
		//for (String period : periods) {
		//	dataVariables.add(period);
		//}
		dataVariables.add("revenue_ownership");
		dataVariables.add("primary_standard");
		dataVariables.add("family_standard");
		dataVariables.add("codes");
		dataVariables.add("comments");
		dataVariables.add("site_certification_name");
		dataVariables.add("contacts");
		//dataVariables.add("contact_name");
		//dataVariables.add("contact_title");
		//dataVariables.add("contact_email");
		//dataVariables.add("contact_phone");
		
		
		data = new DRDataSource(dataVariables.toArray(new String[dataVariables.size()]));
		
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

			// 3) Write data
			for (WorkItem  workItem : workItems) {	
				String familyStandard = "";
				String codes = "";
				for (Competency competency : workItem.getRequiredCompetencies()) {
					if (competency.getType().equals(CompetencyType.CODE)) {
						codes += competency.getCompetencyName() + "\n";
					} else {
						familyStandard += competency.getCompetencyName() + "\n";
					}
				}
				familyStandard = familyStandard.trim();
				codes = codes.trim();
				
				String preferredResourcesString = "";
				if (workItem.getPreferredResourceIds() != null) { 	
					for (String resourceId : workItem.getPreferredResourceIds()) {
						if (resourceId != null) {
							Resource resource = resourceData.get(resourceId);
							if (resource == null) {
								ScheduleParameters param = new ScheduleParameters();
								param.setResourceIds(new String[] {resourceId});
								param.setCalendarStartDate(calendarStartPeriod.getTime());
								param.setCalendarEndDate(calendarEndPeriod.getTime());
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
				}
				preferredResourcesString =  preferredResourcesString.trim();
				
				String resourcesString = "";
				if (workItemResources.get(workItem.getId()).size()>0) {
					for (String resourceId : workItemResources.get(workItem.getId()).keySet()) {
						Resource resource = resourceData.get(resourceId);
						if (resourceId != null) {
							resourcesString += resource.getName() + "\n";
						}
					}
				}
				
				//if (workItemResources.get(workItem.getId()).size()>0) {
				//	for (String resourceId : workItemResources.get(workItem.getId()).keySet()) {
				//		Resource resource = resourceData.get(resourceId);
						
						List<Object> values = new ArrayList<Object>();
						
						if (workItem.getClient()!=null)
							values.add(workItem.getClient().getName()); 
						else
							values.add("");
						if (workItem.getClientSite()!=null)
							values.add(workItem.getClientSite().getFullAddress());
						else
							values.add("");
						
						values.add(workItem.getName());
						if (workItem.getType()!=null)
							values.add(workItem.getType().getName());
						else
							values.add("");
						values.add(workItem.getSfStausAsString());
						values.add(workItem.getOpenStatusSubType());
						values.add(workItem.getStartDate());
						values.add(null);
						values.add(workItem.getRequiredDuration()); 
						values.add(0.0);
						values.add(preferredResourcesString); 
						values.add(resourcesString); 
						values.add("");
						//if (resource.getType()!=null)
						//	values.add(resource.getType().getName());
						//else
						//	values.add("");
						//if ((resource.getOffice() != null) && (resource.getOffice().getLocation()!=null))
						//	values.add(resource.getOffice().getLocation().getState());
						//else
						//	values.add("");
						
						/*
						HashMap<String, String> availPeriods = new HashMap<String, String>(); 
						for (String day : resource.getAvailableDays()) {
							Date date = Utility.getActivitydateformatter().parse(day);
							String period = periodFormatter.format(date);
							if (availPeriods.containsKey(period)) {
								availPeriods.put(period, availPeriods.get(period) + ", " + daysFormatter.format(date));
							} else {
								availPeriods.put(period, daysFormatter.format(date));
							}
						}
						
						
						for (String period : periods) {
							if (availPeriods.containsKey(period))
								values.add(availPeriods.get(period));
							else
								values.add("");
						}
						*/
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
						values.add(workItem.getComment()); 
						if (workItem.getSiteCertification()!=null)
							values.add(workItem.getSiteCertification().getName());
						else
							values.add("");
						if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getContactsText()!=null))
							values.add(StringUtils.join(workItem.getClientSite().getContactsText(), "\n"));
						else
							values.add("");
						/*
						if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getContact_title()!=null))
							values.add(workItem.getClientSite().getContact_title());
						else
							values.add("");
						if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getContact_email()!=null))
							values.add(workItem.getClientSite().getContact_email());
						else
							values.add("");
						if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getContact_phone()!=null))
							values.add(workItem.getClientSite().getContact_phone());
						else
							values.add("");
						*/
						
						data.add(values.toArray(new Object[values.size()]));
					}
				/*
				} else {
					List<Object> values = new ArrayList<Object>();
					
					if (workItem.getClient()!=null)
						values.add(workItem.getClient().getName()); 
					else
						values.add("");
					if (workItem.getClientSite()!=null)
						values.add(workItem.getClientSite().getFullAddress());
					else
						values.add("");
					
					values.add(workItem.getName());
					if (workItem.getType()!=null)
						values.add(workItem.getType().getName());
					else
						values.add("");
					values.add(workItem.getSfStausAsString());
					values.add(workItem.getOpenStatusSubType());
					values.add(workItem.getTargetDate()); 
					values.add(null);
					values.add(workItem.getRequiredDuration()); 
					values.add(0.0);
					values.add(preferredResourcesString); 
					values.add(""); 
					values.add("");
					values.add("");
					values.add("");
					//for (int i=0; i<periods.length; i++) {
					//	values.add("");
					//}
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
					values.add(workItem.getComment()); 
					if (workItem.getSiteCertification()!=null)
						values.add(workItem.getSiteCertification().getName());
					else
						values.add("");
					
					data.add(values.toArray(new Object[values.size()]));
				}
			}
			*/
		} catch (Exception e) {
			logger.error(e);
		}
	}

	private String[] getAllPeriods() {
		List<String> periods = new ArrayList<String>();
		Calendar pointer = new GregorianCalendar(calendarStartPeriod.get(Calendar.YEAR), calendarStartPeriod.get(Calendar.MONTH), calendarStartPeriod.get(Calendar.DAY_OF_MONTH)); 
		if (pointer.getTime().before(Utility.getUtcNow()))
			pointer.setTime(Utility.getUtcNow());
		String period = null;
		while (pointer.before(calendarEndPeriod)) {
			period = periodFormatter.format(pointer.getTime());  
			if (!periods.contains(period))
				periods.add(period);
			pointer.add(Calendar.DAY_OF_YEAR, 1);
		}
		return periods.toArray(new String[periods.size()] );
	}
	
	@Override
	public String[] getReportNames() {
		return new String[] {"EMEA\\Compass\\Open Work Items Reports\\Open Work Items"};
	}
	
	public boolean append() {
		return false;
	}
}
