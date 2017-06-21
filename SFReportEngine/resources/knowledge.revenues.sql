select * from training.sf_tables where ToSync=1 order by TableNAme;

select 'Invc_Header__c', count(Id) from training.Invc_Header__c # 1057481
union
select 'Invoice_History__c', count(Id) from training.Invoice_History__c # 1937572 
union
select 'Invoice_Line__c', count(Id) from training.Invoice_Line__c; # 1705265 

set @today = (select date_format(now(), '%Y-%m-%d'));
set @yesterday = (select date_format(date_add(@today, interval -1 day), '%Y-%m-%d'));
set @week_start = (select date_format(date_add(@today, interval -WEEKDAY(@today) day), '%Y-%m-%d')) ;
set @month_start = (select date_format(@today, '%Y-%m-01'));
set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @fy_start = concat(@fy-1,'-07-01');
set @fy_end = concat(@fy,'-12-31');

#details
(select 
	irt.Name as 'Invoice Record Type',
	rt.Name as 'Record Type', 
    date_format(i.Invoice_Date__c, '%Y-%m-%d') as 'Period', 
    i.Payment_Type__c as 'Payment Type', 
    Product_Description__c as 'Product Description', 
    count(distinct i.Id) as '# invoices', 
    count(distinct ili.Id) as '# invoice lines', 
    sum(ili.Line_Total_Amount__c/ct.ConversionRate) as 'Amount (AUD)',
    ili.Product_Description__c,
    i.Name,
    if(Product_Description__c like '%Ren%', true, false) as 'Ren',
    if(Product_Description__c like '%New%', true, false) as 'New',
    if(Product_Description__c like '%BAP%', true, false) as 'BAP',
    if(Product_Description__c like '%Copyright%', true, false) as 'Copyright',
    if(Product_Description__c like '%Add%', true, false) as 'Add',
    if(Product_Description__c like '%Royalties%', true, false) as 'Royalties',
    if(Product_Description__c like '%CLS%', true, false) as 'CLS',
    if(Product_Description__c like '%IA%', true, false) as 'IA',
    if(Product_Description__c like '%Online%', true, false) as 'Online',
    if(Product_Description__c like '%Buyer%', true, false) as 'Buyer',
    if(Product_Description__c not like '%Online%' and
		Product_Description__c not like '%IA%' and
		Product_Description__c not like '%CLS%' and
		Product_Description__c not like '%Royalties%' and
		Product_Description__c not like '%Add%' and
		Product_Description__c not like '%Copyright%' and
		Product_Description__c not like '%BAP%' and
		Product_Description__c not like '%New%' and
        Product_Description__c not like '%Buyer%' and
		Product_Description__c not like '%Ren%', true, false) as 'Others',
	if(Product_Description__c like '%Online%','Online',
		if(Product_Description__c like '%IA%', 'IA',
			if(Product_Description__c like '%CLS%', 'CLS',
				if(Product_Description__c like '%Royalties%', 'Royalties',
					if(Product_Description__c like '%Add%', 'Add',
						if(Product_Description__c like '%Copyright%', 'Copyright',
							if(Product_Description__c like '%BAP%', 'BAP',
								if(Product_Description__c like '%New%', 'New',
									if(Product_Description__c like '%Ren%', 'Ren', 
										if(Product_Description__c like '%Buyer%', 'Buyer', '"Others"')))))))))) as 'Product Desc Contains',
	if(i.Transaction_ID__c is null, 'null',
		if(i.Transaction_ID__c like ('1_______%') and i.Transaction_ID__c not like ('1_______-4_________'), 'Infostore',
			if(i.Transaction_ID__c like ('1_______-4_________'), 'Infostore - WorldPay',
				if(i.Transaction_ID__c like ('9_____%'), 'Subman',
					if(i.Transaction_ID__c like ('18___'), 'SOL',
						if(i.Transaction_ID__c like ('800_____%'), 'New eCommerce',
							'Unknown'
						)
					)
				)
			)
		)
	) as 'Transaction Id Source',
    i.Transaction_ID__c,
    i.Order_Number__c,
    i.Customer_PO__c
from training.Invc_Header__c i
inner join training.recordtype irt on i.RecordTypeId = irt.Id
inner join training.Invoice_Line__c ili on ili.Invc_Header__c = i.Id
left join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
inner join training.recordtype rt on ili.RecordTypeId = rt.Id
where ili.CreatedDate between concat(year(now()) + if(month(now())<7,-1,0),'-07-01') and concat(year(now()) + if(month(now())<7,0,1),'-06-30')
and i.IsDeleted = 0
and ili.IsDeleted = 0
and ili.Line_Total_Amount__c >=0.1
group by ili.Id, `Record Type`, `Period`, `Payment Type`, `Product Description`, `Transaction Id Source`);



(select
	date_format(i.Invoice_Date__c, '%Y-%m-%d') as 'Date',
	c2.`sai_region` as 'SAI Region',
    con.name as 'Continent',
	c2.Name as 'Country',
    'Knowledge' as 'Portfolio',
    'Publishing' as 'Business Line',
    'Actual' as 'Type', # Actual, PFY Actual, Budget
	date_format(i.Invoice_Date__c, '%Y-%m') as 'Period', 
    sum(ili.Line_Total_Amount__c/ct.ConversionRate) as 'Amount (AUD)',
    sum(if(date_format(i.Invoice_Date__c, '%Y-%m-%d')=@yesterday,ili.Line_Total_Amount__c/ct.ConversionRate,0)) as 'yesterday',
    sum(if(date_format(i.Invoice_Date__c, '%Y-%m-%d')>=@week_start,ili.Line_Total_Amount__c/ct.ConversionRate,0)) as 'this week',
    sum(if(date_format(i.Invoice_Date__c, '%Y-%m-%d')>=@month_start,ili.Line_Total_Amount__c/ct.ConversionRate,0)) as 'this month',
    i.Payment_Type__c as 'Payment Type', 
    if(Product_Description__c like '%Online%','Online',
		if(Product_Description__c like '%IA%', 'IA',
			if(Product_Description__c like '%CLS%', 'CLS',
				if(Product_Description__c like '%Royalties%', 'Royalties',
					if(Product_Description__c like '%Add%', 'Add',
						if(Product_Description__c like '%Copyright%', 'Copyright',
							if(Product_Description__c like '%BAP%', 'BAP',
								if(Product_Description__c like '%New%', 'New',
									if(Product_Description__c like '%Ren%', 'Ren', 
										if(Product_Description__c like '%Buyer%', 'Buyer', '"Others"')))))))))) as 'Product Desc Contains',
	if(i.Transaction_ID__c is null, 'null',
		if(i.Transaction_ID__c like ('1_______%') and i.Transaction_ID__c not like ('1_______-4_________'), 'Infostore',
			if(i.Transaction_ID__c like ('1_______-4_________'), 'Infostore - WorldPay',
				if(i.Transaction_ID__c like ('9_____%'), 'Subman',
					if(i.Transaction_ID__c like ('18___'), 'SOL',
						if(i.Transaction_ID__c like ('800_____%'), 'New eCommerce',
							'Unknown'
						)
					)
				)
			)
		)
	) as 'Transaction Id Source'
from training.Invc_Header__c i
	left join training.account a on i.Account__c = a.Id
    left join analytics.countries_names cn on a.BillingCountry = cn.name
    left join analytics.countries c2 on cn.code = c2.code
    left join analytics.continents con on c2.continent_code = con.code
	inner join training.recordtype irt on i.RecordTypeId = irt.Id
	inner join training.Invoice_Line__c ili on ili.Invc_Header__c = i.Id
	left join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
	inner join training.recordtype rt on ili.RecordTypeId = rt.Id
where 
	ili.CreatedDate 
		between @fy_start
        and @fy_end
	and i.IsDeleted = 0
	and ili.IsDeleted = 0
    and ili.Product_Description__c not like '%BAP%'
    and ili.Product_Description__c not like '%Buyer%'
    and ili.Product_Description__c not like '%New%'
    and ili.Product_Description__c not like '%Ren%'
    and ili.Product_Description__c not like '%Copyright%'
    and ili.Product_Description__c not like '%Add%'
    and ili.Product_Description__c not like '%Royalties%'
    and ili.Product_Description__c not like '%CLS%'
    #and ili.Product_Description__c not like '%IA%'
    #and ili.Product_Description__c not like '%Online%'
	and ili.Line_Total_Amount__c >=0.1
group by `SAI Region`, `Continent`, `Country`, `Date`, `Portfolio`, `Business Line`, `Type`, `Payment Type`, `Product Desc Contains`, `Transaction Id Source`)
union all
(select 
 t.Date as 'Date', t.`sai_region` as 'Region', t.`continent`, t.BillingCountry as 'Country', 'TIS' as 'Portfolio', 'TIS-eLearning' as 'Business Line', 'Actual' as 'Type', date_format(t.Date, '%Y-%m') as 'Period', sum(t.Amount) as 'today', sum(if(t.`Date`=@yesterday, t.Amount,0)) as 'yesterday', sum(if(t.`Date`>=@week_start, t.Amount,0)) as 'week start', sum(if(t.`Date`>=@month_start, t.Amount,0)) as 'month start', '','',''
from (
(select 
c2.`sai_region`,
con.name as 'continent',
c2.Name as 'BillingCountry', 
i.Id,
date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(rt.Name like '%AMER%', i.Total_Amount_Excl_Taxes__c/ct.ConversionRate , if(i.GST_Exempt__c, i.Total_Amount__c/ct.ConversionRate , i.Total_Amount__c/ct.ConversionRate/ 1.1)) as 'Amount' , rt.Name
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
left join training.account a on r.Billing_Account__c = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.currencytype ct on i.CurrencyIsoCode = ct.IsoCode
inner join training.invoice_ent__history ih on ih.ParentId = i.id 
where r.Course_Type__c = 'eLearning' and ih.Field='Processed__c' and ih.NewValue='true'  and  ih.CreatedDate  >= @fy_start  and  ih.CreatedDate <= @fy_end 
group by i.Id) 
union all
(select 
c2.`sai_region`,
con.name as 'continent',
c2.Name as 'BillingCountry',
pa.id,
date_format(date_add(max(ih.CreatedDate), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(rt.Name like '%AMER%', pa.Total_Amount_Excl_Taxes__c/ct.ConversionRate , if(pa.GST_Exempt__c, pa.Total_Amount__c/ct.ConversionRate , pa.Total_Amount__c/ct.ConversionRate/ 1.1)) as 'Amount' , rt.Name
from training.registration__c r 
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
left join training.account a on r.Billing_Account__c = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.invoice_ent__c pa ON pa.Registration__c = r.Id 
inner join training.currencytype ct on pa.CurrencyIsoCode = ct.IsoCode
inner join training.invoice_ent__c i ON i.Prior_Adjustment__c = pa.Name 
inner join training.invoice_ent__history ih on ih.ParentId = i.id 
where r.Course_Type__c = 'eLearning'  and ih.Field='Processed__c' and ih.NewValue='true'  and  i.Invoice_Type__c = 'ARB' and  ih.CreatedDate  >= @fy_start  and  ih.CreatedDate <= @fy_end
group by i.Id)) t 
where t.Date >= @fy_start and  t.Date <= @fy_end
group by t.`Date` order by t.`Date`)
union all
(select t2.`Class_Begin_Date__c` as 'Date', t2.`sai_region` as 'Region', t2.`continent`, t2.BillingCountry as 'Country', 'TIS' as 'Portfolio', 'TIS-public' as 'Business Line', 'Actual' as 'Type', date_format(t2.`Class_Begin_Date__c`, '%Y-%m') as 'Period', t2.`Amount` as 'today', if(t2.`Date`=@yesterday, t2.`Amount`,0) as 'yesterday', if(t2.`Date`>=@week_start, t2.`Amount`,0) as 'week start', if(t2.`Date`>=@month_start, t2.`Amount`,0) as 'month start', '','',''
from (
(select t.`sai_region`, t.`continent`,t.BillingCountry, t.Name, t.`Date`, t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from (
select 
c2.`sai_region`,
con.name as 'continent',
c2.Name as 'BillingCountry',
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(rt.Name like '%AMER%', i.Total_Amount_Excl_Taxes__c/ct.ConversionRate , i.Total_Amount__c/ct.ConversionRate /1.1)as 'Amount', rt.Name
from training.registration__c r 
left join training.account a on r.Billing_Account__c = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
inner join training.currencytype ct on i.CurrencyIsoCode = ct.IsoCode
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null)  and  i.Bill_Type__c = 'ADF'  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date`>= @fy_start  and  t.`Date`<= @fy_end  and  t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`) 
union (select t.`sai_region`,t.`continent`,t.BillingCountry, t.Name, t.`Date`, t.`Date` as 'Class_Begin_Date__c', t.`Date` as 'Class_End_Date__c', sum(t.Amount) as 'Amount' from ( 
select 
c2.`sai_region`,
con.name as 'continent',
c2.Name as 'BillingCountry',
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(rt.Name like '%AMER%', i.Total_Amount_Excl_Taxes__c/ct.ConversionRate , if(i.GST_Exempt__c, i.Total_Amount__c/ct.ConversionRate , i.Total_Amount__c/ct.ConversionRate /1.1)) as 'Amount', rt.Name
from training.registration__c r 
left join training.account a on r.Billing_Account__c = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
inner join training.currencytype ct on i.CurrencyIsoCode = ct.IsoCode
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) and i.Bill_Type__c not in ('ADF')  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date`>= @fy_start  and  t.`Date`<= @fy_end  and  (t.`Date` >= t.Class_Begin_Date__c or t.Class_Begin_Date__c is null)  and  t.`Amount` is not null 
group by t.`Date` 
order by t.`Date`
) union 
(select t.`sai_region`,t.`continent`, t.BillingCountry, t.NAme, t.`Date`, t.Class_Begin_Date__c, t.Class_End_Date__c, sum(t.Amount) as 'Amount' from ( 
select 
c2.`sai_region`,
con.name as 'continent',
c2.Name as 'BillingCountry',
date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
if(rt.Name like '%AMER%', i.Total_Amount_Excl_Taxes__c/ct.ConversionRate , if(i.GST_Exempt__c, i.Total_Amount__c/ct.ConversionRate , i.Total_Amount__c/ct.ConversionRate/1.1)) as 'Amount' , rt.Name
from training.registration__c r 
left join training.account a on r.Billing_Account__c = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.recordtype rt on r.RecordTypeId = rt.Id 
inner join training.invoice_ent__c i ON i.Registration__c = r.Id 
inner join training.currencytype ct on i.CurrencyIsoCode = ct.IsoCode
left join training.invoice_ent__history ih on ih.ParentId = i.id 
where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) and i.Bill_Type__c not in ('ADF')  and  r.NZ_AFS__c = 0  and  r.Coles_Brand_Employee__c = 0  and  r.Error__c = 0  and  r.Status__c not in ('Pending')  and  i.Processed__c = 1  and  (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
group by i.Id) t 
where t.`Date` < t.Class_Begin_Date__c  and  t.Class_Begin_Date__c <= @fy_end  and  t.Class_Begin_Date__c >= @fy_start  and  t.`Amount` is not null 
group by t.`Date`, t.Class_Begin_Date__c, t.Class_End_Date__c 
order by t.Class_Begin_Date__c)) t2 order by t2.Class_Begin_Date__c)
union all
(select c.Class_End_Date__c as 'Date', c2.`sai_region` as 'Region', con.name as 'continent', c2.NAme as 'Country', 'TIS' as 'Portfolio', 'TIS-In-House' as 'Business Line', 'Actual' as 'Type', date_format(c.Class_End_Date__c, '%Y-%m') as 'Period', sum(ihe.Total_Course_Base_Price__c/ct.ConversionRate) as 'today', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@yesterday, ihe.Total_Course_Base_Price__c/ct.ConversionRate, 0)) as 'yesterday', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@week_start, ihe.Total_Course_Base_Price__c/ct.ConversionRate , 0)) as 'week start', sum(if(date_format(ihe.CreatedDate,'%-%m-%d')=@month_start, ihe.Total_Course_Base_Price__c/ct.ConversionRate , 0)) as 'month start', '','',''
from training.In_House_Event__c ihe 
left join training.opportunity o on ihe.Opportunity__c = o.Id
left join training.account a on o.AccountId = a.Id
left join analytics.countries_names cn on a.BillingCountry = cn.name
left join analytics.countries c2 on cn.code = c2.code
left join analytics.continents con on c2.continent_code = con.code
inner join training.currencytype ct on ihe.CurrencyIsoCode = ct.IsoCode
inner join training.class__c c on ihe.Class__c = c.Id 
inner join training.RecordType rt on c.RecordTypeId = rt.Id 
where ihe.Status__c not in ('Cancelled','Postponed') and c.Class_Status__c not in ('Cancelled','Postponed')  and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') >= @fy_start  and date_format(date_add(c.Class_End_Date__c, interval 11 hour),'%Y-%m-%d') <= @fy_end  and (c.Name not like '%Actual%' and c.Name not like '%Budget%')  and rt.NAme in ('TIS - AMER - In House Class', 'In House Class', 'TIS - INDONESIA - In House Class', 'TIS - INDIA - In House Class') 
group by ihe.id order by c.Class_End_Date__c);
