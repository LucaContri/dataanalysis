package com.saiglobal.sf.core.model;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.TimeZone;
import java.util.stream.Collectors;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlTransient;

import com.google.code.geocoder.model.LatLng;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.utility.Utility;

public class Resource extends GenericSfObject implements Comparable<Resource> {
	private static double defaultHourlyRate = 110;
	private List<Competency> competencies;
	private int targetDays;
	private double capacity;
	@XmlTransient
	private ResourceCalendar calendar;
	private String managerName;
	@XmlTransient
	private String managerId;
	private String resourceCoordinatorName;
	private String reportingBusinessUnit;
	private SfResourceType type;
	private Location home;
	private SfSaigOffice office;
	@XmlTransient
	private double availableHours;
	private Double distanceFromClient;
	private Double homeDistanceFromClient;
	private Double travelCost;
	private Double travelTime;
	private Double resourceCost;
	private Double score;
	private TravelType travelType;
	private Double utilization;
	private Double hourlyRate;
	
	@Override
	protected Object clone() throws CloneNotSupportedException {
		return super.clone();
	}
	
	public Resource() {
		
	}
	
	public Resource(ResultSet rs, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		this.setId(rs.getString("r_Id"));
		this.setName(rs.getString("r_Name"));
		this.setLastModified(new Date(rs.getTimestamp("r_LastModifiedDate").getTime()));
		
		this.targetDays = (int) rs.getDouble("r_Resource_Target_Days__c");
		if (this.targetDays<0)
			this.targetDays = 180;
		
		this.reportingBusinessUnit = rs.getString("r_Reporting_Business_Units__c");
		
		this.type = SfResourceType.getValueForName(rs.getString("r_Resource_Type__c"));
		
		if (rs.getDouble("r_Resource_Capacitiy__c")<0) 
			// if capacity is not set, assume 100%
			this.capacity = 100;
		else 
			this.capacity = (int) Math.max(rs.getDouble("r_Resource_Capacitiy__c"),0);
		
		// TODO: Remove override below once resource capacity are fixed in Compass for PS resources
		//if (this.reportingBusinessUnit.toLowerCase().contains("product")) {
			// Product Service auditors capacity override to 50%
		//	this.capacity = 50;
		//}
		calendar = null;
		this.managerName = rs.getString("um_Name");
		this.managerId = rs.getString("um_Id");
		if (rs.getString("ResourceCoordinatorName")!=null) {
			this.resourceCoordinatorName = rs.getString("ResourceCoordinatorName");
		}
		
		Location homeLocation = new Location();
		homeLocation.setName(this.getName() + " - Home");
		homeLocation.setAddress_1(rs.getString("r_Home_Address_1__c"));
		homeLocation.setAddress_2(rs.getString("r_Home_Address_2__c"));
		homeLocation.setAddress_3(rs.getString("r_Home_Address_3__c"));
		homeLocation.setCity(rs.getString("r_Home_City__c"));
		homeLocation.setCountry(rs.getString("r_country"));
		homeLocation.setState(rs.getString("r_state"));
		homeLocation.setPostCode(rs.getString("r_Home_Postcode__c"));
		homeLocation.setLatitude(rs.getDouble("c_Latitude"));
		homeLocation.setLongitude(rs.getDouble("c_Longitude"));
		homeLocation.setTimeZone(TimeZone.getTimeZone(rs.getString("u_TimeZoneSidKey")));
		if(rs.getDouble("c_Latitude")==0 || rs.getDouble("c_Longitude")==0) {
			homeLocation.setLatitude(rs.getDouble("r_Latitude__c"));
			homeLocation.setLongitude(rs.getDouble("r_Longitude__c"));
			
			// Latitude and Longitude from Compass are not reliable.  Using Geocoding API with local cache
			try {
				LatLng coordinates = Utility.getGeocode(homeLocation, db);
				if (coordinates != null) {
					homeLocation.setLatitude(coordinates.getLat().doubleValue());
					homeLocation.setLongitude(coordinates.getLng().doubleValue());
				}
			} catch (Exception e) {
				// Ignore and Carry on
			}
		}
		this.home = homeLocation;
		String mo = rs.getString("r_Managing_Office__c");
		try {
			this.office = SfSaigOffice.getValueForName(mo);
		} catch (Exception e) {
			e.printStackTrace();
			// Ignore and continue
		}
		//this.availableHours = this.targetDays*8;
		
		this.competencies = new ArrayList<Competency>();
		if (rs.getString("CodeIds")!=null) {
			String[] codeIds = rs.getString("codeIds").split(",");
			String[] codes = rs.getString("codes").split(",");
			String[] codesWorkItems = rs.getString("CodesWorkItems").split(",");
			String[] codesWorkItemsExpiry = rs.getString("CodesWorkItemsExpiry").split(",");
			int index = 0;
			for (String codeId : codeIds) {
				competencies.add(new Competency(codeId, codes[index], CompetencyType.CODE, null, codesWorkItems[index], codesWorkItemsExpiry[index++]));
			}
		}
		
		if (rs.getString("StandardIds")!=null) {
			String[] stdIds = rs.getString("StandardIds").split(",");
			String[] stds = rs.getString("Standards").split(",");
			String[] ranks = rs.getString("Ranks").split(",");
			int index = 0;
			for (String stdId : stdIds) {
				competencies.add(new Competency(stdId, stds[index], CompetencyType.STANDARD, ranks[index++]));
			}
		}
		this.score = 0.0;
		
		if (rs.getDouble("HourlyRateAUD")>0) {
			this.setHourlyRate(rs.getDouble("HourlyRateAUD")); 
		} else {
			this.setHourlyRate(defaultHourlyRate);
		}
	}
	
	
	public double getCapacity() {
		return capacity;
	}
	
	public void setCapacity(double capacity) {
		this.capacity = capacity;
	}
	
	public boolean isAvailableFor(ResourceEvent eventToCheck) {
		return this.calendar.isAvailableFor(eventToCheck);
	}
	
	/*
	public NavigableSet<String> getAvailableDays(Date fromDate, Date toDate) {
		if (daysAvailable != null) 
			return daysAvailable.subSet(
					Utility.getActivitydateformatter().format(fromDate), true, 
					Utility.getActivitydateformatter().format(toDate), true);
		return null;
	}
	
	public List<String> getAvailableDaysAsString(Date fromDate, Date toDate) {
		List<String> retValue = new ArrayList<String>();
		if (daysAvailable != null) {
			TreeSet<String> set = new TreeSet<String>();
			set.lower("");
		}
		return retValue;
	}
	*/
	public double hasAvailabilityFor(WorkItem wi) {
		//if (wi.getId().equalsIgnoreCase("006d000000iRYjGAAW-001d000001zcS05AAE-a36d00000004TyZAAU") && this.getName().equalsIgnoreCase("Derrick Lee")) {
		//	System.out.print("break");
		//}
		return this.calendar.hasAvailabilityFor(wi);
	}
	
	public void bookFor(ResourceEvent eventToBook, boolean checkAvailability) throws ResourceCalenderException {
		this.calendar.bookFor(eventToBook, checkAvailability);
		this.availableHours -= eventToBook.getDurationHours();
	}

	public void bookFor(ResourceEvent eventToBook) throws ResourceCalenderException {
		this.bookFor(eventToBook, false);
	}
	
	public List<Competency> getCompetency(Competency requirement) {
		return competencies.stream().filter(c -> c.equals(requirement)).collect(Collectors.toList());
	}
	
	public boolean canPerform(WorkItem workItem) {
		for (Competency requirement : workItem.getRequiredCompetencies()) {
			boolean canPerformRequirement = false;
			for (Competency matchingCompetency : getCompetency(requirement)) {
				if ((matchingCompetency.getCompetencyExpiry() == null || matchingCompetency.getCompetencyExpiry().after(workItem.getStartDateCalendar())) 
						&& (matchingCompetency.getWorkItemId() == null || matchingCompetency.getWorkItemId().equalsIgnoreCase(workItem.getId())))
						canPerformRequirement = true;
			}
			if(!canPerformRequirement)
				return false;
		}
		for ( WorkItem linkedWorkItem: workItem.getLinkedWorkItems()) 
			if (!canPerform(linkedWorkItem))
				return false;
		
		return true;
	}
	
	public boolean hasCompetencies(List<Competency> capabilitiesRequired) {
		return this.competencies.containsAll(capabilitiesRequired);
	}

	public int getTargetDays() {
		return targetDays;
	}

	public void setTargetDays(int targetDays) {
		this.targetDays = targetDays;
	}

	public List<Competency> getCompetencies() {
		return competencies;
	}

	public void setCompetencies(List<Competency> competencies) {
		this.competencies = competencies;
	}

	public ResourceCalendar getCalender() {
		return calendar;
	}

	public void setCalendar(ResourceCalendar calender) {
		this.calendar = calender;
	}
	
	public String toString() {
		String competencyString = "";
		for (Competency aCompetency : this.competencies) {
			competencyString += aCompetency.getCompetencyName();
		}
		return getId() + "-" + getName() + "-" + getManagerName() + "-" + getReportingBusinessUnit() + "-" + getHome().getState() + "-" + getTargetDays() + "-" + competencyString;
	}
	
	public String toCsv() {
		String competencyString = "";
		for (Competency aCompetency : this.competencies) {
			competencyString += aCompetency.getCompetencyName();
		}
		return getId() + "," + getName() + "," + getManagerName() + "," + getReportingBusinessUnit() + "," + getHome().getState() + "," + getCapacity() + "," + getAvailableHours() + "," + competencyString;
	}

	public String getManagerName() {
		return managerName;
	}

	public void setManagerName(String managerName) {
		this.managerName = managerName;
	}

	public String getManagerId() {
		return managerId;
	}

	public void setManagerId(String managerId) {
		this.managerId = managerId;
	}

	public String getReportingBusinessUnit() {
		return reportingBusinessUnit;
	}

	public void setReportingBusinessUnit(String reportingBusinessUnit) {
		this.reportingBusinessUnit = reportingBusinessUnit;
	}

	public double getAvailableHours() {
		return availableHours;
	}

	public void setAvailableHours(double availableHours) {
		this.availableHours = availableHours;
	}

	public double getAvailableDaysInPeriod(ScheduleParameters parameters) {
		// The available days in period is the min between:
		//	- the actual days available excluding BOP, weekends, work already allocated (based on flag) and work allocated by same batchId allocator
		//	- the max allowed by the resource target days
		
		// Get total BOP duration in period
		double totalUnavailableDays = 0.0;
		for (ResourceEvent anEvent : this.calendar.getEvents()) {
			if (((anEvent.startDateTime.getTime()>=parameters.getCalendarStartDate().getTime()) && (anEvent.startDateTime.getTime()<parameters.getCalendarEndDate().getTime())) || 
				((anEvent.endDateTime.getTime()>=parameters.getCalendarStartDate().getTime()) && (anEvent.endDateTime.getTime()<parameters.getCalendarEndDate().getTime()))) {
				
				//totalUnavailableDays += Utility.calculateWorkingDaysInPeriod(anEvent.startDateTime, anEvent.endDateTime, parameters.getTimeZone());
				totalUnavailableDays += (anEvent.endDateTime.getTime() - anEvent.startDateTime.getTime())/1000.0/60/60/8;  
			}	
		}
		// Get Weekends in period
		totalUnavailableDays += parameters.getWeekendDaysInPeriod();
		
		// Calculate max days allowed based on resource target days (Employees only)
		double resourceMaxAvailableDaysInPeriod = Double.MAX_VALUE;
		if (this.type.equals(SfResourceType.Employee))
			resourceMaxAvailableDaysInPeriod = ((double)this.getCapacity())/100.0*(parameters.getDaysInPeriod()-totalUnavailableDays);
		
		// Return min duration of period minus BOP - weekends
		return Math.min(resourceMaxAvailableDaysInPeriod, (parameters.getDaysInPeriod()-totalUnavailableDays));
	}
	
	public void init(ScheduleParameters parameters) {
		// Init resource available hours in selected period
		this.setAvailableHours(Math.round(this.getAvailableDaysInPeriod(parameters)*8));
		
		// Init working days in period
		this.calendar.setPeriodWorkingDays(parameters.getPeriodsWorkingDays());
		//this.calendar.setPeriodWorkingSlots(parameters.getNewPeriodsWorkingSlots());
	}

	public Location getHome() {
		return home;
	}

	public void setHome(Location home) {
		this.home = home;
	}

	public SfSaigOffice getOffice() {
		return office;
	}

	public void setOffice(SfSaigOffice office) {
		this.office = office;
	}

	public SfResourceType getType() {
		return type;
	}

	public void setType(SfResourceType type) {
		this.type = type;
	}
	
	public void setAvailablePeriods(Periods periods) throws Exception {
		throw new Exception("Do not call this. Only for JAXB to serialize this property");
	}

	public Double getDistanceFromClient() {
		return distanceFromClient;
	}

	public void setDistanceFromClient(Double distanceFromClient) {
		this.distanceFromClient = distanceFromClient;
	}

	public Double getTravelCost() {
		return travelCost;
	}

	public void setTravelCost(Double travelCost) {
		this.travelCost = travelCost;
	}

	public Double getResourceCost() {
		return resourceCost;
	}

	public void setResourceCost(Double resourceCost) {
		this.resourceCost = resourceCost;
	}

	public Double getScore() {
		return score;
	}

	public void setScore(Double score) {
		this.score = score;
	}

	public Double getTravelTime() {
		return travelTime;
	}

	public void setTravelTime(Double travelTime) {
		this.travelTime = travelTime;
	}

	public TravelType getTravelType() {
		return travelType;
	}

	public void setTravelType(TravelType travelType) {
		this.travelType = travelType;
	}

	public Double getUtilization() {
		return utilization;
	}

	public void setUtilization(Double utilization) {
		this.utilization = utilization;
	}
	
	public Double getHomeDistanceFromClient() {
		return homeDistanceFromClient;
	}
	
	public void setHomeDistanceFromClient(Double homeDistanceFromClient) {
		this.homeDistanceFromClient = homeDistanceFromClient;
	}
	public String getResourceCoordinatorName() {
		return resourceCoordinatorName;
	}
	public void setResourceCoordinatorName(String resourceCoordinatorName) {
		this.resourceCoordinatorName = resourceCoordinatorName;
	}
	@Override
	public int compareTo(Resource o) {
		if (this.getScore()>o.getScore())
			return 1;
		if (this.getScore()<o.getScore())
			return -1;
		return 0;
	}

	public Double getHourlyRate() {
		return hourlyRate;
	}

	public void setHourlyRate(Double hourlyRate) {
		this.hourlyRate = hourlyRate;
	}

}

class Periods {
	
	private HashMap<String, Period> periodList;

	public Periods() {
		periodList = new HashMap<String, Period>();
	}
	
	public Periods(Set<String> allPeriods) {
		periodList = new HashMap<String, Period>();
		for (String name : allPeriods) {
			periodList.put(name, new Period(name));
		}
	}
	
	public boolean containsPeriod(String name) {
		return periodList.containsKey(name);
	}
	
	public Period getPeriod(String name) {
		addPeriod(name);
		return periodList.get(name);
	}
	
	public void addPeriod(String name) {
		if (!containsPeriod(name))
			periodList.put(name, new Period(name));
	}
	
	@XmlElement(name="period")
	public Collection<Period> getPeriods() {
		List<Period> retValue = new ArrayList<Period>();
		List<String> periodNames = new ArrayList<String>(periodList.keySet());
		Collections.sort(periodNames);
		for (String periodName : periodNames) {
			retValue.add(periodList.get(periodName));
		}
		return retValue;
	}
	
	public void setPeriods(Collection<Period> periodList) {
		// DO nothing here
	}
}

class Period {
	
	private String name;
	private List<String> days;
	
	public Period(String name) {
		this.name = name;
		this.days = new ArrayList<String>();
	}
	
	public void addDay(String day) {
		days.add(day);
	}
	
	public String getName() {
		return name;
	}
	public void setName(String period) {
		this.name = period;
	}
	public List<String> getDay() {
		return days;
	}
	public void setDay(List<String> day) {
		this.days = day;
	}
}
