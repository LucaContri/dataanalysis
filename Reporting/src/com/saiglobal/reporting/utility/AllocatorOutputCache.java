package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TimeZone;
import java.util.concurrent.Semaphore;
import java.util.stream.Collectors;

import com.saiglobal.reporting.model.AllocatorOutputDetails;
import com.saiglobal.reporting.model.Event;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class AllocatorOutputCache {

	private DbHelper db = null;
	private static HashMap<String, AllocatorOutputCache> reference = new HashMap<String, AllocatorOutputCache>();
	private String batchId = null;
	private Calendar lastUpdated;
	private Calendar nextUpdate;
	private long refreshIntervalMillisec = 1*60*60*1000;
	private Semaphore update = new Semaphore(1);
	private AllocatorOutputDetails details = null;
	private AllocatorOutputCache(DbHelper db, String batchId) {
		this.db = db;
		this.batchId = batchId;
		this.nextUpdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
	}
	
	public static AllocatorOutputCache getInstance(DbHelper db, String batchId) {
		if (reference.get(batchId) == null)
			reference.put(batchId, new AllocatorOutputCache(db, batchId));
		
		return reference.get(batchId);
	}
	
	public AllocatorOutputDetails getAllocatorOutputDetails(boolean forceRefresh, int pageNo, int pageSize) throws Exception {
		
		try {
			update.acquire();
			if(lastUpdated == null || nextUpdate.before(Calendar.getInstance(TimeZone.getTimeZone("UTC"))) || forceRefresh) {
				refresh();
				if (lastUpdated == null) {
					lastUpdated = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
				} else {
					if (details.lastUpdated.getTimeInMillis() > lastUpdated.getTimeInMillis()) {
						refreshIntervalMillisec = details.lastUpdated.getTimeInMillis() - lastUpdated.getTimeInMillis();
					}
				}
				lastUpdated.setTimeInMillis(details.lastUpdated.getTimeInMillis());
				nextUpdate.setTimeInMillis(lastUpdated.getTimeInMillis()+refreshIntervalMillisec);
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		
		return getPage(pageNo, pageSize);
	}
	
	private AllocatorOutputDetails getPage(int pageNo, int pageSize) {
		if (details == null)
			return null;
		AllocatorOutputDetails page = new AllocatorOutputDetails(details.name);
		page.lastUpdated = details.lastUpdated;
		page.created = details.created;
		page.startDate = details.startDate;
		page.endDate = details.endDate;
		page.page = pageNo;
		if(pageNo==0)
			page.resources = details.resources;
		page.events = new ArrayList<Event>();
		int i = 0;
		for (i = pageNo*pageSize; i < (pageNo+1)*pageSize && i < details.events.size(); i++) {
			page.events.add(details.events.get(i));
		}
		if(i>=details.events.size())
			page.more = false;
		else
			page.more = true;
		
		return page;
	}
	
	private void refresh() throws Exception {
		if (details == null)
			details = new AllocatorOutputDetails("UK Forward Planning");
		String query = "(SELECT  s.`Id` as 'Event Id', " +
						"    wi.Id AS 'Work Item Id', " +
						"    wi.Name AS 'Work Item', " +
						"    wi.Service_Delivery_Type__c, " +
						"    wi.Status__c AS 'Work Item Status', " +
						"    wi.Open_Sub_Status__c 'Open Sub Status', " +
						"    wi.Work_Item_Stage__c 'Work Item Type', " +
						"    wi.Location__c AS 'WI Location', " +
						"    ifnull(convert_tz(s.`StartDate`, 'UTC', u.TimeZoneSidKey), wi.Work_Item_Date__c) AS 'Start Date', " +
						"    if(s.`Type`='AUDIT',s.`Duration`, s.`TravelDuration`) AS 'Duration', " +
						"    s.`ResourceId` AS 'Resource Id', " +
						"    s.`ResourceName` AS 'Resource Name', " +
						"    s.`ResourceType` AS 'Resource Type', " +
						"    r.`Reporting_Business_Units__c` AS 'Resource Reporting Business Unit', " +
						"    CONCAT(IFNULL(CONCAT(r.Home_Address_1__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Address_2__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Address_3__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_City__c, ' '), ''), " +
						"                IFNULL(CONCAT(scs.Name, ' '), ''), " +
						"                IFNULL(CONCAT(ccs.Name, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Postcode__c, ' '), '')) AS 'Resource Location', " +
						"    s.`Distance` AS 'Resource Distance', " +
						"    IFNULL(s.`Status`, 'OUT OF SCOPE') AS 'Status', " +
						"    IFNULL(s.`Type`, 'AUDIT') AS 'SubType', " + 
						"	 'ALLOCATOR' as 'Type' " +
						"FROM salesforce.allocator_schedule s " +
						"	INNER JOIN salesforce.work_item__c wi  ON LEFT(s.WorkItemId, 18) = wi.Id " +
						"	INNER JOIN salesforce.site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id " +
						"	INNER JOIN salesforce.certification__c sc ON scsp.Site_Certification__c = sc.Id " +
						"	INNER JOIN salesforce.account site ON sc.Primary_client__c = site.Id " +
						"	LEFT JOIN salesforce.country_code_setup__c sccs ON site.Business_Country2__c = sccs.Id " +
						"	LEFT JOIN salesforce.state_code_setup__c sscs ON site.Business_State__c = sscs.Id " +
						"	LEFT JOIN salesforce.saig_geocode_cache sgeo ON CONCAT( " +
						"		IFNULL(CONCAT(site.Business_Address_1__c, ' '), ''), " +
						"		IFNULL(CONCAT(site.Business_Address_2__c, ' '), ''), " +
						"		IFNULL(CONCAT(site.Business_Address_3__c, ' '), ''), " +
						"		IFNULL(CONCAT(site.Business_City__c, ' '), ''), " +
						"		IFNULL(CONCAT(sscs.Name, ' '), ''), " +
						"		IFNULL(CONCAT(sccs.Name, ' '), ''), " +
						"		IFNULL(CONCAT(site.Business_Zip_Postal_Code__c, ' '), '')) = sgeo.Address " +
						"	LEFT JOIN salesforce.resource__c r ON s.ResourceId = r.Id " +
						"   LEFT JOIN salesforce.user u on r.User__c = u.Id " +
						"	LEFT JOIN salesforce.country_code_setup__c ccs ON r.Home_Country1__c = ccs.Id " +
						"	LEFT JOIN salesforce.state_code_setup__c scs ON r.Home_State_Province__c = scs.Id " +
						"WHERE " +
						"	s.BatchId = 'UK Forward Planning' " +
						"    AND s.SubBatchId = (SELECT MAX(SubBatchId) FROM salesforce.allocator_schedule_batch WHERE BatchId = 'UK Forward Planning' and completed=1) " +
						"    AND wi.IsDeleted = 0 " +
						"	AND wi.Status__c NOT IN ('Cancelled' , 'Draft', 'Initiate Service')) " +
						"union all " +
						"(select e.`Id` as 'Event Id'," +
						"	wi.Id AS 'Work Item Id', " +
						"    wi.Name AS 'Work Item', " +
						"    wi.Service_Delivery_Type__c, " +
						"    wi.Status__c AS 'Work Item Status', " +
						"    wi.Open_Sub_Status__c 'Open Sub Status', " +
						"    wi.Work_Item_Stage__c 'Work Item Type', " +
						"    wi.Location__c AS 'WI Location', " +
						"    convert_tz(e.`StartDateTime`, 'UTC', u.TimeZoneSidKey) AS 'Start Date', " +
						"    e.DurationInMinutes/60 AS 'Duration', " +
						"    r.Id AS 'Resource Id', " +
						"    r.Name AS 'Resource Name', " +
						"    r.Resource_Type__c AS 'Resource Type', " +
						"    r.`Reporting_Business_Units__c` AS 'Resource Reporting Business Unit', " +
						"    CONCAT(IFNULL(CONCAT(r.Home_Address_1__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Address_2__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Address_3__c, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_City__c, ' '), ''), " +
						"                IFNULL(CONCAT(scs.Name, ' '), ''), " +
						"                IFNULL(CONCAT(ccs.Name, ' '), ''), " +
						"                IFNULL(CONCAT(r.Home_Postcode__c, ' '), '')) AS 'Resource Location', " +
						"    analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2  AS 'Resource Distance', " +
						"    null, " +
						"    rt.Name as 'SubType', 'COMPASS' as 'Type' " +
						"FROM salesforce.work_item__c wi   " +
						"	INNER JOIN salesforce.site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id " +
						"	INNER JOIN salesforce.certification__c sc ON scsp.Site_Certification__c = sc.Id " +
						"	INNER JOIN salesforce.account site ON sc.Primary_client__c = site.Id " +
						"	LEFT JOIN salesforce.country_code_setup__c sccs ON site.Business_Country2__c = sccs.Id " +
						"	LEFT JOIN salesforce.state_code_setup__c sscs ON site.Business_State__c = sscs.Id " +
						"	LEFT JOIN salesforce.saig_geocode_cache sgeo ON CONCAT( " +
						"			IFNULL(CONCAT(site.Business_Address_1__c, ' '), ''), " +
						"			IFNULL(CONCAT(site.Business_Address_2__c, ' '), ''), " +
						"			IFNULL(CONCAT(site.Business_Address_3__c, ' '), ''), " +
						"			IFNULL(CONCAT(site.Business_City__c, ' '), ''), " +
						"			IFNULL(CONCAT(sscs.Name, ' '), ''), " +
						"			IFNULL(CONCAT(sccs.Name, ' '), ''), " +
						"			IFNULL(CONCAT(site.Business_Zip_Postal_Code__c, ' '), '')) = sgeo.Address " +
						"	INNER JOIN salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.IsDeleted = 0  " +
						"    INNER JOIN salesforce.resource__c r on wir.Resource__c = r.Id " +
						"   LEFT JOIN salesforce.user u on r.User__c = u.Id " +
						"    LEFT JOIN salesforce.country_code_setup__c ccs ON r.Home_Country1__c = ccs.Id " +
						"	LEFT JOIN salesforce.state_code_setup__c scs ON r.Home_State_Province__c = scs.Id " +
						"    LEFT JOIN salesforce.saig_geocode_cache geo on concat( " +
						"			IFNULL(concat(r.Home_Address_1__c,' '),''), " +
						"			ifnull(concat(r.Home_Address_2__c,' '),''), " +
						"			ifnull(concat(r.Home_Address_3__c,' '),''), " +
						"			ifnull(concat(r.Home_City__c,' '),''), " +
						"			ifnull(concat(scs.Name,' '),''), " +
						"			ifnull(concat(ccs.Name,' '),''), " +
						"			ifnull(concat(r.Home_Postcode__c,' '),'')) = geo.Address " +
						"    INNER JOIN salesforce.event e on e.WhatId = wir.Id and e.IsDeleted = 0 " +
						"    INNER JOIN salesforce.recordtype rt on rt.Id = e.RecordTypeId  " +
						"WHERE " +
						"	wi.IsDeleted = 0 " +
						"    AND wi.Status__c NOT IN ('Cancelled' , 'Draft', 'Initiate Service') " +
						"    AND wi.Scheduling_Ownership__c = (select SchedulingOwnership from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "'))  " +
						"	AND sccs.Name = (select AuditCountries from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "'))  " +
						"	AND wi.Work_Item_Date__c >= (select StartDate from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "')) " +
						"	AND wi.Work_Item_Date__c <= (select EndDate from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "'))  " +
						");";
		details.events = new ArrayList<Event>();
		List<SimpleParameter> resources = new ArrayList<SimpleParameter>();
		Set<String> resourceNames = new HashSet<String>(); 
		ResultSet rs = db.executeSelect(query, -1);
		
		while (rs.next()) {
			Calendar startDate = Calendar.getInstance();
			Calendar endDate = Calendar.getInstance();
			startDate.setTimeInMillis(rs.getTimestamp("Start Date").getTime());
			endDate.setTime(startDate.getTime());
			endDate.add(Calendar.HOUR, (int) Math.ceil(rs.getDouble("Duration")));
			details.events.add(new Event(
					rs.getString("Event Id"), 
					rs.getString("Work Item"),
					rs.getString("Work Item Id"), 
					rs.getString("Resource Name"), 
					rs.getString("Resource Id"),
					startDate, 
					endDate, 
					rs.getString("Type"), 
					rs.getString("Type").equalsIgnoreCase("ALLOCATOR")?rs.getString("SubType"):rs.getString("Work Item Type"),
					rs.getString("WI Location"),
					rs.getString("Resource Location"),
					rs.getDouble("Resource Distance"),
					Utility.calculateTravelTimeHrs(rs.getDouble("Resource Distance"))));
			if(!resourceNames.contains(rs.getString("Resource Name"))) {
				resourceNames.add(rs.getString("Resource Name"));
				resources.add(new SimpleParameter(rs.getString("Resource Name")==null?"Unallocated":rs.getString("Resource Name"), rs.getString("Resource Id")));
			}				
		}
		
		Comparator<SimpleParameter> byName = (sp1, sp2) -> sp1.getName().compareTo(sp2.getName());
		details.resources = resources.stream().sorted(byName).collect(Collectors.toList());
		resourceNames = new HashSet<>();
		for (SimpleParameter r : resources) {
			if (r.getId() != null)
				resourceNames.add(r.getName().replace("'", "\\\'"));
		} 
		
		// Load BOP
		query = "(select " +
				"	e.Id AS 'Id', " +
				"    e.Subject AS 'Subject', " +
				"    bop.Comments__c, " +
				"    convert_tz(e.`StartDateTime`, 'UTC', u.TimeZoneSidKey) AS 'Start Date', " +
				"    e.DurationInMinutes/60 AS 'Duration', " +
				"    r.Id AS 'Resource Id', " +
				"    r.Name AS 'Resource Name', " +
				"    r.Resource_Type__c AS 'Resource Type', " +
				"    r.`Reporting_Business_Units__c` AS 'Resource Reporting Business Unit', " +
				"    CONCAT(IFNULL(CONCAT(r.Home_Address_1__c, ' '), ''), " +
				"                IFNULL(CONCAT(r.Home_Address_2__c, ' '), ''), " +
				"                IFNULL(CONCAT(r.Home_Address_3__c, ' '), ''), " +
				"                IFNULL(CONCAT(r.Home_City__c, ' '), ''), " +
				"                IFNULL(CONCAT(scs.Name, ' '), ''), " +
				"                IFNULL(CONCAT(ccs.Name, ' '), ''), " +
				"                IFNULL(CONCAT(r.Home_Postcode__c, ' '), '')) AS 'Resource Location', " +
				"    0  AS 'Resource Distance', " +
				"    rt.Name as 'Event Record Type', " +
				"    bop.Resource_Blackout_Type__c as 'SubType', 'BOP' as 'Type' " +
				"FROM salesforce.event e  " +
				"	inner join salesforce.blackout_period__c bop on e.WhatId = bop.Id " +
				"	inner join salesforce.resource__c r on bop.Resource__c = r.Id " +
				"	inner join salesforce.user u on r.User__c = u.Id " +
				"    inner join salesforce.recordtype rt on e.RecordTypeId = rt.Id " +
				"    LEFT JOIN salesforce.country_code_setup__c ccs ON r.Home_Country1__c = ccs.Id " +
				"	LEFT JOIN salesforce.state_code_setup__c scs ON r.Home_State_Province__c = scs.Id " +
				"WHERE " +
				"	e.IsDeleted = 0 " +
				"	AND e.StartDateTime >= (select StartDate from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning')) " +
				"	AND e.EndDateTime <= (select EndDate from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning'))  " +
				"	AND r.Name in ('" + resourceNames.stream().collect(Collectors.joining("','")) + "') " +
				");";
		
		rs = db.executeSelect(query, -1);
		
		while (rs.next()) {
			Calendar startDate = Calendar.getInstance();
			Calendar endDate = Calendar.getInstance();
			startDate.setTimeInMillis(rs.getTimestamp("Start Date").getTime());
			endDate.setTime(startDate.getTime());
			endDate.add(Calendar.HOUR, (int) Math.ceil(rs.getDouble("Duration")));
			details.events.add(new Event(
					rs.getString("Id"), 
					rs.getString("SubType"),
					null, 
					rs.getString("Resource Name"), 
					rs.getString("Resource Id"),
					startDate, 
					endDate, 
					rs.getString("Type"), 
					rs.getString("SubType"),
					"","",0,0));
		}
		
		query = "select s.created, s.lastModified, s.StartDate, s.EndDate from salesforce.allocator_schedule_batch s "
				+ "where s.BatchId='" + this.batchId + "' " 
				+ "and s.SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + this.batchId + "' and completed=1)";
		rs = db.executeSelect(query, 1);
		while (rs.next()) {
			details.created = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
			details.created.setTimeZone(TimeZone.getTimeZone("UTC"));
			details.created.setTime(Utility.getMysqlutcdateformat().parse(rs.getString("created")));
			details.lastUpdated = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
			details.lastUpdated.setTimeZone(TimeZone.getTimeZone("UTC"));
			details.lastUpdated.setTime(Utility.getMysqlutcdateformat().parse(rs.getString("lastModified")));
			details.startDate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
			details.startDate.setTimeZone(TimeZone.getTimeZone("UTC"));
			details.startDate.setTime(Utility.getMysqlutcdateformat().parse(rs.getString("startDate")));
			details.endDate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
			details.endDate.setTimeZone(TimeZone.getTimeZone("UTC"));
			details.endDate.setTime(Utility.getMysqlutcdateformat().parse(rs.getString("endDate")));
		}
	}
}
