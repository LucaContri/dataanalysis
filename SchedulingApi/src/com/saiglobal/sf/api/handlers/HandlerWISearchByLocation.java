package com.saiglobal.sf.api.handlers;

import java.io.StringWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.Utility;

public class HandlerWISearchByLocation {
	
	//public static Object handle(HttpServletRequest request, HttpServletResponse response, String locationId, String[] revenueOwnership, int maxDistance, int noOfMonths, DbHelper db, boolean debug)
	public static Object handle(HttpServletRequest request, HttpServletResponse response, String locationId, int maxDistance, int noOfMonths, DbHelper db, boolean debug)
	{
		Utility.startTimeCounter("handle");
		response.setContentType("text/json");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			String query = "select * from ("
					+ "select "
					//+ "concat(t.suburb, ', ',t.state, ', ', t.postcode) as 'Target', "
					+ "t2.Client_Name_No_Hyperlink__c as 'Client', "
					+ "t2.Business_City__c as 'City', t2. Business_Zip_Postal_Code__c as 'PostCode', "
					+ "t2.Auditor, "
					+ "t2.Name as 'Audit', "
					+ "date_format(t2.Earliest_Service_Date__c, '%Y-%m-%d') as 'Start Date', "
					+ "date_format(t2.End_Service_Date__c, '%Y-%m-%d') as 'End Date', "
					+ "t2.Status__c as 'Status', "
					+ "round(distance(t.Latitude, t.Longitude, SUBSTRING_INDEX(t2.Geo_Code__c, ', ',1), SUBSTRING_INDEX(t2.Geo_Code__c, ', ',-1)),1) as 'Distance' from "
					+ "(select suburb, state, postcode, latitude, longitude from analytics.postcodes_geo where id = '" + locationId + "') t,"
					+ "(select wi.Id, wi.Client_Name_No_Hyperlink__c, wi.Earliest_Service_Date__c, wi.End_Service_Date__c, wi.Name, r.Name as 'Auditor', wi.Work_Item_Date__C, wi.Status__c, `site`.Geo_Code__c, `site`.Geo_Location__c, `site`.Business_City__c, `site`.Business_Zip_Postal_Code__c from "
					+ "work_item__c wi "
					+ "inner join work_package__c wp on wi.Work_Package__c = wp.Id "
					+ "inner join certification__c sc on wp.Site_Certification__c = sc.Id "
					+ "inner join account `site` on sc.Primary_client__c = `site`.Id "
					+ "inner join resource__c r on wi.Work_Item_Owner__c = r.Id "
					+ "where wi.Status__c not in ('Open', 'Cancelled') "
					+ "and wi.IsDeleted = 0 "
					+ "and wi.Work_Item_Date__c >= date_add(now(), interval 0 month) "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') <= date_format(date_add(now(), interval " + noOfMonths + " month), '%Y-%m')"
					+ "and `site`.Geo_Code__c is not null "
					+ ") t2) t3 "
					+ "where t3.Distance<= " + maxDistance + " "
					+ "order by t3.distance asc;";
			return com.saiglobal.sf.core.utility.Utility.resultSetToObjectArray(db.executeSelect(query, -1), true);
			
		} catch (Exception e) {
			com.saiglobal.sf.core.utility.Utility.getLogger().error(errorMessage, e);
		} finally {
			Utility.stopTimeCounter("handle");
		}
		
		// Exception.  Return Internal Server error
		response.setStatus(500); // 500 Internal Server Error
        return Utility.serializeErrorResponse("Internal Server Error: " + errorMessage.toString(), false);
	} 
}
