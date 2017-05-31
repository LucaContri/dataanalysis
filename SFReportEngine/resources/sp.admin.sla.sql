use analytics;
drop table analytics.sla_admin_newbusiness;
drop procedure analytics.SlaUpdateAdminNewBusiness;
DELIMITER //
CREATE PROCEDURE analytics.SlaUpdateAdminNewBusiness()
 BEGIN
 declare sla_business_days int;
 declare start_time datetime;
 set start_time = utc_timestamp();
 set sla_business_days = 5;
 
 truncate analytics.sla_admin_newbusiness;
 insert into analytics.sla_admin_newbusiness 
   (select * from (
(SELECT 
 if(o.Manual_Certification_Finalised__c=0 and o.Delivery_Strategy_Created__c is null and t.Id is not null, 'Commercial', 'Admin') as 'Team',
 'New Business Setup' as 'Activity',
 o.Business_1__c as 'Region',
 sites.Time_Zone__c as 'TimeZone',
 if(group_concat(distinct if(oli.IsDeleted=0,p.Business_Line__c, null) separator ';') like '%Food%', 'Food', 'MS') as 'Details',
 'AS NewBus-01' as 'Enlighten Activity Code',
 'Opportunity' as 'Id Type',
 o.Id as 'Id',
  o.Quote_Ref__c as 'Name',
 max(if(oh.Field not in ('StageName'), u.Name, '')) as 'Owner',
 'Opportunity Won' as 'Aging Type',
 max(if (oh.Field = 'StageName' AND oh.NewValue = 'Closed Won', oh.createdDate, null)) as 'From',
 #date_add(max(if (oh.Field = 'StageName' AND oh.NewValue = 'Closed Won', oh.createdDate, null)), interval 2 day) as `SLA Due`,
 getSLADueUTCTimestamp(
	max(if (oh.Field = 'StageName' AND oh.NewValue = 'Closed Won', oh.createdDate, null)),
    replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-',''),
    sla_business_days) as `SLA Due`,
 if(o.Delivery_Strategy_Created__c is not null, o.Delivery_Strategy_Created__c , # Auto Finalised
	if (o.Manual_Certification_Finalised__c, #Manual Finalised
		if(max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null)) is null,'n/a',max(if (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true', oh.createdDate, null))),
        null # Not yet finalised
	)) AS 'To',
    group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') as 'Tags'
FROM salesforce.opportunity o 
left join salesforce.task t on t.WhatId = o.Id and t.RecordTypeId = '012d0000001clmNAAQ' and t.Status not in ('Completed')
INNER JOIN salesforce.account a on o.AccountId = a.Id
INNER JOIN salesforce.account sites on sites.ParentId = a.Id
LEFT JOIN salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.id 
LEFT JOIN salesforce.user u on oh.CreatedById = u.Id
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
left join salesforce.standard__c s on oli.Standard__c = s.Id
left join salesforce.program__c p on s.Program__c = p.Id
WHERE 
o.IsDeleted = 0 
AND o.Business_1__c NOT IN ('Product Services')
AND o.StageName = 'Closed Won' 
AND ((oh.Field = 'StageName' AND oh.NewValue = 'Closed Won') OR (oh.Field = 'Manual_Certification_Finalised__c' AND oh.NewValue = 'true') OR (oh.Field = 'Delivery_Strategy_Created__c')) 
#AND o.Type like 'New%'
GROUP BY o.id
) union (
SELECT 
if(o.StageName = 'Negotiation/Review' and t.Id is not null, 'Commercial', 'Admin') as 'Team', 
 'New Business Setup' as 'Activity',
 o.Business_1__c as 'Region',
 sites.Time_Zone__c as 'TimeZone',
 'PS' as 'Details',
 'AS NewBus-01' as 'Enlighten Activity Code',
 'Opportunity' as 'Id Type',
 o.Id as 'Id',
  o.Quote_Ref__c as 'Name',
 max(if(oh.Field = 'StageName' and oh.NewValue = 'Closed Won', u.Name, null)) as 'Owner',
 'Opportunity Won' as 'Aging Type',
 MAX(if (oh.NewValue='Negotiation/Review', oh.createdDate, null)) as 'From',
 getSLADueUTCTimestamp(
	max(if (oh.Field = 'StageName' AND oh.NewValue = 'Negotiation/Review', oh.createdDate, null)),
    replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-',''),
    sla_business_days) as `SLA Due`,
 if(max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)) is not null,
	max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)),
	null
)  AS 'To',
group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') as 'Tags'
FROM 
salesforce.opportunity o 
left join salesforce.task t on t.WhatId = o.Id and t.RecordTypeId = '012d0000001clmNAAQ' and t.Status not in ('Completed')
INNER JOIN salesforce.account a on o.AccountId = a.Id
INNER JOIN salesforce.account sites on sites.ParentId = a.Id
LEFT JOIN salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.id 
LEFT JOIN salesforce.user u on oh.CreatedById = u.Id
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
left join salesforce.standard__c s on oli.Standard__c = s.Id
WHERE 
o.IsDeleted = 0 
AND o.Business_1__c IN ('Product Services') 
AND o.StageName in ('Closed Won', 'Negotiation/Review') 
AND (oh.Field = 'StageName' AND oh.NewValue IN ('Closed Won' , 'Negotiation/Review'))
GROUP BY o.id)) t 
where t.`Team` = 'Admin');

insert into analytics.sp_log VALUES(null,'SlaUpdateAdminNewBusiness',utc_timestamp(), timestampdiff(MICROSECOND, start_time, utc_timestamp()));

 END //
DELIMITER ; 

select *, exec_microseconds/1000000 from analytics.sp_log where sp_name='SlaUpdateAdminNewBusiness' order by exec_time desc limit 10;

drop event SlaUpdateEventAdminNewBusiness;
CREATE EVENT SlaUpdateEventAdminNewBusiness
    ON SCHEDULE EVERY 20 minute DO 
		call SlaUpdateAdminNewBusiness();

select * from analytics.sla_admin_newbusiness;

drop function analytics.getSLADueUTCTimestamp;
DELIMITER //
CREATE FUNCTION analytics.getSLADueUTCTimestamp(utc_from datetime, timezone char(64), business_days INT) RETURNS datetime
BEGIN
	# Used to calculate SLA due dates in utc time.
    # Returns utc timestamp equal to end of business day @business_days business days after @utc_from in the timezone @timezone
    # Assumptions:
	#	1) Business days Mon - Fri regardless of timezone
    #	2) No public holidays
    #	3) Business hours 9.00 to 17:00 regardless of timezone
    #	4) if timezone is null we assume 'UTC'.
    DECLARE sla_due DATETIME;
    DECLARE timezone_from DATETIME;
    SET timezone = if(timezone is null, 'UTC', timezone);
    SET timezone_from = convert_tz(utc_from,'UTC',timezone);
    SET business_days = business_days - if (date_format(timezone_from, '%H%m')<'0900',1,0);
    SET sla_due = date_format(timezone_from, '%Y-%m-%d 17:00:00');
    WHILE business_days > 0 DO
		set sla_due = date_add(sla_due, interval 1 day);
        set business_days = business_days - if(date_format(sla_due, '%W') in ('Saturday','Sunday'),0,1);
	END WHILE;
    
    RETURN convert_tz(sla_due, timezone, 'UTC');
 END //
DELIMITER ;

select convert_tz('2015-06-18 20:39:20','utc','Pacific/Auckland');
select convert_tz('2015-06-16 17:00:00','Australia/Sydney','UTC');
select analytics.getSLADueUTCTimestamp('2014-07-06 11:40:46','Australia/Sydney',1);

select date_format(date_time(now(), interval 1 day), '%W');
select analytics.getSLADueUTCTimestamp(date_add(utc_timestamp(),interval 2 hour), 'Australia/Sydney',1); # Should return end of Friday in Sydney
select analytics.getSLADueUTCTimestamp(date_add(utc_timestamp(),interval 2 hour), 'Australia/Sydney',2); # Should return end of Monday in Sydney

select * from analytics.sla_admin_newbusiness where `To` is not null and `from` > '2014' and `Region` in ('Product Services');
use salesforce;
create index opportunity_account_index on opportunity(AccountId);
select * from (
SELECT 
'Admin' as 'Team',
 'New Business Setup' as 'Activity',
 o.Business_1__c as 'Region',
 'PS' as 'Details',
 'AS NewBus-01' as 'Enlighten Activity Code',
 'Opportunity' as 'Id Type',
 o.Id as 'Id',
 max(if(oh.Field = 'StageName' and oh.NewValue = 'Closed Won', u.Name, null)) as 'Owner',
 'Opportunity Won' as 'Aging Type',
 MAX(if (oh.NewValue='Negotiation/Review', oh.createdDate, null)) as 'From',
 replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-','') as 'TZ1',
 max(if (sites.Finance_Statement_Site__c=1,sites.Time_Zone__c,'')) as 'TZ2',
 getSLADueUTCTimestamp(
	max(if (oh.Field = 'StageName' AND oh.NewValue = 'Negotiation/Review', oh.createdDate, null)),
    replace(min(if (sites.Finance_Statement_Site__c=1,concat('1-',sites.Time_Zone__c),sites.Time_Zone__c)),'1-',''),
    5) as `SLA Due`,
 #date_add(max(if (oh.Field = 'StageName' AND oh.NewValue = 'Negotiation/Review', oh.createdDate, null)), interval 2 day) as 'SLA Due',
 if(max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)) is not null,
	max(IF(oh.NewValue = 'Closed Won', oh.createdDate, NULL)),
	null
)  AS 'To',
group_concat(distinct if(oli.IsDeleted=0,s.Name, null) separator ';') as 'Tags'
FROM 
salesforce.opportunity o 
INNER JOIN salesforce.account a on o.AccountId = a.Id
INNER JOIN salesforce.account sites on sites.ParentId = a.Id
LEFT JOIN salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.id 
LEFT JOIN salesforce.user u on oh.CreatedById = u.Id
left join salesforce.opportunitylineitem oli on oli.OpportunityId = o.Id
left join salesforce.standard__c s on oli.Standard__c = s.Id
WHERE 
o.IsDeleted = 0 
#AND o.Business_1__c IN ('Product Services') 
AND o.StageName in ('Closed Won', 'Negotiation/Review') 
AND (oh.Field = 'StageName' AND oh.NewValue IN ('Closed Won' , 'Negotiation/Review'))
GROUP BY o.id) t
where t.`from` > '2015'
and t.`TZ1` is null;