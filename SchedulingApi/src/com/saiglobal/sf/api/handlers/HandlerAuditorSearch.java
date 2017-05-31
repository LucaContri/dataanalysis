package com.saiglobal.sf.api.handlers;

import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.code.geocoder.model.GeocoderStatus;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.ParametersCache;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.WorkItem;

public class HandlerAuditorSearch {
	private static final String stylesheet = "./scheduling_api_auditor_search.xsl";
	private static final int maxResourceToDisplay = 10;

	private static boolean hasStandard(String[] competencies, DbHelper db) throws Exception {
		if ((competencies != null) && (competencies.length>0)) {
			ParametersCache parametersCache = ParametersCache.getInstance(db);
			for (String competency : competencies) {
				if (parametersCache.getStandardById(competency)!=null)
					return true;
			}
		}
		return false;
	}
	
	public static Object handle(HttpServletRequest request, HttpServletResponse response, String[] states, String[] countries, String[] requiredCompetencies, String[] types, String[] ranks, String[] resources, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget, DbHelper db, boolean debug, List<String> messages)
	{
		Utility.startTimeCounter("handle");
		response.setContentType("text/text");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			WorkItem fakeWorkItem = new WorkItem();
			fakeWorkItem.setId("AuditorSearchWorkItem");
			fakeWorkItem.setStartDate(new Date());
			fakeWorkItem.setRequiredDuration(8);
			Location fakeClientSite = new Location();
			fakeClientSite.setCountry("Australia");
			if ((states != null) && (states.length > 0))
				fakeClientSite.setState(states[0]);
			fakeWorkItem.setClientSite(fakeClientSite);
			if (hasStandard(requiredCompetencies,db) || (resources != null && resources.length>0)) {
				fakeWorkItem.setAllocatedResources(Utility.getResourcesForAuditorSearch(fakeWorkItem, db, debug, states, countries, requiredCompetencies, types, ranks, resources, availabilityWindowBeforeTarget, availabilityWindowAfterTarget, maxResourceToDisplay));
			} else {
				messages = new ArrayList<String>();
				messages.add("Please enter at least one standard to start the search");
			}

			return Utility.serializeAuditorSearchResponseToJson(fakeWorkItem, db, stylesheet,availabilityWindowBeforeTarget,availabilityWindowAfterTarget, messages);
			
		} catch (Exception e) {
			
			if (e instanceof GeoCodeApiException) {
				if (((GeoCodeApiException)e).getResponseStatus().equals(GeocoderStatus.OVER_QUERY_LIMIT)) {
					errorMessage.append("Cannot use Google Geo Code Api as the daily limit has been reached");
				}
			}
			com.saiglobal.sf.core.utility.Utility.getLogger().error(errorMessage, e);
		}
		
		// Exception.  Return Internal Server error
		response.setStatus(500); // 500 Internal Server Error
        return Utility.serializeErrorResponse("Internal Server Error: " + errorMessage.toString(), false);
	} 
}
