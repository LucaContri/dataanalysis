package com.saiglobal.sf.core.schedule;



import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_ResourceUtilization extends AbstractBusinessRule {

	private static final Logger logger = Logger.getLogger(BusinessRule_ResourceUtilization.class);
	private final boolean useCache;
	public BusinessRule_ResourceUtilization(DbHelper db) {
		super(db);
		useCache = false;
	}
	
	public BusinessRule_ResourceUtilization(DbHelper db, boolean useCache) {
		super(db);
		this.useCache= useCache; 
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_ResourceUtilization");
		Calendar targetDate =  new GregorianCalendar();
		targetDate.setTime(workItem.getSearchResourceStartDate());

		int targetFY = targetDate.get(Calendar.YEAR);
		if (targetDate.get(Calendar.MONTH)<5)
			targetFY -= 1;
		
		Calendar startFY = new GregorianCalendar(targetFY,6,1);
		Calendar endFY = new GregorianCalendar(targetFY+1,5,30);
		
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		
		List<String> whereClauseList = new ArrayList<String>();
		List<String> whereClauseList2 = new ArrayList<String>();
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
			whereClauseList2.add(resourceIdInClause);
		}
		whereClauseList.add("e.IsDeleted=0");
		whereClauseList.add("e.ActivityDate>='" + Utility.getActivitydateformatter().format(startFY.getTime()) + "'");
		whereClauseList.add("e.ActivityDate<='" + Utility.getActivitydateformatter().format(endFY.getTime()) + "'");
		whereClauseList.add("wir.Work_Item_Type__c IN ('Audit','Travel')");
		
		String query = "";
		if (useCache) {
			whereClauseList2.add("ru.period = '" + targetFY + "-" + (targetFY+1) + "'");
			query = "SELECT " +
					"r.Id, " +
					"r.Resource_Target_Days__c, " +
					"r.Resource_Type__c, " +
					"ru.wiDays " +
					"FROM Resource__c r " +
					"LEFT JOIN saig_resource_utilization ru ON ru.id = r.Id " +
					db.getWhereClause(whereClauseList2);
		} else {
			query = "SELECT " +
					"r.Id, " +
					"r.Resource_Target_Days__c, " +
					"r.Resource_Type__c, " +
					"sum(t.DurationMin)/60/8 AS 'wiDays'" +
					"FROM Resource__c r " +
					"LEFT JOIN ( " +
						"SELECT " +
						"r.Id, " +
						"wir.Work_Item_Type__c as 'SubType', " +
						"e.DurationInMinutes as 'DurationMin', e.ActivityDate as 'Date' " +
						"FROM event e " +
						"INNER JOIN user u on u.Id = e.OwnerId " +
						"INNER JOIN Resource__c r on u.Id = r.User__c " +
						"INNER JOIN work_item_resource__c wir on wir.Id = e.WhatId " +
						db.getWhereClause(whereClauseList) +
					")  t ON t.Id = r.Id " +
					db.getWhereClause(whereClauseList2) +
					"GROUP BY r.Id, r.Resource_Target_Days__c;";
		}
		ResultSet rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setId(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getDouble("r.Resource_Target_Days__c"), rs.getDouble("wiDays"), rs.getString("r.Resource_Type__c"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		} else {
			while (rs.next()) {
				Resource resource = resourceIdWithScore.get(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getDouble("r.Resource_Target_Days__c"), rs.getDouble("wiDays"), rs.getString("r.Resource_Type__c"));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		}
		
		Utility.stopTimeCounter("BusinessRule_ResourceUtilization");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}
	
	private void updateScore(Resource resource, WorkItem workItem, double targetDays, double actualDays, String resourceType) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		if (resource.getScore() == null)
			resource.setScore(new Double(0));
		
		if (targetDays!=0)
			resource.setUtilization(actualDays/targetDays);
		else
			resource.setUtilization(0.0);
		
		// Using Utilisation as cost. Giving 100% to contractors to give preference to FTE. 
		if (resourceType.equalsIgnoreCase(SfResourceType.Employee.getName())) {
			resource.setScore(new Double(resource.getScore()+resource.getUtilization()*100));
		} else {
			resource.setScore(new Double(resource.getScore()+100));
		}
	}
}
