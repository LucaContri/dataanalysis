#explain
(select 
o.Business_1__c,
o.Id as 'Opp Id', 
o.Type as 'Opp Type', 
o.CloseDate as 'Opp Closed Date', 
date_format(o.CloseDate, '%Y %m') as 'Opp Closed Period', 
o.Total_First_Year_Revenue__c as 'Opp First Year Revenues',
ifnull(sc.Id,'') as 'Site Cert Id',
ifnull(sc.Status__c,'') as 'Site Cert Status',
ifnull(wi.Id,'') as 'Work Item Id',
ifnull(wi.Work_Package_Type__c,'') as 'Work Package Type',
ifnull(wi.Status__c,'') as 'Work Item Status',
ifnull(wi.Open_Sub_Status__c,'') as 'Work Item Open SubStatus',
ifnull(group_concat(if(wih.IsDeleted=0 and wih.Field = 'Open_Sub_Status__c', wih.NewValue, null)),'') as 'All Open Sub Statuses',
sum(if(wih.IsDeleted=0 and wih.Field = 'Service_Target_Month__c', 1, 0)) as '# Changes to Target Month',
sum(if(wih.IsDeleted=0 and wih.Field = 'Service_Target_Year__c', 1, 0)) as '# Changes to Target Year',
ifnull(wi.Work_Item_Stage__c,'') as 'Work Item Type',
ifnull(wi.Comments__c,'') as 'Work Item Comment',
ifnull(if(wi.Status__c in ('Completed','In Progress','Under Review','Under Review - Rejected', 'Submitted','Support'), 1,0),'') as 'Completed',
ifnull(wi.Work_Item_Date__c,'') as 'Work Item Start Date',
ifnull(date_format(wi.Work_Item_Date__c, '%Y %m'),'') as 'Work Item Start Period',
ifnull(datediff(wi.Work_Item_Date__c, o.CloseDate),'') as 'Opp Closed To WI Start Days',
ifnull(if(datediff(wi.Work_Item_Date__c, o.CloseDate)<365,1,0),'') as 'First Year',
ifnull(wi.Required_Duration__c/8,'') as 'Work Item Days',
if(sc.Id is null, false, true) as 'SiteCertLinked'
#Opp Closed FY,
#Opp Closed To WI Start Months
from salesforce.opportunity o 
left join salesforce.certification__c sc on o.Id = sc.Opportunity_Created_From__c
left join salesforce.work_package__c wp on wp.Site_Certification__c = sc.Id
left join salesforce.work_item__c wi on wi.Work_Package__c = wp.Id
left join salesforce.work_item__history wih on wih.ParentId = wi.Id
where
o.IsDeleted = 0 
and o.Business_1__c = 'Australia'
and o.StageName='Closed Won'
#and (sc.Status__c = 'Active' or sc.Id is null)
and (sc.IsDeleted = 0 or sc.Id is null)
and (wp.IsDeleted=0 or wp.Id is null)
and (wi.IsDeleted=0 or wi.Id is null)
#and wi.Status__c not in ('Cancelled', 'Draft', 'Initiate Service')
#and wi.Work_Item_Date__c is not null
and (wi.Work_Package_Type__c = 'Initial' or wi.Id is null)
and (sc.Primary_Certification__c is not null or sc.Id is null)
group by o.Id, sc.Id, wi.Id
order by o.Id, o.CloseDate, sc.Id, wi.Work_Item_Date__c);

(select 
o.Business_1__c,
o.Id as 'Opp Id', 
o.Type as 'Opp Type', 
o.CloseDate as 'Opp Closed Date', 
date_format(o.CloseDate, '%Y %m') as 'Opp Closed Period', 
o.Total_First_Year_Revenue__c as 'Opp First Year Revenues',
ifnull(sc.Id,'') as 'Cert Id',
if(sc.Id is null, false, true) as 'CertLinked'
from salesforce.opportunity o 
left join salesforce.certification__c sc on o.Id = sc.Opportunity_Created_From__c
where
o.IsDeleted = 0 
and o.Business_1__c = 'Australia'
and o.StageName='Closed Won'
and (sc.IsDeleted = 0 or sc.Id is null)
and (sc.Primary_Certification__c is null or sc.Id is null)
group by o.Id);

select Id, Opportunity_Created_From__c from salesforce.certification__c where Id = 'a1kd0000000RWfMAAW';

select Id, name from salesforce.certification__c where Opportunity_Created_From__c ='006d000000OqF9lAAF' and Primary_Certification__c is not null;
