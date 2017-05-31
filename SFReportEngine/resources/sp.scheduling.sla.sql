#database
use analytics;

drop procedure SlaUpdateSchedulingBacklog;
DELIMITER //
CREATE PROCEDURE SlaUpdateSchedulingBacklog()
 BEGIN

declare start_time datetime;
set start_time = utc_timestamp();

 #clear old data
 truncate sla_scheduling_backlog;
 #insert new data
insert into sla_scheduling_backlog (
select t3.* from (
select 
t2.Scheduling_Ownership__c as 'Region',
t2.`Team`, t2.`Activity`, t2.`Details`, t2.`Enlighten Activity Code`, t2.`Id Type`, t2.`Id`, t2.`Owner`, t2.`Aging Type`, t2.`From`, 
if (t2.`Activity`='Scheduled', 
	date_add(t2.`From`, interval analytics.getTarget('scheduling_scheduled_sla',null,null)  day),
	if (t2.`Activity`='Scheduled Offered',
		date_add(t2.`From`, interval analytics.getTarget('scheduling_scheduled_offered_sla',null,null) day),
		if (t2.`Activity`='Confirmed',
			date_add(t2.`work_item_Date__c`, interval analytics.getTarget('scheduling_confirmed_sla',null,null) day),
            # Open with Substatus
			date_add(t2.`From`, interval analytics.getTarget('scheduling_open_substatus_sla',null,null) day)
		)
    )
) as 'SLA Due',
t2.`To`,
t2.`Tags` from (
select t.`Team`, t.`Activity`, t.`Details`, t.`Enlighten Activity Code`, t.`Id Type`, t.`Id`, t.`Owner`,
if (t.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems'),
	if (t.`Activity`='Scheduled', 
		if(t.`Stream`='MS',
			if(t.`Complexity`='High', 'from 6 month before target', if(t.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target')),
			if(t.`Stream`='Food',
				if(t.`Complexity`='High', 'from 6 month before target', if(t.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target')),
				if(t.`Complexity`='High', 'from 6 month before target', if(t.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target'))
			)
		),
		if (t.`Activity`='Scheduled Offered',
			if(t.`Stream`='MS',
				if(t.`Complexity`='High', 'from 3 month before start', if(t.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start')),
				if(t.`Stream`='Food',
					if(t.`Complexity`='High', 'from 3 month before start', if(t.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start')),
					if(t.`Complexity`='High', 'from 3 month before start', if(t.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start'))
				)
			),
			if (t.`Activity`='Confirmed',
				if(t.`Stream`='MS',
					if(t.`Complexity`='High', 'from scheduled offered', if(t.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered')),
					if(t.`Stream`='Food',
						if(t.`Complexity`='High', 'from scheduled offered', if(t.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered')),
						if(t.`Complexity`='High', 'from scheduled offered', if(t.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered'))
					)
				),
				# Open with Substatus
				if(t.`Stream`='MS',
					if(t.`Complexity`='High', 'from open with substatus', if(t.`Complexity`='Medium', 'from open with substatus', 'from open with substatus')),
					if(t.`Stream`='Food',
						if(t.`Complexity`='High', 'from open with substatus', if(t.`Complexity`='Medium', 'from open with substatus', 'from open with substatus')),
						if(t.`Complexity`='High', 'from open with substatus', if(t.`Complexity`='Medium', 'from open with substatus', 'from open with substatus'))
					)
				)
			)
		)
	),
    if (t.`Activity`='Scheduled', 
		'from 3 month before target',
		if (t.`Activity`='Scheduled Offered',
			'from 3 month before start',
			if (t.`Activity`='Confirmed',
				'from scheduled offered',
                'from open with substatus'
			)
		)
	)
) as 'Aging Type',
if (t.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems'),
	if (t.`Activity`='Scheduled', 
		if(t.`Stream`='MS',
			if(t.`Complexity`='High', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t.`Complexity`='Medium', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH))),
			if(t.`Stream`='Food',
				if(t.`Complexity`='High', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t.`Complexity`='Medium', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH))),
				if(t.`Complexity`='High', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t.`Complexity`='Medium', date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t.`Service_Target_date__c`, INTERVAL -6 MONTH)))
			)
		),
		if (t.`Activity`='Scheduled Offered',
			if(t.`Stream`='MS',
				if(t.`Complexity`='High', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), if(t.`Complexity`='Medium', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH))),
				if(t.`Stream`='Food',
					if(t.`Complexity`='High', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), if(t.`Complexity`='Medium', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH))),
					if(t.`Complexity`='High', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), if(t.`Complexity`='Medium', date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH), date_add(t.`work_item_Date__c`, INTERVAL -4 MONTH)))
				)
			),
			if (t.`Activity`='Confirmed',
				if(t.`Stream`='MS',
					if(t.`Complexity`='High', t.`First Scheduled Offered`, if(t.`Complexity`='Medium', t.`First Scheduled Offered`, t.`First Scheduled Offered`)),
					if(t.`Stream`='Food',
						if(t.`Complexity`='High', t.`First Scheduled Offered`, if(t.`Complexity`='Medium', t.`First Scheduled Offered`, t.`First Scheduled Offered`)),
						if(t.`Complexity`='High', t.`First Scheduled Offered`, if(t.`Complexity`='Medium', t.`First Scheduled Offered`, t.`First Scheduled Offered`))
					)
				),
				# Open with Substatus
				if(t.`Stream`='MS',
					if(t.`Complexity`='High', t.`First Open Substatus`, if(t.`Complexity`='Medium', t.`First Open Substatus`, t.`First Open Substatus`)),
					if(t.`Stream`='Food',
						if(t.`Complexity`='High', t.`First Open Substatus`, if(t.`Complexity`='Medium', t.`First Open Substatus`, t.`First Open Substatus`)),
						if(t.`Complexity`='High', t.`First Open Substatus`, if(t.`Complexity`='Medium', t.`First Open Substatus`, t.`First Open Substatus`))
					)
				)
			)
		)
	),
    if (t.`Activity`='Scheduled', 
		date_add(t.`Service_Target_date__c`, INTERVAL -3 MONTH), 
		if (t.`Activity`='Scheduled Offered',
			date_add(t.`work_item_Date__c`, INTERVAL -3 MONTH),
			if (t.`Activity`='Confirmed',
				t.`First Scheduled Offered`, 
				# Open with Substatus
				t.`First Open Substatus`
			)
		)
	)
) as 'From',
'' as 'SLA Due',
null as 'To',
t.`Complexity`,
t.`Stream`,
t.`Primary_Standard__c` as 'Tags' ,
t.`work_item_Date__c`,
t.Scheduling_Ownership__c from (
select 
#if(wi.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling - FP') as 'Team',
if(wi.Scheduling_Ownership__c like '%Food%' or wi.Scheduling_Ownership__c like '%Product%', 'Scheduling - FP', if(wi.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling')) as 'Team',
#if(wi.Scheduling_Ownership__c = 'AUS - Management Systems','MS',if(wi.Scheduling_Ownership__c = 'AUS - Food','Food','PS')) as 'Stream',
if(wi.Scheduling_Ownership__c like '%Food%', 'Food', if (wi.Scheduling_Ownership__c like '%Product%', 'PS', 'MS' )) as 'Stream',
if((wi.Status__c = 'Open' and wi.Open_Sub_Status__c is null) or wi.Status__c = 'Service change','Scheduled',
	if(wi.Status__c = 'Open' and wi.Open_Sub_Status__c is not null,'Open W Substatus',
	if (wi.Status__c = 'Scheduled','Scheduled Offered','Confirmed'))) as 'Activity',
'' as 'Details', 
if((wi.Status__c = 'Open' and wi.Open_Sub_Status__c is null) or wi.Status__c = 'Service change','Sched-02',
	if(wi.Status__c = 'Open' and wi.Open_Sub_Status__c is not null,'Sched-10',
	if (wi.Status__c = 'Scheduled','Sched-05','Sched-06'))) as 'Enlighten Activity Code',
'Work Item' as 'Id Type',
wi.Id as 'Id',
scheduler.name as 'Owner',
wi.Scheduling_Ownership__c,  
wi.Service_Target_date__c, 
wi.work_item_Date__c, 
wi.Status__c, 
wi.Open_Sub_Status__c , 
wi.Scheduling_Complexity__c as 'Complexity',
wi.Primary_Standard__c,
min(if(wih.IsDeleted=0 and wih.Field='Status__c' and wih.NewValue='Scheduled', wih.CreatedDate, null)) as 'First Scheduled', 
min(if(wih.IsDeleted=0 and wih.Field='Status__c' and wih.NewValue='Scheduled - Offered', wih.CreatedDate, null)) as 'First Scheduled Offered',
min(if(wih.IsDeleted=0 and wih.Field='Open_Sub_Status__c' and wih.NewValue is not null and wih.OldValue is null, wih.CreatedDate, null)) as 'First Open Substatus'  
from salesforce.work_item__c wi 
left join salesforce.work_item__history wih on wih.ParentId = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.User scheduler on sc.Scheduler__c = scheduler.Id
where 
#wi.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems') and 
if(wi.Status__c in ('Open', 'Service change'),
	if(wi.Scheduling_Ownership__c = 'AUS - Management Systems',
		if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH))),
		if(wi.Scheduling_Ownership__c = 'AUS - Food', 
			if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH))),
			if(wi.Scheduling_Ownership__c = 'AUS - Product Services', 
				if(wi.Scheduling_Complexity__c = 'High', wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH), if(wi.Scheduling_Complexity__c = 'Medium',wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH),wi.Service_Target_date__c<=date_add(now(), INTERVAL 6 MONTH))),                    
					if(wi.Scheduling_Ownership__c like 'EMEA%',
						# EMEA
						wi.Service_Target_date__c<=date_add(now(), INTERVAL 3 MONTH),
						# APAC
						wi.Service_Target_date__c<=date_add(now(), INTERVAL 3 MONTH)
					)
				)
		)
	),
	if(wi.Status__c in ('Scheduled') and wi.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems'),
		wi.Work_Item_date__c<=date_add(now(), INTERVAL 3 MONTH),
		1 #Scheduled Offered or anything else for EMEA or APAC
	)
)
and wi.Status__c in ('Open', 'Scheduled', 'Scheduled - Offered', 'Service change')
and wi.Work_Item_Stage__c not in ('Follow Up')
group by wi.Id) t) t2
union
select 
sc.Operational_Ownership__c as 'Region',
if(scsp.Administration_Ownership__c like 'AUS%', 
	if (sc.Operational_Ownership__c like '%Food%', 'Scheduling - FP', if (Operational_Ownership__c like '%Product%', 'Scheduling - FP', 'Scheduling - MS')),
    'Scheduling') as 'Team',
'Validate Lifecycle' as 'Activity',
'' as 'Details',
'Sched-16' as 'Enlighten Activity Code',
'Site Certification' as 'Id Type',
sc.Id as 'Id',
scheduler.Name as 'Owner',
'from site certification standard registered',
if(min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null)) is null,
    scsp.CreatedDate,
    min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null))
) as 'From',
date_add(
	if(min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null)) is null,
    scsp.CreatedDate,
    min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null))), 
	interval analytics.getTarget('scheduling_lifecycle_sla',null,null) day) as 'SLA Due',
null as 'To',
sc.FStandards__c as 'Tags'
from salesforce.certification__c sc 
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id 
left join salesforce.site_certification_standard_program__history scsph on scsph.ParentId = scsp.Id
left join salesforce.user scheduler on sc.Scheduler__c = scheduler.Id
where 
sc.IsDeleted = 0 
and scsp.IsDeleted = 0 
and scsp.Status__c in ('Registered', 'Customised') 
and sc.Primary_Certification__c is not null 
and sc.Status__c = 'Active' 
and (sc.Mandatory_Site__c=1 or (sc.Mandatory_Site__c=0 and sc.FSample_Site__c like '%unchecked%')) 
#and scsp.Administration_Ownership__c like 'AUS%' 
and sc.Lifecycle_Validated__c = 0
group by sc.Id) t3 );

insert into analytics.sp_log VALUES(null,'SlaUpdateSchedulingBacklog',utc_timestamp(), timestampdiff(MICROSECOND, start_time, utc_timestamp()));

 END //
DELIMITER ;

drop event SlaUpdateEventSchedulingBacklog;
CREATE EVENT SlaUpdateEventSchedulingBacklog
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSchedulingBacklog();

select * from analytics.sp_log where sp_name = 'SlaUpdateSchedulingBacklog' order by exec_time desc limit 5;

(select * from sla_scheduling_backlog where Activity not in ('Validate Lifecycle'));

truncate sla_scheduling_completed;
DROP PROCEDURE SlaUpdateSchedulingCompleted;
DELIMITER //
CREATE PROCEDURE SlaUpdateSchedulingCompleted()
 BEGIN
 #variables
 declare start_time datetime;
 declare lastUpdateWi datetime;
 declare lastUpdateVLTicked datetime;
 declare lastUpdateVLSCLModified datetime;
 declare lastUpdateVLSCLHCreated datetime;
 declare lastUpdateCU datetime;
 declare lastUpdateCWP datetime;
 set start_time = utc_timestamp();
 set lastUpdateWi = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity not in ('Validate Lifecycle','Calendar Update','Create Work Package'));
 set lastUpdateVLTicked = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity in ('Validate Lifecycle') and Details='Lifecycle Validated Ticked under Site Certification');
 set lastUpdateVLSCLModified = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity in ('Validate Lifecycle') and Details='Site Cert Lifecycle Modified or Created');
 set lastUpdateVLSCLHCreated = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity in ('Validate Lifecycle') and Details='Site Cert Lifecycle History Created');
 set lastUpdateCU = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity in ('Calendar Update'));
 set lastUpdateCWP = (select if(max(`To`) is null, '1970-01-01', max(`To`)) from analytics.sla_scheduling_completed where Activity in ('Create Work Package'));
 
insert into sla_scheduling_completed 
(select t3.Scheduling_Ownership__c as 'Region', t3.`Team`, t3.`Activity`, t3.`Details`, t3.`Enlighten Activity Code`, t3.`Id Type`, t3.`Id`, t3.`Owner`, t3.`Aging Type`, t3.`From`, 
if (t3.`Activity`='Scheduled' or t3.`Activity`='Unable to Schedule', 
	date_add(t3.`From`, interval analytics.getTarget('scheduling_scheduled_sla',null,null)  day),
	if (t3.`Activity`='Scheduled Offered',
		date_add(t3.`From`, interval analytics.getTarget('scheduling_scheduled_offered_sla',null,null) day),
		if (t3.`Activity`='Confirmed',
			date_add(t3.`Work_Item_Date__c`, interval analytics.getTarget('scheduling_confirmed_sla',null,null) day),
            null
		)
    )
) as 'SLA Due',
t3.`To`, t3.`Tags`
from (
select t2.`Team`, t2.`Activity`, t2.`Details`, t2.`Enlighten Activity Code`, t2.`Id Type`, t2.`Id`, t2.`Owner`,
t2.`Stream`,
t2.`Complexity`,
if (t2.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems'),
	if (t2.`Activity`='Scheduled' or t2.`Activity`='Unable to Schedule', 
		if(t2.`Stream`='MS',
			if(t2.`Complexity`='High', 'from 6 month before target', if(t2.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target')),
			if(t2.`Stream`='Food',
				if(t2.`Complexity`='High', 'from 6 month before target', if(t2.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target')),
				if(t2.`Complexity`='High', 'from 6 month before target', if(t2.`Complexity`='Medium', 'from 6 months before target', 'from 6 months before target'))
			)
		),
		if (t2.`Activity`='Scheduled Offered',
			if(t2.`Stream`='MS',
				if(t2.`Complexity`='High', 'from 3 month before start', if(t2.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start')),
				if(t2.`Stream`='Food',
					if(t2.`Complexity`='High', 'from 3 month before start', if(t2.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start')),
					if(t2.`Complexity`='High', 'from 3 month before start', if(t2.`Complexity`='Medium', 'from 3 months before start', 'from 3 months before start'))
				)
			),
			if (t2.`Activity`='Confirmed',
				if(t2.`Stream`='MS',
					if(t2.`Complexity`='High', 'from scheduled offered', if(t2.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered')),
					if(t2.`Stream`='Food',
						if(t2.`Complexity`='High', 'from scheduled offered', if(t2.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered')),
						if(t2.`Complexity`='High', 'from scheduled offered', if(t2.`Complexity`='Medium', 'from scheduled offered', 'from scheduled offered'))
					)
				),
				if (t2.`Activity`='Open W Substatus',
					if(t2.`Stream`='MS',
						if(t2.`Complexity`='High', 'from open with substatus', if(t2.`Complexity`='Medium', 'from open with substatus', 'from open with substatus')),
						if(t2.`Stream`='Food',
							if(t2.`Complexity`='High', 'from open with substatus', if(t2.`Complexity`='Medium', 'from open with substatus', 'from open with substatus')),
							if(t2.`Complexity`='High', 'from open with substatus', if(t2.`Complexity`='Medium', 'from open with substatus', 'from open with substatus'))
						)
					),
					null
				)
			)
		)
	), 
    if (t2.`Activity`='Scheduled' or t2.`Activity`='Unable to Schedule', 
		'from 3 month before target',
		if (t2.`Activity`='Scheduled Offered',
			'from 3 month before start',
			if (t2.`Activity`='Confirmed',
				'from scheduled offered', 
				if (t2.`Activity`='Open W Substatus',
					'from open with substatus',
					null
				)
			)
		)
	)
) as 'Aging Type',
if (t2.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems'),
	if (t2.`Activity`='Scheduled' or t2.`Activity`='Unable to Schedule', 
		if(t2.`Stream`='MS',
			if(t2.`Complexity`='High', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH))),
			if(t2.`Stream`='Food',
				if(t2.`Complexity`='High', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH))),
				if(t2.`Complexity`='High', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH), date_add(t2.`Service_Target_date__c`, INTERVAL -6 MONTH)))
			)
		),
		if (t2.`Activity`='Scheduled Offered',
			if(t2.`Stream`='MS',
				if(t2.`Complexity`='High', date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`work_item_Date__c`, INTERVAL -3 MONTH), date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH))),
				if(t2.`Stream`='Food',
					if(t2.`Complexity`='High', date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`work_item_Date__c`, INTERVAL -3 MONTH), date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH))),
					if(t2.`Complexity`='High', date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH), if(t2.`Complexity`='Medium', date_add(t2.`work_item_Date__c`, INTERVAL -3 MONTH), date_add(t2.`work_item_Date__c`, INTERVAL -4 MONTH)))
				)
			),
			null
		)
	),
    if (t2.`Activity`='Scheduled' or t2.`Activity`='Unable to Schedule', 
		date_add(t2.`Service_Target_date__c`, INTERVAL -3 MONTH),
		if (t2.`Activity`='Scheduled Offered',
			date_add(t2.`work_item_Date__c`, INTERVAL -3 MONTH),
			null
		)
	)
) as 'From',
t2.`To`,
t2.Service_target_date__c,t2.Work_Item_Date__c,t2.Scheduling_Ownership__c,
t2.`Tags` from (
select  
t.`Team`,
if (t.Field = 'Open_Sub_Status__c', 
	#if( t.NewValue in ('Pending Suspension','Pending Cancellation'), 'Cancelled', 'Unable To Schedule'),
    'Unable To Schedule',
	if(t.OldValue is null and t.NewValue='Open', 'Create Work Item',
		if(t.NewValue = 'Scheduled', 'Scheduled',
			if(t.NewValue = 'Scheduled - Offered', 'Scheduled Offered',
				if(t.NewValue = 'Confirmed', 'Confirmed',
					if(t.NewValue = 'Cancelled', 'Cancelled','?')
				)
			)
		)
	)
) as 'Activity',
'' as 'Details',
if (t.Field = 'Open_Sub_Status__c', 
	#if( t.NewValue in ('Pending Suspension','Pending Cancellation'), 'Sched-09', 'Sched-03'),
    'Sched-03',
	if(t.OldValue is null and t.NewValue='Open', 'Sched-08',
		if(t.NewValue = 'Scheduled', 'Sched-02',
			if(t.NewValue = 'Scheduled - Offered', 'Sched-05',
				if(t.NewValue = 'Confirmed', 'Sched-06',
					if(t.NewValue = 'Cancelled', 'Sched-09','?')
				)
			)
		)
	)
) as 'Enlighten Activity Code',
'Work Item' as 'Id Type',
t.`Id`,
t.`Owner`,
t.`Stream`,
t.`Complexity`,
t.CreatedDate as 'To',
t.Primary_standard__c as 'Tags',
t.Service_target_date__c, t.Work_Item_Date__c, t.Scheduling_Ownership__c
from (
select 
#if(wi.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling - FP') as 'Team',
if(wi.Scheduling_Ownership__c like '%Food%' or wi.Scheduling_Ownership__c like '%Product%', 'Scheduling - FP', if(wi.Scheduling_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling')) as 'Team',
wi.Id as 'Id',
u.Name as 'Owner', 
wih.CreatedDate, 
wih.Field , 
wih.OldValue, 
if (wih.Field='created','Open',wih.NewValue) as 'NewValue',
wi.Primary_standard__c,
#if(wi.Scheduling_Ownership__c = 'AUS - Management Systems','MS',if(wi.Scheduling_Ownership__c = 'AUS - Food','Food','PS')) as 'Stream',
if(wi.Scheduling_Ownership__c like '%Food%', 'Food', if (wi.Scheduling_Ownership__c like '%Product%', 'PS', 'MS' )) as 'Stream',
wi.Scheduling_Complexity__c as 'Complexity',
wi.Service_target_date__c, wi.Work_Item_Date__c, wi.Scheduling_Ownership__c
from salesforce.work_item__history wih 
inner join salesforce.user u on wih.CreatedById = u.Id 
inner join salesforce.work_item__c wi on wi.Id = wih.ParentId 
where wih.Field in ('Status__c', 'created', 'Open_Sub_Status__c') 
#and wi.Scheduling_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems')
and wih.IsDeleted=0 
and wih.CreatedDate>lastUpdateWi
) t
where 
if(t.OldValue is null and t.NewValue='Open', 1,
	if (t.Field = 'Status__c',
		if(t.NewValue in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'Cancelled'),1,0),
        1
	)
) ) t2 ) t3);

insert into sla_scheduling_completed 
(select t4.* from (
select t3.* from (
# Lifecycle Validated Ticked under Site Certification
select t2.* from (
select 
sc.Operational_Ownership__c as 'Region',
if (sc.Operational_Ownership__c in ('AUS - Food', 'Scheduling - FP', 'AUS - Product Services'), 'Scheduling - FP', if (sc.Operational_Ownership__c = 'AUS - Management Systems','Scheduling - MS','Scheduling')) as 'Team',
'Validate Lifecycle' as 'Activity',
'Lifecycle Validated Ticked under Site Certification' as 'Details',
'Sched-16' as 'Enlighten Activity Code',
'Site Certification' as 'Id Type',
sc.Id as 'Id',
min(if(sch.IsDeleted=0 and sch.Field = 'Lifecycle_Validated__c' and sch.NewValue='true', scheduler.Name, null)) as 'Owner',
'from site certification standard registered' as 'Aging Type',
if(min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null)) is null,
    scsp.CreatedDate,
    min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null))
) as 'From',
date_add(
	if(min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null)) is null,
    scsp.CreatedDate,
    min(if(scsph.IsDeleted=0 and scsph.Field='Status__c' and (scsph.NewValue='Registered' or scsph.NewValue='Customised'), scsph.CreatedDate, null))), 
	interval 7 day) as 'SLA Due',
min(if(sch.IsDeleted=0 and sch.Field = 'Lifecycle_Validated__c' and sch.NewValue='true', sch.CreatedDate, null)) as 'To',
sc.FStandards__c as 'Tags'
from salesforce.certification__c sc 
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id 
inner join salesforce.certification__history sch on sch.ParentId = sc.Id
left join salesforce.site_certification_standard_program__history scsph on scsph.ParentId = scsp.Id
left join salesforce.user scheduler on sch.CreatedById = scheduler.Id
where 
sc.IsDeleted = 0 
and scsp.IsDeleted = 0 
#and scsp.Status__c in ('Registered', 'Customised') 
and sc.Primary_Certification__c is not null 
#and sc.Status__c = 'Active' 
#and (sc.Mandatory_Site__c=1 or (sc.Mandatory_Site__c=0 and sc.FSample_Site__c like '%unchecked%')) 
and sc.Lifecycle_Validated__c = 1
and sch.CreatedDate > lastUpdateVLTicked
group by sc.Id order by sc.Id
) t2 where t2.`To` is not null
union
# Site Cert Lifecycle Modified or Created 
select 
sc.Operational_Ownership__c as 'Region',
if (sc.Operational_Ownership__c in ('AUS - Food', 'Scheduling - FP', 'AUS - Product Services'), 'Scheduling - FP', if (sc.Operational_Ownership__c = 'AUS - Management Systems','Scheduling - MS','Scheduling')) as 'Team',
'Validate Lifecycle' as 'Activity',
'Site Cert Lifecycle Modified or Created' as 'Details',
'Sched-16' as 'Enlighten Activity Code',
'Site Certification' as 'Id Type',
sc.Id as 'Id', u.Name as 'Owner', null,null,null,
scl.LastModifiedDate as 'To',
sc.FStandards__c as 'Tags'
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.user u on scl.LastModifiedById = u.Id
where 
scl.LastModifiedDate > lastUpdateVLSCLModified
and scl.isDeleted=1
union
select 
sc.Operational_Ownership__c as 'Region',
if (sc.Operational_Ownership__c in ('AUS - Food', 'Scheduling - FP', 'AUS - Product Services'), 'Scheduling - FP', if (sc.Operational_Ownership__c = 'AUS - Management Systems','Scheduling - MS','Scheduling')) as 'Team',
'Validate Lifecycle' as 'Activity',
'Site Cert Lifecycle History Created' as 'Details',
'Sched-16' as 'Enlighten Activity Code',
'Site Certification' as 'Id Type',
sc.Id as 'Id', u.Name as 'Owner', null,null,null,
sclh.CreatedDate as 'To',
sc.FStandards__c as 'Tags'
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.site_certification_lifecycle__history sclh on sclh.ParentId = scl.Id
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.user u on sclh.CreatedById = u.Id
where 
sclh.CreatedDate > lastUpdateVLSCLHCreated
and scl.isDeleted=0
group by scl.Site_Certification__c) t3 order by t3.`Id`, t3.`From` desc) t4 group by t4.`Id`);

insert into sla_scheduling_completed 
(select 
sc.Operational_Ownership__c as 'Region',
if (sc.Operational_Ownership__c like '%Food%', 'Scheduling - FP', if (sc.Operational_Ownership__c like '%Product%', 'Scheduling - FP', if(sc.Operational_Ownership__c = 'AUS - Management Systems', 'Scheduling - MS', 'Scheduling'))) as 'Team',
'Create Work Package' as 'Activity',
sc.Operational_Ownership__c as 'Details',
'Sched-27' as 'Enlighten Activity Code',
'Work Package' as 'Id Type',
wp.Id as 'Work Package',
cb.Name as 'Owner',
null as 'Aging Type',
null as 'From',
null as 'SLA Due',
wp.CreatedDate as 'To',
concat(Client_Site_NOLINK__c,';',sc.Standard_Name__c) as 'Tags'
from salesforce.work_package__c wp
inner join salesforce.User cb on wp.CreatedById = cb.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
where 
#sc.Operational_Ownership__c in ('AUS - Food', 'AUS - Product Services', 'AUS - Management Systems') and 
wp.CreatedDate>lastUpdateCWP);

insert into sla_scheduling_completed 
(select 
r.Reporting_Business_Units__c as 'Region',
'Scheduling' as 'Team',
'Calendar Update' as 'Activity',
concat('Count:',cast(count(e.Id) as CHAR)) as 'Details',
'SchedProd-02' as 'Enlighten Activity Code',
null as 'Id Type',
null as 'Id',
cb.Name as 'Owner',
null as 'Aging Type',
null as 'From',
null as 'SLA Due',
e.LastModifiedDate as 'To',
null as 'Tags'
from salesforce.`event` e 
inner join salesforce.user cb on e.LastModifiedById = cb.Id
inner join salesforce.recordtype rt on e.RecordTypeId = rt.Id
left join salesforce.resource__c r on r.User__c = cb.Id
where 
e.LastModifiedDate > lastUpdateCU
and rt.Name = 'Blackout Period Resource'
group by `Team`, `Owner`, `Activity`, e.LastModifiedDate);

drop temporary table if exists analytics.tmp_from;

create temporary table analytics.tmp_from as
select `Id`, 
min(if(`Activity` = 'Scheduled', `To`,null)) as 'First Scheduled',
min(if(`Activity` = 'Scheduled Offered', `To`,null)) as 'First Scheduled Offered',
min(if(`Activity` = 'Create Work Item', `To`,null)) as 'Create Work Item'
from analytics.sla_scheduling_completed 
where 
`Activity` in ('Scheduled Offered', 'Scheduled', 'Create Work Item')
and `Id` in (select `Id` from analytics.sla_scheduling_completed sc where sc.`Activity`='Confirmed' and sc.`From` is null) 
group by `Id`;

create index tmp_from_index on tmp_from(Id);

SET SQL_SAFE_UPDATES = 0;

update analytics.sla_scheduling_completed sc
left join analytics.tmp_from t on t.`Id` = sc.`Id`
set sc.`From` = if(t.`First Scheduled Offered` is null, if(t.`First Scheduled` is null, t.`Create Work Item`,t.`First Scheduled`), t.`First Scheduled Offered`)
where sc.`Activity`='Confirmed'
and sc.`From` is null;

drop temporary table if exists analytics.tmp_from;

insert into analytics.sp_log VALUES(null,'SlaUpdateSchedulingCompleted',utc_timestamp(), timestampdiff(MICROSECOND, start_time, utc_timestamp()));

 END //
DELIMITER ;


select Owner, count(*) from sla_scheduling_completed where Activity='Calendar Update' and Region='n/a' group by `Owner`;
update sla_scheduling_completed set Region = null where Region = 'n/a';
select Activity, count(*) from sla_scheduling_completed group by Activity;

drop event SlaUpdateEventSchedulingCompleted;
CREATE EVENT SlaUpdateEventSchedulingCompleted
    ON SCHEDULE EVERY 10 minute DO 
		call SlaUpdateSchedulingCompleted();

select * from analytics.sp_log where sp_name = 'SlaUpdateSchedulingCompleted' order by exec_time desc limit 5;

show events;