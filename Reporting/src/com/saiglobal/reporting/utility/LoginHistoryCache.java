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

public class LoginHistoryCache {
	private static HashMap<Region, LoginHistoryCache> reference= new HashMap<Region, LoginHistoryCache>();
	private static final int refreshIntervalMin = 60;
	private DbHelper db_certification = null;
	private Semaphore update = new Semaphore(1);
	private HashMap<String,Object> data = new HashMap<String, Object>();;
	private Calendar lastUpdateDate;
	private Region region;
		
	private LoginHistoryCache(DbHelper db_certification, Region region) {
		this.db_certification = db_certification;
		this.region = region;
		data.put("table", null);
	}

	public static LoginHistoryCache getInstance(DbHelper db_certification, Region region) {
		if (region == null) {
			return null;
		}
		if( reference == null) {
			reference = new HashMap<Region, LoginHistoryCache>();
		}
		if (!reference.containsKey(region)) {
			synchronized (  LoginHistoryCache.class) {
			  	reference.put(region, new LoginHistoryCache(db_certification, region));
			}
		}
		return  reference.get(region);
	}

	public HashMap<String, Object> getActiveSites(boolean forceRefresh) throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.MINUTE, -refreshIntervalMin);
		
		try {
			update.acquire();
			if(lastUpdateDate == null || lastUpdateDate.before(intervalBefore) || forceRefresh) {
				Calendar now = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
				String query = "select replace(u.Business__c, 'EMEA - ', '') as 'Region', u.Name, u.Profile_Name__c as 'Profile Name', u.LastLoginDate as 'Last Login (UTC)', datediff(utc_timestamp(),u.LastLoginDate ) as 'Aging Days' "
						+ "from User u "
						+ "where u.Business__c in ('" + StringUtils.join(this.region.getClientOwnerships(), "', '") + "') "
						+ "and u.IsActive=1 "
						+ "order by `Region`, u.Name";
				
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
