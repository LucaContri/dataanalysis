package com.saiglobal.sf.core.model;

import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;
import java.util.stream.Collectors;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.utility.Utility;

public class ScheduleParameters {
	// WI Countries to be selected
	private String[] wiCountries;
	// Auditors Countries to be selected
	private String[] auditorsCountries;
	// Revenue ownership of WI to be selected
	private CompassRevenueOwnership[] revenueOwnership;
	private String[] schedulingOwnership;
	// Reporting business units of Resources to be selected
	private CompassRevenueOwnership[] reportingBusinessUnits;
	private SfResourceType[] resourceTypes;
	private SfWorkItemStatus[] workItemsStatus;
	private boolean exludeFollowups = false;
	private SfResourceCompetencyRankType[] resourceCompetencyRanks;
	private String[] workItemNames;
	private String[] workItemIds;
	private String[] excludeWorkItemIds;
	private String[] resourcesStates;
	private String[] resourceNames;
	private String[] resourceIds;
	private String[] excludeResourceIds;
	private String[] excludeResourceNames;
	private Date startDate;
	private Date endDate;
	private TimeZone timeZone;
	private String batchId;
	private int subBatchId;
	private String comment;
	private double weekendDaysInPeriod;
	private boolean loadCalendar;
	private ResourceEventType eventTypes = ResourceEventType.ALL;
	private Date calendarStartDate;
	private Date calendarEndDate;
	private boolean loadCompetencies;
	private SfWorkItemDateSelectType workItemDateSelectType = SfWorkItemDateSelectType.TARGET_DATE;
	private HashMap<String, Integer> periodWorkingDays;
	private HashMap<String, byte[]> periodWorkingSlots;
	private double scoreContractorPenalties;
	private double scoreAvailabilityDayReward;
	private double scoreDistanceKmPenalty;
	private double scoreCapabilityAuditPenalty;
	private String[] excludeStandardNames;
	private String[] includeStandardNames;
	private boolean includePipeline = false;
	private boolean milkRuns = false;
	private boolean excludeOpenPendingCancellationorSuspension = false;
	private Double fixedCapacity = null;
	private String businessLine = null;
	private String[] includeSiteIds = null;
	private String[] includeCodeIds = null;
	private List<String> boltOnStandards = null;
	
	public boolean isMilkRuns() {
		return milkRuns;
	}

	public void setMilkRuns(boolean milkRuns) {
		this.milkRuns = milkRuns;
	}

	public String[] getIncludeSiteIds() {
		return includeSiteIds;
	}

	public void setIncludeSiteIds(String[] includeSiteIds) {
		this.includeSiteIds = includeSiteIds;
	}

	public String[] getIncludeCodeIds() {
		return includeCodeIds;
	}

	public void setIncludeCodeIds(String[] includeCodeIds) {
		this.includeCodeIds = includeCodeIds;
	}

	public String getBusinessLine() {
		return businessLine;
	}

	public void setBusinessLine(String businessLine) {
		this.businessLine = businessLine;
	}

	public Double getFixedCapacity() {
		return fixedCapacity;
	}

	public void setFixedCapacity(Double fixedCapacity) {
		this.fixedCapacity = fixedCapacity;
	}

	public ResourceEventType getEventTypes() {
		return eventTypes;
	}

	public void setEventTypes(ResourceEventType eventTypes) {
		this.eventTypes = eventTypes;
	}

	public double getScoreContractorPenalties() {
		return scoreContractorPenalties;
	}

	public void setScoreContractorPenalties(double scoreContractorPenalties) {
		this.scoreContractorPenalties = scoreContractorPenalties;
	}

	public double getScoreAvailabilityDayReward() {
		return scoreAvailabilityDayReward;
	}

	public void setScoreAvailabilityDayReward(double scoreAvailabilityDayReward) {
		this.scoreAvailabilityDayReward = scoreAvailabilityDayReward;
	}

	public double getScoreDistanceKmPenalty() {
		return scoreDistanceKmPenalty;
	}

	public void setScoreDistanceKmPenalty(double scoreDistanceKmPenalty) {
		this.scoreDistanceKmPenalty = scoreDistanceKmPenalty;
	}

	public double getScoreCapabilityAuditPenalty() {
		return scoreCapabilityAuditPenalty;
	}

	public void setScoreCapabilityAuditPenalty(double scoreCapabilityAuditPenalty) {
		this.scoreCapabilityAuditPenalty = scoreCapabilityAuditPenalty;
	}

	public String[] getWiCountries() {
		return wiCountries;
	}

	public void setWiCountries(String[] wiCountries) {
		this.wiCountries = wiCountries;
	}

	public String[] getAuditorsCountries() {
		return auditorsCountries;
	}

	public void setAuditorsCountries(String[] auditorsCountries) {
		this.auditorsCountries = auditorsCountries;
	}

	public String toSqlString() {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		return 
			"'" + getBatchId() + "', " +
			getSubBatchId() + ", " +
			((getRevenueOwnership() != null && getRevenueOwnership().length>0)?"'" + Arrays.stream(getRevenueOwnership()).map(ro -> ro.getName()).collect(Collectors.joining(",")) + "'":"NULL") + ", " +
			((getSchedulingOwnership() != null && getSchedulingOwnership().length>0)?"'" + StringUtils.join(getSchedulingOwnership(), ",") + "'":"NULL") + ", " +
			((getReportingBusinessUnits() != null && getReportingBusinessUnits().length>0)?"'" + Arrays.stream(getReportingBusinessUnits()).map(ro -> ro.getName()).collect(Collectors.joining(",")) + "'":"NULL") + ", " +
			((getWiCountries() != null && getWiCountries().length>0)?"'" + StringUtils.join(getWiCountries(), ",") + "'":"NULL") + ", " +
			((getAuditorsCountries() != null && getAuditorsCountries().length>0)?"'" + StringUtils.join(getAuditorsCountries(), ",") + "'":"NULL") + ", " +
			getScoreContractorPenalties() + ", " +
			getScoreAvailabilityDayReward() + ", " +
			getScoreDistanceKmPenalty() + ", " +
			getScoreCapabilityAuditPenalty() + ", " +
			((getWorkItemsStatus() != null && getWorkItemsStatus().length>0)?"'" + Arrays.stream(getWorkItemsStatus()).map(wis -> wis.getName()).collect(Collectors.joining(",")) + "'":"NULL") + ", " +
			((getResourceTypes() != null && getResourceTypes().length>0)?"'" + Arrays.stream(getResourceTypes()).map(rt -> rt.getName()).collect(Collectors.joining(",")) + "'":"NULL") + ", " +
			(startDate==null?"NULL":("'" + sdf.format(startDate) + "'")) + ", " +
			(endDate==null?"NULL":("'" + sdf.format(endDate) + "'")) + ", " +
			(comment==null?"NULL":("'" + comment+ "'"));
	}
	
	public SfResourceType[] getResourceTypes() {
		return resourceTypes;
	}
	public void setResourceTypes(SfResourceType[] resourceTypes) {
		this.resourceTypes = resourceTypes;
	}
	public SfWorkItemStatus[] getWorkItemsStatus() {
		return workItemsStatus;
	}
	public void setWorkItemsStatus(SfWorkItemStatus[] workItemsStatus) {
		this.workItemsStatus = workItemsStatus;
	}
	public Date getStartDate() {
		return startDate;
	}
	public void setStartDate(Date startDate) {
		this.startDate = startDate;
	}
	public Date getEndDate() {
		return endDate;
	}
	public void setEndDate(Date endDate) {
		this.endDate = endDate;
	}
	public String getBatchId() {
		return batchId;
	}
	public void setBatchId(String batchId) {
		this.batchId = batchId;
	}

	public String getComment() {
		return comment;
	}

	public void setComment(String comment) {
		this.comment = comment;
	}

	public double getWeekendDaysInPeriod() {
		return weekendDaysInPeriod;
	}
	
	public double getDaysInPeriod() {
		if ((this.getCalendarEndDate() != null) && (this.getCalendarStartDate() != null))
			return ((double) this.getCalendarEndDate().getTime() - this.getCalendarStartDate().getTime())/(1000*60*60*24);
		
		return 0;
	}

	public TimeZone getTimeZone() {
		return timeZone;
	}

	public void setTimeZone(TimeZone timeZone) {
		this.timeZone = timeZone;
	}

	public CompassRevenueOwnership[] getRevenueOwnership() {
		return revenueOwnership;
	}

	public void setRevenueOwnership(CompassRevenueOwnership[] revenueOwnership) {
		this.revenueOwnership = revenueOwnership;
	}

	public CompassRevenueOwnership[] getReportingBusinessUnits() {
		return reportingBusinessUnits;
	}

	public void setRepotingBusinessUnits(CompassRevenueOwnership[] repotingBusinessUnits) {
		this.reportingBusinessUnits = repotingBusinessUnits;
	}

	public boolean loadCalendar() {
		return loadCalendar;
	}

	public void setLoadCalendar(boolean loadSFWorkAlreadyAllocated) {
		this.loadCalendar = loadSFWorkAlreadyAllocated;
	}

	public int getSubBatchId() {
		return subBatchId;
	}

	public void setSubBatchId(int subBatchId) {
		this.subBatchId = subBatchId;
	}

	public SfResourceCompetencyRankType[] getResourceCompetencyRanks() {
		return resourceCompetencyRanks;
	}

	public void setResourceCompetencyRanks(
			SfResourceCompetencyRankType[] resourceCompetencyRanks) {
		this.resourceCompetencyRanks = resourceCompetencyRanks;
	}

	public String[] getWorkItemNames() {
		return workItemNames;
	}

	public void setWorkItemNames(String[] workItemNames) {
		this.workItemNames = workItemNames;
	}

	public String[] getWorkItemIds() {
		return workItemIds;
	}

	public void setWorkItemIds(String[] workItemIds) {
		this.workItemIds = workItemIds;
	}

	public String[] getResourcesStates() {
		return resourcesStates;
	}

	public void setResourcesStates(String[] resourcesStates) {
		this.resourcesStates = resourcesStates;
	}

	public String[] getResourceNames() {
		return resourceNames;
	}

	public void setResourceNames(String[] resourceNames) {
		this.resourceNames = resourceNames;
	}

	public String[] getResourceIds() {
		return resourceIds;
	}

	public void setResourceIds(String[] resourceIds) {
		this.resourceIds = resourceIds;
	}

	public Date getCalendarStartDate() {
		return calendarStartDate;
	}

	public void setCalendarStartDate(Date calendarStartDate) {
		this.calendarStartDate = calendarStartDate;
		if ((this.calendarStartDate != null) && (this.calendarEndDate != null))
			this.weekendDaysInPeriod = Utility.calculateWeekendDays(this.calendarStartDate, this.calendarEndDate, this.timeZone);
		this.periodWorkingDays = null;
	}

	public Date getCalendarEndDate() {
		return calendarEndDate;
	}

	public void setCalendarEndDate(Date calendarEndDate) {
		this.calendarEndDate = calendarEndDate;
		if ((this.calendarStartDate != null) && (this.calendarEndDate != null))
			this.weekendDaysInPeriod = Utility.calculateWeekendDays(this.calendarStartDate, this.calendarEndDate, this.timeZone);
		this.periodWorkingDays = null;
	}

	public boolean loadCompetencies() {
		return loadCompetencies;
	}

	public void setLoadCompetencies(boolean loadCompetencies) {
		this.loadCompetencies = loadCompetencies;
	}

	public SfWorkItemDateSelectType getWorkItemDateSelectType() {
		return workItemDateSelectType;
	}

	public void setWorkItemDateSelectType(
			SfWorkItemDateSelectType workItemDateSelectType) {
		this.workItemDateSelectType = workItemDateSelectType;
	}
	
	// TODO: Unused.  To be removed
	public HashMap<String, byte[]> getNewPeriodsWorkingSlots() {
		if (periodWorkingSlots == null) {
			// Calculate periods working slots
			periodWorkingSlots = new HashMap<String, byte[]>();
			Calendar pointer = new GregorianCalendar();
			pointer.setTime(getCalendarStartDate());
			Calendar endPeriod = new GregorianCalendar();
			endPeriod.setTime(getCalendarEndDate());
			int slotPointer = 0;
			while (pointer.before(endPeriod) || pointer.equals(endPeriod)) {
				if(!periodWorkingSlots.containsKey(Utility.getPeriodformatter().format(pointer.getTime()))) {
					periodWorkingSlots.put(Utility.getPeriodformatter().format(pointer.getTime()), new byte[2*pointer.getActualMaximum(Calendar.DAY_OF_MONTH)]);
					slotPointer = 1;
				}
				if (pointer.get(Calendar.DAY_OF_WEEK)!=Calendar.SATURDAY && pointer.get(Calendar.DAY_OF_WEEK)!=Calendar.SUNDAY) {
					periodWorkingSlots.get(Utility.getPeriodformatter().format(pointer.getTime()))[slotPointer++] = 1;
					periodWorkingSlots.get(Utility.getPeriodformatter().format(pointer.getTime()))[slotPointer++] = 1;
				}
				pointer.add(Calendar.DAY_OF_YEAR, 1);
			}
		}
		HashMap<String, byte[]> retValue = new HashMap<String, byte[]>();
		for (String period: periodWorkingSlots.keySet()) {
			retValue.put(period, new byte[periodWorkingSlots.get(period).length]);
			for (int i=0; i<periodWorkingSlots.get(period).length; i++) {
				retValue.get(period)[i] = periodWorkingSlots.get(period)[i];
			}
		}
		return retValue;
	}
	
	public HashMap<String, Integer> getPeriodsWorkingDays() {
		if (periodWorkingDays == null) {
			// Calculate periods working days
			periodWorkingDays = new HashMap<String, Integer>();
			Calendar pointer = new GregorianCalendar();
			pointer.setTime(getStartDate());
			Calendar endPeriod = new GregorianCalendar();
			endPeriod.setTime(getEndDate());
			while (pointer.before(endPeriod) || pointer.equals(endPeriod)) {
				if(!periodWorkingDays.containsKey(Utility.getPeriodformatter().format(pointer.getTime())))
					periodWorkingDays.put(Utility.getPeriodformatter().format(pointer.getTime()), 0);
				if (pointer.get(Calendar.DAY_OF_WEEK)!=Calendar.SATURDAY && pointer.get(Calendar.DAY_OF_WEEK)!=Calendar.SUNDAY)
					periodWorkingDays.put(Utility.getPeriodformatter().format(pointer.getTime()), periodWorkingDays.get(Utility.getPeriodformatter().format(pointer.getTime())).intValue()+1);
				pointer.add(Calendar.DAY_OF_YEAR, 1);
			}
		}
		return periodWorkingDays;
	}

	public boolean isExludeFollowups() {
		return exludeFollowups;
	}

	public void setExludeFollowups(boolean exludeFollowups) {
		this.exludeFollowups = exludeFollowups;
	}

	public String[] getIncludeStandardNames() {
		return includeStandardNames;
	}

	public void setIncludeStandardNames(String[] includeStandardIds) {
		this.includeStandardNames = includeStandardIds;
	}

	public String[] getExcludeStandardNames() {
		return excludeStandardNames;
	}

	public void setExcludeStandardNams(String[] excludeStandardIds) {
		this.excludeStandardNames = excludeStandardIds;
	}

	public boolean includePipeline() {
		return includePipeline;
	}

	public void setIncludePipeline(boolean includePipeline) {
		this.includePipeline = includePipeline;
	}

	public String[] getExcludeResourceIds() {
		return excludeResourceIds;
	}

	public void setExcludeResourceIds(String[] excludeResourceIds) {
		this.excludeResourceIds = excludeResourceIds;
	}

	public String[] getExcludeResourceNames() {
		return excludeResourceNames;
	}

	public void setExcludeResourceNames(String[] excludeResourceNames) {
		this.excludeResourceNames = excludeResourceNames;
	}

	public boolean isExcludeOpenPendingCancellationorSuspension() {
		return excludeOpenPendingCancellationorSuspension;
	}

	public void setExcludeOpenPendingCancellationorSuspension(
			boolean excludeOpenPendingCancellationorSuspension) {
		this.excludeOpenPendingCancellationorSuspension = excludeOpenPendingCancellationorSuspension;
	}

	public String[] getExcludeWorkItemIds() {
		return excludeWorkItemIds;
	}

	public void setExcludeWorkItemIds(String[] excludeWorkItemIds) {
		this.excludeWorkItemIds = excludeWorkItemIds;
	}

	public String[] getSchedulingOwnership() {
		return schedulingOwnership;
	}

	public void setSchedulingOwnership(String[] schedulingOwnership) {
		this.schedulingOwnership = schedulingOwnership;
	}

	public List<String> getBoltOnStandards() {
		return boltOnStandards;
	}

	public void setBoltOnStandards(String[] boltOnStandards) {
		this.boltOnStandards = Arrays.asList(boltOnStandards);
	}
}
