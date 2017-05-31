package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.util.Calendar;
import java.util.HashMap;
import java.util.TimeZone;
import java.util.concurrent.Semaphore;

import org.apache.commons.lang.StringUtils;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Region;
import com.saiglobal.sf.core.utility.Utility;

public class ActiveSitesCache {
	private static HashMap<Region, ActiveSitesCache> reference = new HashMap<Region, ActiveSitesCache>();
	private static final int refreshIntervalMins = 10;
	private DbHelper db_certification = null;
	private Semaphore update = new Semaphore(1);
	private HashMap<String, Object> data = new HashMap<String, Object>();;
	private Calendar lastUpdateDate;
	private Region region;

	private ActiveSitesCache(DbHelper db_certification, Region region) {
		this.db_certification = db_certification;
		this.region = region;
		data.put("table", null);
	}

	public static ActiveSitesCache getInstance(DbHelper db_certification,
			Region region) {
		if (region == null) {
			return null;
		}
		if (reference == null) {
			reference = new HashMap<Region, ActiveSitesCache>();
		}
		if (!reference.containsKey(region)) {
			synchronized (ActiveSitesCache.class) {
				reference.put(region, new ActiveSitesCache(db_certification,
						region));
			}
		}
		return reference.get(region);
	}

	public HashMap<String, Object> getActiveSites(boolean forceRefresh)
			throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.MINUTE, -refreshIntervalMins);
		try {
			update.acquire();

			if (lastUpdateDate == null || lastUpdateDate.before(intervalBefore)
					|| forceRefresh) {
				Calendar now = Calendar
						.getInstance(TimeZone.getTimeZone("UTC"));
				String query = "select t3.*, round(t3.`Sites with no Certs`/t3.`Active Sites`*100, 2) as '% Sites with no Certs',"
						// +
						// "st.`Sites Created Yesterday`, st.`Sites Created This Week`, st.`Sites Created This Month`,"
						+ "sct.`Site Certs Created Today`, sct.`Site Certs Created Yesterday`, sct.`Site Certs Created This Week`, sct.`Site Certs Created This Month` "
						+ " from ( "
						+ "select t2.`Region`, count(distinct t2.`SiteId`) as 'Active Sites', count(distinct if (t2.`Active Site Cert`=0,t2.`SiteId`,null)) as 'Sites with no Certs' from ( "
						+ "select "
						+ "replace(t.Client_Ownership__c, 'EMEA - ', '') as 'Region', "
						+ "t.`SiteId`, "
						+ "count(distinct if(!t.`IsDeleted` and t.`Status__c` = 'Active',t.`SiteCertId`,null) ) as 'Active Site Cert'  "
						+ "from ( "
						+ "select s.Id as 'SiteId', s.Name as 'SiteName', s.Client_Account_Status__c, p.Client_Ownership__c, sc.Id as 'SiteCertId', sc.Name as 'SiteCertName', sc.Status__c, sc.IsDeleted "
						+ "from account s "
						+ "inner join account p on s.ParentId = p.Id "
						+ "left join certification__c sc on sc.Primary_client__c = s.Id "
						+ "where  "
						+ "s.Record_Type_Name__c = 'Client Site' "
						+ "and p.Client_Ownership__c in ('"
						+ StringUtils.join(this.region.getClientOwnerships(), "', '")
						+ "') "
						+ "and s.Client_Account_Status__c = 'Active' "
						+ "and p.Client_Account_Status__c = 'Active' "
						+ "and s.IsDeleted = 0 "
						+ "and p.IsDeleted = 0) t  "
						+ "group by t.`SiteId`) t2 "
						+ "group by t2.`Region`) t3 "
						// + "left join ("
						// + "select p.Client_Ownership__c as 'Region', "
						// +
						// "count(distinct if (date_format(s.CreatedDate, '%Y-%m-%d') = date_format(date_add(utc_timestamp(), interval -24 hour), '%Y-%m-%d'), s.Id, null)) as 'Sites Created Yesterday',"
						// +
						// "count(distinct if (date_format(s.CreatedDate, '%Y-%v') = date_format(utc_timestamp(), '%Y-%v'), s.Id, null)) as 'Sites Created This Week',"
						// +
						// "count(distinct if (date_format(s.CreatedDate, '%Y-%m') = date_format(utc_timestamp(), '%Y-%m'), s.Id, null)) as 'Sites Created This Month' "
						// + "from account s "
						// + "inner join account p on s.ParentId = p.Id "
						// + "where "
						// + "s.Record_Type_Name__c = 'Client Site' "
						// + "and p.Client_Ownership__c in ('" +
						// StringUtils.join(this.region.getBusinesses(), "', '")
						// + "') "
						// + "and s.Client_Account_Status__c = 'Active' "
						// + "and p.Client_Account_Status__c = 'Active' "
						// + "and s.IsDeleted = 0 "
						// + "and p.IsDeleted = 0 "
						// +
						// "and date_format(s.CreatedDate, '%Y-%m') = date_format(utc_timestamp(), '%Y-%m') "
						// + "group by `Region`) st on st.Region = t3.Region "
						+ "left join ( "
						+ "select replace(s.Revenue_Ownership__c, 'EMEA-', '') as 'Region', "
						+ "count(distinct if (date_format(s.CreatedDate, '%Y-%m-%d') = date_format(utc_timestamp(), '%Y-%m-%d'), s.Id, null)) as 'Site Certs Created Today',"
						+ "count(distinct if (date_format(s.CreatedDate, '%Y-%m-%d') = date_format(date_add(utc_timestamp(), interval -24 hour), '%Y-%m-%d'), s.Id, null)) as 'Site Certs Created Yesterday',"
						+ "count(distinct if (date_format(s.CreatedDate, '%Y-%v') = date_format(utc_timestamp(), '%Y-%v'), s.Id, null)) as 'Site Certs Created This Week',"
						+ "count(distinct if (date_format(s.CreatedDate, '%Y-%m') = date_format(utc_timestamp(), '%Y-%m'), s.Id, null)) as 'Site Certs Created This Month' "
						+ "from certification__c s  "
						+ "where "
						+ "s.IsDeleted = 0 "
						+ "and s.Status__c = 'Active' "
						+ "and s.Revenue_Ownership__c in ('"
						+ StringUtils.join(this.region.getRevenueOwnerships(),
								"', '")
						+ "') "
						+ "and date_format(s.CreatedDate, '%Y-%m') = date_format(utc_timestamp(), '%Y-%m') "
						+ "group by `Region`) sct on sct.Region = t3.Region "
						+ "order by t3.`Region`";

				ResultSet rs = db_certification.executeSelect(query, -1);
				data.put("table", Utility.resultSetToObjectArray(rs, true));
				lastUpdateDate = now;
				data.put("lastUpdateDate", now);
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return data;
	}
}
