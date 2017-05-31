use salesforce;
create or replace view emea_pack_renewals as
select
sc.Name as 'SF Site Certification',
csp.Name as 'Certification standard Num',
ifnull(date_format(csp.Re_Audit_Due_Date__c, '%d/%m/%Y'),'') as 'Re-audit due date',
cr.Name as 'Contact Role No',
wi.Status__c as 'Work Item Status',
wi.Scheduling_Ownership__c as 'Scheduling Ownership',
wi.Client_Name_No_Hyperlink__c as 'Client Name',
wi.Client_Site__c as 'Client Site',
wi.Primary_Standard__c as 'Primary Standard',
wi.Required_Duration__c as 'Required Duration',
date_format(wi.Service_Target_date__c,'%d/%m/%Y') as 'Service Target Date',
wi.Name as 'Work Item',
wi.Work_Item_Stage__c as 'Work Item Type',
ifnull(wi.Comments__c,'') as 'Comments',
ifnull(c.Title,'') as 'Contact: Title',	
ifnull(c.FirstName,'') as 'Contact: First Name',	
ifnull(c.LastName,'') as 'Contact: Last Name',
ifnull(c.Phone,'') as 'Contact: Phone',	
ifnull(c.Email,'') as 'Contact: Email',
ag.Name as 'Administration Ownership',
csp.Status__c as 'SAI Certificate Status',
date_format(csp.Expires__c, '%d/%m/%Y') as 'Cert Expiry Date',
date_format(csp.Re_Audit_Due_Date_Range_From__c, '%d/%m/%Y') as 'Re-Audit Due Date Range - From',
date_format(csp.Re_Audit_Due_Date_Range_To__c, '%d/%m/%Y') as 'Re-Audit Due Date Range - To'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.contact_role__c cr on cr.Site_Certification__c = sc.Id
inner join salesforce.contact c on cr.Contact__c = c.Id
inner join salesforce.administration_group__c ag on csp.Administration_Ownership__c = ag.Id
where 
	wi.Status__c in ('Open', 'Scheduled','Scheduled - Offered', 'Service Change')
	and wi.Revenue_Ownership__c like 'EMEA%'
    and wi.Service_Target_date__c >=date_format(now(), '%Y-%m-1')
    and wi.Service_Target_date__c <date_format(date_add(now(), interval 7 month), '%Y-%m')
    and wi.Work_Item_Stage__c not in ('Follow Up')
group by wi.Id;

(select * from emea_pack_renewals);