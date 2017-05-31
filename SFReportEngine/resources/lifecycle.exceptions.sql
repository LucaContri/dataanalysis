select sc.Revenue_Ownership__c, sc.Name, sc.Lifecycle_Validated__c, scl.Id, scl.Name, scl.Frequency__c, scl.Duration__c, scl.fTarget_Date__c, scl.Meta_Work_Item_Stage__c, scl.fWork_Item_Status__c  
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
where
sc.Status__c = 'Active'
and sc.IsDeleted = 0
and scsp.IsDeleted = 0
and scl.IsDeleted = 0
and scsp.Status__c in ('Registered','Customised')
and sc.Lifecycle_Validated__c = 1
and sc.Revenue_Ownership__c like 'AUS%';

# Lifecycle Exception 1 - multiple work item same target date
#select if(t.Revenue_Ownership__c like 'AUS%', 'Australia', substring_index(t.Revenue_Ownership__c, '-',2)) as 'Region', count(t.Id) from (
select * from (
select sc.Revenue_Ownership__c, sc.Id, sc.Name, sc.Lifecycle_Validated__c, scl.fTarget_Date__c, count(scl.Id) as 'Count'
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join salesforce.work_item__c wi on scl.Work_Item__c = wi.Id
where
sc.Status__c = 'Active'
and sc.IsDeleted = 0
and scsp.IsDeleted = 0
and scl.IsDeleted = 0
and scsp.Status__c in ('Registered')
and sc.Lifecycle_Validated__c = 1
#and sc.Revenue_Ownership__c like 'Asia-Indonesia%'
and sc.Revenue_Ownership__c like 'AUS%'
and wi.Status__c not in ('Cancelled')
group by sc.Id, scl.fTarget_Date__c) t
where t.Count > 1
;#group by `Region`;

# Lifecycle Exception 2 - Frequency not matching count
select t.* from (
select sc.Revenue_Ownership__c, sc.Name, sc.Id, sc.Lifecycle_Validated__c, min(cast(scl.Frequency__c as unsigned)) as 'Frequency__c', year(scl.fTarget_Date__c) as 'Year', count(distinct scl.fTarget_Date__c) as 'count', group_concat(distinct wi.work_item_stage__c) as 'Stages'
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join salesforce.work_item__c wi on scl.Work_Item__c = wi.Id
where
sc.Status__c = 'Active'
and sc.IsDeleted = 0
and scsp.IsDeleted = 0
and scl.IsDeleted = 0
and scsp.Status__c in ('Registered','Customised')
and sc.Lifecycle_Validated__c = 1
and wi.Status__c not in ('Cancelled')
#and wi.Work_Item_Stage__c in ('Surveillance')
#and sc.Revenue_Ownership__c like 'Asia-Indonesia%'
and sc.Revenue_Ownership__c like 'AUS%'
#and sc.Id='a1kd0000000Qv6bAAC'
and year(scl.fTarget_Date__c)>=2015
group by sc.Id, `Year`
order by sc.Id, `Year`
) t
where 
(t.`Frequency__c`=6 and t.`count`=1 and `year` in (2016,2017) and t.`Stages` = 'Surveillance'); 
#(t.`Frequency__c`=12 and t.`count`>1 and t.`Stages` = 'Surveillance'); #or (t.`Frequency__c`=6 and t.`count`<>2);

select t2.* from (
select t.* from (
select sc.Revenue_Ownership__c, sc.Name, sc.Id, sc.Lifecycle_Validated__c, scl.Frequency__c , scl.fTarget_Date__c, csp.Expires__c, wi.work_item_stage__c, datediff(csp.Expires__c, scl.fTarget_Date__c)
from salesforce.site_certification_lifecycle__c scl
inner join salesforce.certification__c sc on scl.Site_Certification__c = sc.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
inner join salesforce.work_item__c wi on scl.Work_Item__c = wi.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where
sc.Status__c = 'Active'
and sc.IsDeleted = 0
and scsp.IsDeleted = 0
and scl.IsDeleted = 0
and scsp.Status__c in ('Registered','Customised')
and sc.Lifecycle_Validated__c = 1
and wi.Work_Item_Stage__c in ('Re-Certification')
#and sc.Revenue_Ownership__c like 'Asia-Indonesia%'
and sc.Revenue_Ownership__c like 'AUS%'
and scl.fTarget_Date__c>'2015-09-30'
and wi.Status__c in ('Open', 'Scheduled - Offered','Scheduled','In Progress','Service change', 'Confirmed')
#and sc.Id='a1kd00000009Dg0AAE'
order by sc.Id, scl.fTarget_Date__c) t
group by t.Id) t2
where t2.fTarget_Date__c > t2.Expires__c;

