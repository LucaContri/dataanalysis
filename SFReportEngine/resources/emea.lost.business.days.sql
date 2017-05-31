set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @start_date = concat(@fy-1,'-07-01');
set @end_date = concat(@fy,'-06-30');
set @region = 'EMEA';

describe analytics.audit_values;

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
dacv.`ACV - Duration`,
dacv.`Client`,
dacv.`Site Cert Std`,
dacv.`De-Registered Reason` as 'Reasons'
from analytics.deregistration_acv dacv
left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
inner join salesforce.account client on dacv.`Client Id` = client.Id
where 
dacv.`De-Registered Date`>= @start_date  
and dacv.`De-Registered Date`<= @end_date
and dacv.`Revenue Ownership` not like '%Product%'
and dacv.`Business Line` not in ('Product Services','Retail')
and analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) = @region
#and analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) = 'UK'
group by dacv.`Site Cert Std Id`, `Period`)
union all
(select 'Actual Revenues',analytics.getRegionFromCountry('UK'),'UK',bl.Name,'PFY','',analytics.getFyAuditRevenue('UK',bl.Name,y.Name),'GBP',analytics.getFyAuditRevenue('UK',bl.Name,y.Name),'GBP','','','',''
from 
(select 'Management Systems' as 'Name' union select 'Agri-Food') bl,
(select year(@start_date) as 'Name') y)
union all
(select 'Exchange Rates', '','','',year(ct.LastModifiedDate), date_format(ct.LastModifiedDate, '%Y %m'), ct.`ConversionRate`, '',ct.`ConversionRate`, '','',ct.IsoCode,'','' from salesforce.currencytype ct where ct.IsActive=1);
