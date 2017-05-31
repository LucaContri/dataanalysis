package com.saiglobal.sf.core.schedule;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfResourceCompetencyRankType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_Capability extends AbstractBusinessRule {
	private static final Logger logger = Logger.getLogger(BusinessRule_Capability.class);
	private String requireRanksWhereClause; 
	public BusinessRule_Capability(DbHelper db, SfResourceCompetencyRankType[] requiredRanks) {
		super(db);
		if ((requiredRanks != null) && (requiredRanks.length>0)) {
			boolean first = true;
			for (SfResourceCompetencyRankType aRank : requiredRanks) {
				if (first) {
					requireRanksWhereClause = " (rc.Rank__c LIKE '%" + aRank.getName() + "%'";
					first = false;
				} else {
					requireRanksWhereClause += " OR rc.Rank__c LIKE '%" + aRank.getName() + "%'";
				}
			}
			// Rank apply to standard only???
			requireRanksWhereClause += " OR rc.Code__c IS NOT NULL)";
		} else {
			requireRanksWhereClause = null;
		}
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws Exception {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_Capability");
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		String competencyListQuery = "";
		boolean first = true;
		int competencyCount = 0;
		for (Competency competency : workItem.getRequiredCompetencies()) {
			if (competency.getType().equals(CompetencyType.NO_CODE_AVAILABLE)) {
				// Ignore this.  It is an aux competency type meaning missing code
				continue;
			}
			competencyCount++;
			if (first) {
				competencyListQuery = "SELECT '" + competency.getCompetencyName() + "' AS 'Standard_or_Code__c'";
				first = false;		
			} else {
				competencyListQuery += " UNION SELECT '" + competency.getCompetencyName() + "' AS 'Standard_or_Code__c'";
			}
		}
		if (competencyListQuery=="") {
			Utility.getLogger().info("Something wrong here... a work item with no competencies required.  wi.Id=" + workItem.getId());
			return resourceIdWithScore;
		}
		List<String> whereClauseList = new ArrayList<String>();
		
		if (!emptyInput) {
			String resourceIdInClause = "rc.Resource__c IN (";
			first = true;
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
		whereClauseList.add(requireRanksWhereClause);
		
		String query = 
				"SELECT t3.Resource__c FROM (" +
					"SELECT t2.Resource__c, count(t2.Resource__c) AS 'CompetenciesCount' " +
					"FROM (" + competencyListQuery + ") t " +
					"LEFT JOIN (" +
					"SELECT rc.Standard_or_Code__c, rc.Resource__c " +
					"FROM " + db.getDBTableName("resource_competency__c") + " rc " +
					db.getWhereClause(whereClauseList) +
					") t2 ON t2.Standard_or_Code__c = t.Standard_or_Code__c " +
					"WHERE t2.Resource__c is not null " +
					"GROUP BY t2.Resource__c) t3 " +
				"WHERE t3.CompetenciesCount=" + competencyCount;
		
		ResultSet rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setId(rs.getString("t3.Resource__c"));
				resource.setScore(new Double(0));
				filteredResources.put(rs.getString("t3.Resource__c"), resource);
			}
		} else {
			while (rs.next()) {
				// Score Unchanged for this business rule
				//Resource resource = resourceIdWithScore.get(rs.getString("t3.Resource__c");
				//resource.setScore(resource.getScore());
				filteredResources.put(rs.getString("t3.Resource__c"), resourceIdWithScore.get(rs.getString("t3.Resource__c")));
			}
		}
		Utility.stopTimeCounter("BusinessRule_Capability");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}

}
