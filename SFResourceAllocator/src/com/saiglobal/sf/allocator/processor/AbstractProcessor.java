package com.saiglobal.sf.allocator.processor;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.UUID;

import org.apache.log4j.Logger;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Availability;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ResourceEvent;
import com.saiglobal.sf.core.model.ResourceEventType;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.ScheduleStatus;
import com.saiglobal.sf.core.model.ScheduleType;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public abstract class AbstractProcessor implements Processor {
	protected DbHelper db;
	protected ScheduleParameters parameters;
	protected List<WorkItem> workItemList;
	protected List<Resource> resources;
	protected Logger logger = Logger.getLogger(AbstractProcessor.class);
	protected final double unitDistanceCost = 1;
	protected final double contractorDayCost = 600;
	protected final double auditDayRevenue = 1800;
	
	public AbstractProcessor(DbHelper db, ScheduleParameters parameters) throws Exception {
		this.db = db;
		this.parameters = parameters;
		this.init();
	}
	public AbstractProcessor() {}
	
	public void setDbHelper(DbHelper db) {
		this.db = db;
	}
	
	public void setParameters(ScheduleParameters sp) {
		this.parameters = sp;
	}
	
	@Override
	public abstract int getBatchSize();

	@Override
	public void execute() throws Exception {
		
		// Sort workItems
		Utility.startTimeCounter("AbstactProcessor.execute");
		workItemList = sortWorkItems(workItemList);
		
		// Break processing in sub-groups based on batch size
		int batchStart = 0;
		int batchStop = 0;
		int batchNo = 1;
		boolean finished = false;
		while (!finished) {
			Utility.getLogger().info("Start processing batch no. " + batchNo + ". Time: " + System.currentTimeMillis());
			batchStart = batchStop;
			batchStop += (getBatchSize()+batchStop)>workItemList.size()?workItemList.size()-batchStop:getBatchSize();
			List<WorkItem> workItemsBatch = workItemList.subList(batchStart, batchStop);
			List<Schedule> schedule = schedule(workItemsBatch, resources);
			logger.info("Saving schedule for batch no. " + batchNo + ". Time: " + System.currentTimeMillis());
			saveBatchDetails(this.parameters);
			saveSchedule(schedule);
			batchNo++;
 			if (batchStop==workItemList.size())
				finished = true;
		}
		
		Utility.stopTimeCounter("AbstactProcessor.execute");
		Utility.logAllProcessingTime();
		Utility.logAllEventCounter();
	}
	
	protected void postProcessTravel(List<Schedule> schedules, Schedule travel) throws Exception {

	}
	protected List<Schedule> schedule(List<WorkItem> workItemList, List<Resource> resources) throws Exception {
		
		Calendar cal = Calendar.getInstance();
		List<Schedule> returnSchedule = new ArrayList<Schedule>();
		double allocationCost = 0.0;
		boolean reprocessWI = false;
		for (int i = 0; i<workItemList.size() || reprocessWI; i++) {
			if (reprocessWI) {
				i--;
				reprocessWI =  false;
			}
			WorkItem aWorkItem = workItemList.get(i);
			if (aWorkItem.getStartDate().before(parameters.getCalendarStartDate())) {
				aWorkItem.setStartDate(parameters.getCalendarStartDate());
				aWorkItem.setTargetDate(parameters.getCalendarStartDate());
			}
			
			List<Resource> filteredResources = resources;
			// reset Score
			for (Resource resource : filteredResources) {
				resource.setScore(0.0);
			}
			// Initialise Schedule
			Schedule aSchedule = new Schedule();
			aSchedule.setWorkItemId(aWorkItem.getId());
			aSchedule.setWorkItemName(aWorkItem.getName());
			aSchedule.setStartDate(aWorkItem.getTargetDate());
			aSchedule.setWorkItemSource(aWorkItem.getWorkItemSource());
			aSchedule.setWorkItemCountry(aWorkItem.getClientSite().getCountry());
			aSchedule.setWorkItemState(aWorkItem.getClientSite().getState());
			aSchedule.setWorkItemTimeZone(aWorkItem.getClientSite().getTimeZone().getID());
			aSchedule.setLatitude(aWorkItem.getClientSite().getLatitude());
			aSchedule.setLongitude(aWorkItem.getClientSite().getLongitude());
			aSchedule.setStatus(ScheduleStatus.NOT_ALLOCATED);
			aSchedule.setType(ScheduleType.AUDIT);
			aSchedule.setDuration(aWorkItem.getRequiredDuration());
			aSchedule.setWorkItemDuration(aWorkItem.getRequiredDuration());
			aSchedule.setPrimaryStandard(aWorkItem.getPrimaryStandard());
			aSchedule.setCompetencies(aWorkItem.getRequiredCompetenciesString());
			
			// Apply Processor Rules			
			for (ProcessorRule rule : getRules()) {
				Utility.startTimeCounter(rule.getClass().getName());
				filteredResources = rule.filter(aWorkItem, filteredResources, db, parameters);
				Utility.stopTimeCounter(rule.getClass().getName());
				if (filteredResources.size()==0) {
					String period = Utility.getPeriodformatter().format(aWorkItem.getStartDate());
					if (rule instanceof ProcessorRule_Availability && parameters.getPeriodsWorkingDays().containsKey(period)) {
						Calendar newStartDate = new GregorianCalendar();
						newStartDate.setTime(aWorkItem.getStartDate());
						newStartDate.add(Calendar.MONTH, 1);
						aWorkItem.setStartDate(newStartDate.getTime());
						aWorkItem.setTargetDate(newStartDate.getTime());
						reprocessWI = true;
					} else {
						aSchedule.setNotes("Not allocated due to " + rule.getName());
					}
					break;
				}
			}
			if (reprocessWI)
				continue;
			// Sort Resources
			filteredResources = sortResources(filteredResources);
			Utility.getLogger().debug("wiId,wiName,resourceId,resourceName,score");
			for (Resource resource : filteredResources) {
				Utility.getLogger().debug(aWorkItem.getId()+aWorkItem.getName()+resource.getId()+resource.getName()+resource.getScore());
			}
			// Take the first on the filtered list
			if (filteredResources.size()>0) {
				Resource resource = filteredResources.get(0);
				ResourceEvent eventToBook = new ResourceEvent();
				eventToBook.setType(ResourceEventType.ALLOCATOR_WIR);
				eventToBook.setStartDateTime(aWorkItem.getStartDate());
				cal.setTime(aWorkItem.getStartDate());
				cal.add(Calendar.HOUR_OF_DAY, (int) aWorkItem.getRequiredDuration());
				eventToBook.setEndDateTime(cal.getTime());
				resource.bookFor(eventToBook);
				// Not doing scheduling yet.  
				// StartDate and EndDate are stored only to record duration of the WI and allow proper recording of resource utilization
				aSchedule.setStartDate(aWorkItem.getStartDate());
				aSchedule.setEndDate(cal.getTime());
				aSchedule.setResourceId(resource.getId());
				aSchedule.setResourceName(resource.getName());
				aSchedule.setResourceType(resource.getType());
				aSchedule.setStatus(ScheduleStatus.ALLOCATED);
				if (aWorkItem.getServiceDeliveryType().equalsIgnoreCase("Off Site"))
					aSchedule.setDistanceKm(0);
				else
					aSchedule.setDistanceKm(2*Utility.calculateDistanceKm(aWorkItem.getClientSite(), resource.getHome(), db));
				
				
				
				Schedule travelling = new Schedule();
				travelling.setWorkItemId(aWorkItem.getId());
				travelling.setWorkItemName(aWorkItem.getName());
				travelling.setWorkItemSource(aWorkItem.getWorkItemSource());
				travelling.setWorkItemCountry(aWorkItem.getClientSite().getCountry());
				travelling.setWorkItemState(aWorkItem.getClientSite().getState());
				travelling.setWorkItemDuration(aWorkItem.getRequiredDuration());
				travelling.setLatitude(aWorkItem.getClientSite().getLatitude());
				travelling.setLongitude(aWorkItem.getClientSite().getLongitude());
				travelling.setStatus(ScheduleStatus.ALLOCATED);
				travelling.setType(ScheduleType.TRAVEL);
				travelling.setDistanceKm(aSchedule.getDistanceKm());
				travelling.setStartDate(aWorkItem.getTargetDate());
				travelling.setPrimaryStandard(aWorkItem.getPrimaryStandard());
				travelling.setCompetencies(aWorkItem.getRequiredCompetenciesString());
				travelling.setResourceId(resource.getId());
				travelling.setResourceName(resource.getName());
				travelling.setResourceType(resource.getType());
				travelling.setStatus(ScheduleStatus.ALLOCATED);
				//travelling.setComment("Actual travel time: " + travelTime + ".  Travel time + WI duration: " + aWorkItem.getRequiredDuration() + travelTime + " Total Equivalent Travel Hrs" + totalEquivalentTravelHrs);
				postProcessTravel(returnSchedule, travelling);
				aSchedule.setWorkItemGroup(travelling.getWorkItemGroup());
				travelling.setDuration(Utility.calculateTravelTimeHrs(travelling.getDistanceKm(), true));
				
				cal.setTime(aWorkItem.getTargetDate());
				cal.add(Calendar.HOUR_OF_DAY, (int) travelling.getDuration());
				travelling.setEndDate(cal.getTime());

				// Book resource for travel
				ResourceEvent travelToBook = new ResourceEvent();
				travelToBook.setType(ResourceEventType.ALLOCATOR_TRAVEL);
				travelToBook.setStartDateTime(aWorkItem.getTargetDate());
				travelToBook.setEndDateTime(cal.getTime());
				
				resource.bookFor(travelToBook);
				// Add to return schedule
				returnSchedule.add(travelling);
				
				allocationCost+=resource.getType().equals(SfResourceType.Contractor)?contractorDayCost:0;
				allocationCost+=aSchedule.getDistanceKm()*unitDistanceCost;
			} else {
				allocationCost+=auditDayRevenue;
			}
			parameters.setComment(""+allocationCost);
			returnSchedule.add(aSchedule);
		}
		return returnSchedule;
	}
	
	protected abstract Logger initLogger();
	
	public void init() throws Exception {
		// Init logger
		logger = this.initLogger();
		Utility.startTimeCounter("AbstractProcessor.init");
		
		// Init tables
		this.db.executeStatement(this.db.getCreateScheduleTableSql());
		this.db.executeStatement(this.db.getCreateScheduleBatchTableSql());

		if (parameters.getBatchId() == null)
			this.parameters.setBatchId(getNewBatchId());
		this.parameters.setSubBatchId(getLastSubBatchId()+1);
		
		// Init WorkItems and Resources
		resources = db.getResourceBatch(parameters);
		for (Resource r : resources) {
			logger.debug(r.toCsv());
		}
		workItemList = db.getWorkItemBatch(parameters);
		if (parameters.includePipeline()) {
			List<WorkItem> pipelineWI = getPipelineWorkItems();
			for (WorkItem workItem : pipelineWI) {
				workItemList.add(workItem);
			}
		}
		postProcessWorkItemList();
		
		Utility.stopTimeCounter("AbstractProcessor.init");
	}
	
	protected abstract void postProcessWorkItemList(); 
	
	private int getLastSubBatchId() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		String query = "SELECT MAX(SubBatchId) FROM " + this.db.getScheduleBatchTableName() + " WHERE BatchId='" + this.getBatchId() + "'";
		return db.executeScalarInt(query);
	}
	protected void saveSchedule(List<Schedule> scheduleList) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		// Early exit
		if(scheduleList == null || scheduleList.size()==0)
			return;
		
		String insert = "INSERT INTO " + this.db.getScheduleTableName() + 
				" (`BatchId`, `SubBatchId`, `WorkItemId`, `WorkItemName`, `WorkItemSource`, `WorkItemCountry`, `WorkItemState`, `WorkItemTimeZone`, `ResourceId`, `ResourceName`, `ResourceType`, `StartDate`, `EndDate`, `Duration`, `TravelDuration`, `Status`, `Type`, `PrimaryStandard`, `Competencies`, `Comment`, `Distance`, `Notes`, `WorkItemGroup`, `TotalCost`) VALUES ";
		for (Schedule schedule : scheduleList) {
			insert += " \n('" + getBatchId() + "', " + getSubBatchId() + ", " + schedule.toSqlString() + ") ,";
		}
		this.db.executeStatement(Utility.removeLastChar(insert));
	}
	
	protected void saveBatchDetails(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String insert = "INSERT INTO " + this.db.getScheduleBatchTableName() + 
					" (`BatchId`, `SubBatchId`, `RevenueOwnership`, `SchedulingOwnership`, `ReportingBusinessUnits`, `AuditCountries`, `ResourceCountries`, `ScoreContractorPenalties`,`ScoreAvailabilityDayReward`,`ScoreDistanceKmPenalty`,`ScoreCapabilityAuditPenalty`, `WorkItemStatuses`, `ResourceTypes`, `StartDate`, `EndDate`, `Comment`, `completed`, `created`) " +
					"VALUES (" + parameters.toSqlString() + ", 0, utc_timestamp())";
		this.db.executeStatement(insert);
	}
	
	protected void updateBatchDetails(ScheduleParameters parameters) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String update = "UPDATE " + this.db.getScheduleBatchTableName() + " SET lastModified=utc_timestamp(), completed = 1 WHERE BatchId = '" + parameters.getBatchId() + "' AND SubBatchId = " + parameters.getSubBatchId();
		this.db.executeStatement(update);
	}
	
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		return workItemList;
	};
	
	protected List<WorkItem> getPipelineWorkItems() {
		return new ArrayList<WorkItem>();
	};
	
	protected List<Resource> sortResources(List<Resource> resourceList) {
		return resourceList;
	};

	protected String getNewBatchId() {
		return UUID.randomUUID().toString();
	}

	public String getBatchId() {
		return this.parameters.getBatchId();
	}

	public int getSubBatchId() {
		return this.parameters.getSubBatchId();
	}
}
