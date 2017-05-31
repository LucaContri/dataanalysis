drop table if exists tmp_pricing;
create table tmp_pricing as (
select t.*, 	
	p.Id as 'ProductId',	
	p.Name as 'ProductName',	
	p.UOM__c as 'Unit',
	if(p.UOM__c = 'DAY', t.Days, if(p.UOM__c = 'HFD', t.HalfDays, t.Hours)) as 'Quantity',	
    cep.CreatedDate,
	cep.IsDeleted,
    cep.New_End_Date__c,
    cep.New_Start_Date__c,
	pbe.UnitPrice as 'ListPrice',
    if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, cep.New_Start_Date__c, '9999-12-31') as 'CEP Order',
	if(cp.IsDeleted=0 and cp.Sales_Price_Start_Date__c is not null and cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
	if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'
	
    ,if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=date_add(t.Work_Item_Date__c, interval -12 month) and cep.New_End_Date__c>=date_add(Work_Item_Date__c, interval -12 month), cep.New_Start_Date__c, '9999-12-31') as 'PY CEP Order'
	,if(cp.IsDeleted=0 and cp.Sales_Price_Start_Date__c is not null and cp.Sales_Price_Start_Date__c<= date_add(t.Work_Item_Date__c,interval -12 month) and cp.Sales_Price_End_Date__c>= date_add(t.Work_Item_Date__c, interval -12 month), cp.FSales_Price__c, null) as 'PY Site Cert Pricing'
	,if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=date_add(t.Work_Item_Date__c,interval -12 month) and cep.New_End_Date__c>=date_add(t.Work_Item_Date__c,interval -12 month), 
		if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), 
        null) as 'PY Site Cert Effective Pricing'
	,if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, 
		cep.Adjustment_Type__c, 
        null) as 'Effective Pricing Adjustment Type'	
	,if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=date_add(t.Work_Item_Date__c,interval -12 month) and cep.New_End_Date__c>=date_add(t.Work_Item_Date__c,interval -12 month), 	
		cep.Adjustment_Type__c,
        null) as 'PY Effective Pricing Adjustment Type'
    ,if(cp.IsDeleted=0 and cp.Sales_Price_Start_Date__c is not null and cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.Adjustment_Type__c, null) as 'Site Cert Pricing Adjustment Type'
	,if(cp.IsDeleted=0 and cp.Sales_Price_Start_Date__c is not null and cp.Sales_Price_Start_Date__c<= date_add(t.Work_Item_Date__c,interval -12 month) and cp.Sales_Price_End_Date__c>= date_add(t.Work_Item_Date__c, interval -12 month), cp.Adjustment_Type__c, null) as 'PY Site Cert Pricing Adjustment Type'
	
    from 
    (select 
		wi.Id as 'WorkItemId',
        wi.Name as 'WorkItemName',
        wi.Status__c,
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		wi.Client_Id__c, 
        client.Name as 'Client Name',
        clientSite.Name as 'Client Site',
		if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		wi.Revenue_Ownership__c,
        wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		scsp.Site_Certification__c,
        sc.Pricebook2Id__c,
        if(ig.CurrencyIsoCode is null, sc.CurrencyIsoCode, ig.CurrencyIsoCode ) as 'CurrencyIsoCode',
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
        inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join certification__c sc on scsp.Site_Certification__c = sc.Id
        inner join account clientSite on sc.Primary_client__c = clientSite.Id
        inner join account client on clientSite.ParentId = client.Id
        left join invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c not in ('Cancelled', 'Budget')
        and scsp.De_registered_Type__c is null
        and date_format(wi.Work_Item_Date__c, '%Y %m') >= '2015 07'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= '2016 06'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
	group by wi.Id) t 
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
	);
    
# lost_business_revenue_sub as 
(select 
t3.`Client Name`,
t3.`Client Site`,
t3.`Stream`,
t3.`Revenue_Ownership__c`,
t3.`WorkItemId`,
t3.`WorkItemName`,
t3.`Work_Item_Date__c`,
t3.`RequiredDuration`,
t3.`ProductName`,
t3.`Quantity`,
if(t3.`Site Cert Effective Pricing` is not null, 'Effective Price', if(t3.`Site Cert Pricing` is not null, 'Custom Price', 'List Price')) as 'Price Type' ,
if(t3.`Site Cert Effective Pricing` is not null, t3.`Site Cert Effective Pricing`, if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing`, t3.`ListPrice`)) as 'Price',
if(t3.`PY Site Cert Effective Pricing` is not null, 'Effective Price', if(t3.`PY Site Cert Pricing` is not null, 'Custom Price', 'List Price')) as 'PY Price Type' ,
if(t3.`PY Site Cert Effective Pricing` is not null, t3.`PY Site Cert Effective Pricing`, if(t3.`PY Site Cert Pricing` is not null, t3.`PY Site Cert Pricing`, t3.`ListPrice`)) as 'PY Price', 

if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing Adjustment Type`, null) as 'Site Cert Pricing Adjustment Type',
if(t3.`PY Site Cert Pricing` is not null, t3.`PY Site Cert Pricing Adjustment Type`, null) as 'PY Site Cert Pricing Adjustment Type',

if(t3.`Site Cert Effective Pricing` is not null, t3.`Effective Pricing Adjustment Type`, null) as 'Effective Pricing Adjustment Type',
if(t3.`PY Site Cert Effective Pricing` is not null, t3.`PY Effective Pricing Adjustment Type`, null) as 'PY Effective Pricing Adjustment Type'
from
	(select * from tmp_pricing order by `WorkItemId` , `ProductId`, `CEP Order`, `CreatedDate` desc) t3
 inner join 
	(select * from tmp_pricing order by `WorkItemId` , `ProductId`, `PY CEP Order`, `CreatedDate` desc) pyt3 on t3.WorkItemId = pyt3.WorkItemId and t3.ProductId = pyt3.ProductId
group by t3.`WorkItemId`, t3.`ProductId`);

drop table if exists tmp_pricing;


#----------------------------------------------------------------------------------------------------------

(select 	
t.`Client Ownership`,	
t.`Client`,	
t.`Site`,	
t.`Site Cert`,	
t.`Site Cert Currency`,	
t.`Product`,	
t.Business_Line__c,
if(t.`CEP Price` is null, 'Custom Pricing', 'Cert Effective Pricing') as 'Current Price Type',	
if(t.`CEP Price` is null, t.`Custom Pricing`, t.`Cert Effective Pricing`) as 'Id',	
if(t.`CEP Price` is null, t.`CP Price`, t.`CEP Price`) as 'Price',	
if(t.`CEP Price` is null, t.`CP End Date`, t.`CEP End Date`) as 'End Date',	
if(t.`CEP Price` is null, 'List Price', if (t.`CP Price` is null, 'List Price', 'Custom Price')) as 'New Price Type',	
if(t.`CEP Price` is null, t.`List Price`, if (t.`CP Price` is null, t.`List Price`, t.`CP Price`)) as 'New Price'	
from (	
select 	
	client.Client_Ownership__c as 'Client Ownership',
    client.Name as 'Client',	
    site.Name as 'Site',	
    if(p.Business_Line__c like '%Food%', 'Food', 'MS'),
    p.Business_Line__c,
	sc.Id, 
    sc.Name as 'Site Cert', 	
    sc.CurrencyIsoCode as 'Site Cert Currency',	
    p.Name as 'Product', 	
	pbe.UnitPrice as 'List Price',
    cp.Name as 'Custom Pricing', 	
    cp.Sales_Price_Start_Date__c as 'CP Start Date',	
    cp.Sales_Price_End_Date__c as 'CP End Date',	
    cp.FSales_Price__c as 'CP Price',	
    cep.Name as 'Cert Effective Pricing', 	
	cep.New_Start_Date__c as 'CEP Start Date', 
    cep.New_End_Date__c as 'CEP End Date',	
	if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)) as 'CEP Price'
    	
from certification_pricing__c cp	
inner join certification__c sc on cp.Certification__c = sc.Id	
inner join certification__c c on sc.Primary_Certification__c = c.Id	
inner join account client on c.Primary_client__c = client.Id	
inner join account site on sc.Primary_client__c = site.Id	
inner join product2 p on cp.Product__c = p.Id 	
inner join pricebookentry pbe ON pbe.Product2Id = p.Id and pbe.Pricebook2Id = sc.Pricebook2Id__c and pbe.CurrencyIsoCode = sc.CurrencyIsoCode	
left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
where 	
#(
#	(cp.Sales_Price_End_Date__c >= now() and cp.Sales_Price_End_Date__c <= '2016-06-30') or	
#	(cep.New_End_Date__c >= now() and cep.New_End_Date__c <= '2016-06-30') or
#    (cp.Sales_Price_Start_Date__c >= now() and cp.Sales_Price_Start_Date__c <= '2016-06-30') or	
#	(cep.New_Start_Date__c >= now() and cep.New_Start_Date__c <= '2016-06-30')	
#)	
cp.IsDeleted=0
and c.Status__c = 'Active'
and sc.Status__c = 'Active'
and p.Name like '%Annual Registration%') t);	
