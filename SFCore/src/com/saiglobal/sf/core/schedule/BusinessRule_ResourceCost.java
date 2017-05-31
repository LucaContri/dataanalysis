package com.saiglobal.sf.core.schedule;



import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_ResourceCost extends AbstractBusinessRule {

	private static final double contractor_hourly_rate = 100;
	private static final double fte_hourly_rate = 600/8;
	private static final Logger logger = Logger.getLogger(BusinessRule_ResourceCost.class);
	public BusinessRule_ResourceCost(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_ResourceCost");
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
		
		String query = "SELECT " +
				"r.Id, " +
				"r.Resource_Type__c " +
				"FROM resource__c r " +
				db.getWhereClause(whereClauseList);
		
		ResultSet rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setId(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getString("r.Resource_Type__c"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		} else {
			while (rs.next()) {
				Resource resource = resourceIdWithScore.get(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getString("r.Resource_Type__c"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		}
		
		Utility.stopTimeCounter("BusinessRule_ResourceCost");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}
	
	private void updateScore(Resource resource, WorkItem workItem, String resourceType) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		if (resource.getScore() == null)
			resource.setScore(new Double(0));
		
		if (resourceType.equalsIgnoreCase(SfResourceType.Employee.getName())) {
			// Employee 
			resource.setScore(new Double(resource.getScore() + workItem.getRequiredDuration()*fte_hourly_rate));
			resource.setResourceCost(new Double(workItem.getRequiredDuration()*fte_hourly_rate));			
		} else {
			// Contractor
			resource.setScore(new Double(resource.getScore() + workItem.getRequiredDuration()*contractor_hourly_rate));
			resource.setResourceCost(workItem.getRequiredDuration()*contractor_hourly_rate);
		}
	}
}
