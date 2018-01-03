set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @start_date = concat(@fy-3,'-07-01');
set @end_date = concat(@fy,'-06-30');
set @region = 'APAC';

# Revenues
(SELECT  
  'Confirmed Audit Days' as 'Metric',
  analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) as 'Region',
  analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country',
  sp.Program_Business_Line__c as 'Business Line',
  year(wird.FStartDate__c) + if(month(wird.FStartDate__c)<7, 0, 1) as 'FY',
  DATE_FORMAT(wird.FStartDate__c, '%Y %m') as 'Period',  
  sum(wird.Scheduled_Duration__c / 8) AS 'Value',
     'Days' as 'Unit',
     sum(wird.Scheduled_Duration__c / 8) as 'Original Value',
     'Days' as 'Original Unit',
     '' as 'Name',
  '' as 'Id',
  '' as 'Notes',
  '' as 'SCS Previous Status', 1 as 'Include'
 FROM  
 salesforce.`work_item__c` wi 
 INNER JOIN salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 INNER JOIN salesforce.`work_item_resource__c` wir ON wir.work_item__c = wi.Id  
 INNER JOIN salesforce.`work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id  
 INNER JOIN salesforce.`recordtype` rt ON wi.RecordTypeId = rt.Id  
 WHERE  
 rt.Name = 'Audit' 
 AND wi.Revenue_Ownership__c not like '%Product%'
 AND analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) = @region
 AND sp.Program_Business_Line__c not in ('Product Services', 'Retail')
 AND wir.IsDeleted = 0  
 AND wird.IsDeleted = 0  
 AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget')  
 AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier')  
 and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget', 'Scheduled', 'Scheduled - Offered', 'Draft', 'Initiate Service')  
 AND wird.FStartDate__c >= @start_date  
 AND wird.FStartDate__c <= @end_date  
 GROUP BY `Metric`, `Region`, `Country`, `Business Line`,`Period`)
union
(select 
'Revenue Lost (Audit)' as 'Metric',
analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) as 'Region',
analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) as 'Country',
dacv.`Business Line`,
year(dacv.`De-Registered Date`) + if(month(dacv.`De-Registered Date`)<7, 0, 1) as 'FY',
DATE_FORMAT(dacv.`De-Registered Date`, '%Y %m') as 'Period',  
ifnull(dacv.`ACV`/cur.ConversionRate,0) AS 'Value',
'AUD' as 'Unit',
dacv.`ACV` as 'Original Value',
dacv.`Currency` as 'Original Unit',
dacv.`Client`,
dacv.`Site Cert Std`,
dacv.`De-Registered Reason` as 'Reasons',
if(scsp.Status__c in ('De-Registered','Concluded'), analytics.getSiteCertificationStandardPreviousStatus(scsp.Id), scsp.Status__c ) as 'SCS Previous Status',
if(dacv.`De-Registered Reason` in ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account'), 1, 0) as 'Include'
from analytics.deregistration_acv dacv
inner join salesforce.site_certification_standard_program__c scsp on dacv.`Site Cert Std Id` = scsp.Id
left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
inner join salesforce.account client on dacv.`Client Id` = client.Id
where 
dacv.`De-Registered Date`>= @start_date  
and dacv.`De-Registered Date`<= @end_date
and dacv.`Revenue Ownership` not like '%Product%'
and dacv.`Business Line` not in ('Product Services','Retail')
and analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) = @region
group by dacv.`Site Cert Std Id`, `Period`)
union
(select 
concat('Business Won ', if(oli.Days__c>0, '(Audits)', '(Fees)')) as 'metric',
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(o.`CloseDate`) + if (month(o.`CloseDate`)<7,0,1) as 'FY',
date_format(o.`CloseDate`,'%Y %m') as 'Period',
sum(oli.TotalPrice/cur.ConversionRate) as 'Value',
'AUD' as 'Unit',
sum(oli.TotalPrice) as 'Original Value',
oli.CurrencyIsoCode as 'Original Unit',
o.`Name` as 'Name',
o.`Quote_Ref__c` as 'Id',
o.`Type` as 'Note','' as 'SCS Previous Status', 1 as 'Include'
from salesforce.opportunity o 
inner join salesforce.account a on o.AccountId = a.Id
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.`Id` and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail')
left join salesforce.currencytype cur on oli.CurrencyIsoCode = cur.IsoCode
where
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c ,' - ',-1)) = @region
and o.closeDate between @start_Date and @end_Date
and o.IsDeleted = 0 
and o.StageName='Closed Won' 
and o.Status__c = 'Active'
and a.Client_Ownership__c not in ('Product Services')
group by `Metric`, o.Id, `Business Line`)
union
(select 
'PFY Business Won Audit Initial Package' as 'metric',
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(date_add(o.`CloseDate`, interval 1 year)) + if (month(date_add(o.`CloseDate`, interval 1 year))<7,0,1) as 'FY',
date_format(date_add(o.`CloseDate`, interval 1 year),'%Y %m') as 'Period',
sum(oli.TotalPrice/cur.ConversionRate) as 'Value',
'AUD' as 'Unit',
sum(oli.TotalPrice) as 'Original Value',
oli.CurrencyIsoCode as 'Original Unit',
'' as  'Name',
'' as 'Id',
'' as 'Note','' as 'SCS Previous Status', 1 as 'Include'
from salesforce.opportunity o 
inner join salesforce.account a on o.AccountId = a.Id
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.`Id` and oli.IsDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c > 0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail') and (p.Name like '%Gap%' or p.Name like '%Stage%') 
left join salesforce.currencytype cur on oli.CurrencyIsoCode = cur.IsoCode
where
o.IsDeleted = 0 
and o.StageName='Closed Won' 
and o.Status__c = 'Active'
and a.Client_Ownership__c not in ('Product Services')
and o.CloseDate between date_add(@start_Date, interval -1 year) and date_add(@end_Date, interval -1 year)
and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = @region
group by `Metric`, `Region`,`Country`,`Business Line`,`Period`)
union
#Avg Audit Day Price Quoted
(select 
concat('Avg Audit Day Quoted ', if(o.Type like 'New%' or o.Type = 'Non-Certification', 'New ', 'Retention ' )) as 'Metric',
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(o.`CloseDate`) + if (month(o.`CloseDate`)<7,0,1) as 'FY',
date_format(o.`CloseDate`,'%Y %m') as 'Period',
sum(oli.TotalPrice/cur.ConversionRate)/sum(oli.Days__c) as 'Value',
'AUD' as 'Unit',
sum(oli.TotalPrice)/sum(oli.Days__c) as 'Original Value',
oli.CurrencyIsoCode as 'Original Unit',
'','','','' as 'SCS Previous Status', 1 as 'Include'
from salesforce.opportunity o 
inner join salesforce.account a on o.AccountId = a.Id
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.`Id` and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c>0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail')
left join salesforce.currencytype cur on oli.CurrencyIsoCode = cur.IsoCode
where
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c ,' - ',-1)) = @region
and o.closeDate between @start_Date and @end_Date
and o.IsDeleted = 0 
and o.StageName='Closed Won' 
and o.Status__c = 'Active'
and a.Client_Ownership__c not in ('Product Services')
group by `Metric`, `Region`, `Country`, `Business Line`, `Period`)
union
# % Converted opportunities won 1 year ago
(select t2.`Metric`, t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`FY`, t2.`Period`,sum(t2.`Opp Amount`) as 'Value','Opp $' as 'Unit',sum(t2.`Inv Amount`) as 'Original Value','Inv $' as 'Original Unit','%','','','' as 'SCS Previous Status', 1 as 'Include'
from
(select 
'% Opp Amount Converted (1 year MA)' as 'Metric', analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) as 'Region', substring_index(t.Business_1__c,' - ',-1) as 'Country', t.`Business Line`, t.closedate,
year(t.date) + if(month(t.date)<7,0,1) as 'FY', date_format(t.date, '%Y %m') as 'Period', sum(ifnull(ili.Total_Line_Amount__c,0)) as 'Inv Amount', ifnull(`Opp 1st year amount`,0) as 'Opp Amount',t.`Name`,t.`Id`,''
from
(select o.id,o.Name,o.Business_1__c,year(date_add(o.CloseDate, interval 1 year)) + if(month(o.CloseDate)<7,0,1) as 'FY',periods.date,p.Business_Line__c as 'Business Line',o.CloseDate,sum(oli.TotalPrice) as 'Opp 1st year amount',oli.CurrencyIsoCode
from salesforce.opportunity o
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c>0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail') 
inner join (select distinct date_format(wd.date, '%Y-%m-01') as 'date' from salesforce.sf_working_days wd where wd.date between @start_date and @end_date) periods
where 
o.CloseDate between date_add(periods.date, interval -2 year) and date_add(periods.date, interval -1 year)
and o.Business_1__c not in ('Product Services','Corporate')
and analytics.getRegionFromCountry(substring_index(o.Business_1__c,' - ',-1)) = @region
group by periods.date, o.Id, p.Business_Line__c) t
inner join salesforce.certification__c c on c.Opportunity_Created_From__c = t.Id
inner join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id and wp.IsDeleted = 0
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id and wi.IsDeleted = 0 and wi.Work_Item_Date__c between t.CloseDate and date_add(t.CloseDate, interval 1 year) and wi.Work_Item_Stage__c not in ('Follow Up')
left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted=0 and ili.Invoice_Status__c not in ('Cancelled') and (ili.Product_Category__c like 'Audit%' )#or ili.Product_Category__c like 'Travel%')
left join salesforce.product2 pr on ili.Product__c = pr.Id and pr.Business_Line__c = t.`Business Line`
group by t.date, t.Id, t.`Business Line` ) t2
group by 
t2.`Metric`, t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`Period`)
union
(select 'Actual Revenues',analytics.getRegionFromCountry(c.Name),c.Name,bl.Name,'PFY',date_format(date_add(concat(p.Name,'-01'), interval 1 year), '%Y %m'),analytics.getPeriodAuditRevenue(c.Name,bl.Name,p.Name),'AUD',analytics.getPeriodAuditRevenue(c.Name,bl.Name,p.Name),'AUD','','','','' as 'SCS Previous Status', 1 as 'Include'
from 
(select 'Management Systems' as 'Name' union select 'Agri-Food') bl,
(select date_format(wd.Date, '%Y-%m') as 'Name' from salesforce.sf_working_days wd where wd.date between date_add(@start_date, interval -1 year) and date_add(@end_date, interval -1 year) group by `Name`) p,
(SELECT distinct analytics.getCountryFromRevenueOwnership(Revenue_Ownership__c) as 'Name' from salesforce.work_item__c where Revenue_Ownership__c not like '%Product%') c
where analytics.getRegionFromCountry(c.Name) = @region)
union
(select 'Exchange Rates', '','','',year(ct.LastModifiedDate), date_format(ct.LastModifiedDate, '%Y %m'), ct.`ConversionRate`, '',ct.`ConversionRate`, '',ct.IsoCode,'','','' as 'SCS Previous Status', 1 as 'Include' from salesforce.currencytype ct where ct.IsActive=1);

# Days
(SELECT  
  'Confirmed Audit Days' as 'Metric',
  analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) as 'Region',
  analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country',
  sp.Program_Business_Line__c as 'Business Line',
  year(wird.FStartDate__c) + if(month(wird.FStartDate__c)<7, 0, 1) as 'FY',
  DATE_FORMAT(wird.FStartDate__c, '%Y %m') as 'Period',  
  sum(wird.Scheduled_Duration__c / 8) AS 'Value',
     'Days' as 'Unit',
     sum(wird.Scheduled_Duration__c / 8) as 'Original Value',
     'Days' as 'Original Unit',
     '' as 'Name',
  '' as 'Id',
  '' as 'Notes',
  '' as 'SCS Previous Status', 1 as 'Include'
 FROM  
 salesforce.`work_item__c` wi 
 INNER JOIN salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 INNER JOIN salesforce.`work_item_resource__c` wir ON wir.work_item__c = wi.Id  
 INNER JOIN salesforce.`work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id  
 INNER JOIN salesforce.`recordtype` rt ON wi.RecordTypeId = rt.Id  
 WHERE  
 rt.Name = 'Audit' 
 AND wi.Revenue_Ownership__c not like '%Product%'
 #AND analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) = @region
 AND sp.Program_Business_Line__c not in ('Product Services', 'Retail')
 AND wir.IsDeleted = 0  
 AND wird.IsDeleted = 0  
 AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget')  
 AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier')  
 and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget', 'Scheduled', 'Scheduled - Offered', 'Draft', 'Initiate Service')  
 AND wird.FStartDate__c >= @start_date  
 AND wird.FStartDate__c <= @end_date  
 GROUP BY `Metric`, `Region`, `Country`, `Business Line`,`Period`)
 union all
 (SELECT  
  'Confirmed Audit Days PFY' as 'Metric',
  analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) as 'Region',
  analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country',
  sp.Program_Business_Line__c as 'Business Line',
  year(date_add(wird.FStartDate__c, interval 1 year)) + if(month(date_add(wird.FStartDate__c, interval 1 year))<7, 0, 1) as 'FY',
  DATE_FORMAT(date_add(wird.FStartDate__c, interval 1 year), '%Y %m') as 'Period',  
  sum(wird.Scheduled_Duration__c / 8) AS 'Value',
     'Days' as 'Unit',
     sum(wird.Scheduled_Duration__c / 8) as 'Original Value',
     'Days' as 'Original Unit',
     '' as 'Name',
  '' as 'Id',
  '' as 'Notes',
  '' as 'SCS Previous Status', 1 as 'Include'
 FROM  
 salesforce.`work_item__c` wi 
 INNER JOIN salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 INNER JOIN salesforce.`work_item_resource__c` wir ON wir.work_item__c = wi.Id  
 INNER JOIN salesforce.`work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id  
 INNER JOIN salesforce.`recordtype` rt ON wi.RecordTypeId = rt.Id  
 WHERE  
 rt.Name = 'Audit' 
 AND wi.Revenue_Ownership__c not like '%Product%'
 #AND analytics.getRegionFromReportingBusinessUnit(wi.Revenue_Ownership__c) = @region
 AND sp.Program_Business_Line__c not in ('Product Services', 'Retail')
 AND wir.IsDeleted = 0  
 AND wird.IsDeleted = 0  
 AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget')  
 AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier')  
 and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget', 'Scheduled', 'Scheduled - Offered', 'Draft', 'Initiate Service')  
 AND wird.FStartDate__c >= date_add(@start_date, interval -1 year)
 AND wird.FStartDate__c <= date_add(@end_date, interval -1 year)
 GROUP BY `Metric`, `Region`, `Country`, `Business Line`,`Period`)
 union all
(select 
'Revenue Lost (Audit)' as 'Metric',
analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) as 'Region',
analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) as 'Country',
dacv.`Business Line`,
year(dacv.`De-Registered Date`) + if(month(dacv.`De-Registered Date`)<7, 0, 1) as 'FY',
DATE_FORMAT(dacv.`De-Registered Date`, '%Y %m') as 'Period',  
dacv.`ACV - Duration`/8 AS 'Value',
'Days' as 'Unit',
dacv.`ACV - Duration`/8 as 'Original Value',
'Days' as 'Original Unit',
dacv.`Client`,
dacv.`Site Cert Std`,
dacv.`De-Registered Reason` as 'Reasons',
if(scsp.Status__c in ('De-Registered','Concluded'), analytics.getSiteCertificationStandardPreviousStatus(scsp.Id), scsp.Status__c ) as 'SCS Previous Status',
if(dacv.`De-Registered Reason` in ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account'), 1, 0) as 'Include'
from analytics.deregistration_acv dacv
inner join salesforce.site_certification_standard_program__c scsp on dacv.`Site Cert Std Id` = scsp.Id
where 
dacv.`De-Registered Date`>= @start_date  
and dacv.`De-Registered Date`<= @end_date
and dacv.`Revenue Ownership` not like '%Product%'
and dacv.`Business Line` not in ('Product Services','Retail')
#and analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) = @region
group by dacv.`Site Cert Std Id`, `Period`)
union all
(select 
concat('Business Won ', if(oli.Days__c>0, '(Audits)', '(Fees)')) as 'metric',
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(o.`CloseDate`) + if (month(o.`CloseDate`)<7,0,1) as 'FY',
date_format(o.`CloseDate`,'%Y %m') as 'Period',
sum(oli.Days__c) as 'Value',
'Days' as 'Unit',
sum(oli.Days__c) as 'Original Value',
'Days' as 'Original Unit',
o.`Name` as 'Name',
o.`Quote_Ref__c` as 'Id',
o.`Type` as 'Note','' as 'SCS Previous Status', 1 as 'Include'
from salesforce.opportunity o 
inner join salesforce.account a on o.AccountId = a.Id
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.`Id` and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail')
where
#analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c ,' - ',-1)) = @region and 
o.closeDate between @start_Date and @end_Date
and o.IsDeleted = 0 
and o.StageName='Closed Won' 
and o.Status__c = 'Active'
and a.Client_Ownership__c not in ('Product Services')
group by `Metric`, o.Id, `Business Line`)
union
(select 
'PFY Business Won Audit Initial Package' as 'metric',
analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(date_add(o.`CloseDate`, interval 1 year)) + if (month(date_add(o.`CloseDate`, interval 1 year))<7,0,1) as 'FY',
date_format(date_add(o.`CloseDate`, interval 1 year),'%Y %m') as 'Period',
sum(oli.Days__c) as 'Value',
'Days' as 'Unit',
sum(oli.Days__c) as 'Original Value',
'Days' as 'Original Unit',
'' as  'Name',
'' as 'Id',
'' as 'Note','' as 'SCS Previous Status', 1 as 'Include'
from salesforce.opportunity o 
inner join salesforce.account a on o.AccountId = a.Id
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.`Id` and oli.IsDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c > 0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail') and (p.Name like '%Gap%' or p.Name like '%Stage%') 
where
o.IsDeleted = 0 
and o.StageName='Closed Won' 
and o.Status__c = 'Active'
and a.Client_Ownership__c not in ('Product Services')
and o.CloseDate between date_add(@start_Date, interval -1 year) and date_add(@end_Date, interval -1 year)
#and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = @region
group by `Metric`, `Region`,`Country`,`Business Line`,`Period`)
union
# % Converted opportunities won 1 year ago
(select t2.`Metric`, t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`FY`, t2.`Period`,sum(t2.`Opp Days`) as 'Value','Opp Days' as 'Unit',sum(t2.`WI Days`) as 'Original Value','WI Days' as 'Original Unit','%','','','' as 'SCS Previous Status', 1 as 'Include'
from
(select 
'% Opp Amount Converted (1 year MA)' as 'Metric', analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) as 'Region', substring_index(t.Business_1__c,' - ',-1) as 'Country', t.`Business Line`, t.closedate,
year(t.date) + if(month(t.date)<7,0,1) as 'FY', date_format(t.date, '%Y %m') as 'Period', sum(ifnull(wi.Required_Duration__c/8,0)) as 'WI Days', ifnull(`Opp 1st year days`,0) as 'Opp Days',t.`Name`,t.`Id`,''
from
(select o.id,o.Name,o.Business_1__c,year(date_add(o.CloseDate, interval 1 year)) + if(month(o.CloseDate)<7,0,1) as 'FY',periods.date,p.Business_Line__c as 'Business Line',o.CloseDate,sum(oli.Days__c) as 'Opp 1st year days',oli.CurrencyIsoCode
from salesforce.opportunity o
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c>0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail') 
inner join (select distinct date_format(wd.date, '%Y-%m-01') as 'date' from salesforce.sf_working_days wd where wd.date between @start_date and @end_date) periods
where 
o.CloseDate between date_add(periods.date, interval -2 year) and date_add(periods.date, interval -1 year)
and o.Business_1__c not in ('Product Services','Corporate')
#and analytics.getRegionFromCountry(substring_index(o.Business_1__c,' - ',-1)) = @region
group by periods.date, o.Id, p.Business_Line__c) t
inner join salesforce.certification__c c on c.Opportunity_Created_From__c = t.Id
inner join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id and wp.IsDeleted = 0
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id and wi.IsDeleted = 0 and wi.Work_Item_Date__c between t.CloseDate and date_add(t.CloseDate, interval 1 year) and wi.Work_Item_Stage__c not in ('Follow Up')
#left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted=0 and ili.Invoice_Status__c not in ('Cancelled') and (ili.Product_Category__c like 'Audit%' )#or ili.Product_Category__c like 'Travel%')
#left join salesforce.product2 pr on ili.Product__c = pr.Id and pr.Business_Line__c = t.`Business Line`
group by t.date, t.Id, t.`Business Line` ) t2
group by 
t2.`Metric`, t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`Period`);

(select 'Revenue Lost (Audit) Perc Last 12 Months',analytics.getRegionFromCountry(c.Name),c.Name,bl.Name,'n/a',p.Name,analytics.getPeriodAuditRevenueLostLast12MonthPerc(c.Name, bl.Name, p.Name),'AUD',analytics.getPeriodAuditRevenueLostLast12MonthPerc(c.Name, bl.Name, p.Name),'AUD','','','','' as 'SCS Previous Status', 1 as 'Include'
from 
(select 'Management Systems' as 'Name' union select 'Agri-Food') bl,
(select distinct date_format(wd.Date, '%Y %m') as 'Name' from salesforce.sf_working_days wd where wd.date between @start_date and @end_date) p,
(select 'Australia' as 'Name') c
#(SELECT distinct analytics.getCountryFromRevenueOwnership(Revenue_Ownership__c) as 'Name' from salesforce.work_item__c where Revenue_Ownership__c not like '%Product%') c
where analytics.getRegionFromCountry(c.Name) = @region);

#drop function getPeriodPFYRevenue;
DELIMITER $$
CREATE FUNCTION `getPeriodPFYRevenue`(country VARCHAR(256), business_line VARCHAR(256), period VARCHAR(7)) RETURNS decimal(16,4)
BEGIN
	DECLARE rev DECIMAL(16,4) DEFAULT null;
    DECLARE periodDate DATE DEFAULT null;
    DECLARE stream VARCHAR(10) default null;
    SET stream = (select if(business_line='Management Systems', 
							'MS',
                            if(business_line like '%Food%',
								'Food',
								if(business_line = 'Product Services','PS',
									if(business_line='Retail',
										'Retail',
                                        null
									)
								)
							)
						)
					);
    SET periodDate = (select str_to_date(concat(period, ' 01'),'%Y %m %d'));
    SET rev = (select sum(RefValue) from salesforce.sf_data where DataType='PeopleSoft'  and DataSubType = 'Audit Revenue'  and Region=country and RefName = stream and RefDate >= concat(year(periodDate) + if(month(periodDate)<7,-2,-1), '-07-01') and RefDate <= concat(year(periodDate) + if(month(periodDate)<7,-1,-0), '-06-30'));
		
    RETURN rev;
END$$
DELIMITER ;

#drop function getPeriodAuditRevenueLostLast12Month
DELIMITER $$
CREATE FUNCTION `getPeriodAuditRevenueLostLast12Month`(country VARCHAR(256), business_line VARCHAR(256), period VARCHAR(7)) RETURNS decimal(16,4)
BEGIN
	DECLARE rev DECIMAL(16,4) DEFAULT null;
    DECLARE periodDate DATE DEFAULT null;
    DECLARE stream VARCHAR(10) default null;
    SET periodDate = (select str_to_date(concat(period, ' 01'),'%Y %m %d'));
	SET rev = (
		(select 
			sum(ifnull(dacv.`ACV`/cur.ConversionRate,0))
		from analytics.deregistration_acv dacv
			inner join salesforce.site_certification_standard_program__c scsp on dacv.`Site Cert Std Id` = scsp.Id
			left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
			inner join salesforce.account client on dacv.`Client Id` = client.Id
		where 
			dacv.`De-Registered Date`>= date_add(periodDate, interval -11 month)
			and dacv.`De-Registered Date`< date_add(periodDate, interval 1 month)
			and analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) = country
			and dacv.`Business Line` = business_line
            and dacv.`De-Registered Reason` in ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account')));
		
    RETURN rev;
END$$
DELIMITER ;

# drop function getPeriodAuditRevenueLostLast12MonthPerc;
DELIMITER $$
CREATE FUNCTION `getPeriodAuditRevenueLostLast12MonthPerc`(country VARCHAR(256), business_line VARCHAR(256), period VARCHAR(7)) RETURNS decimal(16,4)
BEGIN
	DECLARE attrition DECIMAL(16,4) DEFAULT null;
    DECLARE periodDate DATE DEFAULT null;
    SET periodDate = (select str_to_date(concat(period, ' 01'),'%Y %m %d'));
	SET attrition = 
			(select sum(t.`RevenueLostPerc`) as 'RevenueLostPercMAT' from
				(select 
					periodDate as 'Period', 
                    date_format(dacv.`De-Registered Date`, '%Y %m') as 'PastPeriod', 
					sum(ifnull(dacv.`ACV`/cur.ConversionRate,0)) as 'AuditRevenueLost',
					getPeriodPFYRevenue(country, business_line, date_format(dacv.`De-Registered Date`, '%Y %m')) as 'PFYRevenue',
					sum(ifnull(dacv.`ACV`/cur.ConversionRate,0))/getPeriodPFYRevenue(country, business_line, date_format(dacv.`De-Registered Date`, '%Y %m')) as 'RevenueLostPerc'
				from analytics.deregistration_acv dacv
					inner join salesforce.site_certification_standard_program__c scsp on dacv.`Site Cert Std Id` = scsp.Id
					left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
				where 
					dacv.`De-Registered Date`>= date_add(periodDate, interval -11 month)
					and dacv.`De-Registered Date`< date_add(periodDate, interval 1 month)
					and analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) = country
					and dacv.`Business Line` = business_line
					and dacv.`De-Registered Reason` in ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account')
					group by `PastPeriod`) 
			t);
		
    RETURN attrition;
END$$
DELIMITER ;

set @periodDate = '2017-10-01';
set @country = 'China';
set @business_line = 'Management Systems';

select t.`Period`, count(t.`Period`), min(t.`PastPeriod`) as 'From', max(t.`PastPeriod`) as 'To', sum(t.`RevenueLostPerc`) as 'RevenueLostPercMAT' from
(select 
	@periodDate as 'Period', date_format(dacv.`De-Registered Date`, '%Y %m') as 'PastPeriod', 
	sum(ifnull(dacv.`ACV`/cur.ConversionRate,0)) as 'AuditRevenueLost',
    getPeriodPFYRevenue(@country, @business_line, date_format(dacv.`De-Registered Date`, '%Y %m')) as 'PFYRevenue',
    sum(ifnull(dacv.`ACV`/cur.ConversionRate,0))/getPeriodPFYRevenue(@country, @business_line, date_format(dacv.`De-Registered Date`, '%Y %m')) as 'RevenueLostPerc'
from analytics.deregistration_acv dacv
	inner join salesforce.site_certification_standard_program__c scsp on dacv.`Site Cert Std Id` = scsp.Id
	left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
	#inner join salesforce.account client on dacv.`Client Id` = client.Id
where 
	dacv.`De-Registered Date`>= date_add(@periodDate, interval -11 month)
	and dacv.`De-Registered Date`< date_add(@periodDate, interval 1 month)
	and analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) = @country
	and dacv.`Business Line` = @business_line
	and dacv.`De-Registered Reason` in ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account')
    group by `PastPeriod`) t;