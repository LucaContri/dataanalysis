package com.saiglobal.sf.core.schedule;



import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_Distance extends AbstractBusinessRule {
	
	private static final Logger logger = Logger.getLogger(BusinessRule_Distance.class);
	public BusinessRule_Distance(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_Distance");
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		
		List<String> whereClauseList = new ArrayList<String>();
		if (!emptyInput) {
			String resourceIdInClause = "r.Id IN (";
			boolean first = true;
			for (String resourceId : resourceIdWithScore.keySet()) {
				if (first) {
					resourceIdInClause += "'" + resourceId + "'";
					first = false;
				} else {
					resourceIdInClause += ", '" + resourceId + "'";
				}
			}
			resourceIdInClause += ")";
			whereClauseList.add(resourceIdInClause);
		}
		if ((workItem.getClientSite()==null) || (workItem.getClientSite().getLatitude() ==0) || (workItem.getClientSite().getLongitude() ==0)) {
			logger.error("Missing client site coordinates.  Cannot calculate distance.  Returning input list unchanged");
			return resourceIdWithScore;
		}
		
		String query = "SELECT " +
				"r.Id, " +
				"DISTANCE(" + workItem.getClientSite().getLatitude() + ", " + workItem.getClientSite().getLongitude() + ", r.Latitude__c, r.Longitude__c) as 'distance' " +
				"FROM resource__c r " +
				db.getWhereClause(whereClauseList) +
				"ORDER BY `distance` asc";
		
		ResultSet rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setId(rs.getString("r.Id"));
				updateScore(resource, rs.getDouble("distance"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		} else {
			while (rs.next()) {
				Resource resource = resourceIdWithScore.get(rs.getString("r.Id"));
				updateScore(resource, rs.getDouble("distance"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		}	
		
		Utility.stopTimeCounter("BusinessRule_Distance");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}

	private void updateScore(Resource resource, Double distanceFromClient) {
		if (resource.getScore() == null)
			resource.setScore(new Double(0));
		resource.setDistanceFromClient(distanceFromClient);
	}
}
