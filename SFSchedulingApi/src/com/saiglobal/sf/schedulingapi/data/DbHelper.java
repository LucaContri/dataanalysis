package com.saiglobal.sf.schedulingapi.data;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.schedulingapi.utility.Utility;

public class DbHelper extends com.saiglobal.sf.core.data.DbHelper {

	public DbHelper(GlobalProperties cmd) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		super(cmd);
		airports = loadAirports();
	}
	
	public List<WorkItem> getWorkItemsByName(String[] workItemsNames) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
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
	
	public List<WorkItem> getWorkItemsById(String[] workItemsIds) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
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

	public WorkItem getWorkItemByName(String workItemName) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		List<WorkItem> list = getWorkItemsByName(new String[] {workItemName});
		if ((list != null) && (list.size()==1))
			return list.get(0);
		return null;
	}
	
	public WorkItem getWorkItemById(String workItemId) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
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
				"from salesforce.work_item__c wi " +
				"where " +
				"wi.IsDeleted=0 " +
				"and match (wi.Name, wi.Client_Site__c) against ('" + search + "') " + 
				"order by wi.Client_Site__c, SF_Site_Certification__c, wi.Name " +
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
}
