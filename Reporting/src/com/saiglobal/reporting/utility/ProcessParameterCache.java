package com.saiglobal.reporting.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashSet;
import java.util.List;
import java.util.concurrent.Semaphore;

import com.saiglobal.reporting.model.CustomFilters;
import com.saiglobal.reporting.model.SimpleParameter;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.downloader.sf.SfHelper;
import com.sforce.soap.partner.DescribeSObjectResult;
import com.sforce.soap.partner.Field;
import com.sforce.soap.partner.FieldType;
import com.sforce.soap.partner.PicklistEntry;

public class ProcessParameterCache {
	private static ProcessParameterCache reference= null;
	private static final int refreshIntervalHrs = 5*24;
	private DbHelper db = null;
	private SfHelper sf = null;
	private Calendar lastUpdatePathways;
	private Calendar lastUpdatePrograms;
	private Calendar lastUpdateStandards;
	private Calendar lastUpdateClientOwnerships;
	private Calendar lastUpdateRevenueOwnerships;
	private Calendar lastUpdateResources;
	private Calendar lastUpdateTags;
	private Semaphore update = new Semaphore(1);
	private List<SimpleParameter> pathways = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> programs = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> standards = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> clientOwnerships = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> revenueOwnerships = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> resources = new ArrayList<SimpleParameter>();
	private List<SimpleParameter> tags = new ArrayList<SimpleParameter>();
	private static final String TAG_PREFIX = "Tag:";
	// Static lists
	//private static List<SimpleParameter> states = new ArrayList<SimpleParameter>();
	
	static {
		// TODO: Init constant parameters here
		//states.add(new SimpleParameter("New South Wales (NSW)", "NSW"));
		
	}
	
	private ProcessParameterCache(DbHelper db, SfHelper sf) {
		this.db = db;
		this.sf = sf;
	}

	public static ProcessParameterCache getInstance(DbHelper db, SfHelper sf) {
		if( reference == null) {
			synchronized (  ProcessParameterCache.class) {
			  	if( reference  == null)
			  		reference  = new ProcessParameterCache(db, sf);
			}
		}
		return  reference;
	}

	
	public List<SimpleParameter> getParameters(String search) throws Exception {
		if ((search == null) || (search == ""))
			return getStandards();
		search = search.toLowerCase();
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		
		for (SimpleParameter standard : getStandards()) {
			if (standard.getName().toLowerCase().contains(search))
				result.add(standard);
		}
		
		for (SimpleParameter program : getPrograms()) {
			if (program.getName().toLowerCase().contains(search))
				result.add(program);
		}
		
		for (SimpleParameter pathway : getPathways()) {
			if (pathway.getName().toLowerCase().contains(search))
				result.add(pathway);
		}
		
		for (SimpleParameter clientOwnership : getClientOwnerships()) {
			if (clientOwnership.getName().toLowerCase().contains(search))
				result.add(clientOwnership);
		}
		
		for (SimpleParameter revenueOwnership : getRevenueOwnerships()) {
			if (revenueOwnership.getName().toLowerCase().contains(search))
				result.add(revenueOwnership);
		}
		
		for (SimpleParameter resource : getResources()) {
			if (resource.getName().toLowerCase().contains(search))
				result.add(resource);
		}
		
		for (SimpleParameter tag : getTags()) {
			if (tag.getName().toLowerCase().contains(search))
				result.add(tag);
		}
		
		for (CustomFilters filter : CustomFilters.values()) {
			if(filter.name.toLowerCase().contains(search))
				result.add(new SimpleParameter(filter.name, filter.ids));
		}
		return result;
	}
	
	public List<SimpleParameter> getStandards() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdateStandards == null || lastUpdateStandards.before(intervalBefore)) {
				String query = "select s.Name as 'Name', s.Id as 'Id' from standard__c s "
						+ "where s.IsDeleted=0 "
						+ "and s.Parent_Standard__c is not null "
						//+ "and s.Status__c = 'Active' "
						+ "order by s.Name";
				try {
					ResultSet rs = db.executeSelect(query, -1);
					standards = new ArrayList<SimpleParameter>();
					while (rs.next()) {
						String name = rs.getString("Name");
						name = name.replace('|', '-');
						standards.add(new SimpleParameter(name, rs.getString("Id")));
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdateStandards = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return standards;
	}
	
	public List<SimpleParameter> getPrograms() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdatePrograms == null || lastUpdatePrograms.before(intervalBefore)) {
				String query = "select p.Name as 'Name', p.Id as 'Id' from program__c p "
						+ "where p.IsDeleted=0 "
						+ "order by p.Name";
				try {
					ResultSet rs = db.executeSelect(query, -1);
					programs = new ArrayList<SimpleParameter>();
					while (rs.next()) {
						String name = rs.getString("Name");
						programs.add(new SimpleParameter(name, rs.getString("Id")));
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdatePrograms = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return programs;
	}
	
	public List<SimpleParameter> getPathways() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdatePathways == null || lastUpdatePathways.before(intervalBefore)) {
				String query = "select p.Pathway__c as 'Name', p.Pathway__c as 'Id' from program__c p "
						+ "where p.IsDeleted=0 "
						+ "and p.Pathway__c is not null "
						+ "group by p.Pathway__c "
						+ "order by p.Pathway__c";
				try {
					ResultSet rs = db.executeSelect(query, -1);
					pathways = new ArrayList<SimpleParameter>();
					while (rs.next()) {
						String name = rs.getString("Name");
						pathways.add(new SimpleParameter(name, rs.getString("Id")));
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdatePathways = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return pathways;
	}
	
	public List<SimpleParameter> getTags() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdateTags == null || lastUpdateTags.before(intervalBefore)) {
				String query = "select distinct(tags) as 'Tags' from sf_business_process_details;";
				try {
					ResultSet rs = db.executeSelect(query, -1);
					tags = new ArrayList<SimpleParameter>();
					HashSet<String> tagsStrings = new HashSet<String>();
					while (rs.next()) {
						String tagsString = rs.getString("Tags");
						if (tagsString != null) {
							for (String tag : tagsString.split(";")) {
								tagsStrings.add(tag);
							}
						}
					}
					
					for (String tag : tagsStrings) {
						tags.add(new SimpleParameter(TAG_PREFIX + tag, tag));
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdateTags = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return tags;
	}
	
	public List<SimpleParameter> getResources() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		try {
			update.acquire();
			if(lastUpdateResources== null || lastUpdateResources.before(intervalBefore)) {
				String query = "select r.id, r.name from resource__c r where r.IsDeleted = 0";
				try {
					ResultSet rs = db.executeSelect(query, -1);
					resources = new ArrayList<SimpleParameter>();
					while (rs.next()) {
						String name = rs.getString("Name");
						name = name.replace('|', '-');
						resources.add(new SimpleParameter(name, rs.getString("Id")));
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdateResources = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return resources;
	}
	
	public List<SimpleParameter> getClientOwnerships() throws InterruptedException {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdateClientOwnerships== null || lastUpdateClientOwnerships.before(intervalBefore)) {
				
				try {
					clientOwnerships = new ArrayList<SimpleParameter>();
					DescribeSObjectResult desc = sf.describeObject("account");
					for (Field field : desc.getFields()) {
						if (field.getName().equalsIgnoreCase("Client_Ownership__c") && field.getType().equals(FieldType.picklist)) {
							for (PicklistEntry entry: field.getPicklistValues()) {
								clientOwnerships.add(new SimpleParameter(entry.getLabel(), entry.getLabel()));
							}
						}
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdateClientOwnerships = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return clientOwnerships;
	}
	
	public List<SimpleParameter> getRevenueOwnerships() throws InterruptedException {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		try {
			update.acquire();
			if(lastUpdateRevenueOwnerships== null || lastUpdateRevenueOwnerships.before(intervalBefore)) {
				
				try {
					clientOwnerships = new ArrayList<SimpleParameter>();
					DescribeSObjectResult desc = sf.describeObject("certification__c");
					for (Field field : desc.getFields()) {
						if (field.getName().equalsIgnoreCase("Revenue_Ownership__c") && field.getType().equals(FieldType.picklist)) {
							for (PicklistEntry entry: field.getPicklistValues()) {
								revenueOwnerships.add(new SimpleParameter(entry.getLabel(), entry.getLabel()));
							}
						}
					}
				} catch (Exception e) {
					throw e;
				}
				lastUpdateRevenueOwnerships = Calendar.getInstance();
			}
		} catch (Exception e) {
			throw e;
		} finally {
			update.release();
		}
		return revenueOwnerships;
	}
	
	public SimpleParameter getResourceById(String id) throws Exception {
		for (SimpleParameter resource: getResources()) {
			if (resource.getId().equals(id))
				return resource;
		}
		return null;
	}
	
	public boolean isResource(String id) throws Exception {
		for (SimpleParameter resource: getResources()) {
			if (resource.getId().equals(id))
				return true;
		}
		return false;
	}
	
	public boolean isClientOwnership(String name) throws InterruptedException {
		for (SimpleParameter clientOwnership: getClientOwnerships()) {
			if (clientOwnership.getName().equals(name))
				return true;
		}
		return false;
	}
	
	public boolean isRevenueOwnership(String name) throws InterruptedException {
		for (SimpleParameter revenueOwnership: getRevenueOwnerships()) {
			if (revenueOwnership.getName().equals(name))
				return true;
		}
		return false;
	}
	
	public boolean isTag(String id) throws Exception {
		for (SimpleParameter tag: getTags()) {
			if (tag.getName().startsWith(TAG_PREFIX) && tag.getId().equals(id))
				return true;
		}
		return false;
	}
	
	public boolean isStandard(String id) throws Exception {
		for (SimpleParameter standard: getStandards()) {
			if (standard.getId().equals(id))
				return true;
		}
		return false;
	}
	
	public boolean isProgram(String id) throws Exception {
		for (SimpleParameter program: getPrograms()) {
			if (program.getId().equals(id))
				return true;
		}
		return false;
	}
	
	public boolean isPathway(String id) throws Exception {
		for (SimpleParameter pathway: getPathways()) {
			if (pathway.getId().equals(id))
				return true;
		}
		return false;
	}
	
	public SimpleParameter getStandardById(String id) throws Exception {
		for (SimpleParameter standard: getStandards()) {
			if (standard.getId().equals(id))
				return standard;
		}
		return null;
	}
	public SimpleParameter getProgramById(String id) throws Exception {
		for (SimpleParameter program: getPrograms()) {
			if (program.getId().equals(id))
				return program;
		}
		return null;
	}
}
