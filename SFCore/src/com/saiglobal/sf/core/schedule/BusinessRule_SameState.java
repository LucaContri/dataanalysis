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

public class BusinessRule_SameState extends AbstractBusinessRule {

	private static final Logger logger = Logger.getLogger(BusinessRule_SameState.class);
	public BusinessRule_SameState(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_SameState");
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
		if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getCountry()!=null))
			whereClauseList.add("ccs.Name='" + workItem.getClientSite().getCountry() + "'");
		if ((workItem.getClientSite()!=null) && (workItem.getClientSite().getState()!=null))
			whereClauseList.add("scs.Name='" + workItem.getClientSite().getState() + "'");
		
		String query = "select r.Id " +
				"from resource__c r " +
				"left join country_code_setup__c ccs on ccs.Id = r.Home_Country1__c " +
				"left join state_code_setup__c scs on scs.Id = r.Home_State_Province__c " +
				db.getWhereClause(whereClauseList);
		
		ResultSet rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setScore(new Double(0));
				resource.setId(rs.getString("r.Id"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		} else {
			while (rs.next()) {
				filteredResources.put(rs.getString("r.Id"), resourceIdWithScore.get(rs.getString("r.Id")));
			}
		}
	
		Utility.stopTimeCounter("BusinessRule_SameState");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}

	
}
