#PM and SDC by Certification with Business Line = 'Product Services'
(select 
rt.Name as 'Record Type', 
a.Client_Ownership__c as 'Client Ownership',
replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
ccs.Name as 'Primary Site Country', 
a.Id as 'Account Id', 
a.Name as 'Account', 
c.Id as 'Certification Id', 
c.Name as 'Certification',
csp.NAme as 'Cert Std',
csp.Status__c as 'Cert Std Status',
sdc.Name as 'SDC',
sdcm.Name as 'SDC Manager',
pm.Name as 'PM',
pmm.Name as 'PM Manager',
p.Business_Line__c as 'Business Line',
p.Pathway__c as 'Pathway',
p.Name as 'Program',
s.Name as 'Standard'
from salesforce.account a
inner join salesforce.recordtype rt on a.RecordTypeId = rt.Id
inner join salesforce.certification__c c on c.Primary_client__c = a.Id
inner join salesforce.certification_standard_program__c csp on csp.Certification__c = c.Id
inner join salesforce.standard_program__c sp on csp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id and sc.Primary_Site__c = 1
left join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.user sdc on a.Service_Delivery_Coordinator__c = sdc.Id
left join salesforce.user sdcm on sdc.ManagerId = sdcm.Id
left join salesforce.resource__c pm on c.Project_Manager_2__c = pm.Id
left join salesforce.user pmu on pm.User__c = pmu.Id
left join salesforce.user pmm on pmu.ManagerId = pmm.Id
where 
#a.Client_Ownership__c = 'Product Services'
p.Business_Line__c = 'Product Services'
and rt.Name in ('Client')
and c.Status__c = 'Active' 
and c.IsDeleted = 0
and csp.Status__C in ('Applicant','Registered','Customised')
#and a.ID= '00190000008nXNFAA2' #Bloomer Corporation Limited
group by a.Id, c.Id);

#Preferred Resource by Site Certification with Business Line = 'Product Services'
(select 
rt.Name as 'Record Type', 
a.Client_Ownership__c as 'Client Ownership',
replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
ccs.Name as 'Primary Site Country', 
a.Id as 'Account Id', 
a.Name as 'Account', 
c.Id as 'Certification Id', 
c.Name as 'Certification',
csp.NAme as 'Cert Std',
csp.Status__c as 'Cert Std Status',
sc.id as 'Site Cert Id',
sc.Name as 'Site Cert',
sdc.Name as 'SDC',
sdcm.Name as 'SDC Manager',
pm.Name as 'PM',
pmm.Name as 'PM Manager',
p.Business_Line__c as 'Business Line',
p.Pathway__c as 'Pathway',
p.Name as 'Program',
s.Name as 'Standard',
sc.Preferred_Resource_1__c,
pr.Name as 'Preferred Resource',
prm.Name as 'Preferred Resource Manager'

from salesforce.account a
inner join salesforce.recordtype rt on a.RecordTypeId = rt.Id
inner join salesforce.certification__c c on c.Primary_client__c = a.Id
inner join salesforce.certification_standard_program__c csp on csp.Certification__c = c.Id
inner join salesforce.standard_program__c sp on csp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.certification__c sc on sc.Primary_Certification__c = c.Id
left join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.user sdc on a.Service_Delivery_Coordinator__c = sdc.Id
left join salesforce.user sdcm on sdc.ManagerId = sdcm.Id
left join salesforce.resource__c pm on c.Project_Manager_2__c = pm.Id
left join salesforce.user pmu on pm.User__c = pmu.Id
left join salesforce.user pmm on pmu.ManagerId = pmm.Id
left join salesforce.resource__c pr on sc.Preferred_Resource_1__c = pr.Id
left join salesforce.user pru on pr.User__c = pru.Id
left join salesforce.user prm on pru.ManagerId = prm.Id
where 
p.Business_Line__c = 'Product Services'
and rt.Name in ('Client')
and c.Status__c = 'Active' 
and c.IsDeleted = 0
and csp.Status__C in ('Applicant','Registered','Customised')
and sc.Status__C = 'Active'
group by a.Id, c.Id, sc.Id);

#Number of audit days per year by location as per example 1 (with slicer for pathway, e.g. Building and Infrastructure, Health and Safety, Appliances, Plumbing and Water)

(select 
 rt.Name as 'Record Type',
 replace(if(ccs.Name = 'Australia', 'Australia', analytics.getRegionFromCountry(ccs.Name)), 'APAC', 'Asia') as 'Primary Site Region 2',
 analytics.getRegionFromCountry(ccs.Name) as 'Primary Site Region',  
 ccs.Name as 'Primary Site Country',
 wi.Id as 'Work Item Id', 
 wi.Name as 'Work Item', 
 wi.Status__c as 'Work Item Status',
 wi.work_item_date__C as 'Date', 
 date_format(wi.Work_Item_Date__c , '%Y %m') as 'Period',
 '' as 'Actual Duration',
 wi.Required_Duration__c/8 as 'Days',
 p.Business_Line__c as 'Business Line', 
 p.Pathway__c as 'Pathway',
 p.Name as 'Program', 
 s.Name as 'Standard'
from salesforce.work_item__c wi
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
where
 wi.IsDeleted= 0
 and wi.Work_Item_Date__c is not null
 and wi.Work_Item_Date__c between '2013-01-01' and '2017-12-31'
 and rt.Name = 'Audit'
 and wi.Status__c not in ('Budget','Cancelled')
 and p.Business_Line__c = 'Product Services');
 
 # Audits
 (select 
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
  wir.Work_Item_Type__c as 'Resource Work Type', 
  wi.Status__c as 'Work Item Status',
  wi.Revenue_Ownership__c as 'Revenue Ownership',
  p.Business_Line__c as 'Business Line', 
  p.Pathway__c as 'Pathway',
  p.Name as 'Program', 
  s.Name as 'Standard', 
  wi.Work_Item_Date__c as 'Date', 
  date_format(wi.Work_Item_Date__c , '%Y %m') as 'Period',
  sum(wir.Total_Duration__c)/8 as 'Actual Duration (Days)',
  if(wir.Work_Item_Type__c = 'Audit', wi.Required_Duration__c, sum(wir.Total_Duration__c))/8 as 'Estimated Duration (Days)',
  if(wir.Work_Item_Type__c = 'Audit', wi.Required_Duration__c, sum(wir.Total_Duration__c))/8/0.8 as 'Resource Days' # 1.25 Days per Audit Day to allow for office days, etc...
from salesforce.work_item__c wi
 inner join salesforce.recordtype rt on wi.RecordTypeId = rt.Id
 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
 inner join salesforce.account site on sc.Primary_Client__c = site.Id
 left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
 inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
 inner join salesforce.standard__c s on sp.Standard__c = s.Id
 inner join salesforce.program__c p on sp.Program__c = p.Id
 inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
 inner join salesforce.resource__c r on wir.Resource__c = r.Id
 left join salesforce.user u on r.User__c = u.Id
 left join salesforce.user m on u.ManagerId = m.Id
where
 wi.IsDeleted= 0
 and wir.IsDeleted = 0
 and wir.Work_Item_Type__c in ('Audit', 'Travel')
 and rt.Name = 'Audit'
 and wi.Work_Item_Date__c between '2013-01-01' and '2016-12-31'
 and wi.Status__c in ('Completed', 'In Progress', 'Under Review', 'Under Review - Rejected', 'Submitted', 'Support')
 and wi.Revenue_Ownership__c like '%Product%'
group by wi.Id, wir.Work_Item_Type__c)
union all
 # Projects
(select 
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
 and ifnull(wi.Project_End_Date__c,wi.Project_Projected_End_Date__c) between '2013-01-01' and '2017-12-31'
group by wi.Id)
union all
#CA Approvals
(select 
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
 count(distinct ah.Id)*30/60/8 as 'Actual Duration (Days)', # 30 mins per ARG review
 count(distinct ah.Id)*30/60/8 as 'Estimated Duration (Days)', # 30 mins per ARG review
 count(distinct ah.Id)*30/60/8/0.72 as 'Resource Days' # Estimated Duration (Days) at 72% productivity
 
from salesforce.approval_history__c ah
 inner join salesforce.audit_report_group__c arg on arg.Id = ah.RAudit_Report_Group__c
 inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
 inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
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
 and ah.CreatedDate between '2013-01-01' and '2016-12-31'
 and ah.Status__c = 'Approved'
 and ah.Assigned_To__c = 'Client Administration'
 and wi.Revenue_Ownership__c like '%Product%'
group by arg.Id)