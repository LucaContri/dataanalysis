package com.saiglobal.sf.reporting.processor;

public class ClientSDCsAndSchedulers extends AbstractQueryReport {

	public ClientSDCsAndSchedulers() {
		this.columnWidth = new int[] {150,300,150,150};
	}
	
	@Override
	protected String getQuery() {
		return "select t.`ClientId`, t.`Client`, t.`SDC`, t.`Manager`, t.`State`, t.`Schedulers`, t.`Site Certs`, t.`Standards` as 'Programs', sqrt(t.`Site Certs`)*t.`Standards` as 'Complexity' from ("
				+ "select "
				+ "client.Id as 'ClientId', "
				+ "client.Client_Number__c as 'Client No',"
				+ "client.Name as 'Client', "
				+ "client.Client_Ownership__c as 'Client Ownership', "
				+ "sdc.Name as 'SDC', "
				+ "sdcm.name as 'Manager',"
				+ "sdc.State, "
				+ "count(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sc.Id,null)) as 'Site Certs',"
				+ "count(distinct if(c.Status__c='Active' and c.IsDeleted=0,c.Id,null)) as 'Certs',"
				+ "count(distinct if(c.Status__c='Active' and c.IsDeleted=0,s.Name,null)) as 'Standards',"
				+ "group_concat(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sched.Name,null)) as 'Schedulers',"
				+ "count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c='Management Systems', sc.Id,null)) as 'MS Site Certs',"
				+ "count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c like '%Food%', sc.Id,null)) as 'Food Site Certs', "
				+ "count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c = 'Product Services', sc.Id,null)) as 'PS Site Certs' "
				+ "from account site "
				+ "inner join recordtype rt on rt.Id = site.RecordTypeId "
				+ "left join account client on site.ParentId = client.Id "
				+ "left join user sdc on client.Service_Delivery_Coordinator__c = sdc.Id "
				+ "left join user sdcm on sdc.ManagerId = sdcm.Id "
				+ "left join certification__c sc on sc.Primary_Client__c = site.Id "
				+ "left join certification__c c on sc.Primary_Certification__c = c.Id "
				+ "left join standard_program__c sp on sp.Id = c.Primary_Standard__c "
				+ "left join standard__c s on sp.Standard__c = s.Id "
				+ "left join user sched on sc.Scheduler__c = sched.Id "
				+ "where "
				+ "rt.Name = 'Client Site' "
				+ "and site.IsDeleted = 0 "
				+ "and client.IsDeleted = 0 "
				+ "and client.Client_Ownership__c = 'Australia' "
				+ "group by client.Id) t "
				+ "where t.`Site Certs`>0 "
				+ "and t.`MS Site Certs`>0 "
				+ "and t.`Food Site Certs`=0 "
				+ "and t.`PS Site Certs`=0";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\SDC\\Client_SDCs_Schedulers";
	}
	
	@Override
	protected String getTitle() {
		return "Clients with SDCs and Schedulers";
	}
}
