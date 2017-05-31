use salesforce;

create index invoice_history_index on invoice__history(ParentId);
create index invoice_line_item_index on invoice_line_item__c (Invoice__c);

#WIP
create or replace view enlighten_finance_wip as
(select 'Finance' as 'Team', '' as 'User', 'Registration Group Creation - Cerification' as 'Activity', count(distinct sc.Primary_Certification__c) as 'WIP', utc_timestamp() as 'Date/Time'
from certification__c sc
inner join site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
where 
client.Client_Ownership__c in ('Australia', 'Product Services')
and sc.Invoice_Group_Registration__c is null
and sc.Primary_Certification__c is not null
and scsp.Status__c in ('Registered','Under Suspension','On Hold')
and sc.Intercompany_Client__c=0
and sc.Auditable_Site__c=1
and sc.IsDeleted=0)
union
(select 'Finance' as 'Team', '' as 'User', 'Registration Group Review - Cerification' as 'Activity', count(distinct sc.Primary_Certification__c) as 'WIP', utc_timestamp() as 'Date/Time'
from certification__c sc
inner join site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join invoice_group__c ig on sc.Invoice_Group_Registration__c = ig.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
where 
ig.status__c in ('Pending','Hold')
and client.Client_Ownership__c in ('Australia', 'Product Services')
and scsp.Status__c in ('Registered','Under Suspension','On Hold')
and sc.Auditable_Site__c=1
and sc.Intercompany_Client__c=0
and date_format(ig.Batch_Pickup_Date__c, '%Y-%m') <= date_format(now(), '%Y-%m'))
union
(select 'Finance' as 'Team',
	'' as 'User', 
	if(i.Status__c='Pending', 'Audit Invoice - Pending to Ready/Cancelled',
		if(i.Status__c='On Hold', 'Audit Invoice - On Hold to Ready/Cancelled','?'
        )
	) as 'Activity', 
	#count(distinct i.Id) as 'WIP (i)',
    
    count(distinct ili.work_item__c) as 'WIP',
    utc_timestamp() as 'Date/Time'
    #,group_concat(distinct i.Id) as 'Items'
from invoice__c i
inner join invoice_line_item__c ili on ili.Invoice__c = i.Id
where
i.IsDeleted = 0
and ili.IsDeleted = 0
and i.Client_Ownership__c in ('Australia', 'Product Services')
and i.Status__c in ('Pending', 'On Hold')
and ili.Work_Item_Record_Type__c = 'Audit'
group by `Team`,`Activity`);

select * from enlighten_finance_wip;


#Activities
create or replace view enlighten_finance_activity_audit_invoice_sub as (
select 
    i.Name as 'InvoiceName',
    u.Name as 'User',
    SUBSTRING_INDEX(GROUP_CONCAT(ih.OldValue ORDER BY ih.CreatedDate), ',', 1 ) as FirstOldValue,
    SUBSTRING_INDEX(GROUP_CONCAT(ih.NewValue ORDER BY ih.CreatedDate), ',', -1 ) as LastNewValue,
	ili.work_item__c as 'WorkItemsCompleted',
    date_format(date_add(ih.CreatedDate, interval 11 hour),'%Y-%m-%d') as 'Date'
from invoice__c i
inner join invoice__history ih on ih.ParentId = i.Id
inner join user u on ih.CreatedById = u.Id
inner join invoice_line_item__c ili on ili.Invoice__c = i.Id
where
i.IsDeleted = 0
and ih.IsDeleted = 0
#and date_format(date_add(ih.CreatedDate, interval 11 hour), '%Y-%m-%d')= '2015-03-10'
and ih.CreatedDate<=utc_timestamp()
and ih.CreatedDate>date_add(utc_timestamp(), interval -1 day)
and ih.Field = 'Status__c'
and i.Client_Ownership__c in ('Australia', 'Product Services')
and u.Name not like 'Castiron User'
and ili.Work_Item_Record_Type__c = 'Audit'
group by u.Name,`Date`,ili.Work_Item__c
order by i.Id, ih.CreatedDate);

#explain
create or replace view enlighten_finance_activity as
(select 'Finance' as 'Team', t.User as 'User', 
	if(t.FirstOldValue='Pending' and (t.LastNewValue='Ready' or t.LastNewValue='Cancelled'), 'Audit Invoice - Pending to Ready/Cancelled',
		if(t.FirstOldValue='Pending' and t.LastNewValue='On Hold', 'Audit Invoice - Pending to On Hold',
			if(t.FirstOldValue='On Hold' and (t.LastNewValue='Ready' or t.LastNewValue='Cancelled'), 'Audit Invoice - On Hold to Ready/Cancelled', concat('Audit Invoice - ', t.FirstOldValue, ' to ', t.LastNewValue))
        )
	) as 'Activity', 
    count( distinct t.WorkItemsCompleted) as 'Completed',
    t.`Date`,
    group_concat(distinct t.InvoiceName) as 'Notes'
    from enlighten_finance_activity_audit_invoice_sub t
group by `Team`, `User`,`Activity`)
union 
(select 'Finance' as 'Team', u.Name as 'User', 'Registration Group Creation - Cerification' as 'Activity', count(distinct sc.Primary_Certification__c) as 'Completed', date_format(date_add(sch.CreatedDate, interval 11 hour), '%Y-%m-%d') as 'Date', group_concat(distinct sc.Primary_Certification__c) as 'Notes'
from certification__c sc 
inner join certification__history sch on sch.ParentId = sc.Id
inner join User u on sch.CreatedById = u.Id
inner join account site on sc.Primary_client__c = site.Id
inner join account client on site.ParentId = client.Id
where 
client.Client_Ownership__c in ('Australia', 'Product Services')
and sch.Field='Invoice_Group_Registration__c'
and sch.OldValue is null
#and date_format(date_add(sch.CreatedDate, interval 11 hour),'%Y-%m')  = '2015-03-10'
and sch.CreatedDate<=utc_timestamp()
and sch.CreatedDate>date_add(utc_timestamp(), interval -1 day)
group by `Team`, `User`, `Activity`, `Date`);

select * from enlighten_finance_activity;