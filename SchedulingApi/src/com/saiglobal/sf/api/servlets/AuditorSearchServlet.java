package com.saiglobal.sf.api.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import com.saiglobal.sf.api.data.ApiRequest;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.handlers.HandlerAuditorSearch;
import com.saiglobal.sf.api.utility.ApiParameters;
import com.saiglobal.sf.api.utility.ParametersCache;
import com.saiglobal.sf.api.utility.ResourceCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfCapabilityRank;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.utility.GlobalProperties;

public class AuditorSearchServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(AuditorSearchServlet.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	private static final List<String> allStates;
	private static final List<String> allCountries;
	private static final List<String> allCountriesEMEA;
	private static final List<String> allTypes;
	private static final List<String> allRanks;
	private static ResourceCache resourceCache;
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			logger.info("static init");
			db = new DbHelper(gp);
			ParametersCache.getInstance(db);
			resourceCache = ResourceCache.getInstance(db);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
		allStates = new ArrayList<String>(Arrays.asList(new String[] {"NSW", "VIC", "QLD", "WA", "SA", "ACT", "NT", "TAS"}));
		allCountriesEMEA = new ArrayList<String>(Arrays.asList(new String[] {"Algeria","Belarus","Belgium","Czech Republic","Egypt","France","Germany","Greece","Hungary","Ireland","Italy","Kazakhstan","Kuwait","Lebanon","Netherlands","Poland","Russian Federation","Saudi Arabia","Slovenia","South Africa","Spain","Sweden","Syria","Tunisia","Turkey","Ukraine","United Arab Emirates","United Kingdom"}));
		allCountries = new ArrayList<String>(Arrays.asList(new String[] {"Argentina","Australia","Bangladesh","Canada","Chile","China","Georgia","India","Indonesia","Japan","Korea, South","Malaysia","Mexico","Mongolia","New Zealand","Singapore","Taiwan","Thailand","United States"}));
		allCountries.addAll(allCountriesEMEA);
		allTypes = new ArrayList<String>(Arrays.asList(new String[] {SfResourceType.Employee.getName(), SfResourceType.Contractor.getName(), SfResourceType.ClientServices.getName(), SfResourceType.ExternalRegulator.getName()}));
		allRanks = new ArrayList<String>(Arrays.asList(new String[] {SfCapabilityRank.Auditor.getName(), SfCapabilityRank.BusinessAdministrator.getName(), SfCapabilityRank.CertificationApprover.getName(), SfCapabilityRank.IndustryExpert.getName(), SfCapabilityRank.Inspector.getName(), SfCapabilityRank.LaboratoryAuditor.getName(), SfCapabilityRank.LeadAuditor.getName(), SfCapabilityRank.Observer.getName(), SfCapabilityRank.ProjectManager.getName(), SfCapabilityRank.Provisional.getName(), SfCapabilityRank.TechnicalAdvisor.getName(), SfCapabilityRank.TechnicalReviewer.getName(), SfCapabilityRank.VerifyingAuditor.getName()}));
	}
		
	@Override
	  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Map<String, String[]> parameters;
		PrintWriter out = response.getWriter();
		long startTime = System.currentTimeMillis();
		ApiRequest requestToLog = new ApiRequest();
		requestToLog.setRequest(request.getRequestURL()+"?"+ request.getQueryString());
		
		requestToLog.setClient(((request.getHeader("Remote_Addr")==null) || (request.getHeader("Remote_Addr")==""))?request.getHeader("HTTP_X_FORWARDED_FOR"):request.getHeader("Remote_Addr"));
		requestToLog.setOutcome("OK");
		try {
			parameters = request.getParameterMap();
			boolean debug = false;
			boolean emeaAll = false;
			int availabilityWindowAfterTarget ;
			int availabilityWindowBeforeTarget;
			List<String> states = new ArrayList<String>();
			List<String> countries = new ArrayList<String>();
			List<Integer> periodParameters = new ArrayList<Integer>();
			List<String> competencyIds = new ArrayList<String>();
			List<String> types = new ArrayList<String>();
			List<String> ranks = new ArrayList<String>();
			List<String> messages = new ArrayList<String>();
			List<String> resources = new ArrayList<String>();
			
			
			try {
				if (parameters.get(ApiParameters.q.toString())!=null && parameters.get(ApiParameters.q.toString())[0]!="") {
					String[] qs = parameters.get(ApiParameters.q.toString())[0].split(",");
					logger.info(parameters.get(ApiParameters.q.toString())[0]);
					for (String q : qs) {
						if (q.equalsIgnoreCase("EMEA")) {
							emeaAll = true;
							continue;
						}
							
						if (allStates.contains(q)) {
							states.add(q);
							continue;
						}
						if (allCountries.contains(q)) {
							countries.add(q);
							continue;
						}
						if (allTypes.contains(q)) {
							types.add(q);
							continue;
						}
						if (allRanks.contains(q)) {
							ranks.add(q);
							continue;
						}
						if (q.length()<3) {
							// Could be a month
							try {
								periodParameters.add(Integer.parseInt(q));
							} catch (NumberFormatException nfe) {
								// Ignore
							}
							continue;
						} else {
							// Could be standard, code or resource
							Resource resource = resourceCache.getResourceById(q);
							if (resource != null)
								resources.add(resource.getId());
							else 
								competencyIds.add(q);
						}
					}
				}
			} catch (Exception e) {
				
			}
			
			// Assignments & defaults
			messages.add("Defaults:");
			
			if (ranks.size()==0) {
				ranks.add(SfCapabilityRank.Auditor.getName());
				messages.add("&nbsp;&nbsp;&nbsp;Rank = 'Auditor'");
			}
			
			if (emeaAll && (countries.size()==0)) {
				// All EMEA
				countries.addAll(allCountriesEMEA);
				messages.add("&nbsp;&nbsp;&nbsp;Search all countries in EMEA");
			}
			
			if (!emeaAll && countries.size()==0) {
				// Default Australia
				countries.add("Australia");
			}
			
			if (states.size()==0 && countries.contains("Australia")) {
				states = allStates;
				messages.add("&nbsp;&nbsp;&nbsp;Search all states in Australia");
			}
			
			if (types.size()==0) {
				types.add(SfResourceType.Contractor.getName());
				types.add(SfResourceType.Employee.getName());
				messages.add("&nbsp;&nbsp;&nbsp;Search both Contractors and FTEs");
			}
			
			if (periodParameters.size()==1) {
				availabilityWindowAfterTarget = periodParameters.get(0);
				availabilityWindowBeforeTarget = -periodParameters.get(0);
			} else  if (periodParameters.size()>1) {
				int min = periodParameters.get(0);
				int max = periodParameters.get(0);
				for (Integer periodParameter : periodParameters) {
					if (periodParameter.intValue()<min)
						min = periodParameter.intValue();
					if (periodParameter.intValue()>max)
						max = periodParameter.intValue();
				}
				availabilityWindowAfterTarget = max;
				availabilityWindowBeforeTarget = -min;
			} else {
				availabilityWindowAfterTarget = 2;
				availabilityWindowBeforeTarget = 0;
			}
			if (messages.size()==1) {
				// Remove first message (header)
				messages.remove(0);
			}
				
			out.print(HandlerAuditorSearch.handle(request, response, states.toArray(new String[states.size()]), countries.toArray(new String[states.size()]), competencyIds.toArray(new String[competencyIds.size()]), types.toArray(new String[types.size()]), ranks.toArray(new String[ranks.size()]), resources.toArray(new String[resources.size()]), availabilityWindowBeforeTarget, availabilityWindowAfterTarget, db, debug, messages));
			requestToLog.setOutcome(String.valueOf(response.getStatus()));
			requestToLog.setTimeMs(System.currentTimeMillis()-startTime);
			db.logRequest(requestToLog);
			//return null;
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.handleError(gp, e);
		} finally {
			db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
		}
		
	  }
}
