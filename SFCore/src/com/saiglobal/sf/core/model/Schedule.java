package com.saiglobal.sf.core.model;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import com.saiglobal.sf.core.utility.Utility;

public class Schedule {
	private String workItemGroup;
	private String workItemId;
	private String workItemName;
	private WorkItemSource workItemSource;
	private String workItemCountry;
	private String workItemState;
	private String workItemTimeZone;
	private double latitude;
	private double longitude;
	private String resourceId;
	private String resourceName;
	private SfResourceType resourceType;
	private Date startDate;
	private Date endDate;
	private double duration;
	private double workItemDuration;
	private double distanceKm;
	private ScheduleType type;
	private ScheduleStatus status;
	private String notes; 
	private Competency primaryStandard;
	private String sfType;
	private String sfSubType;
	private String competencies;
	private String comment;
	private double travelDuration;
	private double totalCost;
	
	public static List<Schedule> getSchedules(WorkItem wi) {
		List<Schedule> schedules = new ArrayList<Schedule>();
		schedules.add(new Schedule(wi));
		for (WorkItem linkedWi : wi.getLinkedWorkItems()) {
			Schedule linkedSchedule = new Schedule(linkedWi);
			linkedSchedule.setWorkItemGroup(wi.getId());
			schedules.add(linkedSchedule);
			
		}
		return schedules;
	}
	
	public Schedule(WorkItem wi) {
		super();
		setWorkItemId(wi.getId());
		setWorkItemGroup(wi.getId()); // No milk run with MIP scheduling yet
		setWorkItemName(wi.getName());
		setWorkItemSource(wi.getWorkItemSource());
		setWorkItemCountry(wi.getClientSite().getCountry());
		setWorkItemState(wi.getClientSite().getState());
		setWorkItemTimeZone(wi.getClientSite().getTimeZone().getID());
		setLatitude(wi.getClientSite().getLatitude());
		setLongitude(wi.getClientSite().getLongitude());
		setType(ScheduleType.AUDIT);
		setDuration(wi.getRequiredDuration());
		setWorkItemDuration(wi.getRequiredDuration());
		setPrimaryStandard(wi.getPrimaryStandard());
		setCompetencies(wi.getRequiredCompetenciesString());
		setStatus(ScheduleStatus.NOT_ALLOCATED);
		setWorkItemGroup(wi.getId());
		setStartDate(wi.getStartDate());
	}
	
	public Schedule() {
	}

	public Schedule(Schedule s) {
		super();
		this.workItemGroup = s.workItemGroup==null?null:new String(s.workItemGroup);
		this.workItemId = s.workItemId==null?null:new String(s.workItemId);
		this.workItemName = s.workItemName==null?null:new String(s.workItemName);
		this.workItemSource = s.workItemSource;
		this.workItemCountry = s.workItemCountry==null?null:new String(s.workItemCountry);
		this.workItemState = s.workItemState==null?null:new String(s.workItemState);
		this.workItemTimeZone = s.workItemTimeZone==null?null:new String(s.workItemTimeZone);
		this.latitude = s.latitude;
		this.longitude = s.longitude;
		this.resourceId = s.resourceId==null?null:new String(s.resourceId);
		this.resourceName = s.resourceName==null?null:new String(s.resourceName);
		this.resourceType = s.resourceType;
		this.startDate = s.startDate==null?null:new Date(s.startDate.getTime());
		this.endDate = s.endDate==null?null:new Date(s.endDate.getTime());
		this.duration = s.duration;
		this.workItemDuration = s.workItemDuration;
		this.distanceKm = s.distanceKm;
		this.type = s.type;
		this.status = s.status;
		this.notes = s.notes==null?null:new String(s.notes);
		this.primaryStandard = s.primaryStandard==null?null:new Competency(s.primaryStandard.getId(), s.primaryStandard.getCompetencyName(), s.primaryStandard.getType(), Arrays.stream(s.primaryStandard.getRanks()).map(r -> r.getName()).collect(Collectors.joining(";")) );
		this.sfType = s.sfType==null?null:new String(s.sfType);
		this.sfSubType = s.sfSubType==null?null:new String(s.sfSubType);
		this.competencies = s.competencies==null?null:new String(s.competencies);
		this.comment = s.comment==null?null:new String(s.comment);
		this.travelDuration = s.travelDuration;
	}
	
	
	public double getTotalCost() {
		return totalCost;
	}

	public void setTotalCost(double totalCost) {
		this.totalCost = totalCost;
	}

	public double getWorkItemDuration() {
		return workItemDuration;
	}
	public void setWorkItemDuration(double work_item_duration) {
		this.workItemDuration = work_item_duration;
	}
	public String getNotes() {
		return notes;
	}
	public void setNotes(String notes) {
		this.notes = notes;
	}
	public double getDistanceKm() {
		return distanceKm;
	}
	public void setDistanceKm(double distanceKm) {
		this.distanceKm = distanceKm;
	}
	public String getWorkItemId() {
		return workItemId;
	}
	public void setWorkItemId(String workItemId) {
		this.workItemId = workItemId;
	}
	public String getWorkItemName() {
		return workItemName;
	}
	public void setWorkItemName(String workItemName) {
		this.workItemName = workItemName;
	}
	public String getResourceId() {
		return resourceId;
	}
	public void setResourceId(String resourceId) {
		this.resourceId = resourceId;
	}
	public String getResourceName() {
		return resourceName;
	}
	public void setResourceName(String resourceName) {
		this.resourceName = resourceName;
	}
	@SuppressWarnings("deprecation")
	public String getStartPeriod() {
		Date now = new Date();
		if(startDate.before(new Date()))
			return "" + now.getYear() + "-" + now.getMonth();
		else
			return "" + startDate.getYear() + "-" + startDate.getMonth();
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
	public ScheduleType getType() {
		return type;
	}
	public void setType(ScheduleType type) {
		this.type = type;
	}
	public ScheduleStatus getStatus() {
		return status;
	}
	public void setStatus(ScheduleStatus status) {
		this.status = status;
	}
	public String getComment() {
		return comment;
	}
	public void setComment(String comment) {
		this.comment = comment;
	}
	public void appendComment(String comment) {
		if (this.comment != null)
			this.comment += "," + comment;
		else
			this.comment = comment;
	}
	public String getCompetencies() {
		return competencies;
	}
	public void setCompetencies(String competencies) {
		this.competencies = competencies;
	}
	
	public String toSqlString() {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String sql = (workItemId==null?"NULL":("'" + workItemId + "'")) + ", " +
				(workItemName==null?"NULL":("'" + Utility.addSlashes(workItemName) + "'")) + ", " +
				(workItemSource==null?"NULL":("'" + workItemSource.toString() + "'")) + ", " +
				(workItemCountry==null?"NULL":("'" + workItemCountry + "'")) + ", " +
				(workItemState==null?"NULL":("'" + workItemState + "'")) + ", " +
				(workItemTimeZone==null?"NULL":("'" + workItemTimeZone + "'")) + ", " +
				(resourceId==null?"NULL":("'" + resourceId + "'")) + ", " +
				(resourceName==null?"NULL":("'" + Utility.addSlashes(resourceName) + "'")) + ", " +
				(resourceType==null?"NULL":("'" + resourceType.getName() + "'")) + ", " +
				(startDate==null?"NULL":("convert_tz('" + sdf.format(startDate) + "', '" + workItemTimeZone + "', 'UTC')")) + ", " +
				(endDate==null?"NULL":("convert_tz('" + sdf.format(endDate) + "', '" + workItemTimeZone + "', 'UTC')")) + ", " +
				duration + ", " +
				travelDuration + ", " +
				(status==null?"NULL":("'" + status.toString() + "'")) + ", " +
				(type==null?"NULL":("'" + type.toString() + "'")) + ", " +
				(primaryStandard==null?"NULL":("'" + Utility.addSlashes(primaryStandard.getCompetencyName()) + "'")) + ", " +
				(competencies==null?"NULL":("'" + Utility.addSlashes(competencies) + "'")) + ", " +
				(comment==null?"NULL":("'" + Utility.addSlashes(comment) + "'")) + ", " +
				distanceKm +", " +
				(notes==null?"NULL":("'" + Utility.addSlashes(notes) + "'")) + ", " +
				(getWorkItemGroup()==null?"NULL":("'" + Utility.addSlashes(getWorkItemGroup()) + "'")) + ", " +
				totalCost;

		return sql;
			
	}
	public double getDuration() {
		return duration;
	}
	public void setDuration(double duration) {
		this.duration = duration;
	}
	public SfResourceType getResourceType() {
		return resourceType;
	}
	public void setResourceType(SfResourceType resourceType) {
		this.resourceType = resourceType;
	}
	public void setResourceType(String resourceType) {
		this.resourceType = SfResourceType.getValueForName(resourceType);
	}
	
	public Competency getPrimaryStandard() {
		return primaryStandard;
	}
	public void setPrimaryStandard(Competency primaryStandard) {
		this.primaryStandard = primaryStandard;
	}
	public String getWorkItemCountry() {
		return workItemCountry;
	}
	public void setWorkItemCountry(String workItemCountry) {
		this.workItemCountry = workItemCountry;
	}
	public String getWorkItemState() {
		return workItemState;
	}
	public void setWorkItemState(String workItemState) {
		this.workItemState = workItemState;
	}
	public String getSfType() {
		return sfType;
	}
	public void setSfType(String sfType) {
		this.sfType = sfType;
	}
	public String getSfSubType() {
		return sfSubType;
	}
	public void setSfSubType(String sfSubType) {
		this.sfSubType = sfSubType;
	}
	public double getLatitude() {
		return latitude;
	}
	public void setLatitude(double latitude) {
		this.latitude = latitude;
	}
	public double getLongitude() {
		return longitude;
	}
	public void setLongitude(double longitude) {
		this.longitude = longitude;
	}
	public String getWorkItemGroup() {
		if (workItemGroup==null)
			return workItemId;
		return workItemGroup;
	}
	public void setWorkItemGroup(String workItemGroup) {
		this.workItemGroup = workItemGroup;
	}
	public WorkItemSource getWorkItemSource() {
		return workItemSource;
	}
	public void setWorkItemSource(WorkItemSource workItemSource) {
		this.workItemSource = workItemSource;
	}
	public double getTravelDuration() {
		return travelDuration;
	}
	public void setTravelDuration(double travelDuration) {
		this.travelDuration = travelDuration;
	}

	public String getWorkItemTimeZone() {
		return workItemTimeZone;
	}

	public void setWorkItemTimeZone(String workItemTimeZone) {
		this.workItemTimeZone = workItemTimeZone;
	}
}
