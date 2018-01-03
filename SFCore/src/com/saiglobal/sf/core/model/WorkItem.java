package com.saiglobal.sf.core.model;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlTransient;

import com.google.code.geocoder.model.LatLng;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.utility.Utility;

public class WorkItem extends GenericSfObject implements Comparable<WorkItem> {
	private List<Competency> requiredCompetencies;
	private WorkItemStatus localStatus;
	private Date targetDate; // Only Month and Year are used
	private Date startDate;
	private Date startAuditWindow;
	private Date endAuditWindow;
	private boolean log = true;
	private boolean isPrimary = true;
	private List<WorkItem> linkedWorkItems = new ArrayList<WorkItem>();
	@XmlTransient
	private List<Resource> allocatedResources;
	private SfWorkItemStatus sfStatus;
	private double requiredDuration;
	private int frequencyOfCapabilities;
	private Location clientSite;
	private CompassRevenueOwnership revenueOwnership;
	private String revenueOwnershipName;
	private SFWorkItemType type;
	private String[] preferredResourceIds;
	private String[] preferredResourceNames;
	private String comment;
	private Certification siteCertification;
	private String siteCertName;
	private Client client;
	private String serviceDeliveryType;
	private String openStatusSubType;
	private Location closestAirport;
	private double distanceToClosestAirport;
	private HashMap<String, Double> flyingTimes;
	private String schedulerName;
	private String schedulingOwnership;
	private String opportunityName;
	private double opportunityProbability;
	private WorkItemSource workItemSource = WorkItemSource.COMPASS_PIPELINE;
	private double costOfNotAllocating = 0;
	
	public WorkItem(ResultSet rs, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException, ParseException {
		setId(rs.getString("wi_id"));
		setName(rs.getString("wi_name"));
		setWorkItemSource(WorkItemSource.COMPASS_WORK_ITEM);
		setLastModified(new Date(rs.getTimestamp("wi_LastModifiedDate").getTime()));
		this.requiredCompetencies = new ArrayList<Competency>();
		if (rs.getTimestamp("wi_Service_target_date__c")!= null) {
			this.targetDate = new Date(rs.getTimestamp("wi_Service_target_date__c").getTime());
		} else {
			this.targetDate = new Date(rs.getTimestamp("wi_Work_Item_Date__c").getTime());
			Utility.getLogger().error("Work Item with null Service_target_date__c");
		}
		if (rs.getTimestamp("wi_Work_Item_Date__c")!=null)
			this.startDate = new Date(rs.getTimestamp("wi_Work_Item_Date__c").getTime());
		else
			Utility.getLogger().error("Work Item with null Work_Item_Date__c");
		this.localStatus = WorkItemStatus.OPEN;
		this.setSfStatus(rs.getString("wi_Status__c"));
		this.allocatedResources = new ArrayList<Resource>();
		this.requiredDuration = rs.getDouble("wi_Required_Duration__c");
		this.serviceDeliveryType = rs.getString("wi_Service_Delivery_Type__c");
		this.clientSite = new Location();
		clientSite.setId(rs.getString("site_Id"));
		clientSite.setName(rs.getString("site_Name"));
		clientSite.setAddress_1(rs.getString("site_Business_Address_1__c"));
		clientSite.setAddress_2(rs.getString("site_Business_Address_2__c"));
		clientSite.setAddress_3(rs.getString("site_Business_Address_3__c"));
		clientSite.setCity(rs.getString("site_Business_City__c"));
		clientSite.setCountry(rs.getString("site_country"));
		clientSite.setStateDescription(rs.getString("site_state_description"));
		clientSite.setState(rs.getString("site_state"));
		clientSite.setPostCode(rs.getString("site_Business_Zip_Postal_Code__c"));
		clientSite.setContact_name(rs.getString("contact_name"));
		clientSite.setContact_title(rs.getString("contact_Title"));
		clientSite.setContact_email(rs.getString("contact_Email"));
		clientSite.setContact_phone(rs.getString("contact_Phone"));
		clientSite.setTimeZone(TimeZone.getTimeZone(rs.getString("site_Time_Zone__c")));
		if (rs.getString("SiteContacts")!=null) {
			clientSite.setContactsText(rs.getString("SiteContacts").split(","));
		}
		this.revenueOwnership = CompassRevenueOwnership.getValueForName(rs.getString("wi_Revenue_Ownership__c"));
		this.schedulerName = rs.getString("SchedulerName");
		this.schedulingOwnership = rs.getString("sc_Operational_Ownership__c");
		this.revenueOwnershipName = this.revenueOwnership.getName();
		this.type = SFWorkItemType.getValueForName(rs.getString("wi_Work_Item_Stage__c"));
		this.comment = rs.getString("wi_Comments__c");
		this.siteCertification = new Certification();
		this.siteCertification.setId(rs.getString("sc_id"));
		this.siteCertification.setName(rs.getString("sc_name"));
		this.siteCertification.bops = new ArrayList<BlackoutPeriod>();
		if(rs.getString("bops")!=null) {
			String[] bopsArray = rs.getString("bops").split(",");
			for (int i = 0; i < bopsArray.length; i++) {
				String[] bopParts = bopsArray[i].split(";");
				if(bopParts.length==2) {
					this.siteCertification.bops.add(new BlackoutPeriod(bopParts[0], bopParts[1]));
				} 
			}
		}
		this.client = new Client();
		this.client.setName(rs.getString("client_name"));
		this.client.setId(rs.getString("client_id"));
		this.setOpenStatusSubType(rs.getString("wi_Open_Sub_Status__c"));
		this.flyingTimes = new HashMap<String, Double>();
		clientSite.setLatitude(rs.getDouble("c_latitude"));
		clientSite.setLongitude(rs.getDouble("c_longitude"));
		if(rs.getDouble("c_Latitude")==0 || rs.getDouble("c_Longitude")==0) {
			clientSite.setLatitude(rs.getDouble("site_latitude__c"));
			clientSite.setLongitude(rs.getDouble("site_longitude__c"));
			// Latitude and Longitude from Compass are not reliable.  Using Geocoding API with local cache
			LatLng coordinates = null;
			try {
				coordinates = Utility.getGeocode(clientSite, db);
				if (coordinates != null) {
					clientSite.setLatitude(coordinates.getLat().doubleValue());
					clientSite.setLongitude(coordinates.getLng().doubleValue());
				}
			} catch (GeoCodeApiException gcae) {
				// Ignore and Carry on.  Can't stop the world because we can't get geocodes :)
			}
		}
		
		// Set preferred resources.
		this.setPreferredResourceIds(new String[] {rs.getString("sc_Preferred_Resource_1__c"), rs.getString("sc_Preferred_Resource_1__c"), rs.getString("sc_Preferred_Resource_1__c")});
		
		// Set Competencies
		List<Competency> requiredCompetencies = new ArrayList<Competency>();
		requiredCompetencies.add(new Competency(rs.getString("PrimaryStandardId"), rs.getString("PrimaryStandard"), CompetencyType.PRIMARYSTANDARD, null));
		if (rs.getString("FoSIds")!=null) {
			String[] fosIds = rs.getString("FoSIds").split(",");
			String[] fos = rs.getString("FoS").split(",");
			int index = 0;
			for (String fosId : fosIds) {
				requiredCompetencies.add(new Competency(fosId, fos[index++], CompetencyType.STANDARD, null));
			}
		}
		if (rs.getString("CodesIds")!=null) {
			String[] codesIds = rs.getString("CodesIds").split(",");
			String[] codes = rs.getString("Codes").split(",");
			int index = 0;
			for (String codeId : codesIds) {
				requiredCompetencies.add(new Competency(codeId, codes[index++], CompetencyType.CODE, null));
			}
		}
		this.setRequiredCompetencies(requiredCompetencies);
	}
	
	public void initPreferredResources(DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		if (preferredResourceIds != null) {
			preferredResourceNames = new String[preferredResourceIds.length];
			for (int i=0; i<preferredResourceIds.length; i++) {
				if ((preferredResourceIds[i] != null) && (!preferredResourceIds[i].isEmpty())) {
					String query = "SELECT r.Name as 'r-name', r.Id as 'r-Id' FROM " + db.getDBTableName("Resource__c") + " r where r.Id = '" + preferredResourceIds[i] + "'";
					ResultSet rs = db.executeSelectThreadSafe(query, -1);
					while (rs.next()) {
						preferredResourceNames[i] = rs.getString("r-Name");
					}
				}
			}
		}
	}
	
	public void add(WorkItem wi) {
		if (getId()==null) {
			setId(wi.getId());
			setName(wi.getName());
			workItemSource = wi.getWorkItemSource();
			requiredCompetencies = wi.getRequiredCompetencies();
			localStatus = wi.getLocalStatus();
			targetDate = wi.getTargetDate();
			startDate = wi.getStartDate();
			allocatedResources = wi.getAllocatedResources();
			sfStatus = getSfStatus();
			requiredDuration = wi.getRequiredDuration();
			frequencyOfCapabilities = wi.getFrequencyOfCapabilities();
			clientSite = wi.getClientSite();
			revenueOwnership = wi.getRevenueOwnership();
			revenueOwnershipName = wi.getRevenueOwnershipName();
			type =  wi.getType();
			preferredResourceIds = wi.getPreferredResourceIds();
			preferredResourceNames = wi.getPreferredResourceNames();
			comment = wi.getComment();
			siteCertification = wi.getSiteCertification();
			siteCertName = wi.getSiteCertName();
			client = wi.getClient();
			serviceDeliveryType = wi.getServiceDeliveryType();
			openStatusSubType = wi.getOpenStatusSubType();
			closestAirport = wi.closestAirport;
			schedulerName = wi.getSchedulerName();
			schedulingOwnership = wi.getSchedulingOwnership();
			opportunityName = wi.getOpportunityName();
			opportunityProbability = wi.getOpportunityProbability();
		} else {
			requiredCompetencies.addAll(wi.getRequiredCompetencies());
			requiredDuration+=wi.getRequiredDuration();
			setName(getName() + "," + wi.getName());
			setId(getId() + "," + wi.getId());
		}
    }

    public WorkItem combine(WorkItem wi) {
    	
    	requiredCompetencies.addAll(wi.getRequiredCompetencies());
    	requiredDuration+=wi.getRequiredDuration();
    	setName(getName() + "," + wi.getName());
		setId(getId() + "," + wi.getId());
        return this;
    }
    
	public String getClientLocation() {
		return this.getClientSite().getFullAddress();
	}
	
	public String getClientLocationAndTargetDate() {
		return this.getClientSite().getFullAddress()+this.getTargetDate();
	}
	
	public WorkItem() {
		this.flyingTimes = new HashMap<String, Double>();
	}

	public List<Competency> getRequiredCompetencies() {
		return requiredCompetencies;
	}

	public void setRequiredCompetencies(List<Competency> requiredCompetencies) {
		Collections.sort(requiredCompetencies);
		this.requiredCompetencies = requiredCompetencies;
	}

	public WorkItemStatus getLocalStatus() {
		return localStatus;
	}

	public void setLocalStatus(WorkItemStatus localStatus) {
		this.localStatus = localStatus;
	}

	public Date getTargetDate() {
		return targetDate;
	}
	public Date getSearchResourceStartDate() {
		Calendar auxCal = new GregorianCalendar();
		if (getStartDate() == null)
			return new Date();
		
		auxCal.setTime(getStartDate());
		if (auxCal.before(Utility.getNow()))
			auxCal.setTime(new Date());
		return auxCal.getTime();
	}
	public void setTargetDate(Date targetDate) {
		this.targetDate = targetDate;
	}

	@XmlElement(name="Resource")
	public List<Resource> getAllocatedResources() {
		return allocatedResources;
	}

	public void setAllocatedResources(List<Resource> allocatedResources) {
		this.allocatedResources = allocatedResources;
	}

	public Date getStartDate() {
		return startDate;
	}
	
	public Calendar getStartDateCalendar() {
		if(startDate == null) 
			return null;
		Calendar startDateCalendar = Calendar.getInstance();
		startDateCalendar.setTime(startDate);
		return startDateCalendar;
	}

	public void setStartDate(Date startDate) {
		this.startDate = startDate;
	}

	public String getSfStausAsString() {
		return sfStatus==null?"":sfStatus.getName();
	}

	public void setSfStatus(String sfStaus) {
		this.sfStatus = SfWorkItemStatus.getValueForName(sfStaus);
	}
	
	public String toString() {
		String retValue = getId() + "-" + getName() + "-" + getSfStausAsString() + "-Competencies Required:";
		for (Competency aCompetency : getRequiredCompetencies()) {
			retValue += "-" + aCompetency.getCompetencyName();
		}
		return retValue;
	}

	public double getRequiredDuration() {
		return requiredDuration;
	}

	public void setRequiredDuration(double requiredDuration) {
		this.requiredDuration = requiredDuration;
	}

	@Override 
	public boolean equals(Object o) {
		if((o instanceof WorkItem) && ((WorkItem)o).getId().equals(this.getId()))
			return true;
		return false;
	}
	
	@Override
	public int compareTo(WorkItem o) {
		if (this.getFrequencyOfCapabilities()>o.getFrequencyOfCapabilities())
			return 1;
		if (this.getFrequencyOfCapabilities()<o.getFrequencyOfCapabilities())
			return -1;
		return 0;//(this.getSiteCertification().getName()+(this.getType().equals(SFWorkItemType.FollowUp)?"-FollowUp":"")).compareTo(o.getSiteCertification().getName()+(o.getType().equals(SFWorkItemType.FollowUp)?"-FollowUp":""));
	}

	public int getFrequencyOfCapabilities() {
		return frequencyOfCapabilities;
	}

	public void setFrequencyOfCapabilities(int frequencyOfCapabilities) {
		this.frequencyOfCapabilities = frequencyOfCapabilities;
	}
	
	public String getRequiredCompetenciesString() {
		String aCompetenciesString = "";
		if(this.requiredCompetencies == null)
			return aCompetenciesString;
		for (Competency competency : this.requiredCompetencies) {
			aCompetenciesString += competency.getCompetencyName() + ",";
		}
		return aCompetenciesString;
	}

	public Location getClientSite() {
		return clientSite;
	}

	public void setClientSite(Location clientSite) {
		this.clientSite = clientSite;
	}
	
	public Competency getPrimaryStandard() {
		if(this.getRequiredCompetencies() == null)
			return null;
		for (Competency aCompetency : this.getRequiredCompetencies()) {
			if (aCompetency.getType().equals(CompetencyType.PRIMARYSTANDARD))
				return aCompetency;
		}
		return null;
	}

	public CompassRevenueOwnership getRevenueOwnership() {
		return revenueOwnership;
	}
	
	public void setRevenueOwnership(CompassRevenueOwnership revenueOwnership) {
		this.revenueOwnership = revenueOwnership;
		this.revenueOwnershipName = this.revenueOwnership.getName();
	}

	public SFWorkItemType getType() {
		return type;
	}

	public void setType(SFWorkItemType type) {
		this.type = type;
	}

	public String[] getPreferredResourceIds() {
		return preferredResourceIds;
	}

	public void setPreferredResourceIds(String[] preferredResource) {
		this.preferredResourceIds = preferredResource;
	}

	public String getComment() {
		return comment;
	}

	public void setComment(String comment) {
		this.comment = comment;
	}

	public Certification getSiteCertification() {
		return siteCertification;
	}

	public void setSiteCertificationName(Certification siteCertificationName) {
		this.siteCertification = siteCertificationName;
	}

	@XmlTransient
	public Client getClient() {
		return client;
	}

	public void setClient(Client client) {
		this.client = client;
	}

	public String getOpenStatusSubType() {
		return openStatusSubType;
	}

	public void setOpenStatusSubType(String openStatusSubType) {
		this.openStatusSubType = openStatusSubType;
	}

	public String getRevenueOwnershipName() {
		return revenueOwnershipName;
	}

	public void setRevenueOwnershipName(String revenueOwnershipName) throws Exception {
		throw new Exception("Do not call this.  It is only for JAXB to serialize revenueOwnershipName property");
	}
	
	public Location getClosestAirport(DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		if (closestAirport==null)
			closestAirport = Utility.getClosestAirport(this.getClientSite(), db);
		
		return closestAirport;
	}
	
	public double getDistanceToClosestAirport(DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		if (distanceToClosestAirport <= 0)
			distanceToClosestAirport = Utility.calculateDistanceKm(this.getClientSite(), this.getClosestAirport(db), db);
		
		return distanceToClosestAirport;
	}
	
	public double getFlyingTimeFrom(SfSaigOffice office, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		if (!flyingTimes.containsKey(office.getName())) {
			double flyTravelTime = db.getFlyingTimeMin(this.getClosestAirport(db).getName(), office);
			if (flyTravelTime<0) {
				// Could not match airport with office ... Something wrong here
				Utility.getLogger().error("To investigate this... table saig_travel_airports is missing some records. Airport:" + getClosestAirport(db).getName() + ". Office: " + office.toString());
				// Fall back to heuristic distance/700
				Utility.getLogger().info("Using heuristic. Time(min) = distance(km)/700(km/h)*60");
				flyTravelTime = Utility.calculateDistanceKm(getClosestAirport(db), office.getLocation(), db)/700*60;
			}
			// Add additional times 
			// (please refer to Travel guidelines: https://ourgateway.assurance.saiglobal.com/Document%20Centre/Document%20Centre/Travel%20Guidelines%20for%20Scheduling%20Assurance%20Services%20Australia.xlsx)
			flyTravelTime += (30 +45 + Utility.addDrivingFatiguePolicyBreaks(getDistanceToClosestAirport(db)/50))*2;

			flyingTimes.put(office.getName(), new Double(Math.round(flyTravelTime/15)*15/60));
		}
		return flyingTimes.get(office.getName());
	}
	
	public SfWorkItemStatus getSfStatus() {
		return sfStatus;
	}

	public void setSfStatus(SfWorkItemStatus sfStatus) {
		this.sfStatus = sfStatus;
	}

	public String getSiteCertName() {
		return siteCertName;
	}

	public void setSiteCertName(String siteCertName) {
		this.siteCertName = siteCertName;
	}

	public String getSchedulerName() {
		return schedulerName;
	}

	public void setSchedulerName(String schedulerName) {
		this.schedulerName = schedulerName;
	}

	public String getSchedulingOwnership() {
		return schedulingOwnership;
	}

	public void setSchedulingOwnership(String schedulingOwnership) {
		this.schedulingOwnership = schedulingOwnership;
	}

	public String getOpportunityName() {
		return opportunityName;
	}

	public void setOpportunityName(String opportunityName) {
		this.opportunityName = opportunityName;
	}

	public double getOpportunityProbability() {
		return opportunityProbability;
	}

	public void setOpportunityProbability(double opportunityProbability) {
		this.opportunityProbability = opportunityProbability;
	}

	public String[] getPreferredResourceNames() {
		return preferredResourceNames;
	}

	public void setPreferredResourceNames(String[] preferredResourceNames) {
		this.preferredResourceNames = preferredResourceNames;
	}

	public String getServiceDeliveryType() {
		return serviceDeliveryType;
	}

	public void setServiceDeliveryType(String serviceDeliveryType) {
		this.serviceDeliveryType = serviceDeliveryType;
	}

	public WorkItemSource getWorkItemSource() {
		return workItemSource;
	}

	public void setWorkItemSource(WorkItemSource workItemSource) {
		this.workItemSource = workItemSource;
	}

	public Date getStartAuditWindow() {
		return startAuditWindow;
	}

	public void setStartAuditWindow(Date startAuditWindow) {
		this.startAuditWindow = startAuditWindow;
	}

	public Date getEndAuditWindow() {
		return endAuditWindow;
	}

	public void setEndAuditWindow(Date endAuditWindow) {
		this.endAuditWindow = endAuditWindow;
	}

	public double getCostOfNotAllocating() {
		return costOfNotAllocating;
	}

	public void setCostOfNotAllocating(double costOfNotAllocating) {
		this.costOfNotAllocating = costOfNotAllocating;
	}

	public boolean isPrimary() {
		return isPrimary;
	}

	public void setPrimary(boolean primary) {
		this.isPrimary = primary;
	}

	public List<WorkItem> getLinkedWorkItems() {
		return linkedWorkItems;
	}

	public void setLinkedWorkItems(List<WorkItem> linkedWorkItems) {
		this.linkedWorkItems = linkedWorkItems;
	}

	public boolean isLog() {
		return log;
	}

	public void setLog(boolean log) {
		this.log = log;
	}
}
