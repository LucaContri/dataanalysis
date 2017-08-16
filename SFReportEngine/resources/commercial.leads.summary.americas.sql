set @now = (select utc_timestamp());
set @week_start = (select date_format(date_add(@now, interval -WEEKDAY(@now) day), '%Y-%m-%d'));
set @period_1_start = (select date_add(@now, interval -1 month));
set @period_1_end = (select @now);
set @period_2_start = (select date_add(@now, interval -12 month));
set @period_2_end = (select @now);

select @period_1_start, @period_1_end, @period_2_start, @period_2_end;
(select 
 if(rt.Name = ('Compliance Americas Lead Record Type'), 
	if(l.Solution_Type__c = 'Learning', 'Learning', 'Risk'), 
    if(rt.Name = 'AS-AMER', 'Assurance', 
		if(rt.name in ('TIS - AMER - Lead (IH)', 'TIS - AMER - Lead (Marketing)', 'TIS - AMER - Lead (Public)', 'TIS - AMER - Lead (Web)'), 
			'Learning',
            if(rt.name in ('PUB-US', 'PUB-US-Marketing Leads'), 'Knowledge', '?')
		)
    )) as 'Product Portfolio', 
 rt.Name as 'Record Type', 
 ifnull(l.Solution_Type__c, '') as 'Solution Type',
 l.Id as 'Lead Id', 
 l.Title,
 l.Name as 'Lead Name', 
 l.Company,
 l.Email,
 l.Rating,
 l.State,
 l.Country,
 l.createdDate, 
 timestampdiff(day, l.CreatedDate, utc_timestamp()) as 'Ageing',
 if(timestampdiff(month, l.CreatedDate, utc_timestamp())>=4, '4+', timestampdiff(month, l.CreatedDate, utc_timestamp())) as 'Ageing (Month)',
 l.LeadSource as 'Source', 
 getLeadSourceCategorySimple(l.LeadSource) as 'Lead Source Category Simple',
 getLeadSourceCategory(l.LeadSource) as 'Lead Source Category',
 l.Status as 'Status', 
 analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) as 'Status Simple',
 l.Area_s_of_Interest__c ,
 ifnull(o.Name, og.Name) as 'Owner', 
 m.Name as 'Manager',
 mm.Name as 'Manager\'s Manager',
    l.Industry as 'Industry',
 l.Industry_Vertical__c as 'Industry Vertical', 
 l.Program__c as 'Program',
 l.IsConverted,
 #if(opp.Id is not null,
 # if(opp.Stages__c like '%Won%',1,0),
 # if(l.IsConverted,
 #  if(rt.Name = 'TIS APAC Lead Record Type',1,
 #   if(group_concat(opp_acc.Stages__c) like '%Won%',1,0)
 #  ),
 #  0
 # )
 #) as 'HasGeneratedOpportunityWon',
 if(opp.Stages__c like '%Won%',1,
  if(rt.Name like 'TIS%' and r.Id is not null,1,0)
 ) as 'HasGeneratedOpportunityWon',
 if(opp.Stages__c like '%Lost%',1,0) as 'HasGeneratedOpportunityLost',
 l.ConvertedDate,
 #ifnull(
 # if(opp.Id is not null,
 #  if(opp.Stages__c like '%Won%',opp.CloseDate,''),
 #   if(l.IsConverted,
 #    if(rt.Name = 'TIS APAC Lead Record Type',l.ConvertedDate,
 #     if(group_concat(opp_acc.Stages__c) like '%Won%',min(if(opp_acc.Stages__c like '%Won%', opp_acc.CloseDate,null)),'')
 #   ),
 #  ''
 # )
 #),'') as 'Closed Won Date',
    if(opp.Stages__c like '%Won%',opp.CloseDate,
  ifnull(min(if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,r.CreatedDate ,null)),'')
    ) as 'Closed Won Date',
 #timestampdiff(day, l.ConvertedDate, 
 # if(opp.Id is not null,
 #  if(opp.Stages__c like '%Won%',opp.CloseDate,null),
 #  if(l.IsConverted,
 #   if(rt.Name = 'TIS APAC Lead Record Type',l.ConvertedDate,
 #    if(group_concat(opp_acc.Stages__c) like '%Won%',min(if(opp_acc.Stages__c like '%Won%', opp_acc.CloseDate,null)),null)
 #   ),
 #   null
 #  )
 # )
 #) as 'Converted To Won Days',
    timestampdiff(day, l.ConvertedDate, 
  if(opp.Stages__c like '%Won%',opp.CloseDate,
   min(if(rt.Name like 'TIS%' and r.Id is not null,r.CreatedDate ,null))
        )
 ) as 'Converted To Won Days',
    if(opp.Stages__c like '%Won%', opp.Global_ACV__c/ct.ConversionRate, 0) as 'ACV (AUD)',
 if(l.CreatedDate between @period_1_start and @period_1_end, true, false) as 'Period 1',
 if(l.CreatedDate between @period_2_start and @period_2_end, true, false) as 'Period 2',
 if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) in ('Archived', 'Converted', 'Qualified'), false, true) as 'isWIP',
 if(l.isConverted and l.ConvertedDate>=@week_start,1,0) as 'IsConvertedLastWeek',
 if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) = 'Open' and timestampdiff(day, l.CreatedDate, utc_timestamp())>2,true,false) as 'NotAddressedWithinTwoDays'
from training.lead l
 left join training.user o on l.OwnerId = o.Id
 left join training.`group` og on l.OwnerId = og.Id
 left join training.user m on o.ManagerId = m.Id
    left join training.user mm on m.ManagerId = mm.Id
 left join training.recordtype rt on l.RecordTypeId = rt.Id
 left join training.opportunity opp on opp.Id = l.ConvertedOpportunityId
    left join salesforce.currencytype ct on opp.CurrencyIsoCode = ct.IsoCode
    left join training.contact c on l.ConvertedContactId = c.Id
    left join training.registration__c r on r.Attendee__c = c.Id and r.Status__c = 'Confirmed' and r.IsDeleted = 0
 #left join training.account acc on acc.Id = l.ConvertedAccountId
 #left join training.opportunity opp_acc on opp_acc.AccountId = acc.Id    
where 
 l.IsDeleted = 0 
 and (l.CreatedDate >= least(@period_1_start, @period_2_start) and l.CreatedDate <= greatest(@period_1_end, @period_2_end) )
 and rt.Name in ('Compliance Americas Lead Record Type', 'AS-AMER', 'TIS - AMER - Lead (IH)', 'TIS - AMER - Lead (Marketing)', 'TIS - AMER - Lead (Public)', 'TIS - AMER - Lead (Web)', 'PUB-US', 'PUB-US-Marketing Leads')
group by l.Id
);

(select rt.name, date_format(l.createdDate, '%Y-%m') as 'Period', count(l.Id) 
from training.lead l 
inner join training.recordtype rt on l.RecordTypeId = rt.Id group by rt.Name, `Period`);