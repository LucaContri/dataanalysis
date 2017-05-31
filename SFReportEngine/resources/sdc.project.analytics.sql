use salesforce;
create index certification_Primary_Client_index on Certification__c(Primary_Client__c);
create index Site_Cert_Standard_Program_Code_index on Site_Cert_Standard_Program_Code__c(Site_Certification_Standard_Program__c);
create index resource_competency_standard_index on resource_competency__c(Standard__c);
create index resource_competency_code_index on resource_competency__c(Code__c);

CREATE FUNCTION `DISTANCE_METRO`(lat1 double(18,10), lon1 double(18,10), postcode varchar(10)) RETURNS double(18,10)
return if (postcode like '2%',distance(lat1, lon1, -33.873651, 151.20688960000007),
			if (postcode like '3%',distance(lat1, lon1, -37.814107000000000000, 144.963279999999940000),
				if (postcode like '4%',distance(lat1, lon1, -27.471010700000000000, 153.023448899999950000),
					if (postcode like '5%',distance(lat1, lon1, -34.928621199999990000, 138.599959400000000000),
						if (postcode like '6%',distance(lat1, lon1, -31.953004400000000000, 115.857469300000050000),-1)
					)
				)
			)
		);

# Complexity = sqrt(Site Certs)*No of Standards
# select client.name, client.Id, sdc.name, scheduler.name, Site Certs, Standards, Complexity
# 
select t.`ClientId`, t.`Client`, t.`Client Ownership`, t.`SDC`, t.`Manager`, t.`State`, t.`Schedulers`, t.`Site Certs`, t.`Standards`, sqrt(t.`Site Certs`)*t.`Standards` as 'Complexity' from (
select 
client.Id as 'ClientId', 
client.Client_Number__c as 'Client No',
client.Name as 'Client', 
client.Client_Ownership__c as 'Client Ownership', 
sdc.Name as 'SDC', 
#substring_index(substring_index(sdcr.Manager__c,'>',-2),'<',1) as 'Manager',
#scs.Name as 'State',
sdc.ManagerId,
sdcm.name as 'Manager',
sdc.State, 
count(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sc.Id,null)) as 'Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0,c.Id,null)) as 'Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0,s.Name,null)) as 'Standards',
group_concat(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sched.Name,null)) as 'Schedulers',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c='Management Systems', sc.Id,null)) as 'MS Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c like '%Food%', sc.Id,null)) as 'Food Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c = 'Product Services', sc.Id,null)) as 'PS Site Certs'
from account site
inner join recordtype rt on rt.Id = site.RecordTypeId
left join account client on site.ParentId = client.Id
left join user sdc on client.Service_Delivery_Coordinator__c = sdc.Id
left join user sdcm on sdc.ManagerId = sdcm.Id
#left join resource__c sdcr on sdcr.User__c = sdc.Id
#left join state_code_setup__c scs on sdcr.Home_State_Province__c = scs.Id
left join certification__c sc on sc.Primary_Client__c = site.Id
left join certification__c c on sc.Primary_Certification__c = c.Id
left join standard_program__c sp on sp.Id = c.Primary_Standard__c
left join standard__c s on sp.Standard__c = s.Id
left join user sched on sc.Scheduler__c = sched.Id
where
rt.Name = 'Client Site'
and site.IsDeleted = 0
and client.IsDeleted = 0
and client.Client_Ownership__c = 'Australia'
group by client.Id) t
where t.`Site Certs`>0
and t.`MS Site Certs`>0
and t.`Food Site Certs`=0
and t.`PS Site Certs`=0
limit 1000000;

select * from sf_tables where TableNAme = 'Resource__c';
#explain
#Clients, Complexity, Segmentation, No of sites, No of site certs, No of Standards, Complexity metric
#create temporary table client_info as 
select 
if(parent.Name is null, 'n/a',parent.Name ) as 'Parent',
client.Id as 'ClientId', 
client.Client_Number__c as 'Client No',
client.Name as 'Client', client.Client_Ownership__c as 'Client Ownership', client.Scheduling_Complexity__c as 'Client Complexity', client.Client_Segmentation__c as 'Client Segmentation', sdc.Name as 'Client SDC', 
count(distinct site.Id) as 'Sites',
count(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sc.Id,null)) as 'Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0,c.Id,null)) as 'Certs',
sum(if(c.Status__c='Active' and c.IsDeleted=0, c.Sample_Service__c, 0)) as 'Sample Services',
count(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sc.Id,null))*count(distinct if(c.Status__c='Active' and c.IsDeleted=0,c.Id,null)) as 'Complexity Metric',
# sqrt(Site Certs)*No of Standards
group_concat(distinct if(c.Status__c='Active' and c.IsDeleted=0,s.Name,null)) as 'Standards',
group_concat(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sc.Operational_Ownership__c,null)) as 'Site Cert Scheduling Ownerships',
group_concat(distinct if(sc.Status__c='Active' and sc.IsDeleted=0,sched.Name,null)) as 'Site Cert Schedulers',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c='Management Systems', sc.Id,null)) as 'MS Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c='Management Systems', c.Id,null)) as 'MS Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c like '%Food%', sc.Id,null)) as 'Food Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c like '%Food%', c.Id,null)) as 'Food Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c = 'Product Services', sc.Id,null)) as 'PS Site Certs',
count(distinct if(c.Status__c='Active' and c.IsDeleted=0 and sp.Program_Business_Line__c = 'Product Services', c.Id,null)) as 'PS Certs'
from account site
inner join recordtype rt on rt.Id = site.RecordTypeId
left join account client on site.ParentId = client.Id
left join user sdc on client.Service_Delivery_Coordinator__c = sdc.Id
left join account parent on client.ParentId = parent.Id
left join certification__c sc on sc.Primary_Client__c = site.Id
left join certification__c c on sc.Primary_Certification__c = c.Id
left join standard_program__c sp on sp.Id = c.Primary_Standard__c
left join standard__c s on sp.Standard__c = s.Id
left join user sched on sc.Scheduler__c = sched.Id
where
rt.Name = 'Client Site'
and site.IsDeleted = 0
and client.IsDeleted = 0
group by client.Id
limit 1000000;

select * from client_info limit 100000;
create temporary table emea_site_cert_resources as 
(select t3.`Client Ownership`, t3.ClientId, t3.Client, t3.Site, t3.`Site Location`, t3.`Site PostCode`, t3.`Latitude__c`, t3.`Longitude__c`, t3.`Site Metro Distance`, t3.`Site Cert`, t3.`Standard`, t3.`Codes`,
count(distinct if(t3.`#Codes`=t3.`AllCodes` and t3.Status__c='Active' and t3.Rank__c like '%Lead Auditor%', t3.`ResourceId`, null)) as '#Resources', 
group_concat(distinct if(t3.`#Codes`=t3.`AllCodes` and t3.Status__c='Active' and t3.Rank__c like '%Lead Auditor%', t3.`Resource`, null)) as 'Resource Name' 
from (
select t2.*, rc.Status__c, rc.Rank__c from (
select t.*,
count(distinct if(r.Reporting_Business_Units__c like 'EMEA-UK%' and r.Status__c='Active' and rc.Status__c='Active', rc.Id, null)) as '#Codes',
if(r.Reporting_Business_Units__c like 'EMEA-UK%' and r.Status__c='Active' and rc.Status__c='Active',r.Id,null) as 'ResourceId', 
if(r.Reporting_Business_Units__c like 'EMEA-UK%' and r.Status__c='Active' and rc.Status__c='Active',r.Name, null) as 'Resource', 
if(r.Reporting_Business_Units__c like 'EMEA-UK%' and r.Status__c='Active' and rc.Status__c='Active',r.Managing_Office__c,null) as 'Managing_Office__c', 
if(r.Reporting_Business_Units__c like 'EMEA-UK%' and r.Status__c='Active' and rc.Status__c='Active',r.Scheduling_Office__c,null) as 'Scheduling_Office__c'
from (
select t1.*,
code.Id as 'CodeId'
from (
select 
#parent.Id, 
parent.Name as 'Parent', 
client.Id as 'ClientId', 
client.Name as 'Client', client.Client_Ownership__c as 'Client Ownership', client.Scheduling_Complexity__c as 'Client Complexity', client.Client_Segmentation__c as 'Client Segmentation', 
site.Id as 'SiteId', 
site.Name as 'Site', sc.Name as 'Site Cert',
site.Location__c as 'Site Location',
site.Business_Zip_Postal_Code__c as 'Site PostCode',
site.Latitude__c, site.Longitude__c,
null as 'Site Metro Distance',
#distance_metro(site.Latitude__c, site.Longitude__c, left(site.Business_Zip_Postal_Code__c,10)) as 'Site Metro Distance',
group_concat(distinct scsp.Standard_Service_Type_Name__c order by scsp.Standard_Service_Type_Name__c) as 'Standard',
sp.Standard__c as 'StandardId',
group_concat(distinct if(scspc.IsDeleted=0 and code.IsDeleted=0, code.Name, null) order by code.id) as 'Codes',
count(distinct if(scspc.IsDeleted=0 and code.IsDeleted=0, code.Name, null)) as 'AllCodes',
#code.Id as 'CodeId',
#sp.Standard__c as 'StandardId'
scsp.Id as 'Site_Certification_Standard_Program__c'
from account site
inner join recordtype rt on rt.Id = site.RecordTypeId
left join account client on site.ParentId = client.Id
left join account parent on client.ParentId = parent.Id
inner join certification__c sc on sc.Primary_Client__c = site.Id
inner join Site_Certification_Standard_Program__c scsp on scsp.Site_Certification__c = sc.Id
inner join Standard_Program__c sp on scsp.Standard_Program__c = sp.Id
left join Site_Cert_Standard_Program_Code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join Code__c code on scspc.Code__c = code.Id
where
rt.Name = 'Client Site'
and site.IsDeleted = 0
and client.IsDeleted = 0
and sc.Status__c = 'Active'
and scsp.Status__c in ('Registered','Applicant')
and client.Client_Ownership__c = 'EMEA - UK'
#and sc.Id = 'a1kd0000000RCpbAAG'
#and client.Id='001d000000AM1L7AAL'
group by sc.Id 
) t1
left join Site_Cert_Standard_Program_Code__c scspc on scspc.Site_Certification_Standard_Program__c = t1.Site_Certification_Standard_Program__c
left join Code__c code on scspc.Code__c = code.Id
where scspc.IsDeleted=0 and code.IsDeleted=0
) t
left join resource_competency__c rc on rc.Code__c = t.CodeId
left join resource__c r on rc.Resource__c = r.Id
#where 
group by t.Site_Certification_Standard_Program__c, r.Id ) t2
left join resource_competency__c rc on rc.Standard__c = t2.StandardId and rc.Resource__c = t2.ResourceId
) t3
#left join client_info ci on t3.ClientId = ci.ClientId
group by t3.`Site_Certification_Standard_Program__c`, t3.`ResourceId`);

# Site Cert with Codes
#explain
select 
t4.`Standard`, t4.`Codes`, count(distinct t4.`Site Cert`) as '#SiteCerts', count(distinct t4.`Resource Name`) as '#Resources', count(distinct t4.`Site Cert`)/count(distinct t4.`Resource Name`) as 'Sites/Resources Ratio'
from emea_site_cert_resources t4
group by t4.`Standard`, t4.`Codes`
limit 1000000;

# Resource
#explain
select t.*, sc.Code_Type__c, code.Name from (
select r.Id, r.Name, s.Id as 'StandardId', s.Name as 'Standard', rc.Rank__c
from resource__c r
inner join resource_competency__c rc on rc.Resource__c = r.Id
left join standard__c s on rc.Standard__c = s.Id
where 
rc.Rank__c like '%Lead Auditor%'
and rc.Status__c='Active'
and r.Managing_Office__c like 'Australia%'
#and r.Id='a0nd0000000hAqWAAU'
) t
left join standard_code__c sc on sc.Standard__c = t.StandardId
left join resource_competency__c rc on rc.Resource__c = t.id
inner join Code__c code on rc.Code__c = code.Id and code.Name like concat(sc.Code_Type__c,'%')
where rc.Status__c='Active'
limit 1000000;

select * from resource_competency__c rc where rc.Resource__c='a0nd0000000hAqWAAU' and Standard__c is not null;
select * from standard_code__c;
select * from sf_tables where TableNAme like '%competen%';