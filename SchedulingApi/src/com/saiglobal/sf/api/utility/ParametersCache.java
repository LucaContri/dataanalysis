package com.saiglobal.sf.api.utility;

import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.concurrent.Semaphore;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.model.SimpleParameter;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfCapabilityRank;
import com.saiglobal.sf.core.model.SfResourceType;

public class ParametersCache {
	private static ParametersCache reference= null;
	private static final int refreshIntervalHrs = 24;
	public static List<SimpleParameter> getRanks() {
		return ranks;
	}

	private DbHelper db = null;
	private Calendar lastUpdateStandards;
	private Calendar lastUpdateCodes;
	private Calendar lastUpdateMonths;
	private List<SimpleParameter> standards = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> codes = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> states = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> countries = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> types = new ArrayList<SimpleParameter>();
	private static List<SimpleParameter> ranks = new ArrayList<SimpleParameter>();
	private ResourceCache resourceCache;
	private Semaphore update = new Semaphore(1);
	private List<SimpleParameter> months = new ArrayList<SimpleParameter>();

	static {
		states.add(new SimpleParameter("New South Wales (NSW)", "NSW"));
		states.add(new SimpleParameter("Victoria (VIC)", "VIC"));
		states.add(new SimpleParameter("Australian Capitol Territory (ACT)", "ACT"));
		states.add(new SimpleParameter("Queensland (QLD)", "QLD"));
		states.add(new SimpleParameter("South Australia (SA)", "SA"));
		states.add(new SimpleParameter("Northern Territory (NT)", "NT"));
		states.add(new SimpleParameter("Tasmania (TAS)", "TAS"));
		states.add(new SimpleParameter("Western Australia (WA)", "WA"));
		
		countries.add(new SimpleParameter("Algeria", "Algeria"));
		countries.add(new SimpleParameter("Argentina", "Argentina"));
		countries.add(new SimpleParameter("Australia", "Australia"));
		countries.add(new SimpleParameter("Bangladesh", "Bangladesh"));
		countries.add(new SimpleParameter("Belarus", "Belarus"));
		countries.add(new SimpleParameter("Belgium", "Belgium"));
		countries.add(new SimpleParameter("Canada", "Canada"));
		countries.add(new SimpleParameter("Chile", "Chile"));
		countries.add(new SimpleParameter("China", "China"));
		countries.add(new SimpleParameter("Czech Republic", "Czech Republic"));
		countries.add(new SimpleParameter("Egypt", "Egypt"));
		countries.add(new SimpleParameter("France", "France"));
		countries.add(new SimpleParameter("Georgia", "Georgia"));
		countries.add(new SimpleParameter("Germany", "Germany"));
		countries.add(new SimpleParameter("Greece", "Greece"));
		countries.add(new SimpleParameter("Hungary", "Hungary"));
		countries.add(new SimpleParameter("India", "India"));
		countries.add(new SimpleParameter("Indonesia", "Indonesia"));
		countries.add(new SimpleParameter("Ireland", "Ireland"));
		countries.add(new SimpleParameter("Italy", "Italy"));
		countries.add(new SimpleParameter("Japan", "Japan"));
		countries.add(new SimpleParameter("Kazakhstan", "Kazakhstan"));
		countries.add(new SimpleParameter("Korea, South", "Korea, South"));
		countries.add(new SimpleParameter("Kuwait", "Kuwait"));
		countries.add(new SimpleParameter("Lebanon", "Lebanon"));
		countries.add(new SimpleParameter("Malaysia", "Malaysia"));
		countries.add(new SimpleParameter("Mexico", "Mexico"));
		countries.add(new SimpleParameter("Mongolia", "Mongolia"));
		countries.add(new SimpleParameter("Netherlands", "Netherlands"));
		countries.add(new SimpleParameter("New Zealand", "New Zealand"));
		countries.add(new SimpleParameter("Poland", "Poland"));
		countries.add(new SimpleParameter("Russian Federation", "Russian Federation"));
		countries.add(new SimpleParameter("Saudi Arabia", "Saudi Arabia"));
		countries.add(new SimpleParameter("Singapore", "Singapore"));
		countries.add(new SimpleParameter("Slovenia", "Slovenia"));
		countries.add(new SimpleParameter("South Africa", "South Africa"));
		countries.add(new SimpleParameter("Spain", "Spain"));
		countries.add(new SimpleParameter("Sweden", "Sweden"));
		countries.add(new SimpleParameter("Syria", "Syria"));
		countries.add(new SimpleParameter("Taiwan", "Taiwan"));
		countries.add(new SimpleParameter("Thailand", "Thailand"));
		countries.add(new SimpleParameter("Tunisia", "Tunisia"));
		countries.add(new SimpleParameter("Turkey", "Turkey"));
		countries.add(new SimpleParameter("Ukraine", "Ukraine"));
		countries.add(new SimpleParameter("United Arab Emirates", "United Arab Emirates"));
		countries.add(new SimpleParameter("United Kingdom", "United Kingdom"));
		countries.add(new SimpleParameter("United States", "United States"));
		
		types.add(new SimpleParameter(SfResourceType.Contractor.getName(), SfResourceType.Contractor.getName()));
		types.add(new SimpleParameter(SfResourceType.Employee.getName(), SfResourceType.Employee.getName()));
		types.add(new SimpleParameter(SfResourceType.ExternalRegulator.getName(), SfResourceType.ExternalRegulator.getName()));
		types.add(new SimpleParameter(SfResourceType.ClientServices.getName(), SfResourceType.ClientServices.getName()));
		
		ranks.add(new SimpleParameter(SfCapabilityRank.Auditor.getName(), SfCapabilityRank.Auditor.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.BusinessAdministrator.getName(), SfCapabilityRank.BusinessAdministrator.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.CertificationApprover.getName(), SfCapabilityRank.CertificationApprover.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.IndustryExpert.getName(), SfCapabilityRank.IndustryExpert.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.Inspector.getName(), SfCapabilityRank.Inspector.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.LaboratoryAuditor.getName(), SfCapabilityRank.LaboratoryAuditor.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.LeadAuditor.getName(), SfCapabilityRank.LeadAuditor.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.Observer.getName(), SfCapabilityRank.Observer.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.ProjectManager.getName(), SfCapabilityRank.ProjectManager.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.Provisional.getName(), SfCapabilityRank.Provisional.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.TechnicalAdvisor.getName(), SfCapabilityRank.TechnicalAdvisor.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.TechnicalReviewer.getName(), SfCapabilityRank.TechnicalReviewer.getName()));
		ranks.add(new SimpleParameter(SfCapabilityRank.VerifyingAuditor.getName(), SfCapabilityRank.VerifyingAuditor.getName()));
	}
	
	private ParametersCache(DbHelper db) {
		this.db = db;
		this.resourceCache = ResourceCache.getInstance(db);
	}

	public static ParametersCache getInstance(DbHelper db) {
		if( reference == null) {
			synchronized (  ParametersCache.class) {
			  	if( reference  == null)
			  		reference  = new ParametersCache(db);
			}
		}
		return  reference;
	}

	public List<SimpleParameter> getCodes() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		update.acquire();
		if(lastUpdateCodes == null || lastUpdateCodes.before(intervalBefore)) {
			String query = "select c.Name as 'Name', c.Id as 'Id' from code__c c "
					+ "where c.IsDeleted=0 "
					+ "and c.Status__c = 'Active'";
			try {
				ResultSet rs = db.executeSelect(query, -1);
				codes = new ArrayList<SimpleParameter>();
				while (rs.next()) {
					codes.add(new SimpleParameter(rs.getString("Name"), rs.getString("Id")));
				}
			} catch (Exception e) {
				throw e;
			}
			lastUpdateCodes = Calendar.getInstance();  
		}
		update.release();
		return codes;
	}
	
	public List<SimpleParameter> getMonths() throws InterruptedException {
		Calendar now = Calendar.getInstance();
		
		update.acquire();
		if((lastUpdateMonths == null) || (lastUpdateMonths.get(Calendar.MONTH) != now.get(Calendar.MONTH))) {
			SimpleDateFormat periodFormatter = new SimpleDateFormat("MMMM YYYY");
			now.set(Calendar.DAY_OF_MONTH, 1);
			Calendar endPeriod = new GregorianCalendar(now.get(Calendar.YEAR), now.get(Calendar.MONTH), now.get(Calendar.DAY_OF_MONTH));
			endPeriod.add(Calendar.MONTH, 24);
			months = new ArrayList<SimpleParameter>();
			int i=0;
			while(now.before(endPeriod)) {
				months.add(new SimpleParameter(periodFormatter.format(now.getTime()), "" + i++));
				now.add(Calendar.DATE, 31);
			}
			lastUpdateMonths = Calendar.getInstance();  
		}
		update.release();
		return months;
	}
	
	public List<SimpleParameter> getParameters(String search) throws Exception {
		if ((search == null) || (search == ""))
			return getStandards();
		search = search.toLowerCase();
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		for (SimpleParameter state : getStates()) {
			if (state.getName().toLowerCase().contains(search))
				result.add(state);
		}
		for (SimpleParameter country : getCountries()) {
			if (country.getName().toLowerCase().contains(search))
				result.add(country);
		}
		for (SimpleParameter month : getMonths()) {
			if (month.getName().toLowerCase().contains(search))
				result.add(month);
		}
		for (SimpleParameter type : getTypes()) {
			if (type.getName().toLowerCase().contains(search))
				result.add(type);
		}
		for (SimpleParameter rank : getRanks()) {
			if (rank.getName().toLowerCase().contains(search))
				result.add(rank);
		}
		for (SimpleParameter code : getCodes()) {
			if (code.getName().toLowerCase().contains(search))
				result.add(code);
		}
		for (SimpleParameter standard : getStandards()) {
			if (standard.getName().toLowerCase().contains(search))
				result.add(standard);
		}
		for (Resource resource : resourceCache.getResources()) {
			if (resource.getName().toLowerCase().contains(search))
				result.add(new SimpleParameter(resource.getName(), resource.getId()));
		}
		return result;
	}
	
	public List<SimpleParameter> getStates() {
		return states;
	}
	
	public List<SimpleParameter> getCountries() {
		return countries;
	}
	
	public List<SimpleParameter> getTypes() {
		return types;
	}
	
	public List<SimpleParameter> getCodes(String search) throws Exception {
		if ((search == null) || (search == ""))
			return getCodes();
		search = search.toLowerCase();
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		for (SimpleParameter code : getCodes()) {
			if (code.getName().toLowerCase().contains(search))
				result.add(code);
		}
		return result;
	}
	
	public List<SimpleParameter> getStandards() throws Exception {
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
				standards = new ArrayList<SimpleParameter>();
				while (rs.next()) {
					String name = rs.getString("Name");
					name = name.replace('|', '-');
					standards.add(new SimpleParameter(name, rs.getString("Id")));
				}
				// Manually add 9001:2008 and 14001:2004
				standards.add(new SimpleParameter("9001:2008 - Certification", "a36900000004FRnAAM"));
				standards.add(new SimpleParameter("9001:2008 - Evaluation", "a36900000004FS9AAM"));
				standards.add(new SimpleParameter("14001:2004 - Certification", "a36900000004FRVAA2"));
				standards.add(new SimpleParameter("14001:2004 - Evaluation", "a36900000004FS6AAM"));
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
		for (SimpleParameter standard : getStandards()) {
			if (standard.getId().equals(id))
				return new Competency(standard.getId(), standard.getName(), CompetencyType.STANDARD, null);
		}
		return null;
	}
	
	public Competency getCodeById(String id) throws Exception {
		if ((id == null) || (id== ""))
			return null;
		for (SimpleParameter code : getCodes()) {
			if (code.getId().equals(id))
				return new Competency(code.getId(), code.getName(), CompetencyType.CODE, null);
		}
		return null;
	}
}
