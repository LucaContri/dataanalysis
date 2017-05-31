package com.saiglobal.reporting.servlets;

import java.io.IOException;
import java.io.PrintWriter;
//import java.util.Map;


import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.saiglobal.reporting.utility.KPI2Handler;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class KPI2Servlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(KPI2Servlet.class);
	private static final GlobalProperties gp;
	private static KPI2Handler handler;
	private static final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	private static final SimpleDateFormat filenameDateFormat = new SimpleDateFormat("yyyy-MM-dd");
	
	static {
		// Initialise
		gp = GlobalProperties.getDefaultInstance();
		
		try {
			logger.debug("static init");
			handler = new KPI2Handler(gp);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
		
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		response.setContentType("text/json");
		boolean forceRefresh = false;
		boolean expandRegions = false;
		boolean allSLAs = false;
		String getDetails = null;
		String detailsFormat = "csv";
		String slaName = null;
		String querySLA = null;
		String queryTags = null;
		String queryRegions = null;
		Set<String> tags = new HashSet<String>();
		Calendar from = Calendar.getInstance();
		Calendar to = Calendar.getInstance();
		from.add(Calendar.MONTH, -5);
		Region region = Region.AUSTRALIA_2;
		boolean multiRegion = false;
		try {
			parameters = request.getParameterMap();			
			
			try {
				// Parse parameters
				if (parameters.get("sla")!=null && handler.hasSLA(parameters.get("sla")[0])) 
					slaName = parameters.get("sla")[0];
				
				if (parameters.containsKey("region"))
					region = Region.valueOf(parameters.get("region")[0]);
				
				if (parameters.containsKey("regionName"))
					region = Region.getRegionByName(parameters.get("regionName")[0]);
				
				if (parameters.containsKey("forceRefresh"))
					forceRefresh = Boolean.parseBoolean(parameters.get("forceRefresh")[0]);

				if (parameters.containsKey("allSLAs"))
					allSLAs = Boolean.parseBoolean(parameters.get("allSLAs")[0]);
				
				if (parameters.containsKey("expandRegions"))
					expandRegions = Boolean.parseBoolean(parameters.get("expandRegions")[0]);
				
				if (parameters.containsKey("multiRegion"))
					multiRegion = Boolean.parseBoolean(parameters.get("multiRegion")[0]);
				
				if (parameters.containsKey("querySLAs"))
					querySLA = parameters.get("querySLAs")[0];
				
				if (parameters.containsKey("queryTags"))
					queryTags = parameters.get("queryTags")[0];

				if (parameters.containsKey("queryRegions"))
					queryRegions = parameters.get("queryRegions")[0];
				
				if (parameters.containsKey("getDetails"))
					getDetails = parameters.get("getDetails")[0];
				
				if (parameters.containsKey("detailsFormat"))
					detailsFormat = parameters.get("detailsFormat")[0];

				if (parameters.containsKey("fromDate")) {
					try {
						Date fromDate = dateFormat.parse(parameters.get("fromDate")[0]);
						from.setTime(fromDate);
						logger.info("fromDate: " + Utility.getMysqldateformat().format(from.getTime()));
					} catch (Exception e) {
						// Ignore
						e.printStackTrace();
					}
				}
					
				if (parameters.containsKey("toDate")) {
					try {
						Date toDate = dateFormat.parse(parameters.get("toDate")[0]);
						to.setTime(toDate);
						logger.info("toDate param: " + parameters.get("toDate")[0]);
						logger.info("toDate: " + Utility.getMysqldateformat().format(to.getTime()));
					} catch (Exception e) {
						// Ignore
						e.printStackTrace();
					}
				}
				
				// Tags
				if (parameters.containsKey("q") && (parameters.get("q")[0] != "")) {
					String[] qs = parameters.get("q")[0].split(",");
					logger.info(parameters.get("q")[0]);
					for (String q : qs) {
						tags.add(q);
					}
				}
			} catch (Exception e) {
				//Ignore and use default
			}
			
			if (forceRefresh) {
				handler = new KPI2Handler(gp);
			}
			
			//Gson gson = new Gson();
			Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create();
			if (queryTags != null) {
				// This is a tag query.  Returns matching available Tags
				out.print(gson.toJson(handler.getMatchingTags(queryTags, multiRegion)));
			} else if (querySLA != null) {
				// This is a parameter query.  Returns matching available SLAs
				out.print(gson.toJson(handler.getMatchingSLAs(querySLA, multiRegion)));
			} else if (queryRegions != null) {
				// This is a parameter query.  Returns matching available Regions
				out.print(gson.toJson(handler.getMatchingRegions(queryRegions)));
			} else {
				if (getDetails != null && (getDetails.equalsIgnoreCase("wip") || getDetails.equalsIgnoreCase("backlog") || getDetails.equalsIgnoreCase("completed") )) {
					if (detailsFormat.equalsIgnoreCase("csv")) {
						response.setContentType("text/csv");
						if(getDetails.equalsIgnoreCase("wip") || getDetails.equalsIgnoreCase("backlog")) {
							response.setHeader("Content-Disposition", "attachment; fileName=" + slaName + ".backlog.csv");
							out.print(handler.getBacklogDataDetailsCsv(region, slaName));
						} else {
							response.setHeader("Content-Disposition", "attachment; fileName=" + slaName + ".completed." + filenameDateFormat.format(from.getTime()) + "-" + filenameDateFormat.format(to.getTime()) + ".csv");
							out.print(handler.getPerformanceDataDetailsCsv(region, slaName, from, to));
						}
					} else if (detailsFormat.equalsIgnoreCase("json")) {
						response.setContentType("text/json");
						if(getDetails.equalsIgnoreCase("wip") || getDetails.equalsIgnoreCase("backlog")) {
							out.print(gson.toJson(handler.getBacklogDataDetailsArray(region, slaName)));
						} else {
							out.print(gson.toJson(handler.getPerformanceDataDetailsArray(region, slaName, from, to)));
						}
					}
				} else {
					if (allSLAs)
						out.print(gson.toJson(handler.getAllSLADataSummary(region, from, to, expandRegions)));
					else
						out.print(gson.toJson(handler.getSLAData(region, slaName, from, to)));
				}
			}
		} catch (Exception e) {
			Utility.handleError(gp, e);
		} finally {
			handler.closeConnections();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}		
	}
}
