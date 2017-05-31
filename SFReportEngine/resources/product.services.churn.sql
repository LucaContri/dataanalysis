create index invoice_invoice_group_index on invoice__c(Invoice_Group__c);

#explain
select t.*, if(date_add(t.`Invoice Processed Date`, interval 12 month)>t.`Withdrawn_Date__c` and t.`Invoice Processed Date`<t.`Withdrawn_Date__c`,1,0) as 'Within 12 month before De-Registration' from (
select 
scsp.Id, 
scsp.Name, 
scsp.Withdrawn_Date__c, 
date_format(scsp.Withdrawn_Date__c, '%Y-%m') as 'De-Registered Period', 
if(month(scsp.Withdrawn_Date__c)<7, concat(year(scsp.Withdrawn_Date__c)-1,'-',year(scsp.Withdrawn_Date__c)), concat(year(scsp.Withdrawn_Date__c),'-',year(scsp.Withdrawn_Date__c)+1)) as 'De-Registered FY', 
sc.Revenue_Ownership__c,
'Work Item' as 'Invoice Group',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Id,null) as 'Invoice Id',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Name,null) as 'Invoice Name',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Invoice_Processed_Date__c,null) as 'Invoice Processed Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Closed_Date__C,null) as 'Invoice Close Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.CreatedDate,null) as 'Invoice Create Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Total_Amount__c,null) as 'Invoice Amount'
from site_certification_standard_program__c scsp
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
left join invoice_group__c igwi on sc.Invoice_Group_Work_Item__c = igwi.Id
left join invoice__c iwi on iwi.Invoice_Group__c = igwi.Id
where 
scsp.De_registered_Type__c in ('SAI Initiated','Client Initiated')
and sc.Revenue_Ownership__c like 'AUS-Product Services%'
union
select 
scsp.Id, 
scsp.Name, 
scsp.Withdrawn_Date__c, 
date_format(scsp.Withdrawn_Date__c, '%Y-%m') as 'De-Registered Period', 
if(month(scsp.Withdrawn_Date__c)<7, concat(year(scsp.Withdrawn_Date__c)-1,'-',year(scsp.Withdrawn_Date__c)), concat(year(scsp.Withdrawn_Date__c),'-',year(scsp.Withdrawn_Date__c)+1)) as 'De-Registered FY', 
sc.Revenue_Ownership__c,
'Registration' as 'Invoice Group',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Id,null) as 'Invoice Id',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Name,null) as 'Invoice Name',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Invoice_Processed_Date__c,null) as 'Invoice Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Closed_Date__C,null) as 'Invoice Close Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.CreatedDate,null) as 'Invoice Create Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Total_Amount__c,null) as 'Invoice Amount'
from site_certification_standard_program__c scsp
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
left join invoice_group__c igwi on sc.Invoice_Group_Registration__c = igwi.Id
left join invoice__c iwi on iwi.Invoice_Group__c = igwi.Id
where 
scsp.De_registered_Type__c in ('SAI Initiated','Client Initiated')
and sc.Revenue_Ownership__c like 'AUS-Product Services%'
union
select 
scsp.Id, 
scsp.Name, 
scsp.Withdrawn_Date__c, 
date_format(scsp.Withdrawn_Date__c, '%Y-%m') as 'De-Registered Period', 
if(month(scsp.Withdrawn_Date__c)<7, concat(year(scsp.Withdrawn_Date__c)-1,'-',year(scsp.Withdrawn_Date__c)), concat(year(scsp.Withdrawn_Date__c),'-',year(scsp.Withdrawn_Date__c)+1)) as 'De-Registered FY', 
sc.Revenue_Ownership__c,
'Royalty' as 'Invoice Group',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Id,null) as 'Invoice Id',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Name,null) as 'Invoice Name',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Invoice_Processed_Date__c,null) as 'Invoice Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Closed_Date__C,null) as 'Invoice Close Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.CreatedDate,null) as 'Invoice Create Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Total_Amount__c,null) as 'Invoice Amount'
from site_certification_standard_program__c scsp
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
left join invoice_group__c igwi on sc.Invoice_Group_Royalty__c = igwi.Id
left join invoice__c iwi on iwi.Invoice_Group__c = igwi.Id
where 
scsp.De_registered_Type__c in ('SAI Initiated','Client Initiated')
and sc.Revenue_Ownership__c like 'AUS-Product Services%') t 
where 
t.`Invoice Id` is not null 
and t.`Invoice Amount` != 0
limit 1000000;


select month('2015-03-01');
select * from sf_tables where TableName='site_certification_standard_program__c';

update sf_tables set LastSyncDate='2014-01-01' where Id=440;


select 
scsp.Id, 
scsp.Name, 
scsp.Withdrawn_Date__c, 
date_format(scsp.Withdrawn_Date__c, '%Y-%m') as 'De-Registered Period', 
if(month(scsp.Withdrawn_Date__c)<7, concat(year(scsp.Withdrawn_Date__c)-1,'-',year(scsp.Withdrawn_Date__c)), concat(year(scsp.Withdrawn_Date__c),'-',year(scsp.Withdrawn_Date__c)+1)) as 'De-Registered FY', 
sc.Revenue_Ownership__c,
'Work Item' as 'Invoice Group',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Id,null) as 'Invoice Id',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Name,null) as 'Invoice Name',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Invoice_Processed_Date__c,null) as 'Invoice Processed Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Closed_Date__C,null) as 'Invoice Close Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.CreatedDate,null) as 'Invoice Create Date',
if (iwi.IsDeleted=0 and iwi.Status__c not in ('Cancelled'),iwi.Total_Amount__c,null) as 'Invoice Amount'
from site_certification_standard_program__c scsp
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
left join work_package__c wp on wp.Site_Certification__c = sc.Id
left join work_item__c wi on wi.Work_Package__c = wp.Id
left join invoice_group__c igwi on sc.Invoice_Group_Work_Item__c = igwi.Id
left join invoice__c iwi on iwi.Invoice_Group__c = igwi.Id
left join invoice_line_item__c ili on ili.Invoice__c = iwi.Id
where 
scsp.De_registered_Type__c in ('SAI Initiated','Client Initiated')
and sc.Revenue_Ownership__c like 'AUS-Product Services%'