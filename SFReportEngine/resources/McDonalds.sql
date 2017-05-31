create or replace view salesforce.mcdonalds_schedule as
(select 
	wi.Client_Name_No_Hyperlink__c as 'Client Name',
	wi.Location__c as ' Site Location', 
	csp.SAI_Certificate_Number__c as 'Certificate Number', 
	wi.Primary_Standard__c as 'Primary Standard', 
    ifnull(group_concat(distinct spf.Standard_Service_Type_Name__c),'')  as 'Family Standards',
	ifnull(csp.Expires__c,'') as 'Expiry Date', 
	sc.Name as 'Site Certification', 
	round(if(sc.Total_Number_of_Employees__c is null, 'n/a', sc.Total_Number_of_Employees__c),0) as 'Site Employees',
	#'?' as 'Additional Standards',
	ifnull(usp.Standard_Service_Type_Name__c, 'No') as 'Upgrading Standard',
	scsp.Status__c as 'Site Status',
	wi.Name as 'Work Item',
	wi.Work_Item_Stage__c as 'Work Item Type',
	ifnull(scl.Frequency__c,'') as 'Frequency',
	ifnull(wi.Required_Duration__c/8,'') as 'Required Duration (Days)',
    ifnull(wi.Service_target_date__c,'') as 'Target Date',
	ifnull(wi.Earliest_Service_Date__c,'') as 'Start Date',
	ifnull(wi.End_Service_Date__c,'') as 'End Date',
	ifnull(r.Name,'') as 'Lead Auditor',
	ifnull(wi.Comments__c,'') as 'Comments',
	wi.Status__c as 'Status'
from 
	salesforce.work_item__c wi
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
    left join salesforce.standard_program__c usp on scsp.Upgrading_Standard__c = usp.Id 
    left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
    left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
	left join salesforce.site_certification_lifecycle__c scl on scl.Work_Item__c = wi.Id
	left join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
where 
	wi.IsDeleted = 0
	and wi.Status__c not in ('Cancelled', 'Draft', 'Completed', 'Initiate service')
    and wi.Work_Item_Date__c <= (date_add(utc_timestamp(), interval 1 year))
    and scsp.Status__c not in ('Concluded')
    and (wi.Primary_Standard__c like '%McDonalds%' or spf.Standard_Service_Type_Name__c like '%McDonalds%')
    and (spf.IsDeleted = 0 or spf.Id is null)
group by wi.Id
order by `Client Name`, `Certificate Number`, `Site Certification`, `Target Date`);
