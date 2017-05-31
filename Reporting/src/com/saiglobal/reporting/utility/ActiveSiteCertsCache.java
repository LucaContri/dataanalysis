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

public class ActiveSiteCertsCache {
	private static HashMap<Region, ActiveSiteCertsCache> reference = new HashMap<Region, ActiveSiteCertsCache>();
	private static final int refreshIntervalMin = 10;
	private DbHelper db_certification = null;
	private Semaphore update = new Semaphore(1);
	private HashMap<String, Object> data = new HashMap<String, Object>();;
	private Calendar lastUpdateDate;
	private Region region;

	private ActiveSiteCertsCache(DbHelper db_certification, Region region) {
		this.db_certification = db_certification;
		this.region = region;
		data.put("table", null);
	}

	public static ActiveSiteCertsCache getInstance(DbHelper db_certification,
			Region region) {
		if (region == null) {
			return null;
		}
		if (reference == null) {
			reference = new HashMap<Region, ActiveSiteCertsCache>();
		}
		if (!reference.containsKey(region)) {
			synchronized (ActiveSiteCertsCache.class) {
				reference.put(region, new ActiveSiteCertsCache(
						db_certification, region));
			}
		}
		return reference.get(region);
	}

	public HashMap<String, Object> getActiveSites(boolean forceRefresh)
			throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.MINUTE, -refreshIntervalMin);
		try {
			update.acquire();
			if (lastUpdateDate == null || lastUpdateDate.before(intervalBefore)
					|| forceRefresh) {
				Calendar now = Calendar
						.getInstance(TimeZone.getTimeZone("UTC"));
				String query = "select t.*, round(t.`# Site Certs Not Validated`/t.`# Site Certs`*100,2) as '% Site Certs Not Validated', "
						+ "scht.`Lifecycles Validated Today`, scht.`Lifecycles Validated Yesterday`, scht.`Lifecycles Validated This Week`, scht.`Lifecycles Validated This Month` "
						+ "from ( "
						+ "select replace(sc.Revenue_Ownership__c, 'EMEA-', '') as 'Region', count(distinct sc.Id) as '# Site Certs', count(distinct if (sc.Lifecycle_Validated__c=0, sc.Id, null)) as '# Site Certs Not Validated' "
						+ "from certification__c sc "
						+ "where sc.Auditable_Site__c = 1 "
						+ "and sc.Sample_Service__c = 0 "
						+ "and sc.IsDeleted = 0 "
						+ "and sc.Status__c = 'Active' "
						+ "and sc.Revenue_Ownership__c in ('"
						+ StringUtils.join(this.region.getRevenueOwnerships(),
								"', '")
						+ "') "
						+ "and not (sc.Standard_Name__c like '%14001%' or "
						+ "sc.Standard_Name__c like '%16949%' or "
						+ "sc.Standard_Name__c like '%18001%' or "
						+ "sc.Standard_Name__c like '%22000%' or "
						+ "sc.Standard_Name__c like '%27001%' or "
						+ "sc.Standard_Name__c like '%29001%' or "
						+ "sc.Standard_Name__c like '%9001%' or "
						+ "sc.Standard_Name__c like '%9100%' or "
						+ "sc.Standard_Name__c like '%Codex HACCP%' or "
						+ "sc.Standard_Name__c like '%Q-Base%') "
						+ "group by `Region` "
						+ "order by `Region`) t "
						+ "left join ("
						+ "select replace(sc.Revenue_Ownership__c, 'EMEA-', '') as 'Region', "
						+ "count(distinct if (date_format(sch.CreatedDate,'%Y-%m-%d')=date_format(utc_timestamp(), '%Y-%m-%d'),sch.Id,null)) as 'Lifecycles Validated Today',"
						+ "count(distinct if (date_format(sch.CreatedDate,'%Y-%m-%d')=date_format(date_add(utc_timestamp(), interval -24 hour), '%Y-%m-%d'),sch.Id,null)) as 'Lifecycles Validated Yesterday',"
						+ "count(distinct if (date_format(sch.CreatedDate,'%Y-%v')=date_format(utc_timestamp(), '%Y-%v'),sch.Id,null)) as 'Lifecycles Validated This Week',"
						+ "count(distinct if (date_format(sch.CreatedDate,'%Y-%m')=date_format(utc_timestamp(), '%Y-%m'),sch.Id,null)) as 'Lifecycles Validated This Month' "
						+ "from certification__c sc "
						+ "inner join certification__history sch on sch.ParentId = sc.Id "
						+ "where sc.Auditable_Site__c = 1 "
						+ "and sch.IsDeleted = 0 "
						+ "and sch.Field = 'Lifecycle_Validated__c' "
						+ "and sch.NewValue = 'true' "
						+ "and date_format(sch.CreatedDate, '%Y-%m') = date_format(utc_timestamp(), '%Y-%m') "
						+ "and sc.Sample_Service__c = 0 "
						+ "and sc.IsDeleted = 0 "
						+ "and sc.Status__c = 'Active' "
						+ "and sc.Revenue_Ownership__c in ('"
						+ StringUtils.join(this.region.getRevenueOwnerships(),
								"', '")
						+ "') "
						+ "and sc.Primary_Certification__c is not null "
						+ "and not (sc.Standard_Name__c like '%14001%' or "
						+ "sc.Standard_Name__c like '%16949%' or "
						+ "sc.Standard_Name__c like '%18001%' or "
						+ "sc.Standard_Name__c like '%22000%' or "
						+ "sc.Standard_Name__c like '%27001%' or "
						+ "sc.Standard_Name__c like '%29001%' or "
						+ "sc.Standard_Name__c like '%9001%' or "
						+ "sc.Standard_Name__c like '%9100%' or "
						+ "sc.Standard_Name__c like '%Codex HACCP%' or "
						+ "sc.Standard_Name__c like '%Q-Base%') "
						+ "group by `Region`) scht on scht.`Region` = t.`Region` "
						+ "order by t.`Region`";

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
