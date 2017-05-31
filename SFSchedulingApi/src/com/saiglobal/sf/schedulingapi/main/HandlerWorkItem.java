package com.saiglobal.sf.schedulingapi.main;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ResourceCalenderException;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.schedule.BusinessRule_Availability;
import com.saiglobal.sf.core.schedule.BusinessRule_BusinessUnit;
import com.saiglobal.sf.core.schedule.BusinessRule_Capability;
import com.saiglobal.sf.core.schedule.BusinessRule_ResourceCost;
import com.saiglobal.sf.core.schedule.BusinessRule_ResourceUtilization;
import com.saiglobal.sf.core.schedule.BusinessRule_SameCountry;
import com.saiglobal.sf.core.schedule.BusinessRule_TravelCostFromHome;
import com.saiglobal.sf.core.schedule.ProcessorRule;
import com.saiglobal.sf.core.utility.ComparatorResourceScoreAsc;
import com.saiglobal.sf.schedulingapi.data.DbHelper;
import com.saiglobal.sf.schedulingapi.utility.Utility;

import spark.Request;
import spark.Response;

public class HandlerWorkItem {
	private static final SfResourceCompetencyRankType[] requiredRanks = new SfResourceCompetencyRankType[] {
																				SfResourceCompetencyRankType.Auditor,
																				SfResourceCompetencyRankType.LeadAuditor
																			};
	private static final int availabilityWindowBeforeTarget = 0;
	private static final int availabilityWindowAfterTarget = 2;
	private static final int maxResourceToDisplay = 10;
	
	public static Object handle(Request request, Response response, String workItemId, DbHelper db, boolean debug)
	{
		Utility.startTimeCounter("handle");
		response.type("text/xml");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			
			if (workItemId == null) {
				response.status(200); // 404 Not found
                return Utility.serializeErrorResponse("Not Found", debug);
			}
			List<WorkItem> matches = db.searchWorkItem(workItemId);
			if (matches.size()==0) {
				response.status(200); // 404 Not found
                return Utility.serializeErrorResponse("Work Item " + workItemId + " not found", debug);
			}
			if (matches.size()>1) {
				// Multiple matches.  Returns list to select from
				return Utility.serializeSearchResponse(matches, debug);
			}
			
			WorkItem workItem = db.getWorkItemById(matches.get(0).getId());
			workItem.initPreferredResources(db);
			
			switch (workItem.getSfStatus()) {
			case Open:
			case Scheduled:
				workItem.setAllocatedResources(getResourcesForWorkItem(workItem,db,debug));
				break;
			case Cancelled:
				// Do nothing
				break;
			default:
				workItem.setAllocatedResources(getResourceAllocatedToWorkItem(workItem,db,debug));
				break;
			}
			
			Utility.stopTimeCounter("handle");
			Utility.logAllProcessingTime();
			Utility.logAllEventCounter();
			Utility.resetAllTimeCounter();
			return Utility.serializeWorkItemResponse(workItem, db, debug);
		} catch (Exception e) {
			e.printStackTrace();
			PrintWriter pw = new PrintWriter(errorMessage);
			e.printStackTrace(pw);
		}
		
		response.status(500); // 500 Internal Server Error
        return "Internal Server Error\n" + errorMessage.toString();
	} 
	
	private static List<Resource> getResourceAllocatedToWorkItem(WorkItem workItem, DbHelper db, boolean debug) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ResourceCalenderException, ParseException, GeoCodeApiException {
		List<Resource> resourceList = new ArrayList<Resource>();
		String query = "select r.Id, r.Name, wird.FStartDate__c " +
				"from salesforce.work_item__c wi " +
				"inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id " +
				"inner join salesforce.resource__c r on wir.Resource__c = r.Id " +
				"inner join salesforce.work_item_resource_day__c wird on wird.Work_Item_Resource__c = wir.Id " +
				"where wi.Id = '" + workItem.getId() +"'";
		ResultSet rs = db.executeSelect(query, -1);
		
		Set<String> resourceIds = new HashSet<String>();
		HashMap<String, TreeSet<String>> auditDays = new HashMap<String, TreeSet<String>>();
		String fromDate = "";
		String toDate = "";
		while (rs.next()) {
			if (fromDate=="")
				fromDate = rs.getString("wird.FStartDate__c");
			if (toDate=="")
				toDate = rs.getString("wird.FStartDate__c");
			String resourceId = rs.getString("r.Id");
			resourceIds.add(resourceId);
			if (!auditDays.containsKey(resourceId))
				auditDays.put(resourceId, new TreeSet<String>());
			auditDays.get(resourceId).add(rs.getString("wird.FStartDate__c"));
			if (rs.getString("wird.FStartDate__c").compareTo(toDate)>0)
				toDate = rs.getString("wird.FStartDate__c");
			if (rs.getString("wird.FStartDate__c").compareTo(fromDate)<0)
				fromDate = rs.getString("wird.FStartDate__c");
		}
		
		// Populate resource data
		if (resourceIds.size()>0) {
			Utility.startTimeCounter("handle.populateResource");
			ScheduleParameters parameters = new ScheduleParameters();
			parameters.setResourceIds(resourceIds.toArray(new String[resourceIds.size()]));
			parameters.setCalendarStartDate(Utility.getActivitydateformatter().parse(fromDate));
			parameters.setCalendarEndDate(Utility.getActivitydateformatter().parse(toDate));
			parameters.setLoadAvailableDays(false);
			parameters.setLoadCompetencies(false);
			resourceList = db.getResourceBatch(parameters);
			for (Resource resource : resourceList) {
				resource.setAvailableDays(auditDays.get(resource.getId()), parameters.getAllPeriods());
			}
			Utility.stopTimeCounter("handle.populateResource");
		}
				
		return resourceList;
	}
	
	private static List<Resource> getResourcesForWorkItem(WorkItem workItem, DbHelper db, boolean debug) throws Exception {
		
		ProcessorRule[] businessRules = new ProcessorRule[] {
				new BusinessRule_SameCountry(db),
				new BusinessRule_BusinessUnit(db),
				new BusinessRule_Capability(db, requiredRanks),
				new BusinessRule_Availability(db, availabilityWindowBeforeTarget, availabilityWindowAfterTarget),
				//new BusinessRule_TravelCostFromOffice(db),
				new BusinessRule_TravelCostFromHome(db),
				new BusinessRule_ResourceCost(db),
				new BusinessRule_ResourceUtilization(db)
				};
		
		// Filter resources meeting business rules
		HashMap<String, Resource> filteredResources = null;
		for (ProcessorRule businessRule : businessRules) {
			filteredResources = businessRule.filter(workItem, filteredResources);
			if (filteredResources.size()==0)
				break;
		}
		
		// Sort filteredResource by score
		List<Resource> resourceList = new ArrayList<Resource>(filteredResources.values());
		
		Collections.sort(resourceList, new ComparatorResourceScoreAsc());
		
		// Filter the top x
		int toShow = Math.min(resourceList.size(), maxResourceToDisplay);
		if (debug) 
			toShow = resourceList.size();
		
		filteredResources = new HashMap<String, Resource>();
		for (int i=0; i<toShow; i++ ) {
			filteredResources.put(resourceList.get(i).getId(), resourceList.get(i));
		}
		
		// Populate resource data
		if (filteredResources.size()>0) {
			Utility.startTimeCounter("handle.populateResource");
			Calendar auxCal = new GregorianCalendar();
			auxCal.setTime(workItem.getSearchResourceStartDate());
			ScheduleParameters parameters = new ScheduleParameters();
			parameters.setResourceIds(filteredResources.keySet().toArray(new String[filteredResources.keySet().size()]));
			parameters.setLoadAvailableDays(true);
			auxCal.add(Calendar.MONTH, -availabilityWindowBeforeTarget);
			parameters.setCalendarStartDate(auxCal.getTime());
			auxCal.add(Calendar.MONTH, availabilityWindowBeforeTarget+availabilityWindowAfterTarget);
			auxCal.add(Calendar.DAY_OF_MONTH, -1);
			parameters.setCalendarEndDate(auxCal.getTime());
			parameters.setLoadCalendar(false);
			parameters.setLoadCompetencies(false);
			resourceList = db.getResourceBatch(parameters);
			Utility.stopTimeCounter("handle.populateResource");
		}
		// Set score data back and re-sort
		for (Resource resource : resourceList) {
			resource.setScore(filteredResources.get(resource.getId()).getScore());
			resource.setDistanceFromClient(filteredResources.get(resource.getId()).getDistanceFromClient());
			resource.setHomeDistanceFromClient(filteredResources.get(resource.getId()).getHomeDistanceFromClient());
			resource.setResourceCost(filteredResources.get(resource.getId()).getResourceCost());
			resource.setTravelCost(filteredResources.get(resource.getId()).getTravelCost());
			resource.setTravelType(filteredResources.get(resource.getId()).getTravelType());
			resource.setTravelTime(filteredResources.get(resource.getId()).getTravelTime());
			resource.setUtilization(filteredResources.get(resource.getId()).getUtilization());
		}
		Collections.sort(resourceList, new ComparatorResourceScoreAsc());
		
		return resourceList;
	}
}
