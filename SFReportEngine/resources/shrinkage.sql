#Shrinkage from audit cancelled (for example reduced frequency)

create or replace view shrinkage_cancelled_audits as
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		wi.Client_Id__c, 
		if (wi.Revenue_Ownership__c like '%Food%', 'Food','MS') as 'Stream',
		scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wih.Field, 
		date_format(max(wih.CreatedDate), '%Y %m') as 'Cancelled Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		wp.Site_Certification__c,
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') >= '2013 07'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		and if(date_format(date_add(wih.CreatedDate, interval 11 hour),'%Y %m') <= '2013 01',
				false,
				Cancellation_Reason__c in ('Lifecycle Frequency Decrease')#, 'Lifecycle Line Deleted')
			)
	group by wi.Id;

select Stream, `Cancelled Period`, sum(RequiredDuration/8) as 'Days' from shrinkage_cancelled_audits group by Stream, `Cancelled Period`;

create or replace view shrinkage_cancelled_audits_revenue_sub as 
select t.*, 	
	p.Id as 'ProductId',	
	p.Name as 'ProductName',	
	p.UOM__c as 'Unit',
	if(p.UOM__c = 'DAY', t.Days, if(p.UOM__c = 'HFD', t.HalfDays, t.Hours)) as 'Quantity',	
	cep.New_End_Date__c,
	cep.New_Start_Date__c,
	pbe.UnitPrice as 'ListPrice',	
	if(cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
	if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'	
	from shrinkage_cancelled_audits t 
	inner join product2 p ON t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
	inner join pricebookentry pbe ON pbe.Product2Id = p.Id	
	left join certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = t.Site_Certification__c	
	left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
	Where	
	p.Category__c = 'Audit'
	and p.IsDeleted=0
	and pbe.IsDeleted=0
	and (cep.IsDeleted=0 or cep.IsDeleted is null)
	and (cp.IsDeleted=0 or cp.IsDeleted is null)
	and pbe.Pricebook2Id = '01s90000000568BAAQ'	
	and pbe.CurrencyIsoCode = 'AUD'
	and (cp.Status__c = 'Active' or cp.Status__c is null)
	and if(p.UOM__c = 'DAY', t.Days, if(p.UOM__c = 'HFD', t.HalfDays, t.Hours)) > 0	
	order by `WorkItemId` , `ProductId`, cep.New_Start_Date__c desc, cep.CreatedDate desc;

create or replace view shrinkage_cancelled_audits_revenue as 
select t3.*, if(t3.`Site Cert Effective Pricing` is not null, t3.`Site Cert Effective Pricing`, if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing`, t3.`ListPrice`)) as 'EffectivePrice' 
from shrinkage_cancelled_audits_revenue_sub t3
group by t3.`WorkItemId`, t3.`ProductId`;


select scar.`Stream` as 'Stream',
'Revenue Lost (Shrinkage Cancelled Audit)' as 'Type', 
scar.`Cancelled Period` as `Period`, 
sum(scar.`Quantity`*scar.`EffectivePrice`) as 'Amount' 
from shrinkage_cancelled_audits_revenue scar 
where scar.`Cancelled Period`>='2014 07'	
and scar.`Cancelled Period`<='2015 06'	
group by `Stream`, `Type`, `Period`;


# Shrinkage from audit duration reduced
create or replace view shrinkage_reduced_audits as
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		wi.Client_Id__c, 
		if (wi.Revenue_Ownership__c like '%Food%', 'Food','MS') as 'Stream',
		scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wih.Field, 
		date_format(max(wih.CreatedDate), '%Y %m') as 'Shrinkage Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		wp.Site_Certification__c,
		sum(wih.OldValue - wih.NewValue) as 'RequiredDuration',
		sum(floor((wih.OldValue - wih.NewValue) / 8)) as 'Days',
		floor(((wih.OldValue - wih.NewValue) - 8 * floor((wih.OldValue - wih.NewValue)/ 8)) / 4) as 'HalfDays',
		((wih.OldValue - wih.NewValue)- 8 * floor((wih.OldValue - wih.NewValue)/ 8) - 4 * floor(((wih.OldValue - wih.NewValue)- 8 * floor((wih.OldValue - wih.NewValue)/ 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
        and scsp.IsDeleted=0
		and wi.Status__c not in ('Cancelled')
		and wih.Field = 'Required_Duration__c'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') >= '2013 07'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		and if(date_format(date_add(wih.CreatedDate, interval 11 hour),'%Y %m') <= '2013 01',
				false,
				true
			)
	group by wi.Id;

select * from shrinkage_reduced_audits_revenue t limit 10000000;
select Stream, `Shrinkage Period`, sum(RequiredDuration/8) as 'Days' from shrinkage_reduced_audits_revenue group by Stream, `Shrinkage Period`;

create or replace view shrinkage_reduced_audits_revenue_sub as 
select t.*, 	
	p.Id as 'ProductId',	
	p.Name as 'ProductName',	
	p.UOM__c as 'Unit',
	t.RequiredDuration/8 as 'Quantity',	
	cep.New_End_Date__c,
	cep.New_Start_Date__c,
	pbe.UnitPrice as 'ListPrice',	
	if(cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
	if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'	
	from shrinkage_reduced_audits t 
	inner join product2 p ON t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
	inner join pricebookentry pbe ON pbe.Product2Id = p.Id	
	left join certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = t.Site_Certification__c	
	left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
	Where	
	p.Category__c = 'Audit'
	and p.IsDeleted=0
	and pbe.IsDeleted=0
	and (cep.IsDeleted=0 or cep.IsDeleted is null)
	and (cp.IsDeleted=0 or cp.IsDeleted is null)
	and pbe.Pricebook2Id = '01s90000000568BAAQ'	
	and pbe.CurrencyIsoCode = 'AUD'
	and (cp.Status__c = 'Active' or cp.Status__c is null)
	and p.UOM__c = 'DAY'
	and t.RequiredDuration >= -40 and t.RequiredDuration <= 80
	order by `WorkItemId` , `ProductId`, cep.New_Start_Date__c desc, cep.CreatedDate desc;


create or replace view shrinkage_reduced_audits_revenue as 
select t3.*, if(t3.`Site Cert Effective Pricing` is not null, t3.`Site Cert Effective Pricing`, if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing`, t3.`ListPrice`)) as 'EffectivePrice' 
from shrinkage_reduced_audits_revenue_sub t3
group by t3.`WorkItemId`, t3.`ProductId`;


select srar.`Stream` as 'Stream',
'Revenue Lost (Shrinkage Reduced Audit)' as 'Type', 
srar.`Shrinkage Period` as `Period`, 
sum(srar.`Quantity`*srar.`EffectivePrice`) as 'Amount' 
from shrinkage_reduced_audits_revenue srar 
where srar.`Shrinkage Period`>='2014 01'	
and srar.`Shrinkage Period`<='2015 06'	
group by `Stream`, `Type`, `Period`;


select date_format(wih.CreatedDate, '%Y %m %d'), u.Name, wih.OldValue, wih.NewValue 
from work_item__history wih 
inner join User u on wih.CreatedById = u.Id
where wih.Field='Cancellation_Reason__c' and wih.OldValue is not null;