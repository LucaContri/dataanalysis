package com.saiglobal.sf.schedulingapi.main;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.saiglobal.sf.core.model.Allocation;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.schedulingapi.data.DbHelper;
import com.saiglobal.sf.schedulingapi.utility.Utility;

import spark.Request;
import spark.Response;

public class HandlerAllocation {
	
	public static Object handle(Request request, Response response, DbHelper db, Date from, Date to, String businessUnits)
	{
		Utility.startTimeCounter("handle");
		response.type("text/html");
		List<String> whereClauseList = new ArrayList<String>();
		String businessUnitWhereClause = "";
		
		if (businessUnits == null) {
			businessUnits = "AUS-Man,AUS-Food,AUS-Direct";
		}
		List<String> businessUnitsList = Arrays.asList(businessUnits.split(","));
		boolean first = true;
		for (String businessUnitString : businessUnitsList) {
			if (first) {
				businessUnitWhereClause = "(Reporting_Business_Units__c like '" + businessUnitString + "%'";
				first = false;
			} else {
				businessUnitWhereClause += " OR Reporting_Business_Units__c like '" + businessUnitString + "%'";
			}
		}
		if (businessUnitWhereClause!="")
			businessUnitWhereClause += ")";
		
		whereClauseList.add(businessUnitWhereClause);
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			
			String query = "SELECT " +
						"r.Name as 'ResourceName', " +
						"r.Resource_Type__c, " +
						"t.From as 'From', " +
						"t.To as 'To', " +
						"DATE_FORMAT(t.Date, '%Y %m') as 'Period', " +
						"a.Id, " +
						"a.Name, " +
						"a.Latitude__c, " +
						"a.Longitude__c, " +
						"t.WorkItem, " +
						"t.Type, " +
						"t.SubType, " +
						"t.DurationMin as 'Minutes' " +
					"FROM " +
						"`Resource__c` r " +
					"INNER JOIN " +
						"(SELECT " +
							"r.Id as 'ResourceId', " +
							"rt.Name as 'Type', " +
							"if(wir.Work_Item_Type__c is null, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) as 'SubType', " +
							"if(wir.Work_Item_Type__c is null, null, wir.Work_Item_Name__c) as 'WorkItem', " +
							"if(wir.Work_Item_Type__c is null, null, wir.Work_Item__c) as 'WorkItemId', " +
							"e.DurationInMinutes as 'DurationMin', " +
							"e.ActivityDate as 'Date', " +
							"e.EndDateTime as 'To', " +
							"e.StartDateTime as 'From' " +
						"FROM " +
							"`event` e " +
							"INNER JOIN `user` u ON u.Id = e.OwnerId " +
							"INNER JOIN `Resource__c` r ON u.Id = r.User__C " +
							"INNER JOIN `recordtype` rt ON e.RecordTypeId = rt.Id " +
							"LEFT JOIN `work_item_resource__c` wir ON wir.Id = e.WhatId " +
							"LEFT JOIN `blackout_period__c` bop ON bop.Id = e.WhatId " +
						"WHERE " +
							"e.IsDeleted = 0 " +
							"AND e.ActivityDate >= '" + Utility.getActivitydateformatter().format(from) + "' " +
							"AND e.ActivityDate <= '" + Utility.getActivitydateformatter().format(to) + "' " +
							"AND r.Reporting_Business_Units__c like 'AUS%') t ON t.ResourceId = r.Id " +
							"LEFT JOIN salesforce.Work_Item__c wi on wi.Id = t.WorkItemId " +
							"LEFT JOIN salesforce.Work_Package__c wp on wp.Id=wi.Work_Package__c " +
							"LEFT JOIN salesforce.Certification__c c on c.Id = wp.Site_Certification__c " +
							"LEFT JOIN salesforce.account a on a.Id = c.Primary_Client__c " +
						db.getWhereClause(whereClauseList) +
					"ORDER BY `ResourceName`, `From`";
			
			ResultSet rs = db.executeSelect(query, -1);
			
			Allocation allocation = new Allocation();
			List<Schedule> schedule = new ArrayList<Schedule>(); 
			HashMap<String, Double> totals = new HashMap<String, Double>();
			totals.put("Audit", new Double(0));
			totals.put("Audit_Employee", new Double(0));
			totals.put("Audit_Contractor", new Double(0));
			totals.put("Travel", new Double(0));
			totals.put("Billable", new Double(0));
			totals.put("Total", new Double(0));
			totals.put("FTE_Count", new Double(0));
			totals.put("Contractor_Count", new Double(0));
			Set<String> contractors = new HashSet<String>();
			Set<String> employees = new HashSet<String>();
			Set<String> workItem = new HashSet<String>();
			while (rs.next()) {
				// Fill in response object
				Schedule aScheduleItem = new Schedule();
				aScheduleItem.setStartDate(new Date(rs.getTimestamp("From").getTime()));
				aScheduleItem.setEndDate(new Date(rs.getTimestamp("To").getTime()));
				aScheduleItem.setWorkItemName(rs.getString("t.WorkItem"));
				aScheduleItem.setLatitude(rs.getDouble("a.Latitude__c"));
				aScheduleItem.setLongitude(rs.getDouble("a.Longitude__c"));
				aScheduleItem.setResourceName(rs.getString("ResourceName"));
				aScheduleItem.setResourceType(rs.getString("r.Resource_Type__c"));
				aScheduleItem.setSfSubType((rs.getString("t.SubType")==null?"":rs.getString("t.SubType")));
				aScheduleItem.setDuration(rs.getDouble("Minutes"));
				schedule.add(aScheduleItem);
				// Calculate totals
				totals.put("Total", new Double(totals.get("Total").doubleValue()+aScheduleItem.getDuration()));
				if (aScheduleItem.getSfSubType().equalsIgnoreCase("Audit")) {
					totals.put("Audit", new Double(totals.get("Audit").doubleValue()+aScheduleItem.getDuration()));
					workItem.add(aScheduleItem.getWorkItemName());
					if (aScheduleItem.getResourceType().equals(SfResourceType.Employee)) {
						totals.put("Audit_Employee", new Double(totals.get("Audit_Employee").doubleValue()+aScheduleItem.getDuration()));
						employees.add(aScheduleItem.getResourceName());
					} else {
						totals.put("Audit_Contractor", new Double(totals.get("Audit_Contractor").doubleValue()+aScheduleItem.getDuration()));
						contractors.add(aScheduleItem.getResourceName());
					}
				}
				if (aScheduleItem.getSfSubType().equalsIgnoreCase("Travel"))
					totals.put("Travel", new Double(totals.get("Travel").doubleValue()+aScheduleItem.getDuration()));
				if (aScheduleItem.getSfSubType().equalsIgnoreCase("Audit") ||
						aScheduleItem.getSfSubType().equalsIgnoreCase("Audit Planning") ||
						aScheduleItem.getSfSubType().equalsIgnoreCase("Client Management") ||
						aScheduleItem.getSfSubType().equalsIgnoreCase("Travel"))
					totals.put("Billable", new Double(totals.get("Billable").doubleValue()+aScheduleItem.getDuration()));
			}
			allocation.setAllocation(schedule);
			
			totals.put("Audit/Total", new Double(totals.get("Audit").doubleValue()/totals.get("Total").doubleValue()));
			totals.put("Travel/Total", new Double(totals.get("Travel").doubleValue()/totals.get("Total").doubleValue()));
			totals.put("Travel/Audit", new Double(totals.get("Travel").doubleValue()/totals.get("Audit").doubleValue()));
			totals.put("Billable/Total", new Double(totals.get("Billable").doubleValue()/totals.get("Total").doubleValue()));
			totals.put("FTE_Count", new Double(employees.size()));
			totals.put("Contractor_Count", new Double(contractors.size()));
			totals.put("WorkItem Count", new Double(workItem.size()));
			totals.put("Contractor Audit/Total Audit", new Double(totals.get("Audit_Contractor").doubleValue()/totals.get("Audit").doubleValue()));
			
			allocation.setTotals(totals);
			Utility.stopTimeCounter("handle");
			Utility.logAllProcessingTime();
			Utility.logAllEventCounter();
			Utility.resetAllTimeCounter();
			return Utility.serializeAllocationResponse(allocation, db);
			
		} catch (Exception e) {
			e.printStackTrace();
			PrintWriter pw = new PrintWriter(errorMessage);
			e.printStackTrace(pw);
		}
		
		response.status(500); // 500 Internal Server Error
        return "Internal Server Error\n" + errorMessage.toString();
	} 
}
