use salesforce;

select t.* from (
select scl.Site_Certification__c, group_concat(distinct wi.Primary_Standard__c), count(distinct wi.Primary_Standard__c) as 'Count Standards'
from salesforce.Site_Certification_Lifecycle__c scl
inner join salesforce.Work_item__c wi on scl.Work_Item__c = wi.Id
where Meta_Work_Item_Stage__c = 'Surveillance'
and scl.IsDeleted=0
and wi.IsDeleted = 0
and scl.fWork_Item_Status__c not in ('Cancelled')
group by scl.Site_Certification__c) t
where t.`Count Standards` > 1;

select Site_Certification__c, Frequency__c, count(Id)
from salesforce.Site_Certification_Lifecycle__c 
where Meta_Work_Item_Stage__c = 'Surveillance'
and IsDeleted=0
and fWork_Item_Status__c not in ('Cancelled')
group by Site_Certification__c, Frequency__c;

select t2.*, datediff(t2.work_item_Date__c, t2.Expires__c) from (
select t.ScspId, t.wiId, t.Status__c, t.work_item_Date__c, t.Expires__c, t.Sample_Site__c from
(select scsp.Id as 'ScspId', wi.Id as 'wiId', wi.Name, wi.Status__c, wi.Work_Item_Stage__c, wi.work_item_Date__c, csp.Expires__c, wi.Sample_Site__c
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled')
and wi.Work_Item_Stage__c = 'Re-Certification'
and wi.Revenue_Ownership__c like 'AUS%'
and scsp.Status__c = 'Registered'
order by scsp.Id, wi.Work_Item_Date__c) t
group by t.ScspId) t2
where t2.work_item_Date__c > t2.Expires__c;


select wi.Site_Certification_Standard__c, scsp.Name, wi.Id, wi.Name, Work_Package_Type__c, scsp.Status__c, datediff(now(), wi.CreatedDate), wi.Comments__c
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
where 
wi.IsDeleted = 0
and wi.Status__c = 'Open'
and wi.Work_Package_Type__c = 'Initial'
and scsp.Status__c = 'Applicant'
and wi.CreatedDate < date_add(now(), interval -1 year);

select * from (
select concat(t.suburb, ',',t.state, ',', t.postcode) as 'Target', t2.Name as 'Nearby Audit', t2.Auditor, 
t2.Business_City__c as 'Nearby Audit City', t2. Business_Zip_Postal_Code__c as 'Nearby Audit PostCode', t2.Work_Item_Date__C as 'When', t2.Status__c as 'Status', distance(t.Latitude, t.Longitude, SUBSTRING_INDEX(t2.Geo_Code__c, ', ',1), SUBSTRING_INDEX(t2.Geo_Code__c, ', ',-1)) as 'distance' from 
	(select suburb, state, postcode, latitude, longitude from analytics.postcodes_geo where suburb like '%darwin%' limit 1) t,
    (select wi.Id, wi.Name, r.Name as 'Auditor', wi.Work_Item_Date__C, wi.Status__c, `site`.Geo_Code__c, `site`.Geo_Location__c, `site`.Business_City__c, `site`.Business_Zip_Postal_Code__c from
		work_item__c wi
        inner join work_package__c wp on wi.Work_Package__c = wp.Id
        inner join certification__c sc on wp.Site_Certification__c = sc.Id
        inner join account `site` on sc.Primary_client__c = `site`.Id 
        inner join resource__c r on wi.Work_Item_Owner__c = r.Id
        where wi.Status__c not in ('Cancelled')
        and wi.IsDeleted = 0
		and wi.Work_Item_Date__c >= date_add(now(), interval 0 month)
        and wi.Work_Item_Date__c <= date_add(now(), interval 1 month)
        #and `site`.Geo_Location__c like '%Australia%'
        and `site`.Geo_Code__c is not null
	) t2) t3 
    where t3.Distance<=100
    order by t3.distance asc;
    
    
    select cs.Id, cs.Name,  cs.Geo_Location__c, cs.Geo_Code__c
	from account cs
	inner join country_code_setup__c ccs on cs.Business_Country2__c = ccs.Id
	where cs.Record_Type_Name__c = 'Client Site'
	and cs.Geo_Location__c is not null
	and cs.Geo_Code__c is not null
	#and ccs.Name = 'Australia'
	and cs.Geo_Location__c like '%Bologna%'
	group by cs.Geo_Code__c;