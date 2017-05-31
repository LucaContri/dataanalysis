#indexes
create index site_cert_standard_program_index on Site_Certification_Standard_Program__c(Site_Certification__c);
create index Certification_Standard_Program_index on Certification_Standard_Program__c(Certification__c);
# All planned DHSS/DSV Audits
#explain
select 
c.Primary_Client_Name__c as 'Client Name', 
sc.Primary_Client_Location__c as 'Location',
wi.Primary_Standard__c as 'Primary Standard', 
wi.Work_Item_Stage__c as 'Type', 
wi.Status__c as 'Status', 
wi.Earliest_Service_Date__c as 'Start Service Date', 
wi.End_Service_Date__c as 'End Service Date', 
scsp.SAI_Certification_Std_Certificate_Number__c as 'SAI Certificate Number', 
wi.Name as 'Work Item', 
sc.Name as 'Site Certification'
from work_item__c wi
inner join work_package__c wp on wi.Work_Package__c = wp.Id
inner join certification__c sc on wp.Site_Certification__c = sc.Id
inner join Site_Certification_Standard_Program__c scsp on scsp.Site_Certification__c = sc.Id
inner join certification__c c on sc.Primary_Certification__c = c.Id
where (wi.Primary_Standard__c like 'Department of Human Services Standards%'
or wi.Primary_Standard__c like 'Standards for Disability Services in Victoria%')
and wi.IsDeleted=0
and wi.Status__c not in ('Cancelled', 'Open', 'Inititate service')
and date_format(wi.Earliest_Service_Date__c, '%Y %m')>=date_format(now(), '%Y %m')
and date_format(wi.Earliest_Service_Date__c, '%Y %m')<=date_format(date_add(now(), interval 5 month), '%Y %m');


#'Core Standards for Safety and Quality in Healthcare - 2007 | Certification','NSQHS Standard 2011 Mental Health Services | Certification','NSQHS Standard 2011 Dental Services | Certification'
#explain
select 
scs.Name as 'State',
if (site.Site_Description__c is null, sc.Primary_Client_Name__c, site.Site_Description__c) as 'Name of all Heath Service Organisations Assessed',
#c.Primary_Client_Name__c, 
#sc.Primary_Client_Name__c, 
#site.Site_Description__c, 
scsp.SAI_Certification_Std_Certificate_Number__c as 'SAI Certificate Number',
csp.Scope__c as 'Scope',
'' as 'Type of Service',
'' as 'Public or Private',
if (wi.Work_Item_Stage__c in ('Re-Certification','Certification'),'Organisational Wide', 'Mid-Cycle') as 'Organisational Wide or Mid-Cycle',
wi.End_Service_Date__c as 'Date Assessed',
csp.Expires__c as 'Date of Determination of Certification Status',
if (csp.Status__c in ('Registered'),'Certified', 'Not Certified') as 'Status (Certified, Not Certified)'
#wi.Id, wi.Name, wi.Status__c, wi.Primary_Standard__c
from work_item__c wi
inner join work_package__c wp on wi.Work_Package__c = wp.Id
inner join certification__c sc on wp.Site_Certification__c = sc.Id
inner join Site_Certification_Standard_Program__c scsp on scsp.Site_Certification__c = sc.Id
inner join certification__c c on sc.Primary_Certification__c = c.Id
inner join Certification_Standard_Program__c csp on csp.Certification__c = c.Id
inner join account site on sc.Primary_client__c = site.Id
inner join state_code_setup__c scs on scs.Id = site.Business_State__c
where
(wi.Primary_Standard__c like 'Core Standards for Safety and Quality in Healthcare%'
or wi.Primary_Standard__c like 'NSQHS Standard 2011 Mental Health Services%'
or wi.Primary_Standard__c like 'NSQHS Standard 2011 Dental Services%')
and wi.IsDeleted = 0
and wi.Status__c not in ('Open','Scheduled','Scheduled - Offered', 'Initiate service', 'Service Change', 'Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y %m') = date_format(date_add(now(), interval -1 month), '%Y %m');

use salesforce;
select 
wi.Client_Name_No_Hyperlink__c as 'Client',
wi.Client_Site__c as 'Site',
wi.Primary_Standard__c as 'Standard',
wi.Name as 'Work Item',
wi.Work_Item_Stage__c as 'Stage',
wi.Status__c as 'Status',
wi.work_item_Date__c as 'Date'
from work_item__c wi
where
(wi.Primary_Standard__c like 'Core Standards for Safety and Quality in Healthcare%'
or wi.Primary_Standard__c like 'NSQHS Standard 2011 Mental Health Services%'
or wi.Primary_Standard__c like 'NSQHS Standard 2011 Dental Services%' 
or wi.Primary_Standard__c like '%NSQHS%')
and wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled')
and date_format(wi.Work_Item_Date__c, '%Y') = '2015'