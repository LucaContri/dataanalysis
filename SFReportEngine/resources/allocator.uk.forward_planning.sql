# Output for UK Scheduling Forward Planning using MIP Allocator
(select
	t2.*,
    if(nullif(t2.`Actual Resource Id`,'') is not null, t2.`Actual Resource Calculated Cost`, if(t2.`Allocator Status` not in ('NOT ALLOCATED'), t2.`Allocator Resource Calculated Cost`, null)) as 'Resource Calculated Cost'
from
	(select 
		t.*,
		analytics.getAuditCostEmpirical(nullif(t.`Allocator Resource Distance`,''), t.`Required Duration`, nullif(t.`Allocator Resource Type`,''), analytics.getAuditorHourlyRate(nullif(t.`Allocator Resource Id`,'')) ) as 'Allocator Resource Calculated Cost',
		analytics.getAuditCostEmpirical(nullif(t.`Actual Resource Distance`,''), t.`Required Duration`, nullif(t.`Actual Resource Type`,''), analytics.getAuditorHourlyRate(nullif(t.`Actual Resource Id`,'')) ) as 'Actual Resource Calculated Cost', 
		ifnull(nullif(t.`Actual Resource Id`,''), t.`Allocator Resource Id`) as 'Resource Id',
		ifnull(nullif(t.`Actual Resource Name`,''), t.`Allocator Resource Name`) as 'Resource Name',
		ifnull(nullif(t.`Actual Resource Type`,''), t.`Allocator Resource Type`) as 'Resource Type',
        ifnull(nullif(t.`Actual Resource Travel Duration`,''), t.`Allocator Resource Travel Duration`) as 'Resource Travel Duration',
		ifnull(nullif(t.`Actual Resource Reporting Business Unit`,''), t.`Allocator Resource Reporting Business Unit`) as 'Resource Reporting Business Unit',
		ifnull(nullif(t.`Actual Resource Location`,''), t.`Allocator Resource Location`) as 'Resource Location',
		if(nullif(t.`Actual Resource Id`,'') is not null, t.`Actual Resource Distance`, t.`Allocator Resource Distance`) as 'Resource Distance'
		from 
		(SELECT 
			wi.Id as 'Work Item Id',
			wi.Name as 'Work Item',
			wi.Service_Delivery_Type__c, 
			wi.Status__c as 'Work Item Status',
			wi.Open_Sub_Status__c 'Open Sub Status', 
			wi.Work_Item_Stage__c 'Work Item Type', 
			wi.Location__c as 'WI Location', 
			wi.Work_Item_Date__c as 'Work Item Start Date',
			wi.Required_Duration__c as 'Required Duration',			
			ifnull(ar.Id, '') as 'Actual Resource Id',
			ifnull(ar.Name,'') as 'Actual Resource Name',
			ifnull(ar.Resource_Type__c, '') as 'Actual Resource Type',
            ifnull(analytics.getTravelReturnTimeHrs(analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)), '') as 'Actual Resource Travel Duration',
			ar.Reporting_Business_Units__c as 'Actual Resource Reporting Business Unit',
			ifnull(concat(
			 ifnull(concat(ar.Home_Address_1__c,' '),''),
			 ifnull(concat(ar.Home_Address_2__c,' '),''),
			 ifnull(concat(ar.Home_Address_3__c,' '),''),
			 ifnull(concat(ar.Home_City__c,' '),''),
			 ifnull(concat(ascs.Name,' '),''),
			 ifnull(concat(accs.Name,' '),''),
			 ifnull(concat(ar.Home_Postcode__c,' '),'')), '') as 'Actual Resource Location',
			ifnull(analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2, '') as 'Actual Resource Distance',
			ifnull(s.`Status`, 'OUT OF SCOPE') as 'Allocator Status',
			ifnull(s.`ResourceId`,'') as 'Allocator Resource Id',
			ifnull(s.`ResourceName`, '') as 'Allocator Resource Name',
			ifnull(s.`ResourceType`, '') as 'Allocator Resource Type',
            ifnull(s.`TravelDuration`, '') as 'Allocator Resource Travel Duration',
			ifnull(r.Reporting_Business_Units__c,'') as 'Allocator Resource Reporting Business Unit',
			ifnull(concat(
			 ifnull(concat(r.Home_Address_1__c,' '),''),
			 ifnull(concat(r.Home_Address_2__c,' '),''),
			 ifnull(concat(r.Home_Address_3__c,' '),''),
			 ifnull(concat(r.Home_City__c,' '),''),
			 ifnull(concat(scs.Name,' '),''),
			 ifnull(concat(ccs.Name,' '),''),
			 ifnull(concat(r.Home_Postcode__c,' '),'')), '') as 'Allocator Resource Location',
			ifnull(s.`Distance`, '') as 'Allocator Resource Distance'
		from salesforce.work_item__c wi 
		left join salesforce.allocator_schedule s on 
			left(s.WorkItemId,18) = wi.Id and 
			BatchId='UK Forward Planning' 
			and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning') 
			and s.`Type` = 'AUDIT'
		inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
		inner join salesforce.account site on sc.Primary_client__c = site.Id
		left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
		left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
		left join salesforce.saig_geocode_cache sgeo on concat(
														 ifnull(concat(site.Business_Address_1__c ,' '),''),
														 ifnull(concat(site.Business_Address_2__c,' '),''),
														 ifnull(concat(site.Business_Address_3__c,' '),''),
														 ifnull(concat(site.Business_City__c ,' '),''),
														 ifnull(concat(sscs.Name,' '),''),
														 ifnull(concat(sccs.Name,' '),''),
														 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = sgeo.Address
		left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.Work_Item_Type__c = 'Audit' and wir.IsDeleted = 0
		left join salesforce.resource__c ar on wir.Resource__c = ar.Id
		left join salesforce.country_code_setup__c accs on ar.Home_Country1__c = accs.Id
		left join salesforce.state_code_setup__c ascs on ar.Home_State_Province__c = ascs.Id
		left join salesforce.saig_geocode_cache geo on concat(
														 ifnull(concat(ar.Home_Address_1__c,' '),''),
														 ifnull(concat(ar.Home_Address_2__c,' '),''),
														 ifnull(concat(ar.Home_Address_3__c,' '),''),
														 ifnull(concat(ar.Home_City__c,' '),''),
														 ifnull(concat(ascs.Name,' '),''),
														 ifnull(concat(accs.Name,' '),''),
														 ifnull(concat(ar.Home_Postcode__c,' '),'')) = geo.Address
		left join salesforce.resource__c r on s.ResourceId = r.Id
		left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
		left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
		where wi.IsDeleted = 0
			AND wi.Status__c NOT IN ('Cancelled', 'Draft', 'Initiate Service')
			AND wi.Work_Item_Stage__c NOT IN ('Follow Up')
			AND wi.Revenue_Ownership__c IN ('EMEA-UK')
			AND sccs.Name IN ('United Kingdom')
			AND wi.Work_Item_Date__c >= '2017-02-01'
			AND wi.Work_Item_Date__c <= '2017-08-31'
		group by wi.Id
		) t
	) t2
);



# Output for UK Scheduling Forward Planning using MIP Allocator
(SELECT 
	wi.Id as 'Work Item Id',
	wi.Name as 'Work Item',
	wi.Service_Delivery_Type__c, 
	wi.Status__c as 'Work Item Status',
	wi.Open_Sub_Status__c 'Open Sub Status', 
	wi.Work_Item_Stage__c 'Work Item Type', 
	wi.Location__c as 'WI Location', 
	wi.Work_Item_Date__c as 'Work Item Start Date',
	wi.Required_Duration__c as 'Required Duration',			
	ar.Id as 'Actual Resource Id',
	ar.Name as 'Actual Resource Name',
	ar.Resource_Type__c as 'Actual Resource Type',
	0.0 as 'Actual Resource Travel Duration',
	ar.Reporting_Business_Units__c as 'Actual Resource Reporting Business Unit',
	concat(
	 ifnull(concat(ar.Home_Address_1__c,' '),''),
	 ifnull(concat(ar.Home_Address_2__c,' '),''),
	 ifnull(concat(ar.Home_Address_3__c,' '),''),
	 ifnull(concat(ar.Home_City__c,' '),''),
	 ifnull(concat(ascs.Name,' '),''),
	 ifnull(concat(accs.Name,' '),''),
	 ifnull(concat(ar.Home_Postcode__c,' '),'')) as 'Actual Resource Location',
	analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2 as 'Actual Resource Distance',
    analytics.getAuditorHourlyRate(ar.Id) as 'Actual Resource Hourly Rate',
	ifnull(s.`Status`, 'OUT OF SCOPE') as 'Allocator Status',
	s.`ResourceId` as 'Allocator Resource Id',
	s.`ResourceName` as 'Allocator Resource Name',
	s.`ResourceType` as 'Allocator Resource Type',
	s.`TravelDuration` as 'Allocator Resource Travel Duration',
	r.Reporting_Business_Units__c as 'Allocator Resource Reporting Business Unit',
	concat(
	 ifnull(concat(r.Home_Address_1__c,' '),''),
	 ifnull(concat(r.Home_Address_2__c,' '),''),
	 ifnull(concat(r.Home_Address_3__c,' '),''),
	 ifnull(concat(r.Home_City__c,' '),''),
	 ifnull(concat(scs.Name,' '),''),
	 ifnull(concat(ccs.Name,' '),''),
	 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Allocator Resource Location',
	s.`Distance` as 'Allocator Resource Distance',
    analytics.getAuditorHourlyRate(ar.Id) as 'Allocator Resource Hourly Rate',
	0.0 as 'Allocator Resource Calculated Cost',
	0.0 as 'Actual Resource Calculated Cost', 
	null as 'Resource Id',
	null as 'Resource Name',
	null as 'Resource Type',
	0.0 as 'Resource Travel Duration',
	null as 'Resource Reporting Business Unit',
	null as 'Resource Location',
	0.0 as 'Resource Distance',
	0.0 as 'Resource Calculated Cost',
    null as 'Resource Scheduling Type'
from salesforce.work_item__c wi 
left join salesforce.allocator_schedule s on 
	left(s.WorkItemId,18) = wi.Id and 
	BatchId='UK Forward Planning' 
	and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning') 
	and s.`Type` = 'AUDIT'
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache sgeo on concat(
												 ifnull(concat(site.Business_Address_1__c ,' '),''),
												 ifnull(concat(site.Business_Address_2__c,' '),''),
												 ifnull(concat(site.Business_Address_3__c,' '),''),
												 ifnull(concat(site.Business_City__c ,' '),''),
												 ifnull(concat(sscs.Name,' '),''),
												 ifnull(concat(sccs.Name,' '),''),
												 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = sgeo.Address
left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.Work_Item_Type__c = 'Audit' and wir.IsDeleted = 0
left join salesforce.resource__c ar on wir.Resource__c = ar.Id
left join salesforce.country_code_setup__c accs on ar.Home_Country1__c = accs.Id
left join salesforce.state_code_setup__c ascs on ar.Home_State_Province__c = ascs.Id
left join salesforce.saig_geocode_cache geo on concat(
												 ifnull(concat(ar.Home_Address_1__c,' '),''),
												 ifnull(concat(ar.Home_Address_2__c,' '),''),
												 ifnull(concat(ar.Home_Address_3__c,' '),''),
												 ifnull(concat(ar.Home_City__c,' '),''),
												 ifnull(concat(ascs.Name,' '),''),
												 ifnull(concat(accs.Name,' '),''),
												 ifnull(concat(ar.Home_Postcode__c,' '),'')) = geo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
where wi.IsDeleted = 0
	AND wi.Status__c NOT IN ('Cancelled', 'Draft', 'Initiate Service')
	AND wi.Work_Item_Stage__c NOT IN ('Follow Up')
	AND wi.Revenue_Ownership__c = (select RevenueOwnership from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning'))
	AND sccs.Name = (select AuditCountries from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning'))
	AND wi.Work_Item_Date__c >= (select StartDate from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning'))
	AND wi.Work_Item_Date__c <= (select EndDate from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning'))
group by wi.Id
);

select * from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning' and SubBatchId = (select max(SubBatchId) from salesforce.allocator_schedule_batch where BatchId='UK Forward Planning');