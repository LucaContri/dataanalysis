package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.TimeZone;
import java.util.concurrent.Semaphore;

import com.saiglobal.reporting.model.AllocatorOutputDetails;
import com.saiglobal.reporting.model.Event;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.Utility;

public class AllocatorOutputTableCache {

	private DbHelper db = null;
	private String batchId = null;
	private static HashMap<String,AllocatorOutputTableCache> reference = new HashMap<String, AllocatorOutputTableCache>();
	private long refreshIntervalMillisec = 1*60*60*1000;
	private Semaphore update = new Semaphore(1);
	private AllocatorOutputDetails details = null;
	private AllocatorOutputTableCache(DbHelper db, String batchId) {
		this.db = db;
		this.batchId = batchId;
	}
	
	public static AllocatorOutputTableCache getInstance(DbHelper db, String batchId) {
		if (reference.get(batchId) == null)
			reference.put(batchId, new AllocatorOutputTableCache(db, batchId));
		
		return reference.get(batchId);
	}
	
	public AllocatorOutputDetails getAllocatorOutputDetails(boolean forceRefresh, int pageNo, int pageSize) throws Exception {
		try {
			update.acquire();
			if(update(pageNo) || forceRefresh) {
				refresh();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return getPage(pageNo, pageSize);
	}
	
	private boolean update(int pageNo) throws Exception {
		if (details == null || details.created == null)
			return true;
		if(pageNo>0)
			return false;
		return 1==db.executeScalarInt("select max(created)>'" + Utility.getMysqlutcdateformat().format(details.created.getTime()) + "' from salesforce.allocator_schedule_batch where BatchId='" + batchId + "' and completed=1");
		
	}
	
	private AllocatorOutputDetails getPage(int pageNo, int pageSize) {
		if (details == null)
			return null;
		AllocatorOutputDetails page = new AllocatorOutputDetails(details.name);
		page.lastUpdated = details.lastUpdated;
		page.created = details.created;
		page.nextUpdate = details.nextUpdate;
		page.startDate = details.startDate;
		page.endDate = details.endDate;
		page.page = pageNo;
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
			details = new AllocatorOutputDetails(batchId);
		String query = "(select "
				+ "wi.Id, "
				+ "wi.Name, "
				+ "s.`ResourceId`, "
				+ "s.`ResourceName`, "
				+ "s.`ResourceType`, "
				+ "s.`Type`, "
				+ "site.Name as 'ClientSite', "
				+ "wi.Primary_Standard__c, "
				+ "wi.Work_Item_Stage__c,"
				+ "u.TimeZoneSidKey, "
				+ "if(u.TimeZoneSidKey is not null, convert_tz(s.`StartDate`, 'UTC', u.TimeZoneSidKey), convert_tz(s.`StartDate`, 'UTC', s.WorkItemTimeZone)) as 'StartDate', "
				+ "if(u.TimeZoneSidKey is not null, DATE_FORMAT(convert_tz(s.`StartDate`, 'UTC', u.TimeZoneSidKey), '%Y-%m'), DATE_FORMAT(convert_tz(s.`StartDate`, 'UTC', s.WorkItemTimeZone), '%Y-%m')) AS 'Period', "
				+ "if(u.TimeZoneSidKey is not null, convert_tz(IFNULL(s.`EndDate`, s.`StartDate`), 'UTC', u.TimeZoneSidKey), convert_tz(IFNULL(s.`EndDate`, s.`StartDate`), 'UTC', s.WorkItemTimeZone)) AS 'EndDate', "
				+ "ifnull(s.`Notes`,'') as 'Notes', "
				+ "ifnull(concat(ifnull(concat(r.Home_Address_1__c,' '),''), "
				+ "ifnull(concat(r.Home_Address_2__c,' '),''),"
				+ "ifnull(concat(r.Home_Address_3__c,' '),''),"
				+ "ifnull(concat(r.Home_City__c,' '),''),"
				+ "ifnull(concat(rscs.Name,' '),''),"
				+ "ifnull(concat(rccs.Name,' '),''),"
				+ "ifnull(concat(r.Home_Postcode__c,' '),'')), '') as 'ResourceLocation', "
				+ "ifnull(concat("
				+ "ifnull(concat(site.Business_Address_1__c ,' '),''),"
				+ "ifnull(concat(site.Business_Address_2__c,' '),''),"
				+ "ifnull(concat(site.Business_Address_3__c,' '),''),"
				+ "ifnull(concat(site.Business_City__c ,' '),''),"
				+ "ifnull(concat(sscs.Name,' '),''),"
				+ "ifnull(concat(sccs.Name,' '),''),"
				+ "ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')), '') as 'SiteLocation' "
				+ "from salesforce.allocator_schedule s "
				+ "left join salesforce.resource__c r on s.`ResourceId` = r.Id "
				+ "left join salesforce.user u on r.User__c = u.Id "
				+ "left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id "
				+ "left join salesforce.state_code_setup__c rscs on r.Home_State_Province__c = rscs.Id "
				+ "inner join salesforce.work_item__c wi on s.WorkItemId = wi.Id and wi.Status__c in ('Open') "
				+ "inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id "
				+ "inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id "
				+ "inner join salesforce.account site on sc.Primary_client__c = site.Id "
				+ "left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id "
				+ "left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id "
				+ "where s.BatchId='" + batchId + "' "
				+ "and s.SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='" + batchId + "' and completed=1) "
				+ "order by `Period`, wi.Name, s.`StartDate`);";
		details.events = new ArrayList<Event>();
		ResultSet rs = db.executeSelect(query, -1);
		
		while (rs.next()) {
			Calendar startDate = Calendar.getInstance();
			Calendar endDate = Calendar.getInstance();
			startDate.setTimeInMillis(rs.getTimestamp("StartDate").getTime());
			endDate.setTimeInMillis(rs.getTimestamp("EndDate").getTime());
			details.events.add(new Event(
					null, 
					rs.getString("Name"),
					rs.getString("Id"),
					rs.getString("ResourceName"), 
					rs.getString("ResourceId"),
					rs.getString("ResourceType"),
					startDate, 
					endDate, 
					"ALLOCATOR", 
					rs.getString("Type"),
					rs.getString("ClientSite"),
					rs.getString("ResourceLocation"),
					rs.getString("SiteLocation"),
					0,
					0,
					rs.getString("Primary_Standard__c"),
					rs.getString("Work_Item_Stage__c"),
					rs.getString("Notes"),
					rs.getString("TimeZoneSidKey")));	
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
			details.nextUpdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
			details.nextUpdate.setTimeZone(TimeZone.getTimeZone("UTC"));
			details.nextUpdate.setTimeInMillis(details.lastUpdated.getTimeInMillis());
			details.nextUpdate.add(Calendar.MILLISECOND, (int) refreshIntervalMillisec);
		}
	}
}
