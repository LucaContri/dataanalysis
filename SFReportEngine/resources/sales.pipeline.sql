use salesforce;
# Certification

# Pipeline days
(select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'Opportunities Created' as 'metric', t.Period,
sum(oli.Days__c) as 'Days',
sum(oli.TotalPrice) as 'Amount',
count(distinct t.Id) as 'Opp Count'
from (select o.Id, date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR),'%Y %m') as 'Period' 
		from opportunity o 
		where o.IsDeleted = 0
			and date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2013 10'
			and date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 09'
			and o.Business_1__c = 'Australia'
			and o.Status__c = 'Active'
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
left join standard__c s on oli.Standard__c = s.Id 
left join program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
#and oli.Days__c>0 #Exclude Fees, only Audit
and oli.First_Year_Revenue__c =1
group by `stream`, `metric`, `Period`)
union
# Sales days
(select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'Opportunities Won' as 'metric', t.Period,
sum(oli.Days__c) as 'Days',
sum(oli.TotalPrice) as 'Amount',
count(distinct t.Id) as 'Opp Count'
from (select o.Id, date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'Period' 
		from opportunity o 
		inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id 
		where o.IsDeleted = 0
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2013 10'
			and date_format(date_add(oh.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 09'
			and o.Business_1__c = 'Australia'
			and o.StageName='Closed Won'
			and oh.Field = 'StageName'
			and oh.NewValue = 'Closed Won'
			and o.Status__c = 'Active'
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
left join standard__c s on oli.Standard__c = s.Id 
left join program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
#and oli.Days__c>0 #Exclude Fees, only Audit
and oli.First_Year_Revenue__c =1
group by `stream`, `metric`, `Period`);

#Audit Days
select if(group_concat(pg.Business_Line__c) like '%Agri-Food%', 'Food', 'MS') as 'stream', 
t.Id, t.StageName, t.Type, t.`Opp Created Date`,t.`Opp Created Period`,t.`Opp Won Date`,t.`Opp Won Period`,t.`Opp Lost Date`,t.`Opp Lost Period`, 
if (greatest(t.`#OppSites`, t.`CountSites`,1) = 1, if (greatest(t.`#OppPrograms`, t.`CountStandards`,1)=1, 'SingleSiteSingleStandard','SingleSiteMultiStandard'),'MultiSite')as 'Category',
if (t.`Opp Won Date` is not null or t.`Opp Lost Date` is not null, true,false) as 'Closed',
datediff(least(if(t.`Opp Won Date` is null,now(),t.`Opp Won Date`),if(t.`Opp Lost Date` is null,now(),t.`Opp Lost Date`)),t.`Opp Created Date`) as 'Created to Closed (Days)',
date_format(least(if(t.`Opp Won Date` is null,now(),t.`Opp Won Date`),if(t.`Opp Lost Date` is null,now(),t.`Opp Lost Date`)), '%Y %m') as 'Closed Period',
round(datediff(date_format(least(if(t.`Opp Won Date` is null,now(),t.`Opp Won Date`),if(t.`Opp Lost Date` is null,now(),t.`Opp Lost Date`)), '%Y-%m-01'),date_format(t.`Opp Created Date`,'%Y-%m-01'))/31,0) as 'Created To Closed (Months)',
sum(oli.Days__c) as 'First Year Days'
from (select o.Id, 
		o.StageName,
		o.Type,
		date_add(o.CreatedDate,INTERVAL 11 HOUR) as 'Opp Created Date',
		date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR), '%Y %m') as 'Opp Created Period',
		date_add(min(if(o.StageName='Closed Won' and oh.Field = 'StageName' and oh.NewValue = 'Closed Won',oh.CreatedDate,null)),INTERVAL 11 HOUR) as 'Opp Won Date', 
		date_format(date_add(min(if(o.StageName='Closed Won' and oh.Field = 'StageName' and oh.NewValue = 'Closed Won',oh.CreatedDate,null)),INTERVAL 11 HOUR), '%Y %m') as 'Opp Won Period',
		date_add(min(if(o.StageName='Closed Lost' and oh.Field = 'StageName' and oh.NewValue = 'Closed Lost',oh.CreatedDate,null)),INTERVAL 11 HOUR) as 'Opp Lost Date', 
		date_format(date_add(min(if(o.StageName='Closed Lost' and oh.Field = 'StageName' and oh.NewValue = 'Closed Lost',oh.CreatedDate,null)),INTERVAL 11 HOUR), '%Y %m') as 'Opp Lost Period', 
		if(o.Number_of_Sites__c is null,0,o.Number_of_Sites__c) as '#OppSites', 
		if(o.Program__c is null, 0, LENGTH(o.Program__c) - LENGTH(REPLACE(o.Program__c, ';', ''))+1) AS '#OppPrograms',
		count(distinct if(osc.IsDeleted=1 or osc.Client_Site__c is null, null,osc.Client_Site__c)) as 'CountSites', 
		count(distinct if(osc.IsDeleted=1 or oscsp.IsDeleted=1 or oscsp.Standard_Program__c is null, null,oscsp.Standard_Program__c)) as 'CountStandards'
		from opportunity o 
		inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id 
		left join opportunity_site_certification__c osc on osc.Opportunity__c = o.Id
		left join oppty_site_cert_standard_program__c oscsp on oscsp.Opportunity_Site_Certification__c = osc.Id
		where o.IsDeleted = 0
			and date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR),'%Y %m') >= '2013 10'
			and date_format(date_add(o.CreatedDate,INTERVAL 11 HOUR),'%Y %m') <= '2014 09'
			and o.Business_1__c = 'Australia'
			and o.Status__c = 'Active'
			and o.StageName not in ('Budget')
			group by o.Id) t
left join opportunitylineitem oli on oli.OpportunityId = t.Id
left join standard__c s on oli.Standard__c = s.Id 
left join program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
and oli.First_Year_Revenue__c =1
group by t.Id
limit 1000000;

#Lead to Opportunity
select 
l.id,
l.convertedOpportunityId,
l.LeadSource,
l.Business__c,
date_format(l.CreatedDate,'%Y %m') as 'Lead Created Period', 
count(l.Id) as 'Total Leads',
sum(if(l.IsConverted, 1,0)) as 'Converted',
sum(if(l.IsConverted, 1,0))/count(l.Id) as 'Conversion Rate',
avg(if(l.IsConverted,datediff(l.ConvertedDate, l.CreatedDate),null)) as 'Avg Conversion Time' 
from lead l
inner join recordtype rt on rt.Id = l.RecordTypeId
where rt.Name in ('AUS - Lead')
and l.IsDeleted=0
and l.IsConverted=1
group by l.Id, Business__c, LeadSource,`Lead Created Period`;

# TIS - InHouse
use training;

select o.Id, o.Name, o.StageName, o.Number_of_Sites__c, o.Program__c from opportunity o where o.IsDeleted=0 limit 1000000;

create index opportunity_site_certification_index on opportunity_site_certification__c(Opportunity__c);
create index oppty_site_cert_standard_program_index on oppty_site_cert_standard_program__c (Opportunity_Site_Certification__c);
#explain
select t.*, greatest(t.`#OppSites`, t.`CountSites`) as '#SitesGuess', greatest(t.`#OppPrograms`, t.`CountStandards`) as '#StandardsGuess' from (
select o.Id, o.Name, date_format(o.CreatedDate, '%Y %m') as 'Period Created', o.StageName, 
if(o.Number_of_Sites__c is null,0,o.Number_of_Sites__c) as '#OppSites', 
if(o.Program__c is null, 0, LENGTH(o.Program__c) - LENGTH(REPLACE(o.Program__c, ';', ''))+1) AS '#OppPrograms',
count(distinct if(osc.IsDeleted=1 or osc.Client_Site__c is null, null,osc.Client_Site__c)) as 'CountSites', 
count(distinct if(osc.IsDeleted=1 or oscsp.IsDeleted=1 or oscsp.Standard_Program__c is null, null,oscsp.Standard_Program__c)) as 'CountStandards' 
from opportunity o 
left join opportunity_site_certification__c osc on osc.Opportunity__c = o.Id
left join oppty_site_cert_standard_program__c oscsp on oscsp.Opportunity_Site_Certification__c = osc.Id
group by o.Id) t limit 1000000;

select * from sf_tables where TableName = 'oppty_site_cert_standard_program__c';