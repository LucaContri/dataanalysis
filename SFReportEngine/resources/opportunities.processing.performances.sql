(select 
 t1.*,
 if(t1.`To` is null, 'WIP', 'Performance') as 'Metric Type',
 if(t1.`From`>='2016-08-25','Current','Backlog') as 'Metric SubType',
 ifnull(max(if(t.Status not in ('Completed'), tu.Name, null)), '') as 'Current Task Owner',
 ifnull(max(if(t.Status not in ('Completed'), t.Return_reason__c, null)), '') as 'Current Task Return Reason',
 count(distinct t.Id) as '# Return Tasks',
 count(distinct if(t.Status not in ('Completed'), t.Id, null)) as '# Outstanding tasks',
 count(distinct if(t.Return_reason__c like '%Waiting for Woolworths%', t.Id, null)) as '# Woolworths Return Tasks',
    count(distinct if(t.Return_reason__c like '%Pending Credit Control%', t.Id, null)) as '# Finance Return Tasks',
    count(distinct if(t.Return_reason__c like '%Regional desk%', t.Id, null)) as '# Regional Desk Return Tasks',
    count(distinct if(t.Return_reason__c like '%Pending PRC review%', t.Id, null)) as '# PRC Return Tasks',
    count(distinct if(t.Return_reason__c not like '%Waiting for Woolworths%' and
    t.Return_reason__c not like '%Pending Credit Control%' and
    t.Return_reason__c not like '%Regional Desk%' and
    t.Return_reason__c not like '%Pending PRC review%',t.Id,null)) as '# Sales Return Tasks',
 if(count(distinct t.Id)>=3,'3+', cast(count(distinct t.Id) as char(1))) as '# Return Tasks Group',
 ifnull(group_concat(distinct t.Return_reason__c order by t.Return_reason__c),'') as 'Return Reasons',
 ifnull(sum(timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24),0) as 'Return Tasks Processing Time',
 ifnull(sum(if(t.Return_reason__c like '%Waiting for Woolworths%', timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24,0)),0) as 'Woolworths Processing Time',
 ifnull(sum(if(t.Return_reason__c like '%Pending Credit Control%', timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24,0)),0) as 'Finance Processing Time',
 ifnull(sum(if(t.Return_reason__c like '%Regional desk%', timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24,0)),0) as 'Regional Desk Processing Time',
 ifnull(sum(if(t.Return_reason__c like '%Pending PRC review%', timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24,0)),0) as 'PRC Processing Time',
 ifnull(sum(if( t.Return_reason__c not like '%Waiting for Woolworths%' and
    t.Return_reason__c not like '%Pending Credit Control%' and
    t.Return_reason__c not like '%Regional Desk%' and
    t.Return_reason__c not like '%Pending PRC review%', 
                timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24,0)),0) as 'Sales Processing Time',
 timestampdiff(second, t1.`from`, ifnull(t1.`to`, utc_timestamp()))/60/60/24 as 'Aging',
 timestampdiff(second, t1.`from`, ifnull(t1.`to`, utc_timestamp()))/60/60/24 - ifnull(sum(timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24),0) as 'Aging Admin',
 date_format(t1.`To`, '%Y %m') as 'Month To',
 date_format(t1.`To`, '%Y %u') as 'Week To',
 if(t1.`To` is not null,
 '',
 if(t1.`Team` = 'Admin',
 concat('Opty\'s to be processed - ',t1.`Stream`),
 if(max(if(t.Status not in ('Completed'), t.Return_reason__c, null)) like '%Waiting for Woolworths%', 'On Hold - Woolworths review',
  if(max(if(t.Status not in ('Completed'), t.Return_reason__c, null)) like '%Pending Credit Control%', 'On Hold - Finance review',
  if(max(if(t.Status not in ('Completed'), t.Return_reason__c, null)) like '%Regional desk%', 'On Hold - Regional Desk review',
  if(max(if(t.Status not in ('Completed'), t.Return_reason__c, null)) like '%Pending PRC review%', 'On Hold - PRC review',
   'On Hold - Returns to Sales'
 )))))) as 'Backlog Type',
 1 as 'Volume',
 if(t1.`To` is not null and t1.`To` < t1.`SLA Due`,1,0) as 'Within SLA',
    if(timestampdiff(second, t1.`from`, ifnull(t1.`to`, utc_timestamp()))/60/60/24 - ifnull(sum(timestampdiff(second, t.createdDate, if(t.Status = 'Completed', t.LastModifiedDate, utc_timestamp()))/60/60/24),0)<=7,1,0) as 'Within Admin SLA'
from (
 (SELECT 
 if (o.createdDate < '2016-08-29',
  if(o.Manual_Certification_Finalised__c=0 and o.Delivery_Strategy_Created__c is null and t.Id is not null , 'Commercial', 'Admin'),
  if(o.Manual_Certification_Finalised__c=0 and t.Id is not null , 'Commercial', 'Admin')
  ) as 'Team',
  o.Business_1__c as 'Region',
  sites.Time_Zone__c as 'TimeZone',
  if(group_concat(distinct if(oli.IsDeleted=0,p.Business_Line__c, null) separator ';') like '%Food%', 'Food', 'MS') as 'Stream',
  ow.Name as 'Opp. Owner',
  o.Id as 'Opportunity Id',
  o.Quote_Ref__c as 'Quote Ref.',
  o.Total_First_Year_Revenue__c/ct.ConversionRate as 'First Year Revenue (AUD)',
  max(if(oh.Field not in ('StageName'), u.Name, '')) as 'Processed By',
  'Opportunity Won' as 'Aging Type',
  max(if (oh.Field = 'StageName' AND oh.NewValue = 'Closed Won', oh.createdDate, null)) as 'From',
  getSLADueUTCTimestamp(
   max(if (oh.Field = 'StageName' AND oh.NewValue = 'Closed Won', oh.createdDate, null)),
   replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-',''),
   5) as 'SLA Due',
   if(o.createdDate<'2016-08-29',
		# Old Process
		if(o.Delivery_Strategy_Created__c is not null, o.Delivery_Strategy_Created__c , # Auto Finalised
			if(o.Manual_Certification_Finalised__c, #Manual Finalised
				if(max(if(oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null)) is null,
				'n/a',
				max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null))),
			null # Not yet finalised
			)
		),
		# New Process
        if(o.Manual_Certification_Finalised__c, #Manual Finalised
			if(max(if(oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null)) is null,
				'n/a', # We should never fall here.  Manually certified but missing action date from history
				max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null))),
			null # Not yet finalised
		)
	) AS 'To',
  group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') as 'Standards',
  if(group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%Woolworths%' or 
   group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%WQA%' or
   group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%WW%', 1, 0) as 'WQA'
 FROM salesforce.opportunity o 
  inner join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
  left join salesforce.task t on t.WhatId = o.Id and t.RecordTypeId = '012d0000001clmNAAQ' and t.Status not in ('Completed') and t.IsDeleted = 0
  inner join salesforce.user ow on o.OwnerId = ow.Id
  left join salesforce.userrole ur on ow.UserRoleId = ur.Id
  inner join salesforce.account a on o.AccountId = a.Id
  inner join salesforce.account sites on sites.ParentId = a.Id
  left join salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.id
  left join salesforce.user u on oh.CreatedById = u.Id
  left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
  left join salesforce.standard__c s on oli.Standard__c = s.Id
  left join salesforce.program__c p on s.Program__c = p.Id
 where  
  o.IsDeleted = 0 
  and o.Business_1__c in ('Australia')
  and ur.Name not in ('Client Services Team','Client Services Team Leader')
  and o.StageName = 'Closed Won' 
  and ((oh.Field = 'StageName' and oh.NewValue = 'Closed Won') or (oh.Field = 'Manual_Certification_Finalised__c' and oh.NewValue = 'true') or (oh.Field = 'Delivery_Strategy_Created__c')) 
  and o.Type not like '%Non-Certification%'
 group by o.id
 ) union (
 SELECT 
  if (o.createdDate < '2016-08-29',
	if(o.StageName = 'Negotiation/Review' and t.Id is not null, 'Commercial', 'Admin'),
    if(o.Manual_Certification_Finalised__c=0 and t.Id is not null , 'Commercial', 'Admin')
  ) as 'Team', 
  o.Business_1__c as 'Region',
  sites.Time_Zone__c as 'TimeZone',
  'PS' as 'Stream',
  ow.Name as 'Opp Owner',
  o.Id as 'Opportunity Id',
  o.Quote_Ref__c as 'Quote Ref.',
  o.Total_First_Year_Revenue__c/ct.ConversionRate as 'First Year Revenue',
  max(if(oh.Field = 'StageName' and oh.NewValue = 'Closed Won', u.Name, null)) as 'Processed By',
  'Opportunity Won' as 'Aging Type',
  ifnull(max(if(oh.Field = 'StageName' AND oh.NewValue='Negotiation/Review', oh.createdDate, null)), o.CloseDate) as 'From',
  getSLADueUTCTimestamp(
   ifnull(max(if(oh.Field = 'StageName' AND oh.NewValue='Negotiation/Review', oh.createdDate, null)), o.CloseDate),
   replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-',''),
   5) as 'SLA Due',
   if(o.createdDate<'2016-08-29',
		# Old Process
		if(max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)) is not null,
			max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)),
			null),
		# New Process
		if(o.Manual_Certification_Finalised__c, #Manual Finalised
			if(max(if(oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null)) is null,
				'n/a', # We should never fall here.  Manually certified but missing action date from history
				max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null))),
			null # Not yet finalised
		)
  ) AS 'To',
  group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') as 'Standards',
  if(group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%Woolworths%' or 
   group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%WQA%' or
   group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') like '%WW%', 1, 0) as 'WQA'
 from salesforce.opportunity o 
  inner join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
  left join salesforce.task t on t.WhatId = o.Id and t.RecordTypeId = '012d0000001clmNAAQ' and t.Status not in ('Completed') and t.IsDeleted = 0
  inner join salesforce.user ow on o.OwnerId = ow.Id
  left join salesforce.userrole ur on ow.UserRoleId = ur.Id
  inner join salesforce.account a on o.AccountId = a.Id
  inner join salesforce.account sites on sites.ParentId = a.Id
  left join salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.id 
  left join salesforce.user u on oh.CreatedById = u.Id
  left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
  left join salesforce.standard__c s on oli.Standard__c = s.Id
 where o.IsDeleted = 0 
  and o.Type not like '%Non-Certification%'
  and o.Business_1__c in ('Product Services') 
  and o.StageName in ('Closed Won', 'Negotiation/Review') 
  and ur.Name not in ('Client Services Team','Client Services Team Leader')
  and ((oh.Field = 'StageName' and oh.NewValue in ('Closed Won' , 'Negotiation/Review')) or (oh.Field = 'Manual_Certification_Finalised__c' and oh.NewValue = 'true'))
 group by o.id)) t1 
 left join salesforce.task t on t.WhatId = t1.`Opportunity Id` and t.RecordTypeId = '012d0000001clmNAAQ' and t.IsDeleted = 0
 left join salesforce.user tu on t.OwnerId = tu.Id
where t1.`To` not in ('n/a')
 and t1.`To` >= '2016-01-01'
 or (t1.`To` is null and t1.`From`>='2015-01-01')
group by t1.`Opportunity Id`);