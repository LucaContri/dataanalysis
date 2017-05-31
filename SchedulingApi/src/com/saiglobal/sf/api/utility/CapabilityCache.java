package com.saiglobal.sf.api.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.concurrent.Semaphore;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.model.SimpleCode;
import com.saiglobal.sf.api.model.SimpleStandard;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;

public class CapabilityCache {
	private static CapabilityCache reference= null;
	private static final int refreshIntervalHrs = 24;
	private DbHelper db = null;
	private Calendar lastUpdateStandards;
	private Calendar lastUpdateCodes;
	private Semaphore update = new Semaphore(1);
	private List<SimpleStandard> standards = new ArrayList<SimpleStandard>();
	private List<SimpleCode> codes = new ArrayList<SimpleCode>();

	private CapabilityCache(DbHelper db) {
		this.db = db;
	}

	public static CapabilityCache getInstance(DbHelper db) {
		if( reference == null) {
			synchronized (  CapabilityCache.class) {
			  	if( reference  == null)
			  		reference  = new CapabilityCache(db);
			}
		}
		return  reference;
	}

	public List<SimpleCode> getCodes() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		update.acquire();
		if(lastUpdateCodes == null || lastUpdateCodes.before(intervalBefore)) {
			String query = "select c.Name as 'Name', c.Id as 'Id' from code__c c "
					+ "where c.IsDeleted=0 "
					+ "and c.Status__c = 'Active'";
			try {
				ResultSet rs = db.executeSelect(query, -1);
				codes = new ArrayList<SimpleCode>();
				while (rs.next()) {
					codes.add(new SimpleCode(rs.getString("Name"), rs.getString("Id")));
				}
			} catch (Exception e) {
				throw e;
			}
			lastUpdateCodes = Calendar.getInstance();  
		}
		update.release();
	  return codes;
	}
	
	public List<SimpleStandard> getStandards(String search) throws Exception {
		if ((search == null) || (search == ""))
			return getStandards();
		search = search.toLowerCase();
		List<SimpleStandard> result = new ArrayList<SimpleStandard>();
		for (SimpleStandard standard : getStandards()) {
			if (standard.getName().toLowerCase().contains(search))
				result.add(standard);
		}
		return result;
	}
	
	public List<SimpleCode> getCodes(String search) throws Exception {
		if ((search == null) || (search == ""))
			return getCodes();
		search = search.toLowerCase();
		List<SimpleCode> result = new ArrayList<SimpleCode>();
		for (SimpleCode code : getCodes()) {
			if (code.getName().toLowerCase().contains(search))
				result.add(code);
		}
		return result;
	}
	
	public List<SimpleStandard> getStandards() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);

		update.acquire();
		if(lastUpdateStandards == null || lastUpdateStandards.before(intervalBefore)) {
			String query = "select s.Name as 'Name', s.Id as 'Id' from standard__c s "
					+ "where s.IsDeleted=0 "
					+ "and s.Parent_Standard__c is not null "
					+ "and s.Status__c = 'Active' order by s.Name";
			try {
				ResultSet rs = db.executeSelect(query, -1);
				standards = new ArrayList<SimpleStandard>();
				while (rs.next()) {
					standards.add(new SimpleStandard(rs.getString("Name"), rs.getString("Id")));
				}
			} catch (Exception e) {
				throw e;
			}
			lastUpdateStandards = Calendar.getInstance();
		}
		update.release();
	  return standards;
	}
	
	public Competency getStandardById(String id) throws Exception {
		if ((id == null) || (id== ""))
			return null;
		for (SimpleStandard standard : getStandards()) {
			if (standard.getId().equals(id))
				return new Competency(standard.getId(), standard.getName(), CompetencyType.STANDARD, null);
		}
		return null;
	}
	
	public Competency getCodeById(String id) throws Exception {
		if ((id == null) || (id== ""))
			return null;
		for (SimpleCode code : getCodes()) {
			if (code.getId().equals(id))
				return new Competency(code.getId(), code.getName(), CompetencyType.CODE, null);
		}
		return null;
	}
}
