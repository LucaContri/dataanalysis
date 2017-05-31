package com.saiglobal.sf.core.schedule;



import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_FixedResource extends AbstractBusinessRule {

	private static final Logger logger = Logger.getLogger(BusinessRule_FixedResource.class);
	public BusinessRule_FixedResource(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_FixedResource");
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		String fixedResourceId = getFixedResource(workItem);
		if (fixedResourceId != null) {
			if (emptyInput || (resourceIdWithScore.get(fixedResourceId)==null)) {
				Resource resource = new Resource();
				resource.setScore(new Double(0));
				resource.setId(fixedResourceId);
				filteredResources.put(fixedResourceId, resource);
			} else {
				filteredResources.put(fixedResourceId, resourceIdWithScore.get(fixedResourceId));
			}
		} else {
			if (emptyInput) {
				// Initialise and return all resources... Someone else will filter them
				String query = "select r.Id " +
						"from resource__c r";
				
				ResultSet rs = db.executeSelect(query, -1);
				
				while (rs.next()) {
					Resource resource = new Resource();
					resource.setScore(new Double(0));
					resource.setId(rs.getString("r.Id"));
					filteredResources.put(rs.getString("r.Id"), resource);
				}
			} else {
				// Return input list
				filteredResources = resourceIdWithScore;
			}
		}
		
		Utility.stopTimeCounter("BusinessRule_FixedResource");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}

	private String getFixedResource(WorkItem workItem) {
		// TODO: Figure out how determine if a work item has a fixed resource
		return null;
	}
}
