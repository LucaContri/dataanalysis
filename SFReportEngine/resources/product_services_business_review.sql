#1.0 Landscape (current clients & services) - Breakdown of clients & services 
#1.1 # of clients by pathway with drill down to program) (e.g. Business line = product services)
#1.2 We are interested in understanding the mix of work (e.g. by Program a count of certificates by Conformity Type e.g. 17065 - Type 5) Conformity type is on the standards object against the standards details.)
#1.3 client overview by location (region, country & for Australia State). I do not think we capture region in compass so if not it will need to be country.
#1.4 # of audit days by program. # of audit days as per point b. above (interested to see where we delivery the audits) can we plot this on a google map?

#2.0 Historical performance (reporting business unit starts with PROD)
#	By individual; (Year on Year & Year to date)
#2.1. On Site audit Delivery (+ travel time) e.g. auditor utilisation 
#2.2. Off Site Client Mgt (work item projects) can we extract from the billing timesheet related to projects the total hours spent?)
#2.3. Approval workload. # of ARG and work item project approvals by individual.

#explain
(select 
client.Id as 'Client Id', 
client.name as 'Client Name', 
sdc.Name as 'SDC',
rm.Name as 'Relationship Manager',
pm.Name as 'Project Manager',
csp.Id as 'Cert Std Id', 
csp.Name as 'Cert Std',
scsp.Id as 'Site Cert Std Id',
scsp.Name as 'Site Cert Std',
sc.Id as 'Site Cert Id',
sc.Name as 'Site Cert',
site.Id as 'Client Site Id',
site.Name as 'Client Site',
ccs.Region__c as 'Region',
ccs.Product_Services_Region__c as 'PS Region',
ccs.Name as 'Country',
scs.Name as 'State',
site.Business_City__c as 'City',
site.Business_Zip_Postal_Code__c as 'PostCode',
site.Location__c as 'Location',
p.Business_Line__c as 'Business Line', 
p.Pathway__c as 'Pathway', 
p.Name as 'Program', 
s.Conformity_Type__c as 'Conformity Type', 
s.Name as 'Standard',
year(if(wi.Work_Item_Date__c is null,wi.Project_Start_Date__c,wi.Work_Item_Date__c )) as 'Year',
if(month(if(wi.Work_Item_Date__c is null,wi.Project_Start_Date__c,wi.Work_Item_Date__c ))<7,year(if(wi.Work_Item_Date__c is null,wi.Project_Start_Date__c,wi.Work_Item_Date__c )), year(if(wi.Work_Item_Date__c is null,wi.Project_Start_Date__c,wi.Work_Item_Date__c ))+1) as 'F.Y.',
wi.Id as 'Work Item Id',
wi.name as 'Work Item',
if(wi.Work_Item_Date__c is null,wi.Project_Start_Date__c,wi.Work_Item_Date__c ) as 'WI/Project Start Date',
wi.Work_Package_Type__c as 'Work Package Type',
wi.Work_Item_Stage__c as 'Work Item Type',
wi.Required_Duration__c as 'Required Duration',
wi.Status__c as 'Work Item Status',
max(tsli.CreatedDate) as 'TSLI Max Date',
if(month(max(tsli.CreatedDate)<7), year(max(tsli.CreatedDate)), year(max(tsli.CreatedDate))+1) as 'TSLI max F.Y.',
sum(if(tsli.Category__c='Audit',tsli.Actual_Hours__c,0)) as 'Audit - Actual Hrs',
sum(if(tsli.Category__c='Client Management',tsli.Actual_Hours__c,0)) as 'Client Management - Actual Hrs',
sum(if(tsli.Category__c='Project Time',tsli.Actual_Hours__c,0)) as 'Project Time - Actual Hrs',
sum(if(tsli.Category__c='Report Writing',tsli.Actual_Hours__c,0)) as 'Report Writing - Actual Hrs',
sum(if(tsli.Category__c='Review/Approval',tsli.Actual_Hours__c,0)) as 'Review/Approval - Actual Hrs',
sum(if(tsli.Category__c='Travel',tsli.Actual_Hours__c,0)) as 'Travel - Actual Hrs',
sum(if(tsli.Billable__c='Billable',tsli.Actual_Hours__c,0)) as 'Billable - Actual Hrs',
sum(if(tsli.Billable__c='Non-Billable',tsli.Actual_Hours__c,0)) as 'Non-Billable - Actual Hrs',
sum(if(tsli.Billable__c='Pre-paid',tsli.Actual_Hours__c,0)) as 'Pre-paid - Actual Hrs',
tsli.Resource_Name__c as 'TSLI Resource',
arg.Id as 'ARG Id',
arg.Name as 'ARG',
arg.CA_Approved__c as 'CA Approved',
if(month(arg.CA_Approved__c)<7, year(arg.CA_Approved__c), year(arg.CA_Approved__c)+1) as 'CA Approved F.Y.',
ca.Name as 'Certification Approver',
ca.Reporting_Business_Units__c as 'CA Reporting Business Unit'
from salesforce.account client
inner join salesforce.certification__c c on c.Primary_client__c = client.Id
inner join salesforce.certification_standard_program__c csp on csp.Certification__c = c.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on s.Program__c = p.Id
left join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.timesheet_line_item__c tsli on tsli.Work_Item__c = wi.Id 
left join salesforce.arg_work_item__c argwi on argwi.RWork_Item__c = wi.Id and argwi.IsDeleted = 0
left join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id and arg.IsDeleted = 0
left join salesforce.resource__c ca on arg.Assigned_CA__c = ca.Id
left join salesforce.user sdc on client.Service_Delivery_Coordinator__c = sdc.Id
left join salesforce.user rm on client.Relationship_Manager__c = rm.Id
left join salesforce.resource__c pm on c.Project_Manager_2__c = pm.Id
where
csp.Status__c in ('Applicant', 'Registered', 'Customised')
and scsp.Status__c in ('Applicant', 'Registered', 'Customised')
and csp.IsDeleted = 0
and scsp.IsDeleted = 0
and wi.IsDeleted=0 
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service')
and p.Business_Line__c = 'Product Services'
group by wi.Id);

#3.0 Skills coverage
#3.1 Existing Product Services Staff  (employees & contractors)– summary of skill set + home office
#3.2 An inventory of  “non product services” who are signed off to delivery product services work 

(select 
r.Reporting_Business_Units__c as 'Reporting Business Unit', 
r.Id as 'Resource Id', 
r.Name as 'Resource Name', 
r.Resource_Type__c as 'Resource Type', 
ccs.Name as 'Home Country', 
p.Business_Line__c as 'Busienss Line',
p.Pathway__c as 'Pathway',
p.Program_Code__c as 'Program Code', 
p.Name as 'Program', 
s.Name as 'Standard', 
rc.Rank__c as 'Ranks'

from salesforce.resource__c r
inner join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
inner join salesforce.resource_competency__c rc on rc.Resource__c = r.Id
inner join salesforce.standard__c s on rc.Standard__c = s.Id
inner join salesforce.program__c p on s.Program__c = p.Id
where 
r.Status__c = 'Active'
and rc.Status__c = 'Active'
and r.IsDeleted = 0
and rc.IsDeleted = 0
and (p.Business_Line__c = 'Product Services'
	or r.Reporting_Business_Units__c like '%Product%')
);

#4.0 Current State
#4.1 Performance Metrics . e.g. daily metrics with product filters. 
#4.2 Current backlog with aging (work is covered by the daily metrics not sure about projects.. Projects.. Can we get a snapshot of projects by aging)
#4.3 This is scary.. We need to understand our exposure with overdue audits. Can we get a High level analysis of overdue audits (by program by region) 

(select * from analytics.ps_ops_metrics);

(select wi.Id as 'Work Item Id', wi.name as 'Work Item', p.Business_Line__c as 'Business Line', p.Pathway__c as 'Pathway', p.Name as 'Program', s.Name as 'Standard', wi.Status__c as 'Status', wi.Work_Item_Stage__c as 'Type', wi.Work_Item_Date__c as 'Date'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
wi.IsDeleted = 0
and wi.Status__c in ('Open','Scheduled','Scheduled - Offered')
and wi.Work_Item_Date__c<utc_timestamp()
and wi.Work_Item_Stage__c not in ('Product Update','Initial Project')
and p.Business_Line__c = 'Product Services');