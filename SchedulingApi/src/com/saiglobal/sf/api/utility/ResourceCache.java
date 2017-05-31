package com.saiglobal.sf.api.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.TreeSet;
import java.util.concurrent.Semaphore;

import org.apache.commons.lang3.StringUtils;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.model.SimpleParameter;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.utility.Utility;

public class ResourceCache {
	private static ResourceCache reference= null;
	private static final int refreshIntervalHrs = 24;
	private DbHelper db = null;
	private Calendar lastUpdateResources;
	private Semaphore update = new Semaphore(1);
	private List<Resource> resources = new ArrayList<Resource>();
	private HashMap<String, List<CapabilityWithRanks>> resourcesCapabilities = new HashMap<String, List<CapabilityWithRanks>>();
	
	private ResourceCache(DbHelper db) {
		this.db = db;
	}

	public static ResourceCache getInstance(DbHelper db) {
		if( reference == null) {
			synchronized (  ResourceCache.class) {
			  	if( reference  == null)
			  		reference  = new ResourceCache(db);
			}
		}
		return  reference;
	}

	public List<Resource> getResources() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		update.acquire();
		if(lastUpdateResources == null || lastUpdateResources.before(intervalBefore)) {
			
			String query = "select "
					+ "r.Id as 'id', r.Name as 'name', r.Resource_Type__c as 'type', r.Reporting_Business_Units__c as 'businessUnit', "
					+ "group_concat(if (rc.Code__c is null, concat(rc.Standard__c, '-', rc.Rank__c), rc.Code__c) SEPARATOR ',') as 'capabilitiesIdsWithRanks',"
					+ "r.Home_Address_1__c, "
					+ "r.Home_Address_2__c, "
					+ "r.Home_Address_3__c, "
					+ "r.Home_City__c, "
					+ "r.Home_Postcode__c, "
					+ "s.Name as 'state', "
					+ "ccs.Name as 'Country' "
					+ "from resource__c r "
					+ "left join state_code_setup__c s on s.Id = r.Home_State_Province__c "
					+ "left join country_code_setup__c ccs on ccs.Id = r.Home_Country1__c "
					+ "left join resource_competency__c rc on rc.Resource__c = r.Id "
					+ "where "
					//+ "r.Home_Country1__c='a0Y90000000CGI8EAO' "
					+ "rc.Status__c = 'Active' "
					//+ "and (rc.Rank__c like '%Auditor%' or rc.Rank__c is null) "
					+ "group by r.Id;";
			try {
				ResultSet rs = db.executeSelect(query, -1);
				resources = new ArrayList<Resource>();
				resourcesCapabilities = new HashMap<String, List<CapabilityWithRanks>>();
				while (rs.next()) {
					Resource resource = new Resource();
					resource.setId(rs.getString("id"));
					resource.setHome(new Location("Home",rs.getString("Home_Address_1__c"),rs.getString("Home_Address_2__c"),rs.getString("Home_Address_3__c"),rs.getString("Home_City__c"),rs.getString("Country"),rs.getString("state"),rs.getString("Home_Postcode__c"),0,0));
					resource.setName(rs.getString("name"));
					resource.setType(SfResourceType.getValueForName(rs.getString("type")));
					resource.setReportingBusinessUnit(rs.getString("businessUnit"));
					List<CapabilityWithRanks> capabilitiesIdsWithRanks = new ArrayList<CapabilityWithRanks>();
					for (String capabilityWithRanksString : rs.getString("capabilitiesIdsWithRanks").split(",")) {
						String[] parts = capabilityWithRanksString.split("-");
						String capabilityId = parts[0];
						List<String> ranks = new ArrayList<String>();
						if (parts.length==2) {
							// Capability has ranks therefore is a standard
							for (String rank : parts[1].split(";")) {
								ranks.add(rank);
							}
						}
						capabilitiesIdsWithRanks.add(new CapabilityWithRanks(capabilityId, ranks));
					}
					resourcesCapabilities.put(resource.getId(), capabilitiesIdsWithRanks);
					resources.add(resource);
				}
			} catch (Exception e) {
				throw e;
			}
			lastUpdateResources = Calendar.getInstance();  
		}
		update.release();
	  return resources;
	}
	
	public List<SimpleParameter> getResourcesParameters(String search) throws Exception {
		if ((search == null) || (search == ""))
			return null;
		search = search.toLowerCase();
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		for (Resource resource : getResources()) {
			if (resource.getName().toLowerCase().contains(search))
				result.add(new SimpleParameter(resource.getName(), resource.getId()));
		}
		return result;
	}
	
	public List<Resource> getResourceByName(String search) throws Exception {
		if ((search == null) || (search == ""))
			return null;
		search = search.toLowerCase();
		List<Resource> result = new ArrayList<Resource>();
		for (Resource resource : getResources()) {
			if (resource.getName().toLowerCase().contains(search))
				result.add(resource);
		}
		return result;
	}
		
	public Resource getResourceById(String id) throws Exception {
		if ((id == null) || (id== ""))
			return null;
		for (Resource resource : getResources()) {
			if (resource.getId().equals(id))
				return resource;
		}
		return null;
	}
	
	public List<Resource> getMatchingResource(String[] states, String[] countries, String[] requiredCompetenciesIds, String[] types, String[] ranks, String[] resources) throws Exception {
		List<Resource> result = new ArrayList<Resource>();
		if ((resources == null || resources.length==0) && ((states == null) || (requiredCompetenciesIds == null) || (requiredCompetenciesIds.length==0)))
			return result;
		@SuppressWarnings("unused")
		String ranksImploded = StringUtils.join(ranks,";");
		List<String> statesList = Arrays.asList(states);
		List<String> countriesList = Arrays.asList(countries);
		List<String> typesList = Arrays.asList(types);
		List<String> resourcesList = null;
		if (resources == null)
			resourcesList = new ArrayList<String>();
		else
			resourcesList = Arrays.asList(resources);
		
		resourceLoop: for (Resource resource : getResources()) {
			// Check resources
			if (resourcesList.size()>0 && !resourcesList.contains(resource.getId()))
				continue;
			// Check types
			if (!typesList.contains(resource.getType().getName()))
				continue;
			// Check state
			if (statesList.size()>0 && !statesList.contains(resource.getHome().getState()))
				continue;
			// Check Country
			if (countriesList.size()>0 && !countriesList.contains(resource.getHome().getCountry()))
				continue;
			// Check capabilities and Ranks
			for (String competencyId : requiredCompetenciesIds) {
				if (!resourcesCapabilities.get(resource.getId()).contains(new CapabilityWithRanks(competencyId, Arrays.asList(ranks))))
					continue resourceLoop;
			}
			
			result.add(resource);
		}
		return result;
	}
	
	public List<Resource> getAvailableResources(List<Resource> inputList, Calendar startDate, Calendar endDate) throws Exception {
		Utility.startTimeCounter("ResourceCache.getAvailableResources");
		if( (inputList == null) || (inputList.size()==0))
			return null;
		List<Resource> filteredResources = new ArrayList<Resource>();
		HashMap<String, Resource> inputMap = new HashMap<String, Resource>();
		// Convert input to HashMap
		ScheduleParameters parameters = new ScheduleParameters();
		parameters.setCalendarStartDate(startDate.getTime());
		parameters.setCalendarEndDate(endDate.getTime());
		
		for (Resource resource : inputList) {
			resource.setAvailableDays(new TreeSet<String>(), parameters.getAllPeriods());
			inputMap.put(resource.getId(), resource);
		}
		
		List<String> whereClauseList1 = new ArrayList<String>();
		List<String> whereClauseList2 = new ArrayList<String>();
		
		String resourceIdInClause = "r.Id IN (";
		boolean first = true;
		for (Resource resource : inputList) {
			if (first) {
				resourceIdInClause += "'" + resource.getId() + "'";
				first = false;
			} else {
				resourceIdInClause += ", '" + resource.getId() + "'";
			}
		}
		resourceIdInClause += ")";
		whereClauseList1.add(resourceIdInClause);
		whereClauseList2.add(resourceIdInClause);
	
		whereClauseList1.add("wd.date>='" + Utility.getActivitydateformatter().format(startDate.getTime()) + "'");
		whereClauseList1.add("wd.date<='" + Utility.getActivitydateformatter().format(endDate.getTime()) + "'");
		whereClauseList2.add("e.ActivityDate>='" + Utility.getActivitydateformatter().format(startDate.getTime()) + "'");
		whereClauseList2.add("e.ActivityDate<='" + Utility.getActivitydateformatter().format(endDate.getTime()) + "'");
		whereClauseList2.add("e.IsDeleted=0");
		
		String query = "SELECT i.Id, i.date FROM" +
				" ( " +
				"SELECT wd.date, r.Id FROM " + db.getDBTableName("sf_working_days") + " wd, resource__c r " +
				db.getWhereClause(whereClauseList1) +
				") i " +
				"LEFT JOIN  " +
				"(SELECT r.Id, e.ActivityDate " +
				"FROM `event` e " +
				"INNER JOIN `resource__c` r ON r.User__c = e.OwnerId " +
				db.getWhereClause(whereClauseList2) + 
				") t ON t.ActivityDate = i.date AND t.id=i.Id " +
				"WHERE t.Id is NULL " +
				"ORDER BY i.Id;";

		try {
			ResultSet rs = db.executeSelect(query, -1);
			String currentResourceId = "";
			TreeSet<String> availableDays = new TreeSet<String>();
			while (rs.next()) {
				if (!rs.getString("i.Id").equals(currentResourceId)) {
					if (currentResourceId!="") {
						inputMap.get(currentResourceId).setAvailableDays(availableDays, parameters.getAllPeriods());
						inputMap.get(currentResourceId).getPeriods();
						filteredResources.add(inputMap.get(currentResourceId));
					}
						
					currentResourceId = rs.getString("i.Id");
					availableDays = new TreeSet<String>();	
				}
				availableDays.add(rs.getString("i.date"));
			}
			// Add last one
			inputMap.get(currentResourceId).setAvailableDays(availableDays, parameters.getAllPeriods());
			inputMap.get(currentResourceId).getPeriods();
			filteredResources.add(inputMap.get(currentResourceId));
			
		} catch (Exception e) {
			throw e;
		}
		Utility.stopTimeCounter("ResourceCache.getAvailableResources");
		return filteredResources;
	}
}

class CapabilityWithRanks {
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((capabilityId == null) ? 0 : capabilityId.hashCode());
		result = prime * result + (isCode ? 1231 : 1237);
		result = prime * result + ((ranks == null) ? 0 : ranks.hashCode());
		return result;
	}

	/*
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		CapabilityWithRanks other = (CapabilityWithRanks) obj;
		if (capabilityId == null) {
			if (other.capabilityId != null)
				return false;
		} else if (!capabilityId.equals(other.capabilityId))
			return false;
		if (isCode != other.isCode)
			return false;
		if (ranks == null) {
			if (other.ranks != null)
				return false;
		} else if (!ranks.equals(other.ranks))
			return false;
		return true;
	}
*/
	private String capabilityId;
	private List<String> ranks;
	private boolean isCode;
	
	public CapabilityWithRanks(String capabilityId, List<String> ranks) {
		this.capabilityId = capabilityId;
		this.ranks = ranks;
		if ((this.ranks == null) || (this.ranks.size()==0)) {
			isCode = true;
		} else {
			isCode = false;
		}
	}
	
	
	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null)
			return false;
		if (getClass() != o.getClass())
			return false;
		CapabilityWithRanks other = (CapabilityWithRanks) o;
		if (capabilityId == null) {
			if (other.capabilityId != null)
				return false;
		} else if (!capabilityId.equalsIgnoreCase(other.capabilityId))
			return false;
		
		if ((this.ranks == null) || (this.ranks.size() == 0) || other.isCode ) {
			// Capability is code or no ranks are required... check only capabilityId... already checked
			return true;
		} else {
			// this.ranks must match all ranks and this.capabilityId = capabilityId
			return other.ranks.containsAll(this.ranks);
		}
	}
	
}