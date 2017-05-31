package com.saiglobal.sf.api.utility;

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

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;

import org.apache.commons.lang3.StringUtils;

import com.google.gson.Gson;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Allocation;
import com.saiglobal.sf.core.model.ApiResponse;
import com.saiglobal.sf.core.model.Certification;
import com.saiglobal.sf.core.model.Client;
import com.saiglobal.sf.core.model.ClientSite;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ResourceCalenderException;
import com.saiglobal.sf.core.model.Schedule;
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

public class Utility extends com.saiglobal.sf.core.utility.Utility {
	
	private static final String header = String.format(
			"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
			+"<?xml-stylesheet type='text/xsl' href='%s'?>\n",
			"./scheduling_api_response.xsl"
			);
	
	private static final String headerDebug = String.format(
			"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
			+"<?xml-stylesheet type='text/xsl' href='%s'?>\n"
			,"./scheduling_api_response_debug.xsl"
			);
	
	private static String getHeader(String stylesheet) {
		if ((stylesheet == null) || (stylesheet == ""))
			return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
			
		return String.format(
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
				+"<?xml-stylesheet type='text/xsl' href='%s'?>\n"
				,stylesheet
				);
	}
	
	public static String serializeWorkItemResponse(WorkItem workItem, DbHelper db, boolean debug, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Serialize resources in either json or xml and return
		startTimeCounter("Utility.serializeWorkItem");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
		
		m.marshal(createResponse(workItem, db, availabilityWindowBeforeTarget, availabilityWindowAfterTarget), sw);
		String result = sw.toString();
		stopTimeCounter("Utility.serializeWorkItem");
		
		return (debug?headerDebug:header) + result;
	}
	
	public static String serializeWorkItemResponse(WorkItem workItem, DbHelper db, String stylesheet, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Serialize resources in either json or xml and return
		startTimeCounter("Utility.serializeWorkItem");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
		
		m.marshal(createResponse(workItem, db, availabilityWindowBeforeTarget, availabilityWindowAfterTarget), sw);
		String result = sw.toString();
		stopTimeCounter("Utility.serializeWorkItem");
		
		return getHeader(stylesheet) + result;
	}
	
	public static String serializeAuditorSearchResponse(WorkItem fakeWorkItem, DbHelper db, String stylesheet, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, List<Competency> standards, List<Competency> codes, List<String> messages) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Serialize resources to xml and return
		startTimeCounter("Utility.serializeAuditorSearch");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
		
		m.marshal(createResponseForAuditorSearch(fakeWorkItem, availabilityWindowBeforeTarget, availabilityWindowAfterTarget, db, messages), sw);
		String result = sw.toString();
		stopTimeCounter("Utility.serializeAuditorSearch");
		
		return getHeader(stylesheet) + result;
	}
	
	public static String serializeAuditorSearchResponseToJson(WorkItem fakeWorkItem, DbHelper db, String stylesheet, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, List<String> messages) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Serialize resources to json and return
		startTimeCounter("Utility.serializeAuditorSearch");
		Gson gson = new Gson();
		String result = gson.toJson(createResponseForAuditorSearch(fakeWorkItem, availabilityWindowBeforeTarget, availabilityWindowAfterTarget, db,messages));
		stopTimeCounter("Utility.serializeAuditorSearch");
		
		return result;
	}
	
	public static String serializeAllocationResponse(Allocation allocation, DbHelper db) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		startTimeCounter("Utility.serializeAllocation");
		StringWriter sw = new StringWriter();
		
		if (allocation.getAllocation() != null) {
			sw.write(allocationHeader);
			int size = allocation.getAllocation().size();
			/*
			sw.write(scriptTimelineHeader);
			for (int i = 0; i < size; i++) {
				Schedule scheduleItem = allocation.getAllocation().get(i);
				
				sw.write("[ '" + Utility.addSlashes(scheduleItem.getResourceName()) + "', '" + (scheduleItem.getWorkItemName()==null?scheduleItem.getSfSubType():scheduleItem.getSfSubType()+" - " + scheduleItem.getWorkItemName()) + "', new Date(" + scheduleItem.getStartDate().getTime() + "), new Date(" + scheduleItem.getEndDate().getTime() + ")] ");
				if (i<size-1) {
					sw.write(",\n ");
				}
			}
			sw.write(scriptTimelineFooter);
			*/
			sw.write(scriptMapHeader);
			
			//[37.4232, -122.0853, 'Work'],[37.4289, -122.1697, 'University'],[37.6153, -122.3900, 'Airport'],[37.4422, -122.1731, 'Shopping']
			for (int i = 0; i < size; i++) {
				Schedule scheduleItem = allocation.getAllocation().get(i);
				if (scheduleItem.getSfSubType().equalsIgnoreCase("Audit") && (scheduleItem.getWorkItemName() != null) && (scheduleItem.getLongitude()!=0) && (scheduleItem.getLatitude()!=0)) 
					sw.write("[ " + scheduleItem.getLatitude() + ", " + scheduleItem.getLongitude() + ", '" + scheduleItem.getWorkItemName() + "'], \n");
				//if (i<size-1) {
				//	sw.write(",\n ");
				//}
			}
			
			sw.write(scriptMapFooter);
			
			sw.write("</head><body>\n");
			// List Totals
			sw.write("\n<table class=\"details\">\n");
			for (String key : allocation.getTotals().keySet()) {
				sw.write("<tr>\n");
				sw.write("<td class=\"details\">" + key + "</td>\n");
				sw.write("<td class=\"details_data\">" +allocation.getTotals().get(key) + "</td>\n");
				sw.write("</tr>\n");
			}
			sw.write("</table>");
			
			sw.write(allocationFooter);
		}
		
		String result = sw.toString();
		stopTimeCounter("Utitlity.serializeAllocation");
		
		return result;
		//return getHeader(null) + result;
	}
	public static ApiResponse createResponse(WorkItem workItem, DbHelper db, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Certification siteCertResponse = workItem.getSiteCertification();
		if (siteCertResponse == null)
			siteCertResponse = new Certification();
		siteCertResponse.workItems = new ArrayList<WorkItem>();
		siteCertResponse.workItems.add(workItem);
		ClientSite clientSiteResponse = new ClientSite();
		clientSiteResponse.setLocation(workItem.getClientSite());
		List<Certification> siteCertifications = new ArrayList<Certification>();
		siteCertifications.add(siteCertResponse);
		clientSiteResponse.setSiteCertifications(siteCertifications);
		//clientSiteResponse.setClosestAirport(Utility.getClosestAirport(clientSiteResponse.getLocation(), db));
		//clientSiteResponse.setDistanceToClosestAirport(Utility.calculateDistanceKm(clientSiteResponse.getClosestAirport(), clientSiteResponse.getLocation(), db));
		Client clientResponse = workItem.getClient();
		List<ClientSite> clientSites = new ArrayList<ClientSite>();
		clientSites.add(clientSiteResponse);
		clientResponse.setClientSites(clientSites);
		ApiResponse responseObject = new ApiResponse();
		responseObject.client = new ArrayList<Client>();
		responseObject.client.add(clientResponse);
		responseObject.previousPeriodUrl = "?id=" + workItem.getId() + "&availabilityWindowBeforeTarget=" + (availabilityWindowBeforeTarget+1) + "&availabilityWindowAfterTarget=" + (availabilityWindowAfterTarget);
		responseObject.nextPeriodUrl = "?id=" + workItem.getId() + "&availabilityWindowBeforeTarget=" + (availabilityWindowBeforeTarget) + "&availabilityWindowAfterTarget=" + (availabilityWindowAfterTarget+1);
		return responseObject;
	}
	
	public static ApiResponse createResponseForAuditorSearch(WorkItem fakeWorkItem, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, DbHelper db, List<String> messages) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Certification siteCertResponse = new Certification();
		siteCertResponse.workItems = new ArrayList<WorkItem>();
		siteCertResponse.workItems.add(fakeWorkItem);
		ClientSite clientSiteResponse = new ClientSite();
		clientSiteResponse.setLocation(fakeWorkItem.getClientSite());
		List<Certification> siteCertifications = new ArrayList<Certification>();
		siteCertifications.add(siteCertResponse);
		clientSiteResponse.setSiteCertifications(siteCertifications);
		Client clientResponse = new Client();
		List<ClientSite> clientSites = new ArrayList<ClientSite>();
		clientSites.add(clientSiteResponse);
		clientResponse.setClientSites(clientSites);
		ApiResponse responseObject = new ApiResponse();
		if ((messages != null) && (messages.size() > 0)) {
			responseObject.errorMessage = StringUtils.join(messages.toArray(new String[messages.size()]),"<br>");
		} else {
			responseObject.errorMessage = "";
		}
		responseObject.client = new ArrayList<Client>();
		responseObject.client.add(clientResponse);
		responseObject.previousPeriodUrl = "?id=" + fakeWorkItem.getId() + "&availabilityWindowBeforeTarget=" + (availabilityWindowBeforeTarget+1) + "&availabilityWindowAfterTarget=" + (availabilityWindowAfterTarget);
		responseObject.nextPeriodUrl = "?id=" + fakeWorkItem.getId() + "&availabilityWindowBeforeTarget=" + (availabilityWindowBeforeTarget) + "&availabilityWindowAfterTarget=" + (availabilityWindowAfterTarget+1);
		return responseObject;
	}
	
	public static String serializeErrorResponse(String errorMessage, boolean debug) {
		startTimeCounter("Utility.serializeErrorResponse");
		StringWriter sw = new StringWriter();
		String result = "";
		try {
			JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
			Marshaller m = jc.createMarshaller();
			m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
	
			ApiResponse responseObject = new ApiResponse();
			responseObject.errorMessage	 = errorMessage;
			m.marshal(responseObject, sw);
			result = sw.toString();
		} catch (Exception e) {
			result = "Exception in serializeErrorResponse";
		}
		stopTimeCounter("handle.serializeErrorResponse");
		
		return (debug?headerDebug:header) + result;
	}
	
	public static String serializeSearchResponse(List<WorkItem> workItems, String stylesheet) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		startTimeCounter("Utility.serializeSearchResponse");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);

		ApiResponse responseObject = new ApiResponse();
		responseObject.workItems = workItems;
		m.marshal(responseObject, sw);
		String result = sw.toString();
		stopTimeCounter("handle.serializeSearchResponse");
		
		return getHeader(stylesheet) + result;
	}
	
	public static String serializeSearchResponse(List<WorkItem> workItems, boolean debug) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		startTimeCounter("Utility.serializeSearchResponse");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);

		ApiResponse responseObject = new ApiResponse();
		responseObject.workItems = workItems;
		m.marshal(responseObject, sw);
		String result = sw.toString();
		stopTimeCounter("handle.serializeSearchResponse");
		
		return (debug?headerDebug:header) + result;
	}
	
	public static List<Resource> getResourceAllocatedToWorkItem(WorkItem workItem, DbHelper db, boolean debug) throws GeoCodeApiException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, ResourceCalenderException, ParseException {
		List<Resource> resourceList = new ArrayList<Resource>();
		String query = "select r.Id, r.Name, wird.FStartDate__c " +
				"from work_item__c wi " +
				"inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id " +
				"inner join resource__c r on wir.Resource__c = r.Id " +
				"inner join work_item_resource_day__c wird on wird.Work_Item_Resource__c = wir.Id " +
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
	
	public static List<Resource> getResourcesForWorkItem(WorkItem workItem, DbHelper db, boolean debug, SfResourceCompetencyRankType[] requiredRanks, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, int maxResourceToDisplay) throws Exception {
		
		ProcessorRule[] businessRules = new ProcessorRule[] {
				new BusinessRule_SameCountry(db),
				new BusinessRule_BusinessUnit(db),
				new BusinessRule_Capability(db, requiredRanks),
				new BusinessRule_Availability(db, availabilityWindowBeforeTarget, availabilityWindowAfterTarget),
				//new BusinessRule_Availability2(db, availabilityWindowBeforeTarget, availabilityWindowAfterTarget),
				//new BusinessRule_TravelCostFromOffice(db),
				new BusinessRule_TravelCostFromHome(db),
				new BusinessRule_ResourceCost(db),
				new BusinessRule_ResourceUtilization(db, true)
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
	
	public static List<Resource> getResourcesForAuditorSearch(WorkItem fakeWorkItem, DbHelper db, boolean debug, String[] states, String[] countries, String[] requiredCompetencies, String[] types, String[] ranks, String[] inputResources, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, int maxResourceToDisplay) throws Exception {
		
		ResourceCache resourceCache = ResourceCache.getInstance(db);
		List<Resource> resources = resourceCache.getMatchingResource(states, countries, requiredCompetencies, types, ranks, inputResources);
		Calendar pointer = new GregorianCalendar();
		pointer.setTime(fakeWorkItem.getSearchResourceStartDate());
		pointer.add(Calendar.MONTH, -availabilityWindowBeforeTarget);
		Calendar startDate = new GregorianCalendar(pointer.get(Calendar.YEAR), pointer.get(Calendar.MONTH), 1);
		pointer.add(Calendar.MONTH, availabilityWindowBeforeTarget+availabilityWindowAfterTarget);
		Calendar endDate = new GregorianCalendar(pointer.get(Calendar.YEAR), pointer.get(Calendar.MONTH), pointer.getActualMaximum(Calendar.DAY_OF_MONTH));
		resources = resourceCache.getAvailableResources(resources, startDate, endDate);
		
		return resources;
	}
	
	private static final String allocationHeader = "<html><head><title>Timeline - Test</title><meta name=\"ROBOTS\" content=\"NOINDEX, NOFOLLOW\" />" +
			"<link rel=\"stylesheet\" type=\"text/css\" href=\"../scheduling_api_response.css\" />";
			
	//private static final String scriptTimelineHeader = "<script type=\"text/javascript\" src=\"https://www.google.com/jsapi?autoload={'modules':[{'name':'visualization', 'version':'1','packages':['timeline']}]}\"></script><script type=\"text/javascript\">google.setOnLoadCallback(drawChart);function drawChart() {var container = document.getElementById('example3.1');var chart = new google.visualization.Timeline(container);var dataTable = new google.visualization.DataTable();dataTable.addColumn({ type: 'string', id: 'Position' });dataTable.addColumn({ type: 'string', id: 'Name' });dataTable.addColumn({ type: 'date', id: 'Start' });dataTable.addColumn({ type: 'date', id: 'End' });dataTable.addRows([";
	//private static final String scriptTimelineFooter = " ]); chart.draw(dataTable);}</script>";
	private static final String scriptMapHeader = "<script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script><script type=\"text/javascript\">google.load(\"visualization\", \"1\", {packages:[\"map\"]});google.setOnLoadCallback(drawMap);function drawMap() {var data = google.visualization.arrayToDataTable([['Lat', 'Lon', 'Name'],";
	//private static final String scriptMapMiddle = "[37.4232, -122.0853, 'Work'],[37.4289, -122.1697, 'University'],[37.6153, -122.3900, 'Airport'],[37.4422, -122.1731, 'Shopping']";
	private static final String scriptMapFooter = " ]); var map = new google.visualization.Map(document.getElementById('map_div'));map.draw(data, {showTip: true});}</script>";
	private static final String allocationFooter = "" +
			//"<div id=\"example3.1\" style=\"width: 100%; height: 300px;\"></div>" +
			"<div id=\"map_div\" style=\"width: 100%; height: 800px\"></div>" +
			"</body></html>";
}