package com.saiglobal.sf.api.handlers;

import java.io.StringWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang3.StringUtils;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.utility.Utility;

public class HandlerWISearch {
	
	public static Object handle(HttpServletRequest request, HttpServletResponse response, String[] resourceId, String[] revenueOwnership, int noOfMonths, DbHelper db, boolean debug)
	{
		Utility.startTimeCounter("handle");
		response.setContentType("text/json");
		
		StringWriter errorMessage = new StringWriter();
		
		try {
			String query = "select s.`Auditor`, concat('<a href=\"https://na14.salesforce.com/', s.`Id`, '\" target=\"_blank\">',s.`Name`,'</a>') as 'Work Item', s.`Client Site`, s.`Primary Standard`, s.`Work Item Date`, s.`Revenue Ownership` from ("
					+ "select rc.Name as 'Auditor', wir.Id, wir.Name, wir.Client_Site__c as 'Client Site', wir.Primary_Standard__c as 'Primary Standard', wir.work_item_Date__c as 'Work Item Date', wir.Revenue_Ownership__c as 'Revenue Ownership',count(wir.`Id`) as 'Requirement Count', count(if(locate(wir.Requirement,rc.`Competencies`)>0, rc.Id, null)) as 'Matching Capabilities' from ("
					+ "select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c, 'Primary Standard' as 'Type', sp.Standard__c as 'Requirement' "
					+ "from work_item__c wi "
					+ "inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id "
					+ "inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id "
					+ "where "
					+ "wi.Revenue_Ownership__c in ('" + StringUtils.join(revenueOwnership, "','") + "') "
					+ "and wi.Status__C in ('Open') "
					+ "and (wi.Open_Sub_Status__c not in ('Pending Cancellation','Pending Suspension') or wi.Open_Sub_Status__c is null) "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') >= date_format(utc_timestamp(), '%Y-%m') "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') <= date_format(date_add(utc_timestamp(), interval " + noOfMonths + " month), '%Y-%m') "
					+ "and wi.IsDeleted = 0 "
					+ "union "
					+ "select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c,'Standard Family' as 'Type', sp.standard__c "
					+ "from work_item__c wi "
					+ "inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id "
					+ "inner join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id "
					+ "inner join standard_program__c sp on scsf.Standard_Program__c = sp.Id "
					+ "where "
					+ "wi.Revenue_Ownership__c in ('" + StringUtils.join(revenueOwnership, "','") + "') "
					+ "and wi.Status__C in ('Open') "
					+ "and (wi.Open_Sub_Status__c not in ('Pending Cancellation','Pending Suspension') or wi.Open_Sub_Status__c is null) "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') >= date_format(utc_timestamp(), '%Y-%m') "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') <= date_format(date_add(utc_timestamp(), interval " + noOfMonths + " month), '%Y-%m') "
					+ "and wi.IsDeleted = 0 "
					+ "and scsp.IsDeleted = 0 "
					+ "and scsf.IsDeleted=0 "
					+ "and sp.IsDeleted=0 "
					+ "union "
					+ "select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c, 'Code' as 'Type', scspc.code__c "
					+ "from work_item__c wi "
					+ "inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id "
					+ "inner join site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id "
					+ "where "
					+ "wi.Revenue_Ownership__c in ('" + StringUtils.join(revenueOwnership, "','") + "') "
					+ "and wi.Status__C in ('Open') "
					+ "and (wi.Open_Sub_Status__c not in ('Pending Cancellation','Pending Suspension') or wi.Open_Sub_Status__c is null) "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') >= date_format(utc_timestamp(), '%Y-%m') "
					+ "and date_format(wi.Work_Item_Date__c, '%Y-%m') <= date_format(date_add(utc_timestamp(), interval " + noOfMonths + " month), '%Y-%m') "
					+ "and wi.IsDeleted = 0 "
					+ "and scsp.IsDeleted = 0 "
					+ "and scspc.IsDeleted = 0) wir, "
					+ "(select r.Id, r.Name, group_concat(if(rc.Code__c is null, rc.standard__c, rc.code__c)) as 'Competencies' "
					+ "from resource__c r  "
					+ "inner join resource_competency__c rc on rc.Resource__c = r.Id "
					+ "where "
					+ "r.Id in ('" + StringUtils.join(resourceId, "','") + "') "
					+ "and (rc.Rank__c like '%Lead Auditor%' or rc.Code__C is not null) "
					+ "and rc.IsDeleted=0 "
					+ "and rc.Status__c = 'Active' "
					+ "group by r.Id) rc "
					+ "group by wir.Id, rc.Id) s "
					+ "where s.`Requirement Count` = s.`Matching Capabilities`;";
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
