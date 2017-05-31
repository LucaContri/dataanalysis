package com.saiglobal.sf.api.handlers;

import java.io.StringWriter;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.Utility;

import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.WorkItem;

public class HandlerWorkItem {
	private static final SfResourceCompetencyRankType[] requiredRanks = new SfResourceCompetencyRankType[] {
																				SfResourceCompetencyRankType.Auditor,
																				SfResourceCompetencyRankType.LeadAuditor
																			};
	//private static final int availabilityWindowBeforeTarget = 0;
	//private static final int availabilityWindowAfterTarget = 2;
	private static final int maxResourceToDisplay = 10;
	
	public static Object handle(HttpServletRequest request, HttpServletResponse response, String textSearch, String wiId, DbHelper db, boolean debug, int availabilityWindowBeforeTarget, int availabilityWindowAfterTarget)
	{
		Utility.startTimeCounter("handle");
		response.setContentType("text/xml");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			WorkItem workItem = null;
			if (wiId == null) {
				if (textSearch == null) {
					response.setStatus(200); // 404 Not found
	                return Utility.serializeErrorResponse("Not Found", debug);
				}
				List<WorkItem> matches = db.searchWorkItem(textSearch);
				if (matches.size()==0) {
					response.setStatus(200); // 404 Not found
	                return Utility.serializeErrorResponse("Work Item " + textSearch + " not found", debug);
				}
				if (matches.size()>1) {
					// Multiple matches.  Returns list to select from
					return Utility.serializeSearchResponse(matches, debug);
				}
				
				workItem = db.getWorkItemById(matches.get(0).getId());
			} else {
				workItem = db.getWorkItemById(wiId);
			}
			if (workItem == null)
				return Utility.serializeErrorResponse("Work Item id " + textSearch + " not found", debug);
			
			workItem.initPreferredResources(db);
			
			switch (workItem.getSfStatus()) {
			case Open:
			case Scheduled:
			case ScheduledOffered:
			case Servicechange:
			case Completed:
			case Complete:
				workItem.setAllocatedResources(Utility.getResourcesForWorkItem(workItem,db,debug, requiredRanks, availabilityWindowBeforeTarget, availabilityWindowAfterTarget, maxResourceToDisplay));
				break;
			case Cancelled:
				// Do nothing
				break;
			default:
				workItem.setAllocatedResources(Utility.getResourceAllocatedToWorkItem(workItem,db,debug));
				break;
			}
			
			Utility.stopTimeCounter("handle");
			Utility.logAllProcessingTime();
			Utility.logAllEventCounter();
			Utility.resetAllTimeCounter();
			return Utility.serializeWorkItemResponse(workItem, db, debug,availabilityWindowBeforeTarget, availabilityWindowAfterTarget);
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.getLogger().error(errorMessage, e);
		}
		
		response.setStatus(500); // 500 Internal Server Error
        return "Internal Server Error\n" + errorMessage.toString();
	} 
	

}
