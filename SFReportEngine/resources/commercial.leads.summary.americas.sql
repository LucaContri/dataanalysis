(select 
 if(rt.Name in ('CMPL - APAC - Lead Record Type'), 'Risk', if(rt.Name in ('IS - APAC - Lead - Marketing','PUB - APAC - Lead - General','PUB - APAC - Lead - Newsletters', 'Compliance Asia Pacific Lead Record Type'), 'Knowledge', if(rt.Name in ('TIS APAC Lead Record Type'), 'Learning', '?'))) as 'Product Portfolio', 
 rt.Name as 'Record Type', 
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
  if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,1,0)
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
   min(if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,r.CreatedDate ,null))
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
 and (l.CreatedDate >= least(@period_1_start, @period_2_start) )
 and rt.Name in ('CMPL - APAC - Lead Record Type', 'Compliance Asia Pacific Lead Record Type', 'IS - APAC - Lead - Marketing', 'PUB - APAC - Lead - General', 'PUB - APAC - Lead - Newsletters','TIS APAC Lead Record Type')
group by l.Id
);