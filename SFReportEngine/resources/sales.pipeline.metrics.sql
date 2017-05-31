use salesforce;
drop function salesforce.getSimpleLeadSource;
DELIMITER //
CREATE FUNCTION salesforce.getSimpleLeadSource(LeadSource VARCHAR(64)) RETURNS VARCHAR(64)
BEGIN
	DECLARE simpleLeadSource VARCHAR(64) DEFAULT "";
    SET simpleLeadSource = (SELECT 
		IF (LeadSource is null, null,
        IF (LeadSource in ('Website/Contact us'), 'Website',
		IF (LeadSource in ('Direct call/email'), 'Call/Email',
        'Relationships'
		))));
		#IF (LeadSource in ('SAIG Internal referral','Auditor referral - New client','Auditor relationship - Existing client','Employee Referral'), 'Internal Referral',
		#IF (LeadSource in ('BDM relationship','Existing client - BDM relationship'), 'BDM relationship',
		#IF (LeadSource in ('Consultants','External Referral'), 'External Referral',
		#'Others'
		#)))))));
	RETURN simpleLeadSource ;
 END //
DELIMITER ;

drop function training.getSimpleLeadSource;
DELIMITER //
CREATE FUNCTION training.getSimpleLeadSource(LeadSource VARCHAR(64)) RETURNS VARCHAR(64)
BEGIN
	DECLARE simpleLeadSource VARCHAR(64) DEFAULT "";
    SET simpleLeadSource = (SELECT 
		IF (LeadSource is null, null,
        IF (LeadSource like '%Website%' or LeadSource like '%Search%', 'Website',
		IF (LeadSource = 'TIS Online Feedback', 'Online Feedback',
        IF (LeadSource like '%call%' or LeadSource like '%email%' or LeadSource like '%e-mail%', 'Call/Email',
		'Networking'
		)))));
        #IF (LeadSource like '%referral', 'Internal Referral',
		#IF (LeadSource like '%SAI Global%', 'BDM relationship',
		#'Others'
		#)))))));
	RETURN simpleLeadSource ;
 END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION mitel.getSubStreamByQueue(queue VARCHAR(64)) RETURNS VARCHAR(64)
BEGIN
	DECLARE substream VARCHAR(64) DEFAULT "";
    SET substream = (SELECT 
		if(q.QueueName in ('MS Sales'), null, if(q.QueueName in ('Public Training'),'Public',if(q.queueName in ('InHouse'), 'In-house', 'eLearning'))) as 'SubStream',
		IF (queue in ('MS Sales'), null,
        IF (queue in ('Public Training'), 'Public',
		IF (queue in ('InHouse'), 'In-house',
		'eLearning'
		))));
	RETURN substream;
 END //
DELIMITER ;

create or replace view sales_pipeline_sub1 as (
select o.Id, o.Business_1__c, o.CreatedDate, o.LeadSource 
		from salesforce.opportunity o 
		where o.IsDeleted = 0
			and o.Status__c = 'Active'
            and o.StageName not in ('Budget')
			group by o.Id
);

create or replace view sales_pipeline_sub2 as (
select o.Id, o.Business_1__c, min(oh.CreatedDate) as 'CreatedDate', o.LeadSource 
		from salesforce.opportunity o 
        inner join salesforce.opportunityfieldhistory oh on oh.OpportunityId = o.Id
		where o.IsDeleted = 0
			and o.Status__c = 'Active'
            and o.StageName not in ('Budget')
            and oh.IsDeleted =0 
            and oh.Field = 'StageName'
            and oh.NewValue = 'Proposal Sent'
			group by o.Id);

create or replace view sales_pipeline_sub3 as (
select o.Id, o.Business_1__c, min(oh.CreatedDate) as 'CreatedDate', o.LeadSource 
		from salesforce.opportunity o 
        inner join salesforce.opportunityfieldhistory oh on oh.OpportunityId = o.Id
		where o.IsDeleted = 0
			and o.Status__c = 'Active'
            and o.StageName = 'Closed Won'
            and oh.IsDeleted = 0 
            and oh.Field = 'StageName'
            and oh.NewValue = 'Closed Won'
			group by o.Id);

create or replace view sales_pipeline_sub4 as (
select 
'Australia' as 'Region', 
'TIS' as 'Stream', 
if(rt.Name = 'ENT - APAC - Opportunity (Public)', 'Public', 'In-house') as 'SubStream', 
training.getSimpleLeadSource(o.LeadSource) as 'Source', 
date_format(o.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
null as 'Days',
sum(o.Amount) as 'Amount',
count(distinct o.Id) as 'Count'
from training.opportunity o
left join training.recordtype rt on o.RecordTypeId = rt.Id
where o.IsDeleted=0
and rt.Name in ('ENT - APAC - Opportunity (Public)','ENT - APAC - Opportunity (In House)')
group by `Region`,`Stream`, `SubStream`,`Source`, `Date (UTC)`);

create or replace view sales_pipeline_sub5 as 
select 'Leads Converted' as 'Name' 
union 
select 'Proposal Sent' as `Name`;

create or replace view sales_pipeline_sub6 as (
select o.Id, o.Amount, min(oh.CreatedDate) as 'CreatedDate', o.LeadSource, rt.Name
from training.opportunity o
inner join training.opportunityhistory oh on oh.OpportunityId = o.Id
left join training.recordtype rt on o.RecordTypeId = rt.Id
where o.IsDeleted=0
and o.StageName like '%Won%'
and rt.Name in ('ENT - APAC - Opportunity (Public)','ENT - APAC - Opportunity (In House)')
and oh.IsDeleted = 0
and oh.StageName like '%Won%'
group by o.Id);

create or replace view sales_pipeline_metrics as 
(select Business_1__c as 'Region', 'Certification' as 'Stream', pg.Business_Line__c as 'SubStream', salesforce.getSimpleLeadSource(t.LeadSource) as 'Source', 'Leads Converted' as 'Metric', date_format(t.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
sum(oli.Days__c) as 'Days',
sum(oli.TotalPrice) as 'Amount',
count(distinct t.Id) as 'Count'
from sales_pipeline_sub1 t
left join salesforce.opportunitylineitem oli on oli.OpportunityId = t.Id
left join salesforce.product2 p on oli.Product2Id = p.Id
left join salesforce.standard__c s on p.Standard__c = s.Id 
left join salesforce.program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
#and oli.Days__c>0 #Exclude Fees, only Audit
and oli.First_Year_Revenue__c =1
group by `Region`,`Stream`,`SubStream`, `Source`,`Metric`, `Date (UTC)`)
union
(select Business_1__c as 'Region', 'Certification' as 'Stream', pg.Business_Line__c as 'SubStream', salesforce.getSimpleLeadSource(t.LeadSource) as 'Source', 'Proposal Sent' as 'Metric', date_format(t.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
sum(oli.Days__c) as 'Days',
sum(oli.TotalPrice) as 'Amount',
count(distinct t.Id) as 'Count'
from sales_pipeline_sub2 t
left join salesforce.opportunitylineitem oli on oli.OpportunityId = t.Id
left join salesforce.product2 p on oli.Product2Id = p.Id
left join salesforce.standard__c s on p.Standard__c = s.Id 
left join salesforce.program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
and oli.First_Year_Revenue__c =1
group by `Region`,`Stream`,`SubStream`, `Source`,`Metric`, `Date (UTC)`)
union
(select Business_1__c as 'Region', 'Certification' as 'Stream', pg.Business_Line__c as 'SubStream', salesforce.getSimpleLeadSource(t.LeadSource) as 'Source', 'Closed Won' as 'Metric', date_format(t.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
sum(oli.Days__c) as 'Days',
sum(oli.TotalPrice) as 'Amount',
count(distinct t.Id) as 'Count'
from sales_pipeline_sub3 t
left join salesforce.opportunitylineitem oli on oli.OpportunityId = t.Id
left join salesforce.product2 p on oli.Product2Id = p.Id
left join salesforce.standard__c s on p.Standard__c = s.Id 
left join salesforce.program__c pg on s.Program__c = pg.Id 
where oli.IsDeleted=0
and oli.First_Year_Revenue__c =1
group by `Region`,`Stream`,`SubStream`, `Source`,`Metric`, `Date (UTC)`)
union
(select t.`Region`,t.`Stream`, t.`SubStream`,t.`Source`,m.Name as `Metric`, t.`Date (UTC)`, t.`Days`, t.`Amount`, t.`Count` from 
sales_pipeline_sub4 t, sales_pipeline_sub5 m)
union
(select 'Australia' as 'Region', 'TIS' as 'Stream', if(t.Name = 'ENT - APAC - Opportunity (Public)', 'Public', 'In-house') as 'SubStream', training.getSimpleLeadSource(t.LeadSource) as 'Source', 'Closed Won' as 'Metric', date_format(t.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
null as 'Days',
sum(t.Amount) as 'Amount',
count(distinct t.Id) as 'Count' 
from sales_pipeline_sub6 t
group by `Region`,`Stream`, `SubStream`,`Metric`,`Source`, `Date (UTC)`)
union
(select l.Business__C as 'Region', 'Certification' as 'Stream', null as 'SubStream', salesforce.getSimpleLeadSource(l.LeadSource) as 'Source', 'Leads Created' as 'Metric',  date_format(l.CreatedDate, '%Y-%m-%d') as 'Date (UTC)', 
null as 'Days',
null as 'Amount',
count(distinct l.Id) as 'Count'
from salesforce.Lead l
where l.IsDeleted = 0
group by `Region`,`Stream`, `SubStream`,`Source`,`Metric`, `Date (UTC)`)
union
(select 'Australia' as 'Region', 'TIS' as 'Stream', if(l.ENT_APAC_Lead_Layout_Web__c is null, 'Public', if(l.ENT_APAC_Lead_Layout_Web__c like '%Public%', 'Public', 'In-house')) as 'SubStream', training.getSimpleLeadSource(l.LeadSource) as 'Source', 'Leads Created' as 'Metric',  date_format(l.CreatedDate, '%Y-%m-%d') as 'Date (UTC)', 
null as 'Days',
null as 'Amount',
count(distinct l.Id) as 'Count'
from training.Lead l
inner join training.recordtype rt on l.RecordTypeId = rt.Id
where l.IsDeleted = 0
and (rt.Name like 'ENT - APAC%' or rt.Name = 'TIS APAC Lead Record Type')
group by `Region`,`Stream`, `SubStream`, `Source`,`Metric`, `Date (UTC)`)
union
(select 'Australia' as 'Region', 'TIS' as 'Stream', if(r.Course_Type__c = 'eLearning', 'eLearning', if(r.Class_Type__c='Public Class', 'Public', 'In-house')) as 'SubStream', 
if(cb.Name='CastIron User','Online', r.Registration_Method__c) as 'Source', 'Registration' as 'Metric', 
date_format(r.CreatedDate, '%Y-%m-%d') as 'Date (UTC)',
sum(datediff(Class_End_Date__c, Class_Begin_Date__c)+1) as 'Days',
sum(i.PSoft_Inv_Amt__c) as 'Amount',
count(distinct r.Id) as 'Count'
from training.registration__c r
inner join training.recordtype rt on r.RecordTypeId = rt.Id
inner join training.invoice_ent__c i on i.Registration__c = r.Id
inner join training.user cb on r.CreatedById = cb.Id
where 
rt.Name not like 'TIS - AMER%'
and r.IsDeleted=0
and i.IsDeleted=0
and r.Status__c in ('Confirmed','Transferred')
group by `Region`, `Stream`, `SubStream`, `Source`, `Metric`, `Date (UTC)`)
union 
(select 'Australia' as 'Region', 
'n/a' as 'Stream',
null as 'SubStream',
null as 'Source',
if(q.queueName in ('Outbound'), 'Outbound Calls', 'Inbound Calls') as 'Metric',
date_format(eqd.`fromDate`, '%Y-%m-%d') as 'Date (UTC)',
null as 'Days',
null as 'Amount',
sum(eqd.`Count`) as 'Count'
from mitel.employee_queue_data eqd
left join mitel.queue q on eqd.queueId = q.queueId
where eqd.Span = 'DAY'
and q.queueName not in ('MS Sales','Public Training','InHouse','Online Learning')
group by `Region`, `Stream`, `SubStream`, `Source`, `Metric`, `Date (UTC)`)
union
(select 'Australia' as 'Region', 
if(q.QueueName in ('MS Sales'), 'Certification', 'TIS') as 'Stream',
if(q.QueueName in ('MS Sales'), null, if(q.QueueName in ('Public Training'),'Public',if(q.queueName in ('InHouse'), 'In-house', 'eLearning'))) as 'SubStream',
null as 'Source',
'Inbound Calls' as 'Metric',
date_format(eqd.`fromDate`, '%Y-%m-%d') as 'Date (UTC)',
null as 'Days',
null as 'Amount',
sum(eqd.`Count`) as 'Count'
from mitel.employee_queue_data eqd
left join mitel.queue q on eqd.queueId = q.queueId
where eqd.Span = 'DAY'
and q.queueName in ('MS Sales','Public Training','InHouse','Online Learning')
group by `Region`, `Stream`, `SubStream`, `Source`, `Metric`, `Date (UTC)`)
union
(select 'Australia' as 'Region', 
'n/a' as 'Stream',
null as 'SubStream',
null as 'Source',
if(q.queueName in ('Outbound'), 'Outbound Calls', 'Inbound Calls') as 'Metric',
date_format(eqd.`fromDate`, '%Y-%m-%d') as 'Date (UTC)',
null as 'Days',
null as 'Amount',
sum(eqd.`Count`) as 'Count'
from mitel.employee_queue_data eqd
left join mitel.queue q on eqd.queueId = q.queueId
where eqd.Span = 'DAY'
and q.queueName not in ('MS Sales','Public Training','InHouse','Online Learning')
group by `Region`, `Stream`, `SubStream`, `Source`, `Metric`, `Date (UTC)`);

select * from sales_pipeline_metrics;
select 
date_format(eqd.fromDate, '%Y-%m') as 'Period',
sum(if(q.QueueName = 'InHouse', eqd.`Count`, 0))/sum(eqd.`Count`) as 'InHouse',
sum(if(q.QueueName = 'MS Sales', eqd.`Count`, 0))/sum(eqd.`Count`) as 'MS Sales',
sum(if(q.QueueName = 'Online Learning', eqd.`Count`, 0))/sum(eqd.`Count`) as 'Online Learning',
sum(if(q.QueueName = 'Public Training', eqd.`Count`, 0))/sum(eqd.`Count`) as 'Public Training'
from mitel.employee_queue_data eqd
left join mitel.queue q on eqd.queueId = q.queueId
where eqd.Span = 'DAY'
and q.queueName in ('MS Sales','Public Training','InHouse','Online Learning')
and eqd.fromDate > date_add(now(), interval -12 month);

create or replace view sales_pipeline_certification_australia_sub as
select 
`Metric`,
date_format(`Date (UTC)`, '%Y %m') as 'Period',
Sum(`Days`) as 'Days',
sum(`Count`) as 'Count'
 from sales_pipeline_metrics 
where 
`Date (UTC)` >= '2015-03-01' 
and Region = 'Australia'
and Stream = 'Certification'
and Metric in ('Closed Won', 'Leads Created', 'Leads Converted', 'Proposal Sent')
group by `Metric`,`Period`;

select * from sales_pipeline_certification_australia_sub;
create or replace view sales_pipeline_certification_australia as
(select t.`Metric`, t.`Period`,
if (t.`Period`=date_format(utc_timestamp(), '%Y %m'),
	round(t.`Days`/day(utc_timestamp())*day(last_day(utc_timestamp())),3),
    t.`Days`) as 'Days',
if (t.`Period`=date_format(utc_timestamp(), '%Y %m'),
	round(t.`Count`/day(utc_timestamp())*day(last_day(utc_timestamp())),0),
    t.`Count`) as 'Count'
from sales_pipeline_certification_australia_sub t)
union
(select 
'Audit Days' as 'Metric',
Period, 
sum(Value) as 'Days',
null as 'Count' 
from salesforce.financial_visisbility_latest_days
where Region like 'AUS%'
and Region not like '%Product%'
and `Revenue Stream` in ('MS', 'Food')
and `Audit Status` not in ('Cancelled')
and Period>='2015 06'
and Period<='2016 06'
and (`Audit Open SubStatus` not in ('Pending Suspension','Pending Cancellation') or `Audit Open SubStatus` is null)
group by Period);

select * from sales_pipeline_certification_australia t;