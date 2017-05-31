package com.saiglobal.sf.reporting.processor;	

import java.util.Calendar;

import com.saiglobal.sf.core.utility.Utility;

public class AuditorsAuditsMatrix extends AbstractQueryReport {

	private String nameSuffix = null;
	public AuditorsAuditsMatrix() {
		setHeader(false);
	}
	
	@Override
	protected void finaliseQuery() throws Throwable {
		db.executeStatement("drop table if exists rot_req_audits;");
		db.executeStatement("drop table if exists rot_req_audits_hist;");
	}

	@Override
	protected void initialiseQuery() throws Throwable {
		db.executeStatement("drop table if exists rot_req_audits;");
		db.executeStatement("create table rot_req_audits as ( " + 
			"select t.SiteId, t.SiteName, t.SiteCertId, t.SiteCertName, t.StdName, t.StdFamilyName, t.WIName, t.WIId, Work_Item_Stage__c, t.work_item_Date__c,  " + 
			"if(concat(t.StdName, if(t.StdFamilyName is null, '',t.StdFamilyName)) like '%BRC%', 1,0) as 'BRC', " + 
			"if(concat(t.StdName, if(t.StdFamilyName is null, '',t.StdFamilyName)) like '%SQF%', 1,0) as 'SQF', " + 
			"if(concat(t.StdName, if(t.StdFamilyName is null, '',t.StdFamilyName)) like '%Woolworth%', 1,0) as 'WQA',  " + 
			"group_concat(distinct t.ResourceName) as 'ResourceName', group_concat(distinct t.ResourceId) as 'ResourceId'  " + 
			"from ( " + 
			"select  " + 
			"site.Id as 'SiteId', site.Name as 'SiteName', sc.Id as 'SiteCertId', sc.Name as 'SiteCertName', std.Name as 'StdName',  " + 
			"group_concat(sf.Name) as 'StdFamilyName',  " + 
			"wi.Name as 'WINAme', wi.Id as 'WIId', wi.Work_Item_Stage__c, wi.work_item_Date__c, r.Name as 'ResourceName', r.Id as 'ResourceId' " + 
			"from site_certification_standard_program__c scsp " + 
			"left join site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id " + 
			"left join standard_program__c spf on scspf.Standard_Program__c = spf.Id " + 
			"left join standard__c sf on spf.Standard__c = sf.Id " + 
			"inner join certification__c sc on scsp.Site_Certification__c = sc.Id " + 
			"inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id " + 
			"inner join standard__c std on sp.Standard__c = std.Id " + 
			"inner join account site on sc.Primary_client__c = site.Id " + 
			"inner join work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id " + 
			"inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id " + 
			"inner join resource__c r on wir.Resource__c = r.Id " + 
			"where  " + 
			"( (std.Name like '%Woolworth%' or (sf.Name like '%Woolworth%' and scspf.IsDeleted=0) or (std.Name like '%Woolworth%' and scspf.Id is null)) or " + 
			"(std.Name like '%BRC%' or (sf.Name like '%BRC%' and scspf.IsDeleted=0) or (std.Name like '%BRC%' and scspf.Id is null)) or  " + 
			"(std.Name like '%SQF%' or (sf.Name like '%SQF%' and scspf.IsDeleted=0) or (std.Name like '%SQF%' and scspf.Id is null)) ) " + 
			"and wi.Status__c = 'Completed' " + 
			"and wi.IsDeleted = 0 " + 
			"and wir.IsDeleted = 0 " + 
			"and wir.Role__c in ('Lead Auditor', 'Auditor') " + 
			"and wi.Work_Item_Stage__c in  ('Certification','Surveillance', 'Re-Certification', 'Unannounced Certification','Unannounced Surveillance', 'Unannounced Re-Certification') " + 
			"group by scsp.Id, wi.Id, wir.Id " + 
			"order by site.Id, wi.Work_Item_Date__c) t group by t.WIId order by t.Work_Item_Date__c " + 
			");");
		
			db.executeStatement("drop table if exists rot_req_audits_hist; ");
			db.executeStatement("create table rot_req_audits_hist as ( " + 
				"select rra.SiteId, rra.SiteName, rra.SiteCertId, rra.SiteCertName, rra.StdName, rra.StdFamilyName, scah.Name as 'WIName', 'n/a' as 'WIId',  scah.Audit_Type__c as 'Work_Item_Stage__c',  " + 
				"scah.From_Date__c as 'work_item_Date__c', rra.BRC, rra.SQF, rra.WQA, scah.Team_Leader__c as 'ResourceName', r.Id as 'ResourceId' " + 
				"from rot_req_audits rra " + 
				"inner join certification_activity_history__c scah on rra.SiteCertId = scah.Site_Certification__c " + 
				"left join resource__c r on r.Name = scah.Team_Leader__c " + 
				"where  " + 
				"scah.Audit_Type__c in ('Surveillance Audit', 'Certification Audit','Triennial Audit') " + 
				"and scah.Status__c = 'Completed'  " + 
				"order by scah.From_Date__c desc);");
	}
	
	@Override
	protected String getQuery() {
		int fromMonth = 3;
		int toMonth = 13;
		String rev_own_like = "AUS-Food%";
		
		if (gp.hasCustomParameter("fromMonth")) {
			try {
				fromMonth = Integer.parseInt(gp.getCustomParameter("fromMonth"));
			} catch (Exception e) {
				// Ignore
			}
		}
		if (gp.hasCustomParameter("toMonth")) {
			try {
				toMonth = Integer.parseInt(gp.getCustomParameter("toMonth"));
			} catch (Exception e) {
				// Ignore
			}
		}
		if (gp.hasCustomParameter("revOwnLike") && (gp.getCustomParameter("revOwnLike") != null) && (gp.getCustomParameter("revOwnLike") != "")) {
			rev_own_like = gp.getCustomParameter("revOwnLike");
		}
		if (gp.hasCustomParameter("nameSuffix") && (gp.getCustomParameter("nameSuffix") != null) && (gp.getCustomParameter("nameSuffix") != "")) {
			nameSuffix = gp.getCustomParameter("nameSuffix");
		} else {
			nameSuffix = rev_own_like.replaceAll("%", ""); 
		}
		Calendar today = Calendar.getInstance();
		today.add(Calendar.MONTH, fromMonth);
		String periodFrom = Utility.getPeriodformatter().format(today.getTime());
		today.add(Calendar.MONTH, toMonth-fromMonth);
		String periodTo = Utility.getPeriodformatter().format(today.getTime());
		
		
		//periodFrom = "2016-06";
		//periodTo = "2016-06";
		//rev_own_like = "AUS-Food-NSW/ACT";
		
		return "select mat.*, da.`Days Available`, if (((mat.BRC=1 and rr.BRC=1) or (mat.SQF=1 and rr.SQF=1) or (mat.WQA=1 and rr.WQA=1)) and rr.ResourceIdNotAllowed=mat.`Resource Id`, 1,0) as 'RotReqNotAllowed' " + 
		"from ( " + 
		"SELECT  " + 
		"	 s.`Resource Id` as 'Resource Id', " + 
		"    s.`Auditor`, " + 
		"    s.Reporting_Business_Units__c as 'Reporting Business Unit', " + 
		"    s.Resource_Type__c as 'Resource Type', " + 
		"    s.Resource_Capacitiy__c as 'Resource Capacity', " + 
		"    s.`Id` as 'Work Item Id', " + 
		"    s.`Name` as 'Work Item', " + 
		"    s.Status__c as 'Work Item Status', " + 
		"    s.`Client`, " + 
		"    s.`ClientSiteId`, " + 
		"    s.`Client Site`, " + 
		"	 s.`Scheduling Complexity`, " + 
		"    s.`Scheduler`,  " + 
		"    s.`Primary Standard`, " + 
		"    s.`Work Item Date`, " +
		"    s.`Work Item Stage`," +
		"    s.`Family Standards`, " + 
		"    s.`Codes`, " + 
		"    if(concat(s.`Primary Standard`, s.`Family Standards`) like '%BRC%',1,0) as 'BRC', " + 
		"    if(concat(s.`Primary Standard`, s.`Family Standards`) like '%SQF%',1,0) as 'SQF', " + 
		"    if(concat(s.`Primary Standard`, s.`Family Standards`) like '%Woolworth%',1,0) as 'WQA', " + 
		"    date_format(s.`Work Item Date`,'%Y %m') as 'WI Period', " + 
		"    s.`Revenue Ownership`, " + 
		"    s.`Required_Duration__c`, " + 
		"    round(s.`Required_Duration__c`/8,1), " + 
		"    s.`Site State`, " + 
		"	concat(s.`Name`, '(', s.Status__c, ') - ', s.`Primary Standard`,if(s.`Family Standards` is null,'',concat(',',s.`Family Standards`))) as 'Name', " + 
		"    concat(if(s.BRC_Re_Audit_From_Date__c is null,'',s.BRC_Re_Audit_From_Date__c),if(s.Support_Waiver_Additional_Comments__c is null, '', s.Support_Waiver_Additional_Comments__c)) as 'Comment' " + 
		"FROM " + 
		"    (SELECT " + 
		"		rc.Id as 'Resource Id', " + 
		"        rc.Name AS 'Auditor', " + 
		"        rc.Resource_Capacitiy__c, " + 
		"        rc.Reporting_Business_Units__c, " + 
		"        rc.Resource_Type__c, " + 
		"            wir.Id, " + 
		"            wir.Name, " + 
		"            wir.Status__c, " + 
		"            wir.`Client`, " + 
		"            wir.`ClientSiteId`, " + 
		"            wir.Client_Site__c AS 'Client Site', " + 
		"            wir.`Scheduling Complexity`, " + 
		"			wir.`Scheduler`,  " + 
		"            wir.Primary_Standard__c AS 'Primary Standard', " + 
		"            wir.work_item_Date__c AS 'Work Item Date', " +
		"            wir.work_item_Stage__c AS 'Work Item Stage', " +
		"            wir.Revenue_Ownership__c AS 'Revenue Ownership', " + 
		"            wir.Required_Duration__c, " + 
		"            COUNT(wir.`Id`) AS 'Requirement Count', " + 
		"            GROUP_CONCAT(if (wir.`Type`='Standard Family',wir.`ReqName`,null)) as 'Family Standards', " + 
		"            GROUP_CONCAT(if (wir.`Type`='Code',wir.`ReqName`,null)) as 'Codes', " + 
		"            COUNT(IF(LOCATE(wir.Requirement, rc.`Competencies`) > 0, rc.Id, NULL)) AS 'Matching Capabilities', " + 
		"            wir.`Site State`, " + 
		"            wir.BRC_Re_Audit_From_Date__c, " + 
		"			wir.Support_Waiver_Additional_Comments__c " + 
		"    FROM " + 
		"		(select wir_2.*,  " + 
		"        client.Scheduling_Complexity__c as 'Scheduling Complexity',  " + 
		"        client.Name as 'Client', " + 
		"        cs.Id as 'ClientSiteId', " + 
		"        client.Scheduler__c, " + 
		"        scheduler.name as 'Scheduler',  " + 
		"        scs.Name as 'Site State', " + 
		"        certStd.BRC_Re_Audit_From_Date__c, " + 
		"        certStd.Support_Waiver_Additional_Comments__c " + 
		"        from  " + 
		"        (SELECT  " + 
		"        wi.Id, " + 
		"            wi.Name, " + 
		"            wi.Status__c, " + 
		"            wi.Client_Site__c, " + 
		"            wi.Primary_Standard__c, " + 
		"            wi.work_item_Date__c, " +
		"            wi.work_item_Stage__c, " +
		"            wi.Revenue_Ownership__c, " + 
		"            wi.Required_Duration__c, " + 
		"            'Primary Standard' AS 'Type', " + 
		"            '' as 'ReqName', " + 
		"            sp.Standard__c AS 'Requirement', " + 
		"            wi.work_package__c " + 
		"    FROM " + 
		"        work_item__c wi " + 
		"    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id " + 
		"    INNER JOIN standard_program__c sp ON scsp.Standard_Program__c = sp.Id " + 
		"    WHERE " + 
		"        wi.Revenue_Ownership__c LIKE '" + rev_own_like + "' " + 
		"        AND wi.Status__C NOT IN ('Cancelled') " + 
		"            AND (NOT (wi.Status__c = 'Open' AND wi.Open_Sub_Status__c is not null AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') )) " +
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= '" + periodFrom + "' " + 
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= '" + periodTo + "' " + 
		"            AND wi.IsDeleted = 0  " + 
		"	UNION  " + 
		"    SELECT  " + 
		"        wi.Id, " + 
		"            wi.Name, " + 
		"            wi.Status__c, " + 
		"            wi.Client_Site__c, " + 
		"            wi.Primary_Standard__c, " + 
		"            wi.work_item_Date__c, " +
		"            wi.work_item_Stage__c, " +
		"            wi.Revenue_Ownership__c, " + 
		"            wi.Required_Duration__c, " + 
		"            'Standard Family' AS 'Type', " + 
		"            f.Name as 'ReqName', " + 
		"            sp.standard__c, " + 
		"            wi.work_package__c " + 
		"    FROM " + 
		"        work_item__c wi " + 
		"    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id " + 
		"    INNER JOIN site_certification_standard_family__c scsf ON scsf.Site_Certification_Standard__c = scsp.Id " + 
		"    INNER JOIN standard_program__c sp ON scsf.Standard_Program__c = sp.Id " + 
		"    LEFT JOIN standard__c f on sp.Standard__c = f.Id " + 
		"    WHERE " + 
		"        wi.Revenue_Ownership__c LIKE '" + rev_own_like + "' " + 
		"        AND wi.Status__C NOT IN ('Cancelled') " + 
		"            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c is not null AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') )) " + 
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= '" + periodFrom + "' " + 
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= '" + periodTo + "' " + 
		"            AND wi.IsDeleted = 0 " + 
		"            AND scsp.IsDeleted = 0 " + 
		"            AND scsf.IsDeleted = 0 " + 
		"            AND sp.IsDeleted = 0  " + 
		"	UNION  " + 
		"    SELECT  " + 
		"        wi.Id, " + 
		"            wi.Name, " + 
		"            wi.Status__c, " + 
		"            wi.Client_Site__c, " + 
		"            wi.Primary_Standard__c, " + 
		"            wi.work_item_Date__c, " + 
		"            wi.work_item_Stage__c, " +
		"            wi.Revenue_Ownership__c, " + 
		"            wi.Required_Duration__c, " + 
		"            'Code' AS 'Type', " + 
		"            c.Name as 'ReqName', " + 
		"            scspc.code__c, " + 
		"            wi.work_package__c " + 
		"    FROM " + 
		"        work_item__c wi " + 
		"    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id " + 
		"    INNER JOIN site_cert_standard_program_code__c scspc ON scspc.Site_Certification_Standard_Program__c = scsp.Id " + 
		"    LEFT JOIN code__c c on scspc.Code__c = c.Id " + 
		"    WHERE " + 
		"        wi.Revenue_Ownership__c LIKE '" + rev_own_like + "' " + 
		"            AND wi.Status__C NOT IN ('Cancelled') " + 
		"            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c is not null AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') )) " + 
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= '" + periodFrom + "' " + 
		"            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= '" + periodTo + "' " + 
		"            AND wi.IsDeleted = 0 " + 
		"            AND scsp.IsDeleted = 0 " + 
		"            AND scspc.IsDeleted = 0) wir_2  " + 
		"            inner join work_package__c wp on wir_2.work_package__c = wp.Id  " + 
		"            inner join certification__c sc on wp.Site_Certification__c = sc.Id " + 
		"            inner join account cs on sc.Primary_client__c = cs.Id " + 
		"            inner join certification__c cert on sc.Primary_Certification__c = cert.Id  " + 
		"            inner join certification_standard_program__c certStd on certStd.Certification__c = cert.Id " + 
		"            left join account client on cs.ParentId = client.Id " + 
		"            left join user scheduler on sc.Scheduler__c = scheduler.Id " + 
		"            left join state_code_setup__c scs on cs.Business_State__c = scs.Id " + 
		"            ) wir, (SELECT  " + 
		"        r.Id, " + 
		"            r.Name, " + 
		"            r.Reporting_Business_Units__c, " + 
		"            r.Resource_Type__c, " + 
		"            r.Resource_Capacitiy__c, " + 
		"            GROUP_CONCAT(IF(rc.Code__c IS NULL, rc.standard__c, rc.code__c)) AS 'Competencies' " + 
		"    FROM " + 
		"        resource__c r " + 
		"    INNER JOIN resource_competency__c rc ON rc.Resource__c = r.Id " + 
		"    WHERE " + 
		"        r.Id in (select Id from resource__c where Reporting_Business_Units__c like '" + rev_own_like + "') " + 
		"        and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS')  " + 
		"        and r.Reporting_Business_Units__c not like '%Product%' " + 
		"            AND (rc.Rank__c LIKE '%Lead Auditor%' " + 
		"            OR rc.Code__C IS NOT NULL) " + 
		"            AND rc.IsDeleted = 0 " + 
		"            AND rc.Status__c = 'Active' " + 
		"    GROUP BY r.Id) rc " + 
		"    GROUP BY wir.Id , rc.Id) s " + 
		"WHERE " + 
		"    s.`Requirement Count` = s.`Matching Capabilities`) mat " + 
		" LEFT JOIN ( " + 
		" select Id, Name, date_format(date,'%Y %m') as 'Period', count(Id) as 'Days Available' from ( " + 
		"(SELECT  " + 
		"    i.Id, i.date, i.Name " + 
		"FROM " + 
		"    (SELECT  " + 
		"        wd.date, r.Id, r.Name " + 
		"    FROM " + 
		"        `sf_working_days` wd, resource__c r " + 
		"    WHERE " + 
		"        r.Id IN (select Id from resource__c where Reporting_Business_Units__c like '" + rev_own_like + "') " + 
		"		AND date_format(wd.date, '%Y-%m') >= '" + periodFrom + "' " + 
		"        AND date_format(wd.date, '%Y-%m') <= '" + periodTo + "') i " + 
		"        LEFT JOIN " + 
		"    (SELECT  " + 
		"        r.Id, e.ActivityDate " + 
		"    FROM " + 
		"        `event` e " + 
		"    INNER JOIN `resource__c` r ON r.User__c = e.OwnerId " + 
		"    WHERE " + 
		"        r.Id IN (select Id from resource__c where Reporting_Business_Units__c like '" + rev_own_like + "') " + 
		"		AND date_format(e.ActivityDate, '%Y-%m') >= '" + periodFrom + "' " + 
		"        AND date_format(e.ActivityDate, '%Y-%m') <= '" + periodTo + "' " + 
		"        AND e.IsDeleted = 0) t ON t.ActivityDate = i.date AND t.id = i.Id " + 
		"WHERE " + 
		"    t.Id IS NULL " + 
		"ORDER BY i.Id)) t group by Id, `Period`) da on mat.`Resource Id` = da.`Id` and mat.`WI Period` = da.`Period` " + 
		//"#Rotational Requirements " + 
		"left join ( " + 
		"select t4.* from ( " + 
		"select t2.SiteId, t2.SiteName, t2.StdName, t2.StdFamilyName, t2.BRC, t2.SQF, t2.WQA,  " + 
		"SUBSTRING_INDEX(group_concat(t2.ResourceId separator ';'),';',1) as 'ResourceIdNotAllowed',  " + 
		"SUBSTRING_INDEX(group_concat(t2.ResourceId separator ';'),';',1) as 'ResourceId First Audit',  " + 
		"SUBSTRING_INDEX(group_concat(t2.ResourceName separator ';'),';',1) as 'Resources First Audit',  " + 
		"if(count(t2.ResourceName) <4,null, SUBSTRING_INDEX(SUBSTRING_INDEX(group_concat(t2.ResourceName separator ';'),';',-4),';',1)) as 'Resources Fourth Last Audit', " + 
		"if(count(t2.ResourceName) <3,null, SUBSTRING_INDEX(SUBSTRING_INDEX(group_concat(t2.ResourceName separator ';'),';',-3),';',1)) as 'Resources Third Last Audit', " + 
		"if(count(t2.ResourceName) <2,null, SUBSTRING_INDEX(SUBSTRING_INDEX(group_concat(t2.ResourceName separator ';'),';',-2),';',1)) as 'Resources Second Last Audit', " + 
		"SUBSTRING_INDEX(group_concat(t2.ResourceName separator ';'),';',-1) as 'Resources Last Audit'  " + 
		"from ( " + 
		"select * from " + 
		"(select * from rot_req_audits  " + 
		"union " + 
		"select * from rot_req_audits_hist) t " + 
		"order by Work_Item_Date__c) t2 group by t2.SiteId, t2.BRC, t2.SQF, t2.WQA " + 
		") t4  " + 
		"where t4.`Resources Last Audit` = t4.`Resources Second Last Audit`  " + 
		"and t4.`Resources Second Last Audit` = t4.`Resources Third Last Audit` " + 
		") rr on rr.SiteId = mat.ClientSiteId ";
		// + "where da.`Days Available` is not null";
	}

	@Override
	protected String getReportName() {
		return "Resource Planning\\Scheduling\\Auditors.Audits.Matrix." + nameSuffix;
	}
	
	@Override
	protected String getTitle() {
		return "";
	}
}
