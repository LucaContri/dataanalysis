set @travel_rate = 
(select 
  sum(if(wir.Work_Item_Type__c = 'Travel', wir.Total_Duration__c ,0 ))/sum(if(wir.Work_Item_Type__c = 'Audit', wir.Total_Duration__c ,0 ))
from salesforce.work_item__c wi
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id 
 where
 wi.IsDeleted= 0
 and wir.IsDeleted = 0 
 and wir.Work_Item_Type__c in ('Audit', 'Travel')
 and rt.Name = 'Audit'
 and wi.Work_Item_Date__c between '2016-01-01' and '2017-06-30'
 and wi.Status__c in ('Completed')
 and wi.Revenue_Ownership__c like '%Product%');

# Audits
 (select 
  if(wir.Id is null, 'Forecast', 'Actual') as 'Type',
  rt.Name as 'Record Type',
  replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
  analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
  ccs.Name as 'Primary Site Country',
  ifnull(r.Reporting_Business_Units__c, '') as 'Reporting Business Unit', 
  ifnull(r.Resource_Type__c, '') as 'Resource Type', 
  ifnull(r.Id, '') as 'Resource Id', 
  ifnull(r.Name, '') as 'Resource', 
  ifnull(m.Name, '') as 'Manager',
  wi.Id as 'Work Item Id', 
  wi.Name as 'Work Item', 
  ifnull(wir.Work_Item_Type__c, 'Audit') as 'Resource Work Type', 
  wi.Status__c as 'Work Item Status',
  wi.Revenue_Ownership__c as 'Revenue Ownership',
  p.Business_Line__c as 'Business Line', 
  p.Pathway__c as 'Pathway',
  p.Name as 'Program', 
  s.Name as 'Standard', 
  wi.Work_Item_Date__c as 'Date', 
  date_format(wi.Work_Item_Date__c , '%Y %m') as 'Period',
  year(wi.Work_Item_Date__c) + if(month(wi.Work_Item_Date__c)<7,0,1) as 'F.Y.',
  ifnull(sum(wir.Total_Duration__c)/8,0) as 'Actual Duration (Days)',
  if(wir.Work_Item_Type__c is null, wi.Required_Duration__c, sum(wir.Total_Duration__c))/8 as 'Estimated Duration (Days)',
  if(wir.Work_Item_Type__c is null, wi.Required_Duration__c, sum(wir.Total_Duration__c))/8/0.8 as 'Resource Days' # 1.25 Days per Audit Day to allow for office days, etc...
from salesforce.work_item__c wi
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
 left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.IsDeleted = 0 and wir.Work_Item_Type__c in ('Audit', 'Travel')
 left join salesforce.resource__c r on wir.Resource__c = r.Id
 left join salesforce.user u on r.User__c = u.Id
 left join salesforce.user m on u.ManagerId = m.Id
where
 wi.IsDeleted= 0
 and rt.Name = 'Audit'
 and wi.Work_Item_Date__c between '2013-01-01' and '2018-06-30'
 and wi.Status__c not in ('Cancelled','Draft', 'Initiate Service','Budget')
 and wi.Revenue_Ownership__c like '%Product%'
group by wi.Id, `Resource Work Type`)
union all
 # Estimated Travel
 (select 
 'Forecast' as 'Type',
  rt.Name as 'Record Type',
  replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
  analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
  ccs.Name as 'Primary Site Country',
  '' as 'Reporting Business Unit', 
  '' as 'Resource Type', 
  '' as 'Resource Id', 
  '' as 'Resource', 
  '' as 'Manager',
  wi.Id as 'Work Item Id', 
  wi.Name as 'Work Item', 
  'Travel' as 'Resource Work Type', 
  wi.Status__c as 'Work Item Status',
  wi.Revenue_Ownership__c as 'Revenue Ownership',
  p.Business_Line__c as 'Business Line', 
  p.Pathway__c as 'Pathway',
  p.Name as 'Program', 
  s.Name as 'Standard', 
  wi.Work_Item_Date__c as 'Date', 
  date_format(wi.Work_Item_Date__c , '%Y %m') as 'Period',
  year(wi.Work_Item_Date__c) + if(month(wi.Work_Item_Date__c)<7,0,1) as 'F.Y.',
  0 as 'Actual Duration (Days)',
  wi.Required_Duration__c/8*@travel_rate as 'Estimated Duration (Days)',
  wi.Required_Duration__c/8*@travel_rate/0.8 as 'Resource Days' # 1.25 Days per Audit Day to allow for office days, etc...
from salesforce.work_item__c wi
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
 left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.IsDeleted = 0 and wir.Work_Item_Type__c in ('Audit', 'Travel')
where
 wi.IsDeleted= 0
 and rt.Name = 'Audit'
 and wi.Work_Item_Date__c between '2013-01-01' and '2018-06-30'
 and wi.Status__c not in ('Cancelled','Draft', 'Initiate Service','Budget')
 and wi.Revenue_Ownership__c like '%Product%'
 and wir.Id is null
group by wi.Id, `Resource Work Type`)
union all
 # Projects
(select 
'Actual' as 'Type',
 rt.Name as 'Record Type',
 replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
 analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
 ccs.Name as 'Primary Site Country',
 r.Reporting_Business_Units__c as 'Reporting Business Unit', 
 r.Resource_Type__c as 'Resource Type', 
 r.Id as 'Resource Id', 
 r.Name as 'Resource', 
 m.Name as 'Manager',
 wi.Id as 'Work Item Id', 
 wi.Name as 'Work Item', 
 wi.Work_Item_Stage__c as 'Resource Work Type', 
 wi.Status__c as 'Work Item Status',
 wi.Revenue_Ownership__c as 'Revenue Ownership', 
 p.Business_Line__c as 'Business Line', 
 p.Pathway__c as 'Pathway',
 p.Name as 'Program', 
 s.Name as 'Standard',
 ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c) 'Date',
 date_format(ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c), '%Y %m')  as 'Period',
 year(ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c)) + if(month(ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c))<7,0,1) as 'F.Y.',
 ifnull(sum(tsli.Actual_Hours__c),0)/8 as 'Actual Duration (Days)',
 analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60/8 as 'Estimated Duration (Days)',
 analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c)/60/8/0.72 as 'Resource Days' # Estimated Duration (Days) at 72% Productivity 
from salesforce.work_item__c wi
 left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
 left join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
 left join salesforce.user u on r.User__c = u.Id
 left join salesforce.user m on u.ManagerId = m.Id
where
 wi.IsDeleted= 0
 and rt.Name = 'Project'
 and wi.Status__c in ('Completed')
 and wi.Revenue_Ownership__c like '%Product%'
 and ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c) between '2013-01-01' and '2018-06-30'
group by wi.Id)
union all
#CA Approvals
(select 
 'Actual' as 'Record Type',
 'ARG' as 'Record Type',
 replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
 analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
 ccs.Name as 'Primary Site Country',
 r.Reporting_Business_Units__c as 'Reporting Business Unit', 
 r.Resource_Type__c as 'Resource Type', 
 r.Id as 'Resource Id', 
 r.Name as 'Resource', 
 m.Name as 'Manager',
 arg.Id as 'Record Id', 
 arg.Name as 'Record Name', 
 'CA Approvals' as 'Resource Work Type', 
 'n/a' as 'Work Item Status',
 group_concat(distinct wi.Revenue_Ownership__c) as 'Revenue Ownership',  
 p.Business_Line__c as 'Business Line', 
 p.Pathway__c as 'Pathway',
 p.Name as 'Program', 
 s.Name as 'Standard', 
 max(ah.CreatedDate) as 'Date', 
 date_format(max(ah.CreatedDate), '%Y %m') as 'Period', 
 year((max(ah.CreatedDate))) + if(month(max(ah.CreatedDate))<7,0,1) as 'F.Y.',
 count(distinct ah.Id)*30/60/8 as 'Actual Duration (Days)', # 30 mins per ARG review
 count(distinct ah.Id)*30/60/8 as 'Estimated Duration (Days)', # 30 mins per ARG review
 count(distinct ah.Id)*30/60/8/0.72 as 'Resource Days' # Estimated Duration (Days) at 72% productivity 
from salesforce.approval_history__c ah
 inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
 inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
 inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
 left join salesforce.resource__c r on ah.RApprover__c = r.Id
 left join salesforce.user u on r.User__c = u.Id
 left join salesforce.user m on u.ManagerId = m.Id
where
 arg.IsDeleted= 0
 and ah.IsDeleted = 0
 and argwi.IsDeleted = 0
 and ah.CreatedDate between '2013-01-01' and '2017-06-30'
 and ah.Status__c = 'Approved'
 and ah.Assigned_To__c = 'Client Administration'
 and wi.Revenue_Ownership__c like '%Product%'
 and rt.Name = 'Audit'
group by arg.Id)
union all
(select 
 'Forecast' as 'Type',
 'WI' as 'Record Type',
 replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
 analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
 ccs.Name as 'Primary Site Country',
 '' as 'Reporting Business Unit', 
 '' as 'Resource Type', 
 '' as 'Resource Id', 
 '' as 'Resource', 
 '' as 'Manager',
 wi.Id as 'Record Id', 
 wi.Name as 'Record Name', 
 'CA Approvals' as 'Resource Work Type', 
 'n/a' as 'Work Item Status',
 group_concat(distinct wi.Revenue_Ownership__c) as 'Revenue Ownership',  
 p.Business_Line__c as 'Business Line', 
 p.Pathway__c as 'Pathway',
 p.Name as 'Program', 
 s.Name as 'Standard', 
 wi.Work_Item_Date__c as 'Date', 
 date_format(wi.Work_Item_Date__c, '%Y %m') as 'Period', 
 year(wi.Work_Item_Date__c) + if(month(wi.Work_Item_Date__c)<7,0,1) as 'F.Y.',
 0 as 'Actual Duration (Days)', # 30 mins per ARG review
 30/60/8 as 'Estimated Duration (Days)', # 30 mins per ARG review
 30/60/8/0.72 as 'Resource Days' # Estimated Duration (Days) at 72% productivity 
from salesforce.work_item__c wi 
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 left join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id and argwi.IsDeleted = 0
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
where
 wi.Work_Item_Date__c between '2013-01-01' and '2018-06-30'
 and wi.Revenue_Ownership__c like '%Product%'
 and argwi.Id is null
 and rt.Name = 'Audit'
group by wi.Id)
