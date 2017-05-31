select group_concat(s.Id separator '\', \'') from standard__c s
where s.name like '%WQA%' or s.name like '%Woolworths%';

use salesforce;
select t.*, 
group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) as 'Other Programs at same Site' ,
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%BRC%', 1, 0) as 'BRC',
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%SQF%', 1, 0) as 'SQF',
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%HACCP%', 1, 0) as 'HACCP',
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%9001%', 1, 0) as '9001',
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%4801%', 1, 0) as '4801',
IF (group_concat(distinct if( t.`Site Certification Id` != scc.Id and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%14001%', 1, 0) as '14001'
from (
select 
	parent.Id as 'Parent Id',
	parent.Name as 'Parent Client',
	client.id as 'Client Id',
	client.Name as 'Client Name',
	site.Id as 'Site Id', 
	site.Name as 'Site Name', 
	site.Business_Address_1__c as 'Site Address 1',
	site.Business_Address_2__c as 'Site Address 2',
	site.Business_Address_3__c as 'Site Address 3',
	site.Business_City__c as 'Site City',
	scs.Name as 'Site State',
	site.Business_Zip_Postal_Code__c as 'Site PostCode',
	ccs.Name as 'Site Country',
	sc.Id as 'Site Certification Id', 
	sc.Name as 'Site Certification', 
	scsp.Id as 'Site Certification Standard Id', 
	scsp.Name as 'Site Certification Standard', 
    scsp.External_Site_Code__c as 'External Site Ref.',
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
    sp.Standard__c as 'Primary Standard Id',
    group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fsp.Standard__c) order by fsp.Standard__c) as 'Family Standard Ids',
	group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name) order by fs.Name) as 'Family Standard',
    group_concat(distinct if(scspc.IsDeleted or code.Name not like 'RABQSA%', null,code.Name) order by code.Name) as 'RABQSA Codes',
    group_concat(distinct if(scspc.IsDeleted , null,code.Code_Description__c ) order by code.Code_Description__c) as 'Industries',
    group_concat(if(scspc.IsDeleted, null,code.Name)) as 'Codes'
    #wi.Id,
    #wi.Name,
    #wi.Status__c,
    #wi.Work_Item_Date__c,
    #date_format(wi.Work_Item_Date__c, '%Y %m') as 'WI Period',
    #wi.Required_Duration__c,
    #wi.Scheduled_Duration__c,
    #wi.Work_Item_Stage__c
from site_certification_standard_program__c scsp
inner join Certification_Standard_Program__c csp on scsp.Certification_Standard__c = csp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.id
left join country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join state_code_setup__c scs on site.Business_State__c = scs.Id
inner join account client on site.ParentId = client.id
left join account parent on client.ParentId = parent.id
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
left join site_cert_standard_program_code__c scspc on scsp.Id = scspc.Site_Certification_Standard_Program__c
left join code__c code on code.Id = scspc.Code__c
#inner join work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
where (sp.Standard__c in ('a36900000004F2EAAU', 'a36900000004FRPAA2', 'a36900000004FRQAA2', 'a36900000004FRRAA2', 'a36d00000004ZXrAAM', 'a36d00000004ZXwAAM', 'a36d0000000Ci6QAAS', 'a36d0000000Ci6VAAS', 'a36d0000000Cr9yAAC', 'a36d0000000CrA3AAK', 'a36d0000000CtD2AAK') 
		or fsp.Standard__c in ('a36900000004F2EAAU', 'a36900000004FRPAA2', 'a36900000004FRQAA2', 'a36900000004FRRAA2', 'a36d00000004ZXrAAM', 'a36d00000004ZXwAAM', 'a36d0000000Ci6QAAS', 'a36d0000000Ci6VAAS', 'a36d0000000Cr9yAAC', 'a36d0000000CrA3AAK', 'a36d0000000CtD2AAK'))
and site.IsDeleted=0
and sc.IsDeleted=0
and scsp.IsDeleted=0
and site.Status__c='Active'
and sc.Status__c = 'Active'
and scsp.Status__c not in ('De-registered','Concluded')
#and wi.IsDeleted = 0
#and wi.Status__c in ('Completed')
#and client.Id='001d000000IeO4mAAF'
group by scsp.Id#, wi.Id
) t 
left join certification__c scc on scc.Primary_client__c = t.`Site Id`
where 
(t.`Primary Standard` like '%Woolworths%' or t.`Primary Standard` like '%WQA%' or t.`Family Standard` like '%Woolworths%' or t.`Family Standard` like '%WQA%' )
#and t.`Site Id` = '001d000001F8q49AAB'
group by t.`Site Certification Standard Id`
limit 100000;

# Other Programs Summary
select 
t2.`Site Country` as 'Site Country',
count(t2.`Site Id`) as 'Sites #',
sum(t2.`BRC`) as 'BRC',
sum(t2.`SQF`) as 'SQF',
sum(t2.`HACCP`) as 'HACCP',
sum(t2.`9001`) as '9001',
sum(t2.`4801`) as '4801',
sum(t2.`14001`) as '14001',
avg(t2.`WQA Yearly Duration (inc FoS)`) as 'WQA Yearly Avg Duration (inc FoS)',
avg(t2.`BRC Yearly Duration`) as 'BRC Yearly Avg Duration',
avg(t2.`SQF Yearly Duration`) as 'SQF Yearly Avg Duration',
avg(t2.`HACCP Yearly Duration`) as 'HACCP Yearly Avg Duration',
avg(t2.`9001 Yearly Duration`) as '9001 Yearly Avg Duration',
avg(t2.`4801 Yearly Duration`) as '4801 Yearly Avg Duration',
avg(t2.`14001 Yearly Duration`) as '14001 Yearly Avg Duration'
from (
select 
 t.`Site Id`,
 t.`Site Country`,
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%BRC%', 1, 0) as 'BRC',
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%SQF%', 1, 0) as 'SQF',
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%HACCP%', 1, 0) as 'HACCP',
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%9001%', 1, 0) as '9001',
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%4801%', 1, 0) as '4801',
IF (group_concat( if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active',scc.Standard_Name__c, null) order by scc.Standard_Name__c) like '%14001%', 1, 0) as '14001',
sum(if( scc.Id = t.`Site Certification Id` and scc.Status__c = 'Active' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as 'WQA Yearly Duration (inc FoS)',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%BRC%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as 'BRC Yearly Duration',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%SQF%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as 'SQF Yearly Duration',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%HACCP%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as 'HACCP Yearly Duration',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%9001%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as '9001 Yearly Duration',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%4801%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as '4801 Yearly Duration',
sum(if( scc.Id != t.`Site Certification Id` and scc.Status__c = 'Active' and scc.Standard_Name__c like '%14001%' and wic.Status__c not in ('Cancelled') and wic.IsDeleted=0 and wic.Work_Item_Stage__c in ('Certification', 'Re-Certification', 'Surveillance') and wic.work_item_Date__c <'2015-08-01' and wic.work_item_Date__c >='2014-07-31', wic.Required_Duration__c, null)) as '14001 Yearly Duration'
from (
select 
	parent.Id as 'Parent Id',
	parent.Name as 'Parent Client',
	client.id as 'Client Id',
	client.Name as 'Client Name',
	site.Id as 'Site Id', 
	site.Name as 'Site Name', 
	site.Business_Address_1__c as 'Site Address 1',
	site.Business_Address_2__c as 'Site Address 2',
	site.Business_Address_3__c as 'Site Address 3',
	site.Business_City__c as 'Site City',
	scs.Name as 'Site State',
	site.Business_Zip_Postal_Code__c as 'Site PostCode',
	ccs.Name as 'Site Country',
	sc.Id as 'Site Certification Id', 
	sc.Name as 'Site Certification', 
	scsp.Id as 'Site Certification Standard Id', 
	scsp.Name as 'Site Certification Standard', 
    scsp.External_Site_Code__c as 'External Site Ref.',
	csp.Name as 'Certification Standard',
	csp.External_provided_certificate__c as 'Certification Standard External Ref',
	s.Name as 'Primary Standard', 
    sp.Standard__c as 'Primary Standard Id',
    group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fsp.Standard__c) order by fsp.Standard__c) as 'Family Standard Ids',
	group_concat(distinct if(scsf.IsDeleted or fsp.isDeleted or fs.IsDeleted, null,fs.Name) order by fs.Name) as 'Family Standard',
    group_concat(distinct if(scspc.IsDeleted or code.Name not like 'RABQSA%', null,code.Name) order by code.Name) as 'RABQSA Codes',
    group_concat(distinct if(scspc.IsDeleted or code.Name not like 'RABQSA%', null,code.Code_Description__c ) order by code.Code_Description__c) as 'Industries',
    group_concat(if(scspc.IsDeleted, null,code.Name)) as 'Codes'
    #wi.Id,
    #wi.Name,
    #wi.Status__c,
    #wi.Work_Item_Date__c,
    #date_format(wi.Work_Item_Date__c, '%Y %m') as 'WI Period',
    #wi.Required_Duration__c,
    #wi.Scheduled_Duration__c,
    #wi.Work_Item_Stage__c
from site_certification_standard_program__c scsp
inner join Certification_Standard_Program__c csp on scsp.Certification_Standard__c = csp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.id
left join country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join state_code_setup__c scs on site.Business_State__c = scs.Id
inner join account client on site.ParentId = client.id
left join account parent on client.ParentId = parent.id
left join standard_program__c sp on sp.Id = scsp.Standard_Program__c
left join standard__c s on sp.Standard__c = s.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join standard__c fs on fsp.Standard__c = fs.Id
left join site_cert_standard_program_code__c scspc on scsp.Id = scspc.Site_Certification_Standard_Program__c
left join code__c code on code.Id = scspc.Code__c
#inner join work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
where (sp.Standard__c in ('a36900000004F2EAAU', 'a36900000004FRPAA2', 'a36900000004FRQAA2', 'a36900000004FRRAA2', 'a36d00000004ZXrAAM', 'a36d00000004ZXwAAM', 'a36d0000000Ci6QAAS', 'a36d0000000Ci6VAAS', 'a36d0000000Cr9yAAC', 'a36d0000000CrA3AAK', 'a36d0000000CtD2AAK') 
		or fsp.Standard__c in ('a36900000004F2EAAU', 'a36900000004FRPAA2', 'a36900000004FRQAA2', 'a36900000004FRRAA2', 'a36d00000004ZXrAAM', 'a36d00000004ZXwAAM', 'a36d0000000Ci6QAAS', 'a36d0000000Ci6VAAS', 'a36d0000000Cr9yAAC', 'a36d0000000CrA3AAK', 'a36d0000000CtD2AAK'))
and site.IsDeleted=0
and sc.IsDeleted=0
and scsp.IsDeleted=0
and site.Status__c='Active'
and sc.Status__c = 'Active'
and scsp.Status__c not in ('De-registered','Concluded')
#and wi.IsDeleted = 0
#and wi.Status__c in ('Completed')
#and client.Id='001d000000IeO4mAAF'
group by scsp.Id#, wi.Id
) t 
left join certification__c scc on scc.Primary_client__c = t.`Site Id`
left join work_package__c wpc on wpc.Site_Certification__c = scc.Id
left join work_item__c wic on wic.Work_Package__c = wpc.Id
where 
(t.`Primary Standard` like '%Woolworths%' or t.`Primary Standard` like '%WQA%' or t.`Family Standard` like '%Woolworths%' or t.`Family Standard` like '%WQA%' )
#and t.`Site Id` = '001d000001F8q49AAB'
group by t.`Site Id`) t2
group by `Site Country`;

describe code__c;

select c.Id, c.Code__c, c.Code_Description__c from code__c c where c.Name like 'RAB%';

#Current Capacity
select t.*, c.Id, c.Code__c, c.Code_Description__c, ru.Utilisation from (
select 
r.Id as 'id', r.Name as 'name', r.Resource_Type__c as 'type', r.Reporting_Business_Units__c as 'businessUnit', 
group_concat(if (rc.Code__c is null, concat(rc.Standard__c, '-', rc.Rank__c), rc.Code__c) SEPARATOR ',') as 'capabilitiesIdsWithRanks',
r.Home_City__c, 
r.Home_Postcode__c, 
s.Name as 'state'
from resource__c r 
left join state_code_setup__c s on s.Id = r.Home_State_Province__c 
left join resource_competency__c rc on rc.Resource__c = r.Id 
where 
r.Home_Country1__c='a0Y90000000CGI8EAO' 
and rc.Status__c = 'Active' 
and (rc.Rank__c like '%Auditor%' or rc.Rank__c is null) 
and rc.Standard__c = 'a36d00000004ZXwAAM'
group by r.Id) t
inner join resource_competency__c rc on rc.Resource__c = t.Id 
inner join code__c c on rc.Code__c = c.Id
left join (
select w.Id, avg(w.Utilisation) as 'Utilisation' from (
SELECT 
        i.*, j.`Working Days`, if(i.Resource_Target_Days__c is null, i.AuditPlusTravelDays/(j.`Working Days`-LeavePlusHolidayDays), if(i.Resource_Target_Days__c<=50,'N/A', i.AuditPlusTravelDays/(j.`Working Days`/180*i.Resource_Target_Days__c-LeavePlusHolidayDays))) as 'Utilisation'    FROM
        (SELECT 
        DATE_FORMAT(t.ActivityDate, '%Y %m') AS 'Period',
            t.Id,
            t.Name,
            t.Resource_Target_Days__c,
            SUM(IF(t.SubType = 'Audit'
                OR t.SubType = 'Travel', t.DurationDays, 0)) AS 'AuditPlusTravelDays',
            SUM(IF(t.SubType LIKE 'Leave%'
                OR t.SubType = 'Public Holiday', t.DurationDays, 0)) AS 'LeavePlusHolidayDays'
    FROM
        (SELECT 
        r.Id,
            r.Name,
            r.Resource_Target_Days__c,
            r.Resource_Capacitiy__c,
            r.Resource_Type__c,
            r.Work_Type__c,
            rt.Name AS 'Type',
            IF(wir.Work_Item_Type__c IS NULL, bop.Resource_Blackout_Type__c, wir.Work_Item_Type__c) AS 'SubType',
            e.DurationInMinutes AS 'DurationMin',
            e.DurationInMinutes / 60 / 8 AS 'DurationDays',
            e.ActivityDate
    FROM
        resource__c r
    INNER JOIN user u ON u.Id = r.User__c
    INNER JOIN event e ON u.Id = e.OwnerId
    INNER JOIN recordtype rt ON e.RecordTypeId = rt.Id
    LEFT JOIN work_item_resource__c wir ON wir.Id = e.WhatId
    LEFT JOIN blackout_period__c bop ON bop.Id = e.WhatId
    WHERE
        (r.Reporting_Business_Units__c LIKE 'AUS%' OR r.Reporting_Business_Units__c LIKE 'ASS%')
            AND ((DATE_FORMAT(e.ActivityDate, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
            AND DATE_FORMAT(e.ActivityDate, '%Y %m') in ('2014 11','2014 10','2014 09','2014 08','2014 07','2014 06','2014 05'))
            OR e.Id IS NULL)
            AND Resource_Type__c NOT IN ('Client Services')
            #AND r.Reporting_Business_Units__c NOT IN ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS')
            #AND r.Reporting_Business_Units__c NOT LIKE 'AUS-Product%'
            #AND (r.Reporting_Business_Units__c LIKE '%AUS-Manage%' OR r.Reporting_Business_Units__c LIKE '%AUS-Direct%' or r.Reporting_Business_Units__c LIKE '%AUS-Global%')
             AND r.Active_User__c = 'Yes'
            #AND r.Resource_Type__c = 'Employee'
            #AND r.Resource_Target_Days__c IS NOT NULL
            #AND r.Resource_Target_Days__c > 0
            AND (e.IsDeleted = 0 OR e.Id IS NULL)) t
    GROUP BY `Period` , t.Id) i
    INNER JOIN (SELECT 
        DATE_FORMAT(wd.date, '%Y %m') AS 'Period',
            COUNT(wd.date) AS 'Working Days'
    FROM
        `sf_working_days` wd
    WHERE
        DATE_FORMAT(wd.date, '%Y %m') < DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 5 MONTH), '%Y %m')
            AND DATE_FORMAT(wd.date, '%Y %m') in ('2014 11','2014 10','2014 09','2014 08','2014 07','2014 06','2014 05')
    GROUP BY `Period`) j ON i.Period = j.Period
    ) w group by w.Id) ru on ru.Id = t.Id
where rc.Code__c in (select c.Id from code__c c where c.Name like 'RAB%');

create temporary table resource_available_days as 
select rwd.date, rwd.Id from (select wd.date, r2.Id from sf_working_days wd, resource__c r2
where #r2.Id='a0nd0000000hAkxAAE' and 
r2.Id in (select r.Id from resource__c r inner join resource_competency__c rc on rc.Resource__c = r.Id where rc.Status__c = 'Active' and (rc.Rank__c like '%Auditor%' or rc.Rank__c is null) and r.Status__c = 'Active' and r.IsDeleted=0 and rc.IsDeleted = 0 and rc.Standard__c = 'a36d00000004ZXwAAM' AND r.Active_User__c = 'Yes')
and wd.date >= '2015-05' and wd.date <= '2015-12'
) rwd 
left join
(select r.Id, count(e.Id), e.ActivityDate from resource__c r
INNER JOIN user u ON u.Id = r.User__c
INNER JOIN event e ON u.Id = e.OwnerId
where #r.Id='a0nd0000000hAkxAAE' and
r.Id in (select r.Id from resource__c r inner join resource_competency__c rc on rc.Resource__c = r.Id where rc.Status__c = 'Active' and (rc.Rank__c like '%Auditor%' or rc.Rank__c is null) and r.Status__c = 'Active' and r.IsDeleted=0 and rc.IsDeleted = 0 and rc.Standard__c = 'a36d00000004ZXwAAM' AND r.Active_User__c = 'Yes')
and e.ActivityDate >= '2015-05'
and e.ActivityDate <= '2015-12'
and e.IsDeleted=0
group by r.Id, e.ActivityDate) rescal on rescal.ActivityDate = rwd.date and rescal.Id = rwd.Id
where rescal.ActivityDate is null;

#Current Capacity V2
select t.*, c.Id, c.Code__c, c.Code_Description__c, date_format(rad.date , '%Y-%m') as 'Available Period', rad.date as 'Available Days' from (
select 
r.Id as 'id', r.Name as 'name', r.Resource_Type__c as 'type', r.Reporting_Business_Units__c as 'businessUnit', 
group_concat(rc.Rank__c SEPARATOR ',') as 'Ranks',
r.Home_City__c, 
r.Home_Postcode__c,
r.Resource_Capacitiy__c, 
s.Name as 'state'
from resource__c r 
left join state_code_setup__c s on s.Id = r.Home_State_Province__c 
left join resource_competency__c rc on rc.Resource__c = r.Id 
where 
r.Home_Country1__c='a0Y90000000CGI8EAO' 
and rc.Status__c = 'Active' 
and (rc.Rank__c like '%Auditor%' or rc.Rank__c is null) 
and rc.Standard__c = 'a36d00000004ZXwAAM' 
group by r.Id) t
inner join resource_competency__c rc on rc.Resource__c = t.Id 
inner join code__c c on rc.Code__c = c.Id
inner join resource_available_days rad on t.Id = rad.Id
where rc.Code__c in (select c.Id from code__c c where c.Name like 'RAB%') limit 100000000;

#a0nd0000000hAkxAAE

select wi.Primary_Standard__c, Work_Item_Stage__c, avg(wi.Required_Duration__c)
from salesforce.work_item__c wi 
where (wi.Primary_Standard__c like '%HACCP%' or wi.Primary_Standard__c like '%BRC%'
and wi.Revenue_Ownership__c like 'AUS%'
group by wi.Primary_Standard__c, wi.Work_Item_Stage__c;
