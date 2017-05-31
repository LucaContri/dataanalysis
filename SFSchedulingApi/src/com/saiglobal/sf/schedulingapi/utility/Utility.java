package com.saiglobal.sf.schedulingapi.utility;

import java.io.StringWriter;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;

import com.saiglobal.sf.core.model.Allocation;
import com.saiglobal.sf.core.model.ApiResponse;
import com.saiglobal.sf.core.model.Certification;
import com.saiglobal.sf.core.model.Client;
import com.saiglobal.sf.core.model.ClientSite;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.schedulingapi.data.DbHelper;

public class Utility extends com.saiglobal.sf.core.utility.Utility {
	
	private static final String header = String.format(
			"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
			+"<?xml-stylesheet type='text/xsl' href='%s'?>\n",
			"../scheduling_api_response.xsl"
			);
	
	private static final String headerDebug = String.format(
			"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
			+"<?xml-stylesheet type='text/xsl' href='%s'?>\n"
			,"../scheduling_api_response_debug.xsl"
			);
	/*
	private static String getHeader(String stylesheet) {
		if ((stylesheet == null) || (stylesheet == ""))
			return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
			
		return String.format(
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" 
				+"<?xml-stylesheet type='text/xsl' href='../%s'?>\n"
				,stylesheet
				);
	}
	*/
	
	public static String serializeWorkItemResponse(WorkItem workItem, DbHelper db, boolean debug) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		// Serialize resources in either json or xml and return
		startTimeCounter("Utility.serializeWorkItem");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
		
		m.marshal(createResponse(workItem, db), sw);
		String result = sw.toString();
		stopTimeCounter("Utility.serializeWorkItem");
		
		return (debug?headerDebug:header) + result;
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
	public static ApiResponse createResponse(WorkItem workItem, DbHelper db) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Certification siteCertResponse = workItem.getSiteCertification();
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
		return responseObject;
	}
	
	public static String serializeErrorResponse(String errorMessage, boolean debug) throws JAXBException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		startTimeCounter("Utility.serializeErrorResponse");
		StringWriter sw = new StringWriter();
		JAXBContext jc = JAXBContext.newInstance( ApiResponse.class );
		Marshaller m = jc.createMarshaller();
		m.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);

		ApiResponse responseObject = new ApiResponse();
		responseObject.errorMessage	 = errorMessage;
		m.marshal(responseObject, sw);
		String result = sw.toString();
		stopTimeCounter("handle.serializeErrorResponse");
		
		return (debug?headerDebug:header) + result;
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