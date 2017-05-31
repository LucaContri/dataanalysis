package com.saiglobal.sf.api.handlers;

import java.io.StringWriter;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.code.geocoder.model.GeocoderStatus;
import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.WorkItem;

public class HandlerOpportunity {
	private static final String stylesheet = "./scheduling_api_opportunity.xsl";
	private static final SfResourceCompetencyRankType[] requiredRanks = new SfResourceCompetencyRankType[] {
		SfResourceCompetencyRankType.Auditor,
		SfResourceCompetencyRankType.LeadAuditor
	};
	private static final int availabilityWindowBeforeTarget = 0;
	private static final int availabilityWindowAfterTarget = 2;
	private static final int maxResourceToDisplay = 10;

	public static Object handle(HttpServletRequest request, HttpServletResponse response, String oppLineItemId, String opportunityName, DbHelper db, boolean debug)
	{
		Utility.startTimeCounter("handle");
		response.setContentType("text/xml");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			if ((oppLineItemId != null) && (oppLineItemId != "")) {
				WorkItem match = db.getOpportunityLineItemAsWorkItem(oppLineItemId);
				match.setAllocatedResources(Utility.getResourcesForWorkItem(match, db, debug, requiredRanks, availabilityWindowBeforeTarget, availabilityWindowAfterTarget, maxResourceToDisplay));
				return Utility.serializeWorkItemResponse(match, db, stylesheet,0,0);
			}
			
			if (opportunityName == null) {
				response.setStatus(200); // 404 Not found
                return Utility.serializeErrorResponse("Not Found", debug);
			}
			List<WorkItem> matches = db.searchOpportunity(opportunityName);
			if (matches.size()==0) {
				response.setStatus(200); // 404 Not found
                return Utility.serializeErrorResponse("Work Item " + opportunityName + " not found", debug);
			}
			
			// Returns list to select from
			Utility.stopTimeCounter("handle");
			return Utility.serializeSearchResponse(matches, stylesheet);
			
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
