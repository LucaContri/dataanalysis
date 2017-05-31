# https://saicompass.my.salesforce.com/?ec=302&startURL=%2F00Od0000004hhXJ
# https://emea.salesforce.com/00O20000007Umby/e?retURL=%2F00O20000007Umby

(select 
 'Compass Opportunity' as 'Record Type',
 o.Id, 
 concat('https://saicompass.my.salesforce.com/', o.Id) as 'Opportunity Link',
    o.Name, 
    a.Name as 'Client Name', 
    oo.Name as 'Opportunity Owner',
    oom.Name as 'Opp Owner Manager',
    o.Type as 'Type',
    o.StageName as 'Stage',
    if(o.StageName = 'Needs Analysis', 'Prospect (Needs Analysis)',
  if(o.StageName = 'Sales Duration Review', 'Qualified (Sales Duration Review)',
   if(o.StageName = 'Proposal Sent', 'Proposal (Proposal Sent)',
    if(o.StageName = 'Negotiation/Review', 'Negotiation/Review',
     o.StageName 
    )
   )
  )
    ) as 'Stages',
    o.Total_First_Year_Revenue__c as '1st Year New Business Revenue', 
    o.CurrencyIsoCode as 'Currency', 
    round(o.Total_First_Year_Revenue__c/ct.ConversionRate,2) as '1st Year New Business Revenue (AUD)', 
    o.Amount, 
    round(o.Amount/ct.ConversionRate,2) as 'Amount (AUD)', 
    ifnull(round(o.Total_First_Year_Revenue__c/ct.ConversionRate,2),0) as 'Global ACV (AUD)',
    o.CreatedDate as 'Created Date', 
    o.LastModifiedDate as 'Last Modified Date',
    o.CloseDate as 'Closed Date', 
    '' as 'Revenue Date',
    timestampdiff(day, o.createdDate, utc_timestamp()) as 'Aging Created (Days)', 
    timestampdiff(day, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Days)',
    timestampdiff(month, o.createdDate, utc_timestamp()) as 'Aging Created (Months)', 
    timestampdiff(month, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Months)',
    if(timestampdiff(month, o.createdDate, utc_timestamp())>=4, '4+', timestampdiff(month, o.createdDate, utc_timestamp())) as 'Aging Created (Buckets)' ,
    analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
 substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
    'Assurance' as 'Portfolio',
    if(o.Business_1__c like 'Product Services', 'Product Services', 'MS and FS') as 'Stream',
    i.Name as 'Industry',
    'TBD' as 'Industry Vertical',
    oor.Name as 'Owner Role',
    if(o.CloseDate < now(), 'Out of Date', 'Current') as 'Pipeline Status',
    o.Probability/100 as 'Probability',
    o.Probability/100*round(o.Amount/ct.ConversionRate,2) as 'Revenue Forecast (AUD)',
    ifnull(o.Probability/100*round(o.Total_First_Year_Revenue__c/ct.ConversionRate,2),0) as 'Global ACV Forecast (AUD)'
from salesforce.opportunity o
 inner join salesforce.account a on o.AccountId = a.Id
    left join salesforce.industry__c i on a.Industry_2__c = i.Id
 left join salesforce.user oo on o.Opportunity_Owner__c = binary left(oo.Id,15)
 left join salesforce.user oom on oo.ManagerId = oom.Id
 left join salesforce.userrole oor on oo.UserRoleId = oor.Id
 left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
where 
 o.Probability > 0
    and o.Probability < 100
    and o.StageName not like 'Close%'
    and o.StageName not like '%budget%'
    and o.CloseDate >= '2015-07-01' #Ignore Old Stuff
    and o.CloseDate < date_add(now(), interval 6 month)
    and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = 'APAC'
)
union all
(select
 rt.Name as 'Record Type',
 o.Id, 
 concat('https://emea.salesforce.com/', o.Id) as 'Opportunity Link',
 o.Name, 
 ifnull(a.Name,'') as 'Client Name', 
 oo.Name as 'Opportunity Owner', 
 oom.Name as 'Opp Owner Manager',
 o.Type as 'Type',
 o.StageName as 'Stage',
 if(o.Stages__c = '10%Prospect', 'Prospect (Needs Analysis)',
 if(o.Stages__c = '25%Qualified', 'Qualified (Sales Duration Review)',
  if(o.Stages__c = '40%Proposal', 'Proposal (Proposal Sent)',
   if(o.Stages__c = '75%Negotiation/Review', 'Negotiation/Review',
    if(o.Stages__c = '90%Verbal', 'Verbal',
     o.Stages__c
    )
   )
  )
 )
 ) as 'Stages',
 o.X1st_Year_Amount__c as '1st Year New Business Revenue', 
 o.CurrencyIsoCode as 'Currency', 
 round(o.X1st_Year_Amount__c/ct.ConversionRate,2) as '1st Year New Business Revenue (AUD)', 
 o.Amount, 
 round(o.Amount/ct.ConversionRate,2) as 'Amount (AUD)', 
 ifnull(round(o.Global_ACV__c/ct.ConversionRate,2),0) as 'Global ACV (AUD)',
 o.CreatedDate as 'Created Date', 
 o.LastModifiedDate as 'Last Modified Date',
 o.CloseDate as 'Closed Date', 
 o.Revenue_Date__c as 'Revenue Date',
 timestampdiff(day, o.createdDate, utc_timestamp()) as 'Aging Created (Days)', 
 timestampdiff(day, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Days)',
 timestampdiff(month, o.createdDate, utc_timestamp()) as 'Aging Created (Months)', 
 timestampdiff(month, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Months)',
 if(timestampdiff(month, o.createdDate, utc_timestamp())>=4, '4+', timestampdiff(month, o.createdDate, utc_timestamp())) as 'Aging Created (Buckets)',
 if(o.Region__c = 'Asia Pacific', 'APAC', o.Region__c) as 'Region',
 o.Country__c as 'Country',
 o.Portfolio__c as 'Portfolio',
 '' as 'Stream',
 a.Industry as 'Industry',
 a.Industry_Vertical__c as 'Industry Vertical',
 '' as 'Owner Role',
 if(o.Revenue_Date__c < now(), 'Out of Date', 'Current') as 'Pipeline Status',
 o.Probability/100 as 'Probability',
 o.Probability/100*round(o.Amount/ct.ConversionRate,2) as 'Revenue Forecast (AUD)',
 ifnull(o.Probability/100*round(o.Global_ACV__c/ct.ConversionRate,2),0) as 'Global ACV (AUD)'
from training.opportunity o
 left join training.recordtype rt on o.RecordTypeId = rt.Id
    left join training.account a on o.AccountId = a.Id
 left join training.user oo on o.OwnerId = oo.Id
 left join training.user oom on oo.ManagerId = oom.Id
    left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
where
 o.IsDeleted = 0
 and o.StageName not like '%trial%'
    and o.Stages__c not like '%closed%'
    and o.Stages__c not like '%ren%'
    and o.Revenue_Date__c >= '2015-07-01'
    and o.Revenue_Date__c < date_add(now(), interval 6 month)
    and (o.Type not like '%renewal%' or o.Type  is null)
 and (o.New_or_Renewal__c not like '%Ren%' or o.New_or_Renewal__c is null)
 and (
  (rt.Name in ('Compliance Asia Pacific Opportunity Record Type','ENT - APAC - Opportunity (In House)','PUB - APAC - Oppty') and (o.Type not like '%cls%' or o.Type is null) and (o.Type not like '%copy%' or o.Type is null) ) 
        or 
        (rt.Name in ('CMPL - APAC - Opportunity Record Type') and o.Type like '%BV%')
 )
)
union all
# TIS
(select
 rt.Name as 'Record Type',
 o.Id, 
 concat('https://emea.salesforce.com/', o.Id) as 'Opportunity Link',
 o.Name, 
 ifnull(a.Name,'') as 'Client Name', 
 oo.Name as 'Opportunity Owner', 
 oom.Name as 'Opp Owner Manager',
 o.Type as 'Type',
 o.StageName as 'Stage',
 if(o.Stages__c = '10%Prospect', 'Prospect (Needs Analysis)',
 if(o.Stages__c = '25%Qualified', 'Qualified (Sales Duration Review)',
  if(o.Stages__c = '40%Proposal', 'Proposal (Proposal Sent)',
   if(o.Stages__c = '75%Negotiation/Review', 'Negotiation/Review',
    if(o.Stages__c = '90%Verbal', 'Verbal',
     o.Stages__c
    )
   )
  )
 )
 ) as 'Stages',
 o.X1st_Year_Amount__c as '1st Year New Business Revenue', 
 o.CurrencyIsoCode as 'Currency', 
 round(o.X1st_Year_Amount__c/ct.ConversionRate,2) as '1st Year New Business Revenue (AUD)', 
 ifnull(o.Amount,0) as 'Amount', 
 ifnull(round(o.Amount/ct.ConversionRate,2),0) as 'Amount (AUD)', 
 ifnull(round(o.Global_ACV__c/ct.ConversionRate,2),0) as 'ACV (AUD)',
 o.CreatedDate as 'Created Date', 
 o.LastModifiedDate as 'Last Modified Date',
 o.CloseDate as 'Closed Date', 
 o.Revenue_Date__c as 'Revenue Date',
 timestampdiff(day, o.createdDate, utc_timestamp()) as 'Aging Created (Days)', 
 timestampdiff(day, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Days)',
 timestampdiff(month, o.createdDate, utc_timestamp()) as 'Aging Created (Months)', 
 timestampdiff(month, o.LastModifiedDate, utc_timestamp()) as 'Aging Last Modified (Months)',
 if(timestampdiff(month, o.createdDate, utc_timestamp())>=4, '4+', timestampdiff(month, o.createdDate, utc_timestamp())) as 'Aging Created (Buckets)',
 if(o.Region__c = 'Asia Pacific', 'APAC', o.Region__c) as 'Region',
 o.Country__c as 'Country',
 o.Portfolio__c as 'Portfolio',
 '' as 'Stream',
 a.Industry as 'Industry',
 a.Industry_Vertical__c as 'Industry Vertical',
 '' as 'Owner Role',
 if(o.Revenue_Date__c < now(), 'Out of Date', 'Current') as 'Pipeline Status',
 o.Probability/100 as 'Probability',
 o.Probability/100*round(o.Amount/ct.ConversionRate,2) as 'Revenue Forecast (AUD)',
 ifnull(o.Probability/100*round(o.Global_ACV__c/ct.ConversionRate,2),0) as 'ACV Forecast (AUD)'
from training.opportunity o
	left join training.recordtype rt on o.RecordTypeId = rt.Id
    left join training.account a on o.AccountId = a.Id
	left join training.user oo on o.OwnerId = oo.Id
    left join training.user oom on oo.ManagerId = oom.Id
    left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
where
	o.IsDeleted = 0
	and o.Stages__c not like '%closed%'
    and o.CloseDate >= '2015-07-01'
    and o.CloseDate < date_add(now(), interval 6 month)
    and rt.Name in ('ENT - APAC - Opportunity (In House)', 'ENT - APAC - Opportunity (Marketing)', 'ENT - APAC - Opportunity (Public)')
);

#Lead conversion:
#	a. Lead to opportunity
#	b. Opportunity to closed won
#	c. By person

# Compass
use analytics;
#explain
(select
	analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
    substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
    if(l.Id is null, FALSE, TRUE) as 'Opportunity From Lead',
	l.Id as 'Lead Id', 
	l.Name 'Lead', 
	l.CreatedDate 'Lead Created Date', 
	l.ConvertedDate as 'Lead Converted Date', 
	o.Id as 'Opportunity Id', 
	o.Name as 'Opportunity', 
	u.Name as 'Opp Owner', 
	o.CreatedDate as 'Opp Created Date', 
	o.StageName as 'Stage', 
	o.CloseDate as 'Close Date', 
	o.Total_First_Year_Revenue__c as 'First Year Revenue', 
	o.Amount as 'Amount', 
	o.CurrencyIsoCode as 'Currency',
    o.LeadSource, 
    o.Lead_Type__c,
    max(if(ofh.NewValue='Needs Analysis', ofh.CreatedDate, 0)) as 'Needs Analysis Date',
    max(if(ofh.NewValue='Sales Duration Review', ofh.CreatedDate, 0)) as 'Sales Duration Review Date',
    max(if(ofh.NewValue='Proposal Sent', ofh.CreatedDate, 0)) as 'Proposal Sent Date',
    max(if(ofh.NewValue='Negotiation/Review', ofh.CreatedDate, 0)) as 'Negotiation Review Date',
    max(if(ofh.NewValue='Closed Lost', ofh.CreatedDate, 0)) as 'Closed Lost Date',
    max(if(ofh.NewValue='Closed Won', ofh.CreatedDate, 0)) as 'Closed Won Date'
from salesforce.opportunity o
	left join salesforce.opportunityfieldhistory ofh on ofh.OpportunityId = o.Id and ofh.Field = 'StageName' and ofh.IsDeleted = 0
    #left join salesforce.opportunityhistory oh on oh.OpportunityId = o.Id
	inner join salesforce.account a on o.AccountId = a.Id
    inner join salesforce.user u on o.Opportunity_Owner__c = binary left(u.Id,15)
    left join salesforce.lead l on l.ConvertedOpportunityId = o.Id and l.IsDeleted = 0 
where 
	o.isDeleted = 0
	and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = 'APAC'
group by o.Id);
    
    
(select
	analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
    substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
	o.Id as 'Opportunity Id', 
	o.Name as 'Opportunity', 
	u.Name as 'Opp Owner', 
	o.CreatedDate as 'Opp Created Date', 
	o.StageName as 'Stage', 
	o.CloseDate as 'Close Date', 
	o.Total_First_Year_Revenue__c as 'First Year Revenue', 
	o.Amount as 'Amount', 
	o.CurrencyIsoCode as 'Currency',
    o.LeadSource, 
    o.Lead_Type__c,
    ofh.OldValue, 
    ofh.NewValue, 
    ofh.CreatedDate
from salesforce.opportunity o
	inner join salesforce.opportunityfieldhistory ofh on ofh.OpportunityId = o.Id and ofh.Field = 'StageName' and ofh.IsDeleted = 0
	inner join salesforce.account a on o.AccountId = a.Id
    inner join salesforce.user u on o.Opportunity_Owner__c = binary left(u.Id,15)
where 
	o.isDeleted = 0
	and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = 'APAC'
order by o.Id, ofh.CreatedDate)
union all
(select
	analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) as 'Region',
    substring_index(a.Client_Ownership__c,' - ',-1) as 'Country',
	o.Id as 'Opportunity Id', 
	o.Name as 'Opportunity', 
	u.Name as 'Opp Owner', 
	o.CreatedDate as 'Opp Created Date', 
	o.StageName as 'Stage', 
	o.CloseDate as 'Close Date', 
	o.Total_First_Year_Revenue__c as 'First Year Revenue', 
	o.Amount as 'Amount', 
	o.CurrencyIsoCode as 'Currency',
    o.LeadSource, 
    o.Lead_Type__c,
    'Created' as 'OldValue', 
    ifnull((select ofh.OldValue from salesforce.opportunityfieldhistory ofh where ofh.OpportunityId=o.Id and ofh.Field = 'StageName' and ofh.IsDeleted = 0 order by ofh.CreatedDate limit 1), o.StageName) as 'New Value', 
    o.CreatedDate
from salesforce.opportunity o
	inner join salesforce.account a on o.AccountId = a.Id
    inner join salesforce.user u on o.Opportunity_Owner__c = binary left(u.Id,15)
where 
	o.isDeleted = 0
	and analytics.getRegionFromCountry(substring_index(a.Client_Ownership__c,' - ',-1)) = 'APAC'
order by o.Id);

# Corporate Salesforce
use training;
create index lead_opportunity_index on training.lead(ConvertedOpportunityId);
#explain
(select
rt.Name as 'Record Type',
	if(o.Region__c = 'Asia Pacific', 'APAC', o.Region__c) as 'Region',
	o.Country__c as 'Country',
    if(l.Id is null, FALSE, TRUE) as 'Opportunity From Lead',
	l.Id as 'Lead Id', 
	l.Name 'Lead', 
	l.CreatedDate 'Lead Created Date', 
	l.ConvertedDate as 'Lead Converted Date', 
	o.Id as 'Opportunity Id', 
	o.Name as 'Opportunity', 
	u.Name as 'Opp Owner', 
	o.CreatedDate as 'Opp Created Date', 
	o.Stages__c as 'Stages', 
	o.CloseDate as 'Close Date', 
	'' as 'First Year Revenue', 
	o.Amount as 'Amount', 
	o.CurrencyIsoCode as 'Currency',
    o.LeadSource, 
    o.Lead_Type__c
from training.opportunity o
	left join training.recordtype rt on o.RecordTypeId = rt.Id
	left join training.opportunityfieldhistory ofh on ofh.OpportunityId = o.Id and ofh.Field = 'StageName' and ofh.IsDeleted = 0
    left join training.user u on o.OwnerId = u.Id
    left join training.lead l on l.ConvertedOpportunityId = o.Id and l.IsDeleted = 0 
where 
	o.isDeleted = 0
	and o.Stages__c like '%closed%'
    and (o.Type not like '%renewal%' or o.Type  is null)
	and (o.New_or_Renewal__c not like '%Ren%' or o.New_or_Renewal__c is null)
	and (
		(rt.Name in ('Compliance Asia Pacific Opportunity Record Type','ENT - APAC - Opportunity (In House)','PUB - APAC - Oppty') and (o.Type not like '%cls%' or o.Type is null) and (o.Type not like '%copy%' or o.Type is null) ) 
        or 
        (rt.Name in ('CMPL - APAC - Opportunity Record Type') and o.Type like '%BV%')
		)
#group by o.Id
);

describe training.opportunityfieldhistory;
