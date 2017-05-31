use salesforce;

set @rev_own_like = 'EMEA-UK';
set @periodFrom = '2016-05';
set @periodTo = '2016-12';

#explain
#(select mat.*, da.`Days Available`
#from (
(SELECT 
# Clients Details
	s.`Client`,
    s.`ClientSiteId` as 'Client Site Id',
    s.`Client Site`,
    s.`Client Site Address` as 'Address',
    s.`Client Site Country` as 'Country',
    s.`Client Site State` as 'State',
    s.`Client Site City` as 'City',
    s.`Client Site Postcode` as 'Postcode',
# Work Items Details    
    s.`Id` as 'Work Item Id',
    s.`Name` as 'Work Item',
    s.Status__c as 'Work Item Status',
    s.`Primary Standard`,
    s.`Family Standards`,
    s.`Codes`,
    s.`Work Item Date`,
    date_format(s.`Work Item Date`,'%Y %m') as 'WI Period',
    s.`Revenue Ownership`,
    s.`Required_Duration__c`,
# Resources Details
    s.`Resource Id` as 'Resource Id',
    s.`Auditor` as 'Resource',
    s.Reporting_Business_Units__c as 'Reporting Business Unit',
    s.Resource_Type__c as 'Resource Type',
    s.Resource_Capacitiy__c as 'Resource Capacity',
    s.`Resource Lat`, s.`Resource Lon`, s.`Client Site Lat`, s.`Client Site Lon`,
    analytics.distance(s.`Resource Lat`, s.`Resource Lon`, s.`Client Site Lat`, s.`Client Site Lon`) as 'distance'
	
FROM
    (SELECT
		rc.Id as 'Resource Id',
        rc.Name AS 'Auditor',
        rc.Resource_Capacitiy__c,
        rc.Reporting_Business_Units__c,
        rc.Resource_Type__c ,
        rc.Latitude__c as 'Resource Lat',
        rc.Longitude__c as 'Resource Lon',
        rc.`Resource Address`,
        rc.`Resource Country`,
        rc.`Resource State`,
        rc.`Resource City`,
        rc.`Resource Postcode`,
			wir.`Client Site Lat`,
            wir.`Client Site Lon`,
            wir.`Client Site Address`,
            wir.`Client Site Country`,
            wir.`Client Site State`,
            wir.`Client Site City`,
            wir.`Client Site Postcode`,
            wir.Id,
            wir.Name,
            wir.Status__c,
            wir.`Client`,
            wir.`ClientSiteId`,
            wir.Client_Site__c AS 'Client Site',
            wir.`Scheduling Complexity`,
			wir.`Scheduler`, 
            wir.Primary_Standard__c AS 'Primary Standard',
            wir.work_item_Date__c AS 'Work Item Date',
            wir.Revenue_Ownership__c AS 'Revenue Ownership',
            wir.Required_Duration__c,
            COUNT(wir.`Id`) AS 'Requirement Count',
            GROUP_CONCAT(if (wir.`Type`='Standard Family',wir.`ReqName`,null)) as 'Family Standards',
            GROUP_CONCAT(if (wir.`Type`='Code',wir.`ReqName`,null)) as 'Codes',
            COUNT(IF(LOCATE(wir.Requirement, rc.`Competencies`) > 0, rc.Id, NULL)) AS 'Matching Capabilities',
            wir.`Site State`,
            wir.BRC_Re_Audit_From_Date__c,
			wir.Support_Waiver_Additional_Comments__c
    FROM
		(select wir_2.*, 
        client.Scheduling_Complexity__c as 'Scheduling Complexity', 
        client.Name as 'Client',
        cs.Id as 'ClientSiteId',
        geo.Latitude as 'Client Site Lat',
        geo.Longitude as 'Client Site Lon',
        concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) as 'Client Site Address',
		ccs.name as 'Client Site Country',
        scs.Name as 'Client Site State',
        cs.Business_City__c as 'Client Site City',
        cs.Business_Zip_Postal_Code__c as 'Client Site Postcode',
        client.Scheduler__c,
        scheduler.name as 'Scheduler', 
        scs.Name as 'Site State',
        certStd.BRC_Re_Audit_From_Date__c,
        certStd.Support_Waiver_Additional_Comments__c
        from 
        (SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Primary Standard' AS 'Type',
            '' as 'ReqName',
            sp.Standard__c AS 'Requirement',
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsp.Standard_Program__c = sp.Id
    WHERE
        wi.Revenue_Ownership__c like @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT (wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Standard Family' AS 'Type',
            f.Name as 'ReqName',
            sp.standard__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_certification_standard_family__c scsf ON scsf.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsf.Standard_Program__c = sp.Id
    LEFT JOIN standard__c f on sp.Standard__c = f.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scsf.IsDeleted = 0
            AND sp.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Code' AS 'Type',
            c.Name as 'ReqName',
            scspc.code__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_cert_standard_program_code__c scspc ON scspc.Site_Certification_Standard_Program__c = scsp.Id
    LEFT JOIN code__c c on scspc.Code__c = c.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
            AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scspc.IsDeleted = 0) wir_2 
            inner join work_package__c wp on wir_2.work_package__c = wp.Id 
            inner join certification__c sc on wp.Site_Certification__c = sc.Id
            inner join account cs on sc.Primary_client__c = cs.Id
            inner join certification__c cert on sc.Primary_Certification__c = cert.Id 
            inner join certification_standard_program__c certStd on certStd.Certification__c = cert.Id
            left join account client on cs.ParentId = client.Id
            left join user scheduler on sc.Scheduler__c = scheduler.Id
            left join salesforce.state_code_setup__c scs on cs.Business_State__c = scs.Id
            left join salesforce.country_code_setup__c ccs on cs.Business_Country2__c = ccs.Id
			left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) 
            ) wir, (SELECT 
			r.Id,
             geo.Latitude as 'Latitude__c',
            geo.Longitude as 'Longitude__c',
            concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Address',
			ccs.Name as 'Resource Country',
            scs.Name as 'Resource State',
            r.Home_City__c as 'Resource City',
            r.Home_Postcode__c as 'Resource Postcode',
            r.Name,
            r.Reporting_Business_Units__c,
            r.Resource_Type__c,
            r.Resource_Capacitiy__c,
            GROUP_CONCAT(IF(rc.Code__c IS NULL, rc.standard__c, rc.code__c)) AS 'Competencies'
    FROM
        resource__c r
    INNER JOIN resource_competency__c rc ON rc.Resource__c = r.Id
    left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
	left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) 
    WHERE
        r.Id in (select Id from resource__c where Reporting_Business_Units__c like @rev_own_like)
        and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') 
        and r.Reporting_Business_Units__c not like '%Product%'
            AND (rc.Rank__c LIKE '%Lead Auditor%'
            OR rc.Code__C IS NOT NULL)
            AND rc.IsDeleted = 0
            AND rc.Status__c = 'Active'
    GROUP BY r.Id) rc
    GROUP BY wir.Id , rc.Id) s
WHERE
    s.`Requirement Count` = s.`Matching Capabilities`); /*mat
 
 LEFT JOIN (
 select Id, Name, date_format(date,'%Y %m') as 'Period', count(Id) as 'Days Available' from (
(SELECT 
    i.Id, i.date, i.Name
FROM
    (SELECT 
        wd.date, r.Id, r.Name
    FROM
        `sf_working_days` wd, resource__c r
    WHERE
        r.Id IN (select Id from resource__c where Reporting_Business_Units__c like @rev_own_like)
		AND date_format(wd.date, '%Y-%m') >= @periodFrom
        AND date_format(wd.date, '%Y-%m') <= @periodTo) i
        LEFT JOIN
    (SELECT 
        r.Id, e.ActivityDate
    FROM
        `event` e
    INNER JOIN `resource__c` r ON r.User__c = e.OwnerId
    WHERE
        r.Id IN (select Id from resource__c where Reporting_Business_Units__c like @rev_own_like)
		AND date_format(e.ActivityDate, '%Y-%m') >= @periodFrom
        AND date_format(e.ActivityDate, '%Y-%m') <= @periodTo
        AND e.IsDeleted = 0) t ON t.ActivityDate = i.date AND t.id = i.Id
WHERE
    t.Id IS NULL
ORDER BY i.Id)) t group by Id, `Period`) da on mat.`Resource Id` = da.`Id` and mat.`WI Period` = da.`Period`

where da.`Days Available` is not null);*/

set @rev_own_like = 'EMEA-UK';
set @periodFrom = '2015-07';
set @periodTo = '2016-03';

#Past Audits Travel Analysis
(select 
site.Id as 'Client Site Id', 
site.Name as 'Client Site',
concat(
	 ifnull(concat(site.Business_Address_1__c,' '),''),
	 ifnull(concat(site.Business_Address_2__c,' '),''),
	 ifnull(concat(site.Business_Address_3__c,' '),''),
	 ifnull(concat(site.Business_City__c,' '),''),
	 ifnull(concat(scs.Name,' '),''),
	 ifnull(concat(ccs.Name,' '),''),
	 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) as 'Client Site Address',
geo.Latitude as 'Client Site Lat', 
geo.Longitude as 'Client Site Lon',
wi.Id as 'Work Item Id',
wi.Name as 'Work Item',
wi.Work_Item_Date__c as 'Work Item Date',
date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period',
wi.Status__c as 'Work Item Status',
wi.Primary_Standard__c as 'Primary Standard',
r.Id as 'Resource Id',
r.Name as 'ARG Author' ,
r.Resource_Type__c as 'Resource Type',
concat(
	 ifnull(concat(r.Home_Address_1__c,' '),''),
	 ifnull(concat(r.Home_Address_2__c,' '),''),
	 ifnull(concat(r.Home_Address_3__c,' '),''),
	 ifnull(concat(r.Home_City__c,' '),''),
	 ifnull(concat(scs2.Name,' '),''),
	 ifnull(concat(ccs2.Name,' '),''),
	 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Address',
geo2.Latitude as 'Resource Lat', 
geo2.Longitude as 'Resource Lon',
analytics.distance(geo2.Latitude, geo2.Longitude, geo.Latitude, geo.Longitude) as 'Distance (km)'
from salesforce.work_item__c wi 
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
left join salesforce.saig_geocode_cache geo on geo.Address = concat(
					 ifnull(concat(site.Business_Address_1__c,' '),''),
					 ifnull(concat(site.Business_Address_2__c,' '),''),
					 ifnull(concat(site.Business_Address_3__c,' '),''),
					 ifnull(concat(site.Business_City__c,' '),''),
					 ifnull(concat(scs.Name,' '),''),
					 ifnull(concat(ccs.Name,' '),''),
					 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) 
left join salesforce.country_code_setup__c ccs2 on r.Home_Country1__c = ccs2.Id
left join salesforce.state_code_setup__c scs2 on r.Home_State_Province__c = scs2.Id
left join salesforce.saig_geocode_cache geo2 on geo2.Address = concat(
					 ifnull(concat(r.Home_Address_1__c,' '),''),
					 ifnull(concat(r.Home_Address_2__c,' '),''),
					 ifnull(concat(r.Home_Address_3__c,' '),''),
					 ifnull(concat(r.Home_City__c,' '),''),
					 ifnull(concat(scs2.Name,' '),''),
					 ifnull(concat(ccs2.Name,' '),''),
					 ifnull(concat(r.Home_Postcode__c,' '),'')) 
where 
wi.Revenue_Ownership__c like @rev_own_like
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
and wi.IsDeleted = 0
and wi.Work_Item_Stage__c not in ('Follow Up')
and wi.Status__c not in ('Open', 'Cancelled', 'Initiate Service', 'Draft'));

# Export for Google Fusion table map
(SELECT 
	'Client Site' as 'Record Type',
    s.`ClientSiteId` as 'Id',
    s.`Client Site` as 'Name',
    s.`Client Site Address` as 'Address',
    s.`Client Site Country` as 'Country',
    s.`Client Site State` as 'State',
    s.`Client Site City` as 'City',
    s.`Client Site Postcode` as 'Postcode',
	null as 'Type',
    null as 'Capacity',
    s.`Primary Standard`,
    s.`Family Standards`,
    s.`Codes`,
    concat(ifnull(s.`Primary Standard`,''),ifnull(concat(' - -',s.`Family Standards`),''),ifnull(concat(' - ',s.`Codes`),'')) as 'Competencies',
    s.`Client Site Lat` as 'Latitude', 
    s.`Client Site Lon` as 'Longitude',
    avg(analytics.distance(s.`Resource Lat`, s.`Resource Lon`, s.`Client Site Lat`, s.`Client Site Lon`)) as 'Avg Distance to Resource',
	'small_red' as 'Marker'
FROM
    (SELECT
		rc.Id as 'Resource Id',
        rc.Name AS 'Auditor',
        rc.Resource_Capacitiy__c,
        rc.Reporting_Business_Units__c,
        rc.Resource_Type__c ,
        rc.Latitude__c as 'Resource Lat',
        rc.Longitude__c as 'Resource Lon',
        rc.`Resource Address`,
        rc.`Resource Country`,
        rc.`Resource State`,
        rc.`Resource City`,
        rc.`Resource Postcode`,
			wir.`Client Site Lat`,
            wir.`Client Site Lon`,
            wir.`Client Site Address`,
            wir.`Client Site Country`,
            wir.`Client Site State`,
            wir.`Client Site City`,
            wir.`Client Site Postcode`,
            wir.Id,
            wir.Name,
            wir.Status__c,
            wir.`Client`,
            wir.`ClientSiteId`,
            wir.Client_Site__c AS 'Client Site',
            wir.`Scheduling Complexity`,
			wir.`Scheduler`, 
            wir.Primary_Standard__c AS 'Primary Standard',
            wir.work_item_Date__c AS 'Work Item Date',
            wir.Revenue_Ownership__c AS 'Revenue Ownership',
            wir.Required_Duration__c,
            COUNT(wir.`Id`) AS 'Requirement Count',
            GROUP_CONCAT(if (wir.`Type`='Standard Family',wir.`ReqName`,null)) as 'Family Standards',
            GROUP_CONCAT(if (wir.`Type`='Code',wir.`ReqName`,null)) as 'Codes',
            COUNT(IF(LOCATE(wir.Requirement, rc.`Competencies`) > 0, rc.Id, NULL)) AS 'Matching Capabilities',
            wir.BRC_Re_Audit_From_Date__c,
			wir.Support_Waiver_Additional_Comments__c
    FROM
		(select wir_2.*, 
        client.Scheduling_Complexity__c as 'Scheduling Complexity', 
        client.Name as 'Client',
        cs.Id as 'ClientSiteId',
        geo.Latitude as 'Client Site Lat',
        geo.Longitude as 'Client Site Lon',
        concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) as 'Client Site Address',
		ccs.name as 'Client Site Country',
        scs.Name as 'Client Site State',
        cs.Business_City__c as 'Client Site City',
        cs.Business_Zip_Postal_Code__c as 'Client Site Postcode',
        client.Scheduler__c,
        scheduler.name as 'Scheduler', 
        certStd.BRC_Re_Audit_From_Date__c,
        certStd.Support_Waiver_Additional_Comments__c
        from 
        (SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Primary Standard' AS 'Type',
            '' as 'ReqName',
            sp.Standard__c AS 'Requirement',
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsp.Standard_Program__c = sp.Id
    WHERE
        wi.Revenue_Ownership__c like @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT (wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Standard Family' AS 'Type',
            f.Name as 'ReqName',
            sp.standard__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_certification_standard_family__c scsf ON scsf.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsf.Standard_Program__c = sp.Id
    LEFT JOIN standard__c f on sp.Standard__c = f.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scsf.IsDeleted = 0
            AND sp.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Code' AS 'Type',
            c.Name as 'ReqName',
            scspc.code__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_cert_standard_program_code__c scspc ON scspc.Site_Certification_Standard_Program__c = scsp.Id
    LEFT JOIN code__c c on scspc.Code__c = c.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
            AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scspc.IsDeleted = 0) wir_2 
            inner join work_package__c wp on wir_2.work_package__c = wp.Id 
            inner join certification__c sc on wp.Site_Certification__c = sc.Id
            inner join account cs on sc.Primary_client__c = cs.Id
            inner join certification__c cert on sc.Primary_Certification__c = cert.Id 
            inner join certification_standard_program__c certStd on certStd.Certification__c = cert.Id
            left join account client on cs.ParentId = client.Id
            left join user scheduler on sc.Scheduler__c = scheduler.Id
            left join salesforce.state_code_setup__c scs on cs.Business_State__c = scs.Id
            left join salesforce.country_code_setup__c ccs on cs.Business_Country2__c = ccs.Id
			left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) 
            ) wir, (SELECT 
			r.Id,
            geo.Latitude as 'Latitude__c',
            geo.Longitude as 'Longitude__c',
            concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Address',
			ccs.Name as 'Resource Country',
            scs.Name as 'Resource State',
            r.Home_City__c as 'Resource City',
            r.Home_Postcode__c as 'Resource Postcode',
            r.Name,
            r.Reporting_Business_Units__c,
            r.Resource_Type__c,
            r.Resource_Capacitiy__c,
            GROUP_CONCAT(IF(rc.Code__c IS NULL, rc.standard__c, rc.code__c)) AS 'Competencies'
    FROM
        resource__c r
    INNER JOIN resource_competency__c rc ON rc.Resource__c = r.Id
    left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
	left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) 
    WHERE
        r.Id in (select Id from resource__c where Reporting_Business_Units__c like @rev_own_like)
        and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') 
        and r.Reporting_Business_Units__c not like '%Product%'
            AND (rc.Rank__c LIKE '%Lead Auditor%'
            OR rc.Code__C IS NOT NULL)
            AND rc.IsDeleted = 0
            AND rc.Status__c = 'Active'
    GROUP BY r.Id) rc
    GROUP BY wir.Id , rc.Id) s
WHERE
    s.`Requirement Count` = s.`Matching Capabilities`
GROUP BY s.`ClientSiteId`, `Competencies`)
union
(SELECT 
	'Resource' as 'Record Type',
	s.`Resource Id` as 'Id',
    s.`Auditor` as 'Name',
    s.`Resource Address`,
    s.`Resource Country`,
    s.`Resource State`,
    s.`Resource City`,
    s.`Resource Postcode`,
    s.Resource_Type__c as 'Resource Type',
    s.Resource_Capacitiy__c as 'Resource Capacity',
    s.`Primary Standard`,
    s.`Family Standards`,
    s.`Codes`,
    concat(ifnull(s.`Primary Standard`,''),ifnull(concat(' - -',s.`Family Standards`),''),ifnull(concat(' - ',s.`Codes`),'')) as 'Competencies',
    s.`Resource Lat`, 
    s.`Resource Lon`,
    null as 'Distance',
	'small_green' as 'Marker'
FROM
    (SELECT
		rc.Id as 'Resource Id',
        rc.Name AS 'Auditor',
        rc.Resource_Capacitiy__c,
        rc.Reporting_Business_Units__c,
        rc.Resource_Type__c ,
        rc.Latitude__c as 'Resource Lat',
        rc.Longitude__c as 'Resource Lon',
        rc.`Resource Address`,
        rc.`Resource Country`,
        rc.`Resource State`,
        rc.`Resource City`,
        rc.`Resource Postcode`,
			wir.`Client Site Lat`,
            wir.`Client Site Lon`,
            wir.`Client Site Address`,
            wir.`Client Site Country`,
            wir.`Client Site State`,
            wir.`Client Site City`,
            wir.`Client Site Postcode`,
            wir.Id,
            wir.Name,
            wir.Status__c,
            wir.`Client`,
            wir.`ClientSiteId`,
            wir.Client_Site__c AS 'Client Site',
            wir.`Scheduling Complexity`,
			wir.`Scheduler`, 
            wir.Primary_Standard__c AS 'Primary Standard',
            wir.work_item_Date__c AS 'Work Item Date',
            wir.Revenue_Ownership__c AS 'Revenue Ownership',
            wir.Required_Duration__c,
            COUNT(wir.`Id`) AS 'Requirement Count',
            GROUP_CONCAT(if (wir.`Type`='Standard Family',wir.`ReqName`,null)) as 'Family Standards',
            GROUP_CONCAT(if (wir.`Type`='Code',wir.`ReqName`,null)) as 'Codes',
            COUNT(IF(LOCATE(wir.Requirement, rc.`Competencies`) > 0, rc.Id, NULL)) AS 'Matching Capabilities',
            wir.BRC_Re_Audit_From_Date__c,
			wir.Support_Waiver_Additional_Comments__c
    FROM
		(select wir_2.*, 
        client.Scheduling_Complexity__c as 'Scheduling Complexity', 
        client.Name as 'Client',
        cs.Id as 'ClientSiteId',
        geo.Latitude as 'Client Site Lat',
        geo.Longitude as 'Client Site Lon',
        concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) as 'Client Site Address',
		ccs.name as 'Client Site Country',
        scs.Name as 'Client Site State',
        cs.Business_City__c as 'Client Site City',
        cs.Business_Zip_Postal_Code__c as 'Client Site Postcode',
        client.Scheduler__c,
        scheduler.name as 'Scheduler', 
        certStd.BRC_Re_Audit_From_Date__c,
        certStd.Support_Waiver_Additional_Comments__c
        from 
        (SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Primary Standard' AS 'Type',
            '' as 'ReqName',
            sp.Standard__c AS 'Requirement',
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsp.Standard_Program__c = sp.Id
    WHERE
        wi.Revenue_Ownership__c like @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT (wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Standard Family' AS 'Type',
            f.Name as 'ReqName',
            sp.standard__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_certification_standard_family__c scsf ON scsf.Site_Certification_Standard__c = scsp.Id
    INNER JOIN standard_program__c sp ON scsf.Standard_Program__c = sp.Id
    LEFT JOIN standard__c f on sp.Standard__c = f.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
        AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scsf.IsDeleted = 0
            AND sp.IsDeleted = 0 
	UNION 
    SELECT 
        wi.Id,
            wi.Name,
            wi.Status__c,
            wi.Client_Site__c,
            wi.Primary_Standard__c,
            wi.work_item_Date__c,
            wi.Revenue_Ownership__c,
            wi.Required_Duration__c,
            'Code' AS 'Type',
            c.Name as 'ReqName',
            scspc.code__c,
            wi.work_package__c
    FROM
        work_item__c wi
    INNER JOIN site_certification_standard_program__c scsp ON wi.Site_Certification_Standard__c = scsp.Id
    INNER JOIN site_cert_standard_program_code__c scspc ON scspc.Site_Certification_Standard_Program__c = scsp.Id
    LEFT JOIN code__c c on scspc.Code__c = c.Id
    WHERE
        wi.Revenue_Ownership__c LIKE @rev_own_like
            AND wi.Status__C NOT IN ('Cancelled')
            AND (NOT(wi.Status__c = 'Open' AND wi.Open_Sub_Status__c IN ('Pending Cancellation' , 'Pending Suspension') ))
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
            AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
            AND wi.IsDeleted = 0
            AND scsp.IsDeleted = 0
            AND scspc.IsDeleted = 0) wir_2 
            inner join work_package__c wp on wir_2.work_package__c = wp.Id 
            inner join certification__c sc on wp.Site_Certification__c = sc.Id
            inner join account cs on sc.Primary_client__c = cs.Id
            inner join certification__c cert on sc.Primary_Certification__c = cert.Id 
            inner join certification_standard_program__c certStd on certStd.Certification__c = cert.Id
            left join account client on cs.ParentId = client.Id
            left join user scheduler on sc.Scheduler__c = scheduler.Id
            left join salesforce.state_code_setup__c scs on cs.Business_State__c = scs.Id
            left join salesforce.country_code_setup__c ccs on cs.Business_Country2__c = ccs.Id
			left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(cs.Business_Address_1__c,' '),''),
						 ifnull(concat(cs.Business_Address_2__c,' '),''),
						 ifnull(concat(cs.Business_Address_3__c,' '),''),
						 ifnull(concat(cs.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(cs.Business_Zip_Postal_Code__c,' '),'')) 
            ) wir, (SELECT 
			r.Id,
            geo.Latitude as 'Latitude__c',
            geo.Longitude as 'Longitude__c',
            concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Address',
			ccs.Name as 'Resource Country',
            scs.Name as 'Resource State',
            r.Home_City__c as 'Resource City',
            r.Home_Postcode__c as 'Resource Postcode',
            r.Name,
            r.Reporting_Business_Units__c,
            r.Resource_Type__c,
            r.Resource_Capacitiy__c,
            GROUP_CONCAT(IF(rc.Code__c IS NULL, rc.standard__c, rc.code__c)) AS 'Competencies'
    FROM
        resource__c r
    INNER JOIN resource_competency__c rc ON rc.Resource__c = r.Id
    left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
	left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) 
    WHERE
        r.Id in (select Id from resource__c where Reporting_Business_Units__c like @rev_own_like)
        and r.Reporting_Business_Units__c not in ('AUS-CSC','AUS-MGT', 'AUS-OPS') 
        and r.Reporting_Business_Units__c not like '%Product%'
            AND (rc.Rank__c LIKE '%Lead Auditor%'
            OR rc.Code__C IS NOT NULL)
            AND rc.IsDeleted = 0
            AND rc.Status__c = 'Active'
    GROUP BY r.Id) rc
    GROUP BY wir.Id , rc.Id) s
WHERE
    s.`Requirement Count` = s.`Matching Capabilities`
GROUP BY s.`Resource Id`, `Competencies`);
    

set @rev_own_like = 'EMEA-UK';
set @periodFrom = '2015-07';
set @periodTo = '2016-03';

(select 
'Client Site' as 'Record Type',
site.Id, site.Name,
concat(
						 ifnull(concat(site.Business_Address_1__c,' '),''),
						 ifnull(concat(site.Business_Address_2__c,' '),''),
						 ifnull(concat(site.Business_Address_3__c,' '),''),
						 ifnull(concat(site.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) as 'Address',
geo.Latitude, geo.Longitude,
wi.Work_Item_Date__c,
date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period',
wi.Primary_Standard__c,
wi.Status__c,
r.Name as 'ARG Author' ,
'small_red' as 'Marker'
from salesforce.work_item__c wi 
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(site.Business_Address_1__c,' '),''),
						 ifnull(concat(site.Business_Address_2__c,' '),''),
						 ifnull(concat(site.Business_Address_3__c,' '),''),
						 ifnull(concat(site.Business_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) 
where 
wi.Revenue_Ownership__c like @rev_own_like
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
and wi.IsDeleted = 0
and wi.Work_Item_Stage__c not in ('Follow Up')
and wi.Status__c not in ('Open', 'Cancelled', 'Initiate Service', 'Draft'))
union
(
select 
'Resource' as 'Record Type',
r.Id,
r.Name,
concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) ,
geo.Latitude, geo.Longitude,
null,
date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period2',
null,null,r.Name, 'small_green' as 'Marker'
from salesforce.work_item__c wi 
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
	left join salesforce.saig_geocode_cache geo on geo.Address = concat(
						 ifnull(concat(r.Home_Address_1__c,' '),''),
						 ifnull(concat(r.Home_Address_2__c,' '),''),
						 ifnull(concat(r.Home_Address_3__c,' '),''),
						 ifnull(concat(r.Home_City__c,' '),''),
						 ifnull(concat(scs.Name,' '),''),
						 ifnull(concat(ccs.Name,' '),''),
						 ifnull(concat(r.Home_Postcode__c,' '),'')) 

where 
wi.Revenue_Ownership__c like @rev_own_like
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') >= @periodFrom
AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= @periodTo
and wi.IsDeleted = 0
and wi.Status__c not in ('Open', 'Cancelled', 'Initiate Service', 'Draft')
and wi.Work_Item_Stage__c not in ('Follow Up')
group by r.Id, `Period2`
)