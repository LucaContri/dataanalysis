DROP function getCountryFromRevenueOwnership;
DELIMITER $$
CREATE FUNCTION `getCountryFromRevenueOwnership`(ro VARCHAR(256)) RETURNS varchar(256) CHARSET utf8
BEGIN
	DECLARE country VARCHAR(256) DEFAULT null;
    SET country = (SELECT 
		if(ro like '%Product%', 
			'Product Services', 
			if(ro like 'AUS%' or ro like '%AMERICAS%', 
				'Australia', 
				if (ro like '%Regional Desk%',
					'Regional Desk',
                    if (ro like 'EMEA%',
						if(ro='EMEA-MS', 'UK', substring_index(ro,'-',-1)),
						substring_index(substring_index(ro,'-',-2),'-',1)
					)
				)
			)
		)
	);
		
    RETURN country;
END$$
DELIMITER ;

drop FUNCTION `getFyActiveClientsCount`;
DELIMITER $$
CREATE FUNCTION `getFyActiveClientsCount`(country VARCHAR(256), fy INTEGER) RETURNS INTEGER 
BEGIN
	DECLARE count DECIMAL(16,4) DEFAULT null;
    DECLARE startDate DATE DEFAULT null;
    DECLARE endDate DATE DEFAULT null;
    SET startDate = (select concat((fy-1),'-07-01'));
    SET endDate = (select concat(fy,'-06-30'));
    SET count = (
		select count(t.Client_Id__c) from 
			(select wi.Client_Id__c, analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country', sp.Program_Business_Line__c as 'Business Line'
			from salesforce.work_item__c wi 
			inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
			inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
			where 
			wi.Work_Item_Date__c >= startDate 
			and wi.Work_Item_Date__c<= endDate 
			and wi.IsDeleted = 0
			and wi.Status__c = 'Completed'
			group by wi.Client_Id__c) t
		where t.Country = country
    );
		
    RETURN count;
END$$
DELIMITER ;


		select Country, count(t.Client_Id__c) from 
			(select wi.Client_Id__c, analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country'
			from salesforce.work_item__c wi 
			where 
			wi.Work_Item_Date__c >= '2014-07-01'
			and wi.Work_Item_Date__c<= '2015-06-30' 
			and wi.IsDeleted = 0
			and wi.Status__c = 'Completed'
			group by wi.Client_Id__c) t
        group by t.`Country`;
        
drop FUNCTION `getFyAuditRevenue`;
DELIMITER $$
CREATE FUNCTION `getFyAuditRevenue`(country VARCHAR(256), business_line VARCHAR(256), fy INTEGER) RETURNS DECIMAL(16,4) 
BEGIN
	DECLARE rev DECIMAL(16,4) DEFAULT null;
    DECLARE startDate DATE DEFAULT null;
    DECLARE endDate DATE DEFAULT null;
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
    SET startDate = (select concat((fy-1),'-07-01'));
    SET endDate = (select concat(fy,'-06-30'));
    SET rev = (select sum(RefValue) from salesforce.sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and Region=country and RefName = stream and RefDate >= startDate and RefDate <= endDate);
		
    RETURN rev;
END$$
DELIMITER ;

# Assurance Global Metrics - Australia
set @start_date = '2014-07-01';
set @end_date = '2016-06-30';
set @region = 'APAC';
# Confirmed Audit Days
# Questions:
#	Which Region/Country should we put Revenue Ownership AMERICA-MS?
#	Business Line split is not the same as revenue ownership Food/MS
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
	 '' as 'Notes'
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
(select if(t.`Active Site Cert Std` = 0, 'Customer Lost (Audit Revenue)', 'Sites/Licences Lost (Audit Revenue)') as `Metric`, t.`Region`, t.`Country`, t.`Business Line`, t.`FY`, t.`Period`, 
t.`Value`, t.`Unit`, -t.`Original Value`, t.`Original Unit`, 
t.`Client`, t.`Lost Site Cert Std`, t.`Reasons` from
(select t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`FY`, t2.`Period`, sum(t2.`Value`) as 'Value', t2.`Unit`, sum(t2.`Original Value`) as 'Original Value', t2.`Original Unit`, t2.`Client`, group_concat(distinct t2.`Lost Site Cert Std`) as 'Lost Site Cert Std', group_concat(distinct t2.`Reasons`) as 'Reasons', t2.`Active Site Cert Std` from
(select 
analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) as 'Region',
analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) as 'Country',
dacv.`Business Line`,
year(dacv.`De-Registered Date`) + if(month(dacv.`De-Registered Date`)<7, 0, 1) as 'FY',
DATE_FORMAT(dacv.`De-Registered Date`, '%Y %m') as 'Period',  
ifnull(dacv.`ACV`/cur.ConversionRate,0) AS 'Value',
'AUD' as 'Unit',
dacv.`ACV` as 'Original Value',
dacv.`Currency` as 'Original Unit',
dacv.`Client Id`,
dacv.`Client`,
dacv.`Site Cert Std` as 'Lost Site Cert Std',
dacv.`De-Registered Reason` as 'Reasons',
count(distinct scsp.Id) as 'Active Site Cert Std'
from analytics.deregistration_acv dacv
left join salesforce.CurrencyType cur on dacv.Currency = cur.IsoCode
inner join salesforce.account client on dacv.`Client Id` = client.Id
left join salesforce.certification__c c on c.Primary_client__c = client.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id and scsp.Status__c not in ('Transferred') and (scsp.Withdrawn_Date__c is null or DATE_FORMAT(scsp.Withdrawn_Date__c, '%Y %m') > DATE_FORMAT(dacv.`De-Registered Date`, '%Y %m'))
where 
dacv.`De-Registered Date`>= @start_date  
and dacv.`De-Registered Date`<= @end_date
and dacv.`Revenue Ownership` not like '%Product%'
and dacv.`Business Line` not in ('Product Services','Retail')
and analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) = @region
group by dacv.`Site Cert Std Id`, `Period`) t2
group by t2.`Client Id`, t2.`Period`) t)
union
(select 
concat('Business Won ', if(t.Type like 'New%' or t.Type = 'Non-Certification', concat('New ', if(oli.Days__c>0, '(Audits)', '(Fees)')), concat('Retention ', if(oli.Days__c>0, '(Audits)', '(Fees)')) )) as 'metric',
analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) as 'Region',
substring_index(t.Business_1__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(t.`ClosedWonDate`) + if (month(t.`ClosedWonDate`)<7,0,1) as 'FY',
date_format(t.`ClosedWonDate`,'%Y %m') as 'Period',
sum(oli.TotalPrice/cur.ConversionRate) as 'Value',
'AUD' as 'Unit',
sum(oli.TotalPrice) as 'Original Value',
oli.CurrencyIsoCode as 'Original Unit',
t.`Opp` as 'Name',
t.`Opp Id` as 'Id',
t.`Type` as 'Note'
from (
select 
	if(min(oh.CreatedDate) between @start_Date and @end_Date, o.Id,null) as 'Opp Id', 
	o.Name as 'Opp',
	min(oh.CreatedDate) as 'ClosedWonDate',
	date_format(min(oh.CreatedDate),'%Y %m') as 'WonPeriod',
	o.Business_1__c,
	o.Type
from salesforce.opportunity o 
inner join salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.Id 
where 
	o.IsDeleted = 0 
	and o.StageName='Closed Won' 
	and oh.Field = 'StageName' 
	and oh.NewValue = 'Closed Won' 
	and o.Status__c = 'Active'
    and o.Business_1__c not in ('Product Services','Corporate')
	group by o.Id) t 
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail')
left join salesforce.currencytype cur on oli.CurrencyIsoCode = cur.IsoCode
where
analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) = @region
group by `Metric`, t.`Opp Id`, `Business Line`)
union
#Avg Audit Day Price Quoted
(select 
concat('Avg Audit Day Quoted ', if(t.Type like 'New%' or t.Type = 'Non-Certification', 'New ', 'Retention ' )) as 'Metric',
analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) as 'Region',
substring_index(t.Business_1__c,' - ',-1) as 'Country',
p.Business_Line__c as 'Business Line', 
year(t.`ClosedWonDate`) + if (month(t.`ClosedWonDate`)<7,0,1) as 'FY',
date_format(t.`ClosedWonDate`,'%Y %m') as 'Period',
sum(oli.TotalPrice/cur.ConversionRate)/sum(oli.Days__c) as 'Value',
'AUD' as 'Unit',
sum(oli.TotalPrice)/sum(oli.Days__c) as 'Original Value',
oli.CurrencyIsoCode as 'Original Unit',
'','',''
from (
select 
	if(min(oh.CreatedDate) between @start_Date and @end_Date, o.Id,null) as 'Opp Id', 
	o.Name as 'Opp',
	min(oh.CreatedDate) as 'ClosedWonDate',
	date_format(min(oh.CreatedDate),'%Y %m') as 'WonPeriod',
	o.Business_1__c,
	o.Type
from salesforce.opportunity o 
inner join salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.Id 
where 
	o.IsDeleted = 0 
	and o.StageName='Closed Won' 
	and oh.Field = 'StageName' 
	and oh.NewValue = 'Closed Won' 
	and o.Status__c = 'Active'
    and o.Business_1__c not in ('Product Services', 'Corporate')
	group by o.Id) t 
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c>0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail')
left join salesforce.currencytype cur on oli.CurrencyIsoCode = cur.IsoCode
where
analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) = @region
group by `Metric`, `Region`, `Country`, `Business Line`, `Period`)
union
#FTE Auditor Utilisation
(select 
'FTE Auditor Utilisation' as 'Metric',
analytics.getRegionFromCountry(t.`Region`) as 'Region',
if(t.`Region`='United Kingdom', 'UK', t.`Region`) as 'Country',
'' as 'Business Line', 
left(t.`ColumnName`,4) + if(right(t.`ColumnName`,2)<'07',0,1) as 'FY',
t.`ColumnName` as 'Period',
cast(t.`Value` as DECIMAL(16,4)) as 'Value',
'%' as 'Unit',
cast(t.`Value` as DECIMAL(16,4)) as 'Original Value',
'%' as 'Original Unit',
'','',''
from (
select * from salesforce.sf_report_history 
where ReportName='Scheduling Auditors Metrics' 
and ColumnName >= date_format(@start_date, '%Y %m')
and ColumnName <= date_format(@end_date, '%Y %m')
and RowName = 'Utilisation' 
and Region not in ('EMEA UK', 'Asia') 
order by Date desc) t 
where analytics.getRegionFromCountry(t.`Region`) = @region
group by `Region`,`Period`)
union
#No Of Days to Issue Certificate
(select 
'No Of Days to Issue Certificate' as 'Metric2', 
analytics.getRegionFromReportingBusinessUnit(arg.Region) as 'Region2', 
analytics.getCountryFromRevenueOwnership(arg.Region) as 'Country2',
arg.`Business Line` as 'Business Line2',
year(arg.`To`)+if(month(arg.`To`)<7,0,1) as 'FY',
date_format(arg.`To`, '%Y %m') as 'Period2',
#avg(analytics.getBusinessDays(arg.`From`, arg.`To`, arg.`TimeZone`) )as 'Value',
avg(timestampdiff(second, arg.`From`, arg.`To`)/3600/24 )as 'Value2',
'Days' as 'Unit', 
avg(timestampdiff(second, arg.`From`, arg.`To`)/3600/24 )as 'Original Value',
'Days' as 'Original Unit', 
'','',''
from analytics.sla_arg_v2 arg 
where Metric in ('ARG Process Time (Other)','ARG Process Time (BRC)') 
and arg.`WI Type` not like '%Follow Up%'
and arg.`To` between @start_date and @end_date
and arg.Region not like '%Product%'
and arg.`Business Line` not in ('Product Services','Retail')
and analytics.getRegionFromReportingBusinessUnit(arg.Region) = @region
group by `Metric2`, `Region2`, `Country2`, `Business Line2`, `Period2`)
union
(select 'Client Count',analytics.getRegionFromCountry(t.`Country`), t.`Country`, '', year(@start_date), '', count(t.Client_Id__c), '#',count(t.Client_Id__c), '#','','','' from 
	(select wi.Client_Id__c, analytics.getCountryFromRevenueOwnership(wi.Revenue_Ownership__c) as 'Country'
	from salesforce.work_item__c wi 
	where wi.Work_Item_Date__c >= date_add(@start_date, interval -1 year) and wi.Work_Item_Date__c<= date_add(@end_date, interval -1 year) and wi.IsDeleted = 0 and wi.Status__c = 'Completed' and wi.Revenue_Ownership__c not like '%Product%'
	group by wi.Client_Id__c) t
where analytics.getRegionFromCountry(t.`Country`) = @region
group by t.`Country`)
union
# % Converted opportunities won 1 year ago
(select t2.`Metric`, t2.`Region`, t2.`Country`, t2.`Business Line`, t2.`FY`, t2.`Period`,sum(t2.`Opp Amount`) as 'Value','Opp $' as 'Unit',sum(t2.`Inv Amount`) as 'Original Value','Inv $' as 'Original Unit','%','','' 
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
(select 'Actual Revenues',analytics.getRegionFromCountry(c.Name),c.Name,bl.Name,y.Name,'',analytics.getFyAuditRevenue(c.Name,bl.Name,y.Name),'AUD',analytics.getFyAuditRevenue(c.Name,bl.Name,y.Name),'AUD','','',''
from 
(select 'Management Systems' as 'Name' union select 'Agri-Food') bl,
(select year(@start_date) as 'Name') y,
(SELECT distinct analytics.getCountryFromRevenueOwnership(Revenue_Ownership__c) as 'Name' from salesforce.work_item__c where Revenue_Ownership__c not like '%Product%') c
where analytics.getRegionFromCountry(c.Name) = @region)
union
(select 'Exchange Rates', '','','',year(ct.LastModifiedDate), date_format(ct.LastModifiedDate, '%Y %m'), ct.`ConversionRate`, '',ct.`ConversionRate`, '',ct.IsoCode,'','' from salesforce.currencytype ct where ct.IsActive=1);

# % Converted opportunities won 1 year ago
(select 
'% Opp Amount Converted (1 year MA)' as 'Metric', analytics.getRegionFromCountry(substring_index(t.Business_1__c,' - ',-1)) as 'Region', substring_index(t.Business_1__c,' - ',-1) as 'Country', t.`Business Line`, t.closedate,
year(t.date) + if(month(t.date)<7,0,1) as 'FY', date_format(t.date, '%Y %m') as 'Period', sum(ifnull(ili.Total_Line_Amount__c,0)) as 'Inv Amount', ifnull(`Opp 1st year amount`,0) as 'Opp Amount',t.`Name`,t.`Id`,group_concat(distinct sc.Id) as 'Site Cert Ids', t.`Opp Products`, group_concat(distinct pr.`Name`) as 'Invoiced Products'
from
(select o.id,o.Name,o.Business_1__c,year(date_add(o.CloseDate, interval 1 year)) + if(month(o.CloseDate)<7,0,1) as 'FY',periods.date,p.Business_Line__c as 'Business Line',o.CloseDate,sum(oli.TotalPrice) as 'Opp 1st year amount',oli.CurrencyIsoCode, group_concat(distinct p.Name) as 'Opp Products'
from salesforce.opportunity o
inner join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id and oli.ISDeleted = 0 and oli.First_Year_Revenue__c =1 and oli.Days__c>0
inner join salesforce.product2 p on oli.Product2Id = p.Id and p.Business_Line__c not in ('Product Services','Retail') 
inner join (select distinct date_format(wd.date, '%Y-%m-01') as 'date' from salesforce.sf_working_days wd where wd.date between '2016-02-01' and '2016-02-29') periods
where 
o.CloseDate between date_add(periods.date, interval -2 year) and date_add(periods.date, interval -1 year)
and o.Business_1__c not in ('Product Services')
and substring_index(o.Business_1__c,' - ',-1) = 'China'
group by periods.date, o.Id, p.Business_Line__c) t
inner join salesforce.certification__c c on c.Opportunity_Created_From__c = t.Id
inner join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id and wp.IsDeleted = 0
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id and wi.IsDeleted = 0 and wi.Work_Item_Date__c between t.CloseDate and date_add(t.CloseDate, interval 1 year) and wi.Work_Item_Stage__c not in ('Follow Up')
left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted=0 and ili.Invoice_Status__c not in ('Cancelled') and (ili.Product_Category__c like 'Audit%' )#or ili.Product_Category__c like 'Travel%')
left join salesforce.product2 pr on ili.Product__c = pr.Id and pr.Business_Line__c = t.`Business Line`
group by t.date, t.Id, t.`Business Line` );

select Business_1__c from salesforce.opportunity where Id='006d000000PVCdEAAX';
use analytics;

#explain
(select rt.Name, o.Id, o.Name, o.CloseDate, oli.TotalPrice, oli.CurrencyIsoCode, oli.TotalPrice/ct.ConversionRate as 'AUD Amount', p.Business_Line__c, p.Pathway__c, ow.Name as 'Owner', 
a.Name as 'Client', greatest(ifnull(ow.Country,''),ifnull(ow.Division, ''), ifnull(a.BillingCountry,''), ifnull(a.Account_Site_Location__c,'')) as 'Client Country', o.New_Business_perc__c
from training.opportunity o
inner join training.recordtype rt on o.RecordTypeId = rt.Id
inner join training.user ow on o.OwnerId = ow.Id
inner join training.account a on o.AccountId = a.Id
left join training.opportunitylineitem oli on oli.OpportunityId = o.Id
left join salesforce.currencytype ct on oli.CurrencyIsoCode = ct.IsoCode
left join training.product2 p on oli.product2id = p.Id
where rt.Name = 'AS-EMEA-Opportunities'
and o.StageName = 'Closed Won');


