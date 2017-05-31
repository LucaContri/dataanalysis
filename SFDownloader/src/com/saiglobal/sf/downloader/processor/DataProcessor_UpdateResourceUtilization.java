package com.saiglobal.sf.downloader.processor;

import java.util.Calendar;
import java.util.GregorianCalendar;

import com.saiglobal.sf.core.utility.Utility;

public class DataProcessor_UpdateResourceUtilization extends
		AbstractPostDownloadDataProcessor {

	@Override
	public void executeInternal() throws Exception {
		
		// Update table saig_resources_utilization
		Calendar startDate = new GregorianCalendar();
		Calendar endDate = new GregorianCalendar();
		int currentFy = 0;
		int yearSpan = 4;
		if (startDate.get(Calendar.MONTH)<Calendar.JULY) {
			startDate.add(Calendar.YEAR, -1);
			endDate.add(Calendar.YEAR, (yearSpan-1));
		} else {
			endDate.add(Calendar.YEAR, yearSpan);
		}
		currentFy = startDate.get(Calendar.YEAR);
		startDate.set(Calendar.MONTH, Calendar.JULY);
		startDate.set(Calendar.DAY_OF_MONTH, 1);
		endDate.set(Calendar.MONTH, Calendar.JUNE);
		endDate.set(Calendar.DAY_OF_MONTH, 30);
		
		logger.debug("Init saig_resources_utilization set all resource to 0,null for all periods ... ");
		String periodselect = "";
		// Init for all resource for the next 10 fy.  Is it enough?
		for (int i=0; i<10; i++) {
			if (i==0)  {
				periodselect = "(select '" + currentFy + "-" + (currentFy+1) + "' as 'period' ";
			} else {
				periodselect += "union select '" + (currentFy+i) + "-" + (currentFy+i+1) + "' as 'period' ";
			}
		}
		periodselect += ") t ";
		
		String insert = "INSERT INTO saig_resource_utilization "
				+ "(id, period, wiDays, utilization) "
				+ "select r.Id  as 'id', t.period as 'period', 0 as 'wiDays', null as 'utilization' from resource__c r, "
				+ periodselect + 
				"ON DUPLICATE KEY UPDATE wiDays = wiDays, utilization = utilization";
		db.executeStatement(insert);
		
		logger.debug("Updating saig_resources_utilization ... ");
		String update = "INSERT INTO saig_resource_utilization (id, period, wiDays, utilization) "
				+ "SELECT "
				+ "t.id as 'id',"
				+ "t.fy as 'period',"
				+ "sum(t.DurationInMinutes)/60/8 as 'wiDays',"
				+ "if (r.Resource_Target_Days__c is not null and r.Resource_Target_Days__c>0, sum(t.DurationInMinutes)/60/8/r.Resource_Target_Days__c,null) as 'utilization' "
				+ "FROM Resource__c r "
				+ "INNER JOIN ( "
				+ "SELECT "
				+ "r.Id,"
				+ "e.DurationInMinutes,"
				+ "if(month(e.ActivityDate)<7, concat(year(e.ActivityDate)-1,'-',year(e.ActivityDate)),concat(year(e.ActivityDate),'-',year(e.ActivityDate)+1)) as 'fy' "
				+ "FROM event e "
				+ "INNER JOIN user u ON u.Id = e.OwnerId "
				+ "INNER JOIN Resource__c r ON u.Id = r.User__c "
				+ "INNER JOIN work_item_resource__c wir ON wir.Id = e.WhatId "
				+ "WHERE "
				+ "e.IsDeleted = 0 "
				+ "AND e.ActivityDate >= '" + Utility.getActivitydateformatter().format(startDate.getTime()) + "' "
				+ "AND e.ActivityDate <= '" + Utility.getActivitydateformatter().format(endDate.getTime()) + "' "
				+ "AND wir.Work_Item_Type__c IN ('Audit' , 'Travel')) t ON t.Id = r.Id "
				+ "GROUP BY t.Id , t.fy "
				+ "ON DUPLICATE KEY UPDATE wiDays = wiDays, utilization = utilization";
		int rowsAffected = db.executeStatement(update);
		logger.debug("Updated " + rowsAffected + " records in saig_resources_utilization");
	}

	@Override
	public String getName() {
		return "ResourceUtilizationUpdater";
	}

}
