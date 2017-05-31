package com.saiglobal.sf.api.data;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import com.google.code.geocoder.model.LatLng;
import com.saiglobal.sf.api.utility.Utility;
import com.saiglobal.sf.core.model.Client;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;

public class DbHelper extends com.saiglobal.sf.core.data.DbHelperConnPool {

	public DbHelper(GlobalProperties cmd) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		super(cmd);
		airports = loadAirports();
	}
	
	public List<WorkItem> getWorkItemsByName(String[] workItemsNames) throws GeoCodeApiException, SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String whereClause = " WHERE wi.Name IN (";
		boolean first = true;
		for (String name : workItemsNames) {
			if (first) {
				whereClause += "'" + name + "'";
				first = false;
			} else {
				whereClause += ", '" + name + "'";
			}
		}
		whereClause += ")";
		
		return getWorkItembatch(whereClause);
	}
	
	public List<WorkItem> getWorkItemsById(String[] workItemsIds) throws GeoCodeApiException, SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		String whereClause = " WHERE wi.Id IN (";
		boolean first = true;
		for (String id : workItemsIds) {
			if (first) {
				whereClause += "'" + id + "'";
				first = false;
			} else {
				whereClause += ", '" + id + "'";
			}
		}
		whereClause += ")";
		
		return getWorkItembatch(whereClause);
	}

	public WorkItem getWorkItemByName(String workItemName) throws GeoCodeApiException, SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		List<WorkItem> list = getWorkItemsByName(new String[] {workItemName});
		if ((list != null) && (list.size()==1))
			return list.get(0);
		return null;
	}
	
	public WorkItem getWorkItemById(String workItemId) throws GeoCodeApiException, SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		List<WorkItem> list = getWorkItemsById(new String[] {workItemId});
		if ((list != null) && (list.size()==1))
			return list.get(0);
		return null;
	}
	public List<WorkItem> searchWorkItem(String search) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		return this.searchWorkItem(search, 100);
	}
	public List<WorkItem> searchWorkItem(String search, int limit) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Utility.startTimeCounter("DbHelper.searchWorkItem");
		List<WorkItem> workItems = new ArrayList<WorkItem>();
		String query = "select wi.Id, wi.Name, wi.Status__c, wi.Client_Name__c, wi.Client_Site__c, wi.SF_Site_Certification__c , wi.Work_Item_Date__c " +
				"from work_item__c wi " +
				"where " +
				"wi.IsDeleted=0 " +
				//"and wi.Name = '" + search + "'" +
				"and wi.Status__c IN ('Open','Scheduled','Scheduled - Offered', 'Confirmed', 'Service Change') " +
				"and match (wi.Name, wi.Client_Site__c) against ('" + search + "') " + 
				//"and wi.Client_Site__c like '%" + search + "%') " +
				//"or wi.SF_Site_Certification__c = '" + search + "') " +
				"order by wi.Client_Site__c, wi.Service_target_date__c " +
				"LIMIT " + limit;
		ResultSet rs = this.executeSelect(query, -1);
		while (rs.next()) {
			WorkItem workItem = new WorkItem();
			workItem.setId(rs.getString("wi.Id"));
			workItem.setName(rs.getString("wi.Name"));
			workItem.setSfStatus(rs.getString("wi.Status__c"));
			workItem.setSiteCertName(rs.getString("wi.SF_Site_Certification__c"));
			if (rs.getTimestamp("Work_Item_Date__c")!=null)
				workItem.setStartDate(new Date(rs.getTimestamp("wi.Work_Item_Date__c").getTime()));
			Location clientSite = new Location();
			clientSite.setName(rs.getString("wi.Client_Site__c"));
			workItem.setClientSite(clientSite);
			workItems.add(workItem);
		}
		Utility.stopTimeCounter("DbHelper.searchWorkItem");
		return workItems;
	}
	
	public WorkItem getOpportunityLineItemAsWorkItem(String oppLineItemId) throws GeoCodeApiException, ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Utility.startTimeCounter("DbHelper.getOpportunityLineItemAsWorkItem");
		WorkItem workItem = null;
		String query = "select "
				+ "o.Id, "
				+ "o.Name, "
				+ "o.Proposed_Delivery_Date__c, "
				+ "o.Probability, "
				+ "p.name, "
				+ "oli.Id, "
				+ "oli.Days__c, "
				+ "c.Name, "				
				+ "c.Business_Address_1__c, "
				+ "c.Business_Address_2__c, "
				+ "c.Business_Address_3__c, "
				+ "c.Business_City__c, "
				+ "c.Business_Zip_Postal_Code__c, "
				+ "c.FCountry__c, "
				+ "scs.Name as 'State', "
				+ "sp.Standard__c, "
				+ "s.Name, "
				+ "cd.Name, "
				+ "cd.Id "
				+ "from opportunity o "
				+ "left join opportunitylineitem oli ON oli.OpportunityId = o.Id "
				+ "left join pricebookentry pbe ON pbe.Id = oli.PricebookEntryId "
				+ "left join product2 p ON p.Id = pbe.Product2Id "
				+ "left join opportunity_site_certification__c osc ON osc.Id = oli.Opportunity_Site_Certification__c "
				+ "left join account c ON c.Id = osc.Client_Site__c "
				+ "left join State_Code_Setup__c scs ON c.Business_State__c = scs.Id "
				+ "left join oppty_site_cert_standard_program__c oscs ON oscs.Opportunity_Site_Certification__c = osc.Id "
				+ "left join standard_program__c sp ON oscs.Standard_Program__c = sp.Id "
				+ "left join standard__c s ON sp.Standard__c = s.Id "
				+ "left join opportunity_site_certification_code__c oscc ON oscc.Oppty_Site_Cert_Standard_Program__c = oscs.Id "
				+ "left join code__c cd ON cd.Id = oscc.Code__c "
				+ "where "
				+ "oli.Id = '" + oppLineItemId + "' "
				+ "and o.IsDeleted = 0 "
				+ "and oli.Status__c = 'Active' "
				+ "and oli.Days__C > 0 "
				+ "order by p.name , c.Name , s.Name , cd.Name";
		
		ResultSet rs = this.executeSelect(query, 10);
		boolean first = true;
		List<Competency> requiredCompetencies = new ArrayList<Competency>();
		
		while (rs.next()) {
			if (first) {
				workItem = new WorkItem();
				workItem.setId(rs.getString("oli.Id"));
				workItem.setName(rs.getString("p.name"));
				workItem.setOpportunityName(rs.getString("o.Name"));
				workItem.setOpportunityProbability(rs.getDouble("o.Probability")/100);
				if (rs.getTimestamp("o.Proposed_Delivery_Date__c")!=null) {
					workItem.setStartDate(new Date(rs.getTimestamp("o.Proposed_Delivery_Date__c").getTime()));
				}
				Location clientSite = new Location();
				Client client = new Client();
				client.setName(rs.getString("c.Name"));
				clientSite.setName(rs.getString("c.Name"));
				clientSite.setAddress_1(rs.getString("c.Business_Address_1__c"));
				clientSite.setAddress_2(rs.getString("c.Business_Address_2__c"));
				clientSite.setAddress_3(rs.getString("c.Business_Address_3__c"));
				clientSite.setCity(rs.getString("c.Business_City__c"));
				clientSite.setState(rs.getString("State"));
				clientSite.setCountry(rs.getString("c.FCountry__c"));
				clientSite.setPostCode(rs.getString("c.Business_Zip_Postal_Code__c"));
				LatLng coordinates = Utility.getGeocode(clientSite, this);
				if ((coordinates != null) && (coordinates.getLat() != null) && (coordinates.getLng() != null)) {
					clientSite.setLatitude(coordinates.getLat().doubleValue());
					clientSite.setLongitude(coordinates.getLng().doubleValue());
				}
				
				requiredCompetencies.add(new Competency(rs.getString("sp.Standard__c"), rs.getString("s.Name"), CompetencyType.PRIMARYSTANDARD, null));
				workItem.setClientSite(clientSite);
				workItem.setClient(client);
				workItem.setRequiredDuration(rs.getDouble("oli.Days__c")*8);
				first = false;
			}
			boolean codeMissing = true;
			// Set Required Codes
			if (rs.getString("cd.Name") != null) {
				requiredCompetencies.add(new Competency(rs.getString("cd.Id"), rs.getString("cd.Name"), CompetencyType.CODE, null));
				codeMissing = false;
			}
			if (codeMissing) {
				requiredCompetencies.add(new Competency("", "", CompetencyType.NO_CODE_AVAILABLE, null));
			}
		}
		
		if (workItem!=null) {
			workItem.setRequiredCompetencies(requiredCompetencies);
		}
		
		Utility.stopTimeCounter("DbHelper.getOpportunityLineItemAsWorkItem");
		return workItem;
	}
	
	public List<WorkItem> searchOpportunity(String search) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		return this.searchOpportunity(search, 100);
	}
	
	public List<WorkItem> searchOpportunity(String search, int limit) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		Utility.startTimeCounter("DbHelper.searchOpportunity");
		// Returns a list of fictous  work items with info regarding 
		List<WorkItem> workItems = new ArrayList<WorkItem>();
		String query = "select "
				+ "o.Id, "
				+ "o.Name, "
				+ "oli.Id, "
				+ "oli.Client_Site__c, "
				+ "p.name as 'Product', "
				+ "o.Proposed_Delivery_Date__c "
				+ "from opportunity o "
				+ "left join opportunitylineitem oli ON oli.OpportunityId = o.Id "
				+ "left join pricebookentry pbe ON pbe.Id = oli.PricebookEntryId "
				+ "left join product2 p ON p.Id = pbe.Product2Id "
				+ "where "
				+ "o.Name like '%" + search + "%' "
				+ "and o.IsDeleted = 0 "
				+ "and oli.Status__c = 'Active' "
				+ "and oli.Days__C > 0 "
				+ "order by o.Name , oli.Client_Site__c , p.Name "
				+ "LIMIT " + limit;
		ResultSet rs = this.executeSelect(query, -1);
		while (rs.next()) {
			WorkItem workItem = new WorkItem();
			workItem.setId(rs.getString("oli.Id"));
			workItem.setName(rs.getString("Product"));
			workItem.setOpportunityName(rs.getString("o.Name"));
			if (rs.getTimestamp("o.Proposed_Delivery_Date__c")!=null)
				workItem.setStartDate(new Date(rs.getTimestamp("o.Proposed_Delivery_Date__c").getTime()));
			Location clientSite = new Location();
			clientSite.setName(rs.getString("oli.Client_Site__c"));
			workItem.setClientSite(clientSite);
			workItems.add(workItem);
		}
		Utility.stopTimeCounter("DbHelper.searchOpportunity");
		return workItems;
	}
	
	public void logRequest(ApiRequest request) {
		if ((request == null) || (request.getRequest()==null))
			return;
		try {
			String insert = "insert into " + getDBTableName("saig_schedulingapi_log") + " (`Request`, `LastUpdate`, `Client`, `Outcome`, `TimeMs`) values ('" + request.getRequest() + "', now(), '" + (request.getClient()==null?"":request.getClient()) + "','" + (request.getOutcome()==null?"":request.getOutcome()) + "'," + request.getTimeMs() + ")";
			this.executeStatement(insert);
		} catch (Exception e) {
			logger.error(e);
		}
	}
}
