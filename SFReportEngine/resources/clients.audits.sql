use analytics;
#drop table filters;
create table filters (
	`Query Id` varchar(64) not null,
    `Filter Type` varchar(64) not null,
    `Value` varchar(64) not null,
    PRIMARY KEY (`Query Id`, `Filter Type`, `Value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

##### FILTERS #######

# 2Sisters BRC
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.2Sisters.BRC.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId, 'Standard', s.Id from salesforce.standard__c s where s.Name like '%BRC%'
	union all
	select @queryId,  'Client' as 'Filter Type', a.Id from salesforce.account a where a.Client_Number__c in ('AS330164', 'AS328464', 'AS329638', 'AS328465', 'AS459311', 'AS328479', 'AS330971', 'AS331033', 'AS330100', 'AS330082', 'AS330243', 'AS330048', 'AS330467', 'AS330055', 'AS329897', 'AS329517', 'AS330368', 'AS328475', 'AS328599', 'AS331217', 'AS328468', 'AS328461', 'AS326720', 'AS327691', 'AS329634', 'AS328491', 'AS327562', 'AS329730', 'AS328933', 'AS328467', 'AS330172', 'AS328492', 'AS331252', 'AS328607', 'AS329106')
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);

# BMPA
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.BMPA.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId, 'Standard', s.Id from salesforce.standard__c s where s.Name like '%British Quality Assured%' or s.Name like 'West Country%' or s.Name like 'Charter Quality British%'
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);
    
# Greggs
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.Greggs.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId,  'Client' as 'Filter Type', a.Id from salesforce.account a inner join salesforce.account p on a.ParentId = p.Id where p.Client_Number__c in ('AS415060')
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);
    
# Noble
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.noble.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId,  'Client' as 'Filter Type', a.Id from salesforce.account a where a.Client_Number__c in ('AS280598')
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);

# United Biscuits
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.UnitedBiscuits.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId, 'Standard', s.Id from salesforce.standard__c s where s.Name like '%United Biscuits%'
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);
    
# Yum!
set @arg_completion_days_target_brc = 42;
set @arg_completion_days_target = 15;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
set @queryId = 'audits.YUM.Query';
delete from analytics.filters where `Query Id` = @queryId;
insert into analytics.filters 
	select @queryId, 'Standard', s.Id from salesforce.standard__c s where s.Name like '%YUM%'
	union all
	select @queryId, 'FromDate', date_format(date_add(utc_timestamp(), interval -12 month), '%Y-%m-01')
	union all
	select @queryId, 'ToDate', date_add(date_format(date_add(utc_timestamp(), interval 7 month), '%Y-%m-01'), interval -1 day);
	
# General
#set @audit_window_months_before_target  = 1;
#set @audit_window_months_after_target = 1;
#set @queryId = 'audits.client.standard.Query';
#delete from analytics.filters where `Query Id` = @queryId;
#insert into analytics.filters 
	#select @queryId, 'FromDate', '2015-10-01'
	#union all
	#select @queryId, 'ToDate', '2017-11-30'
	#union all
	#select @queryId, 'Country', ccs.Id from salesforce.country_code_setup__c ccs where analytics.getRegionFromCountry(ccs.name) = 'EMEA'
	#union all
	#select @queryId, 'Standard', s.Id from salesforce.standard__c s where s.Name like '%British Quality Assured%' or s.Name like 'West Country%' or s.Name like 'Charter Quality British%'; 
	#union all
	#select @queryId,  'Client' as 'Filter Type', a.Id from salesforce.account a inner join salesforce.account p on a.ParentId = p.Id where p.Client_Number__c in ('AS415060');
		
#explain
(SELECT 
	client.name as 'Client',
	client.Client_Number__c as 'Client No',
	site.Name as 'Client Site',
	ifnull(csp.External_provided_certificate__c,'') as 'Site Code',
	country.sai_region as 'Site Region',
	cont.name as 'Continent',
	ccs.Name as 'Site Country',
	ifnull(csp.BRC_Grade_Achieved__c, '') as 'BRC Grade',
	ifnull(csp.BRD_Audit_Program__c, '') as 'BRC Audit Program',
	wi.Id AS 'Work Item Id',
	wi.Name AS 'Work Item Name',
	wi.Status__c AS 'Work Item Status',
	if (wi.Status__c  in ('Open','Service change'), 'Open',
	if(wi.Status__c  in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress'), 'Planned','Delivered')) as 'Simple Status',
	#ifnull(wi.Open_Sub_Status__c, '') as 'Open Sub Status',
	wi.Work_Item_Date__c AS 'Work Item Date',
    date_format(wi.Work_Item_Date__c, '%Y %m') AS 'Work Item Period',
	str_to_date(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y-%m-%d') as 'Work Item Target Date',
	ifnull(date_format(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y %m'),'') as 'Work Item Target Period',
	str_to_date(ifnull(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month),''),'%Y-%m-%d') as 'WI Audit Window Start',
	str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d') as 'WI Audit Window End',
	wi.Work_Item_Date__c between 
		date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month) 
		and str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d') as 'Scheduling Within SLA',
	1 as '# Audits',
	ifnull(group_concat(distinct r.Name order by r.Name), '') as 'Auditor(s)',
	wi.Required_Duration__c/8 as 'Days',
	sc.Operational_Ownership__c AS 'Scheduling Ownership',
	sc.Revenue_Ownership__c as 'Revenue Ownership',
	s.Name as 'Primary Standard',
	wi.Work_Item_Stage__c as 'Work Item Type',
	ifnull(group_concat(distinct sf.Name), '') as 'FoS',
	ifnull(group_concat(distinct code.Code_Description__c), '') as 'Codes',
	ifnull(wi.Comments__c,'') as 'Comments',
    if (wi.Status__c  in ('Open','Service change') and wi.Work_Item_Date__c<date_format(utc_timestamp(), '%Y-%m-%d') ,1,0) as 'backlog',
    wi.Rollup_End_Time__c as 'End Service Date',
    cast(ifnull(max(wih.CreatedDate) ,'1970-01-01') as datetime) as 'WI Completed Date',
    if(s.Name like '%BRC%', @arg_completion_days_target_brc, @arg_completion_days_target) as 'WI Processing Days Target',
    timestampdiff(second, wi.Rollup_End_Time__c, max(wih.CreatedDate))/3600/24 as 'WI Processing Days',
    if(timestampdiff(second, wi.Rollup_End_Time__c, max(wih.CreatedDate))/3600/24<=if(s.Name like '%BRC%', @arg_completion_days_target_brc, @arg_completion_days_target), 1, 0) as 'WI Completed within SLA'
FROM	
	salesforce.work_item__c wi
	left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.ID and wir.IsDeleted = 0
	left join salesforce.resource__c r on wir.Resource__c = r.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id and scspc.IsDeleted = 0
	left join salesforce.code__c code on scspc.Code__c = code.Id
	inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	left join analytics.countries_names cn on ccs.Name = cn.name
	left join analytics.countries country on cn.code = country.code
	left join analytics.continents cont on country.continent_code = cont.code
	inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
	left join salesforce.delivery_strategy__c ds on c.Delivery_Strategy__c = ds.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id and scsf.IsDeleted = 0
	left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
	left join salesforce.standard__c sf on spf.Standard__c = sf.Id
    left join salesforce.work_item__history wih on wih.ParentId = wi.Id and wih.IsDeleted = 0 and wih.Field = 'Status__c' and wih.NewValue = 'Completed'
WHERE
	wi.Status__c NOT IN ('Cancelled' , 'Draft', 'Initiate Service')
    and wi.Work_Item_Stage__c not in ('Follow Up')
	AND if((select count(*) from analytics.filters where `Filter Type` = 'Client' and `Query Id` = @queryId) = 0, 1, 
		client.Id in (select `value` from analytics.filters where `Filter Type` = 'Client' and `Query Id` = @queryId))
	AND if(
	(select count(*) from analytics.filters where `Filter Type` = 'Standard' and `Query Id` = @queryId) = 0, 1, 
		s.Id in (select `value` from analytics.filters where `Filter Type` = 'Standard' and `Query Id` = @queryId) or
		(sf.Id in (select `value` from analytics.filters where `Filter Type` = 'Standard' and `Query Id` = @queryId)))
	AND if((select count(*) from analytics.filters where `Filter Type` = 'Country' and `Query Id` = @queryId) = 0, 1, 
		ccs.Id in (select `value` from analytics.filters where `Filter Type` = 'Country' and `Query Id` = @queryId))
	AND if((select count(*) from analytics.filters where `Filter Type` = 'FromDate' and `Query Id` = @queryId) = 0, 1, 
		wi.Work_Item_Date__c >= (select `value` from analytics.filters where `Filter Type` = 'FromDate' and `Query Id` = @queryId limit 1))
	AND if((select count(*) from analytics.filters where `Filter Type` = 'ToDate' and `Query Id` = @queryId) = 0, 1, 
		wi.Work_Item_Date__c <= (select `value` from analytics.filters where `Filter Type` = 'ToDate' and `Query Id` = @queryId limit 1))
group by wi.Id);