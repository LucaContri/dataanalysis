use salesforce;

#Views
create or replace view work_item_pricing_sub as 
select 
		wi.Id as 'WorkItemId',
		wi.Work_Item_Stage__c,
		wi.Work_Item_Date__c,
		wp.Site_Certification__c,
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		group by wi.Id; 

create or replace view work_item_pricing as 
select t.*, 	
	sum(if(p.UOM__c = 'DAY', pbe.UnitPrice, 0)) as 'ListPrice_day',
	sum(if(p.UOM__c = 'HFD', pbe.UnitPrice, 0)) as 'ListPrice_halfday',
	sum(if(p.UOM__c = 'HR', pbe.UnitPrice, 0)) as 'ListPrice_hour',	
	sum(if(cep.New_Price__c is null, if(p.UOM__c = 'DAY',pbe.UnitPrice,0), if(p.UOM__c = 'DAY',cep.New_Price__c,0))) as 'EffectivePrice_day',
	sum(if(cep.New_Price__c is null, if(p.UOM__c = 'HFD',pbe.UnitPrice,0), if(p.UOM__c = 'HFD',cep.New_Price__c,0))) as 'EffectivePrice_halfday',
	sum(if(cep.New_Price__c is null, if(p.UOM__c = 'HR',pbe.UnitPrice,0), if(p.UOM__c = 'HR',cep.New_Price__c,0))) as 'EffectivePrice_hour'	
	from work_item_pricing_sub t 
	left join product2 p ON t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
	left join pricebookentry pbe ON pbe.Product2Id = p.Id	
	left join certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = t.Site_Certification__c	
	left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
	Where	
	p.Category__c = 'Audit'	
	and pbe.Pricebook2Id = '01s90000000568BAAQ'	
	and (cp.Status__c = 'Active' or cp.Status__c is null)	
	and (if(cep.New_Start_Date__c is not null, cep.New_Start_Date__c <= t.Work_Item_Date__c, 1))	
	and (if(cep.New_End_Date__c is not null, cep.New_End_Date__c >= t.Work_Item_Date__c, 1))		
group by t.`WorkItemId`;	

select t.*, wi.Work_Item_Stage__c, wi.Work_Package_Type__c from (
(select wi.Id, wi.Required_Duration__c/8 as 'Days',wi.Service_target_date__c as 'Original Scheduled Date',date_format(wi.Service_target_date__c, '%Y %m') as 'Original Scheduled Period', wir.Start_Date__c as 'Scheduled Date', date_format(wir.Start_Date__c, '%Y %m') as 'Scheduled Period', min(wir.CreatedDate) as 'ModifiedDate', date_format(min(wir.CreatedDate), '%Y %m') as 'ModifiedPeriod', wi.CreatedDate as 'WorkItemCreateDate', date_format(wi.CreatedDate,'%Y %m') as 'WorkItemCreatePeriod' 
from work_item__c wi 
inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id
where 
#wi.Id='a3Id00000000acEEAQ'
wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget')
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.id, wir.Start_Date__c
order by wi.id, `ModifiedDate`)
UNION
(select wi.Id, wi.Required_Duration__c/8 as 'Days',wi.Service_target_date__c as 'Original Scheduled Date', date_format(wi.Service_target_date__c, '%Y %m') as 'Original Scheduled Period', wi.Service_target_date__c as 'Scheduled Date', date_format(wi.Service_target_date__c, '%Y %m') as 'Scheduled Period',wi.CreatedDate as 'ModifiedDate', date_format(wi.CreatedDate, '%Y %m') as 'ModifiedPeriod', wi.CreatedDate as 'WorkItemCreateDate', date_format(wi.CreatedDate,'%Y %m') as 'WorkItemCreatePeriod'
from work_item__c wi 
where 
wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget')
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
order by wi.id, `ModifiedDate`)) t
inner join work_item__c wi on t.Id = wi.Id
order by t.id, t.`ModifiedDate`
limit 1000000;

select Field from work_item__history group by Field; 

#select sum(t.ReductionHrs)/8 from (
select wi.Id, wi.Name, u.Name as 'ChangedBy', date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', date_format(wi.CreatedDate, '%Y %m') as 'WI Created Period', date_format(wih.CreatedDate, '%Y %m') as 'Change Period', wih.OldValue, wih.NewValue, (wih.OldValue - wih.NewValue) as 'ReductionHrs', wip.EffectivePrice_day
from work_item__c wi 
inner join work_item__history wih on wih.ParentId = wi.Id
inner join User u on wih.CreatedById = u.Id
left join work_item_pricing wip on wip.WorkItemId = wi.Id
where wih.Field='Required_Duration__c'
#and wih.CreatedDate >= '2014-01-01' # Include only changes done in 1st half 2014
#and wih.CreatedDate <= '2014-06-30'
#and wi.Work_Item_Date__c >= '2014-01-01' # Include only wi currently scheduled in 1st half 2014
#and wi.Work_Item_Date__c <= '2014-06-30'
#and wi.CreatedDate < '2014-01-01' # Exclude new business during 1st half 2014
and wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget')
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.id;
#limit 1000000) t;

select t.NewValue, date_format(t.CreatedDate, '%Y %m') as 'Change Period', count(t.Id) from (
select wi.Id, wi.Name, u.Name as 'ChangedBy', wih.CreatedDate, wih.OldValue, wih.NewValue, (wih.OldValue - wih.NewValue) as 'ReductionHrs'
from work_item__c wi 
inner join work_item__history wih on wih.ParentId = wi.Id
inner join User u on wih.CreatedById = u.Id
where wih.Field='Service_Change_Reason__c'
and wih.CreatedDate >= '2014-01-01'
and wih.CreatedDate <= '2014-07-30'
and wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget')
and wih.NewValue is not null
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
limit 100000) t group by t.NewValue, `Change Period`;

SET @serial=0;
CREATE TEMPORARY TABLE IF NOT EXISTS work_item_schedule_changes_2 AS (
select @serial := @serial+1 AS `serial_number`, t.* from (
select 
wi.Id, wi.Required_Duration__c/8 as 'Days',wi.Service_target_date__c as 'Original Scheduled Date',date_format(wi.Service_target_date__c, '%Y %m') as 'Original Scheduled Period', wir.Start_Date__c as 'Scheduled Date', date_format(wir.Start_Date__c, '%Y %m') as 'Scheduled Period', min(wir.CreatedDate) as 'ModifiedDate', date_format(min(wir.CreatedDate), '%Y %m') as 'ModifiedPeriod', wi.CreatedDate as 'WorkItemCreateDate', date_format(wi.CreatedDate,'%Y %m') as 'WorkItemCreatePeriod' 
from work_item__c wi
inner join work_item_resource__c wir on wir.Work_Item__c = wi.Id
where 
#wi.Id='a3Id00000000acEEAQ'
wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Budget')
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
group by wi.id, wir.Start_Date__c
order by wi.id, `ModifiedDate`) t );
drop table work_item_schedule_changes ;
select t.`From Period`, sum(t.Days) from (
select wic.*, if (wicp.Id=wic.Id, wicp.`Scheduled Period` , wic.`Original Scheduled Period`) as 'From Period'
from work_item_schedule_changes wic
left join work_item_schedule_changes_2 wicp on wic.serial_number = (wicp.serial_number +1) ) t
group by t.`ModifiedPeriod`,t.`From Period`, t.`Scheduled Period`;