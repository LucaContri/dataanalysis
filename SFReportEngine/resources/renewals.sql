create or replace view emea_renewals_report_sub as
select csp.Client_Text__c as 'Client', csp.Id, csp.Name as 'Cert Standard', csp.Status__c, csp.Re_Audit_Due_Date_Range_From__c, csp.Re_Audit_Due_Date_Range_To__c, sc.Name as 'Site Cert', cont.Name, cont.Title, cont.Email, cont.Phone, wi.Name as 'Work Item', 
ifnull(wi.Work_Item_Date__c, '9999-12-31') as 'WI Date', 
wi.Work_Item_Stage__c, csp.Standard_Service_Type_Name__c, wi.Scheduling_Ownership__c, ag.Name as 'Admin Ownership'
from salesforce.certification_standard_program__c csp
inner join salesforce.administration_group__c ag on csp.Administration_Ownership__c = ag.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
left join salesforce.contact_role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact cont on cr.Contact__c = cont.Id
left join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.Status__c = 'Open' and wi.IsDeleted = 0 and wi.Work_Item_Stage__c not in ('Follow Up')
where 
csp.Status__c in ('Applicant', 'Registered', 'Customised')
and scsp.Status__c in ('Applicant', 'Registered', 'Customised')
and ag.Name like 'EMEA%'
and csp.Re_Audit_Due_Date_Range_From__c <= date_format(date_add(now(), interval 6 month), '%Y-%m-31')
and csp.Re_Audit_Due_Date_Range_To__c >= date_format(date_add(now(), interval 6 month), '%Y-%m-1')
#and csp.Re_Audit_Due_Date_Range_From__c <= '2016-06-31'
#and csp.Re_Audit_Due_Date_Range_To__c >= '2015-12-01'
and csp.IsDeleted = 0
and sc.IsDeleted = 0
order by `Cert Standard`, `Site Cert`, `WI Date` asc;


create or replace view emea_renewals_report as
select 
	t.`Client`,
    t.`Cert Standard`,
    t.`Status__c` as 'Cert Std Status',
    t.`Re_Audit_Due_Date_Range_From__c` as 'Audit due date from', 
    t.`Re_Audit_Due_Date_Range_To__c`as 'Audit due date to', 
    t.`Site Cert`, 
    ifnull(t.`Name`,'') as'Contact Name', 
    ifnull(t.`Title`,'') as 'Contact Title', 
    ifnull(t.`Email`,'') as 'Contact Email', 
    ifnull(t.`Phone`,'') as 'Contact Pone', 
    ifnull(t.`Work Item`,'') as 'Work Item', 
    if(t.`WI Date`='9999-12-31','', t.`WI Date`) as 'Work Item Date', 
    ifnull(t.`Work_Item_Stage__c`,'') as 'Work Item Type', 
    t.`Standard_Service_Type_Name__c` as 'Standard', 
    ifnull(t.`Scheduling_Ownership__c`,'') as 'Scheduling Ownership', 
    t.`Admin Ownership`
from emea_renewals_report_sub t
group by t.`Cert Standard`, t.`Site Cert`;

(select * from emea_renewals_report);

(select csp.Client_Text__c as 'Client', csp.Id, csp.Name as 'Cert Standard', csp.Status__c, csp.Re_Audit_Due_Date_Range_From__c, csp.Re_Audit_Due_Date_Range_To__c, sc.Name as 'Site Cert', cont.Name, cont.Title, cont.Email, cont.Phone, ag.Name as 'Admin Ownership'
from salesforce.certification_standard_program__c csp
inner join salesforce.administration_group__c ag on csp.Administration_Ownership__c = ag.Id
inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
left join salesforce.contact_role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact cont on cr.Contact__c = cont.Id
where 
csp.Status__c in ('Applicant', 'Registered', 'Customised')
and scsp.Status__c in ('Applicant', 'Registered', 'Customised')
and csp.Standard_Service_Type_Name__c like '%BRC%'
and ag.Name like 'EMEA%'
and (csp.Re_Audit_Due_Date_Range_From__c is null or csp.Re_Audit_Due_Date_Range_To__c is null)
and csp.IsDeleted = 0
and sc.IsDeleted = 0
order by `Cert Standard`, `Site Cert`);