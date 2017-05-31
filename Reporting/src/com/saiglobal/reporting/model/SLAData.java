package com.saiglobal.reporting.model;

import java.util.Calendar;

public class SLAData {
	public String team, slaName, slaDescription, slaUnit, regionName;
	public double slaTarget;
	public Calendar from, to;
	public boolean hasProcessing;
	public int qtyProcessed;
	public int qtyProcessedOverSLA;
	public double avgProcessingTimeHrs;
	public boolean hasBacklog;
	public int qtyBacklog;
	public int qtyBacklogOverSLA;
	public double avgAgingTimeHrs;
	public double activityDuration;
	public String slaTargetText;
	
	public Object[][] processedByPeriod;
	public Object[][] processedByResource;
	
	
	public String getRegionName() {
		return regionName;
	}
	public void setRegionName(String regionName) {
		this.regionName = regionName;
	}
	public String getSlaTargetText() {
		return slaTargetText;
	}
	public void setSlaTargetText(String slaTargetText) {
		this.slaTargetText = slaTargetText;
	}
	public boolean isHasProcessing() {
		return hasProcessing;
	}
	public void setHasProcessing(boolean hasProcessing) {
		this.hasProcessing = hasProcessing;
	}
	public boolean isHasBacklog() {
		return hasBacklog;
	}
	public void setHasBacklog(boolean hasBacklog) {
		this.hasBacklog = hasBacklog;
	}
	public double getActivityDuration() {
		return activityDuration;
	}
	public void setActivityDuration(double activityDuration) {
		this.activityDuration = activityDuration;
	}
	public String getTeam() {
		return team;
	}
	public void setTeam(String team) {
		this.team = team;
	}
	public String getSlaName() {
		return slaName;
	}
	public void setSlaName(String slaName) {
		this.slaName = slaName;
	}
	public String getSlaDescription() {
		return slaDescription;
	}
	public void setSlaDescription(String slaDescription) {
		this.slaDescription = slaDescription;
	}
	public String getSlaUnit() {
		return slaUnit;
	}
	public void setSlaUnit(String slaUnit) {
		this.slaUnit = slaUnit;
	}
	public double getSlaTarget() {
		return slaTarget;
	}
	public void setSlaTarget(double slaTarget) {
		this.slaTarget = slaTarget;
	}
	public Calendar getFrom() {
		return from;
	}
	public void setFrom(Calendar from) {
		this.from = from;
	}
	public Calendar getTo() {
		return to;
	}
	public void setTo(Calendar to) {
		this.to = to;
	}
	public int getQtyProcessed() {
		return qtyProcessed;
	}
	public void setQtyProcessed(int qtyProcessed) {
		this.qtyProcessed = qtyProcessed;
	}
	public int getQtyProcessedOverSLA() {
		return qtyProcessedOverSLA;
	}
	public void setQtyProcessedOverSLA(int qtyProcessedOverSLA) {
		this.qtyProcessedOverSLA = qtyProcessedOverSLA;
	}
	public double getAvgProcessingTimeHrs() {
		return avgProcessingTimeHrs;
	}
	public void setAvgProcessingTimeHrs(double avgProcessingTimeHrs) {
		this.avgProcessingTimeHrs = avgProcessingTimeHrs;
	}
	public int getQtyBacklog() {
		return qtyBacklog;
	}
	public void setQtyBacklog(int qtyBacklog) {
		this.qtyBacklog = qtyBacklog;
	}
	public int getQtyBacklogOverSLA() {
		return qtyBacklogOverSLA;
	}
	public void setQtyBacklogOverSLA(int qtyBacklogOverSLA) {
		this.qtyBacklogOverSLA = qtyBacklogOverSLA;
	}
	public double getAvgAgingTimeHrs() {
		return avgAgingTimeHrs;
	}
	public void setAvgAgingTimeHrs(double avgAgingTimeHrs) {
		this.avgAgingTimeHrs = avgAgingTimeHrs;
	}

}
