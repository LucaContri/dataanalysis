# China CNCA monthly report
#explain
create or replace view china_cnca_report as 
select 
client.Client_Number__c as 'Client Number',
IFNULL(client.Client_Name_Local_Language__c,'') as 'Client Name Local Language',
client.Name as 'Client Name',
ifnull(group_concat(distinct if(scspc.IsDeleted=0 and code.IsDeleted=0, code.Name, null)),'') as 'Codes',
ifnull(site.Location__c,'') as 'Location',
ifnull(site.LL_Location__c,'') as 'LL Location',
ifnull(site.LL_Business_Zip_Postal_Code__c,'') as 'LL Business Zip/Postal Code',
ifnull(contact.phone,'') as 'Phone',
ifnull(contact.fax,'') as 'Fax',
ifnull(contact.Name,'') as 'Contact',
ifnull(sc.Total_Number_of_Employees__c,'') as 'Total Number of Employees',
concat(wi.Primary_Standard__c, ifnull(group_concat(if(scsf.IsDeleted=0,sp.Standard_Service_Type_Name__c,null)),'')) as 'Standards',
#'' as 'client name:LL Location',
ifnull(csp.Translated_Scope_1__c,'') as 'Scope/Translated scope 1',
wi.Name as 'Work Item',
wi.Work_Item_Stage__c as 'WI Type',
date_format(wi.Earliest_Service_Date__c,'%d/%m/%Y') as 'Work Item Start Date',
date_format(wi.End_Service_Date__c,'%d/%m/%Y') as 'End Service Date',
wi.Scheduled_Duration__c as 'Scheduled Duration',
group_concat(distinct if(wir.IsDeleted=0, r.Name, null)) as 'Resources',
ifnull(date_format(csp.Originally_Registered__c,'%d/%m/%Y'),'') as 'Originally Registered',
ifnull(date_format(csp.Current_Certification__c,'%d/%m/%Y'),'') as 'Current Registration Day',
ifnull(date_format(csp.Issued__c,'%d/%m/%Y'),'') as 'Issue Date',
ifnull(date_format(csp.Expires__c,'%d/%m/%Y'),'') as 'Expiry Date'
from salesforce.work_item__c wi
inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id
inner join salesforce.resource__c r on wir.Resource__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c code on scspc.Code__c = code.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
left join salesforce.contact_role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact contact on cr.Contact__c = contact.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
inner join salesforce.certification__c c on csp.Certification__c = c.Id
inner join salesforce.account client on c.Primary_client__c = client.Id
where
	wi.IsDeleted = 0
    and wi.Status__c not in ('Draft','Initiate Service','Open','Cancelled', 'Scheduled', 'Scheduled - Offered', 'Budget')
    and date_format(wi.Work_Item_Date__c, '%Y-%m') = date_format(now(), '%Y-%m') 
    and client.Client_Ownership__c in ('Asia - China')
group by wi.Id;

select * from salesforce.china_cnca_report;

set names big5;
select c.Id, c.Name, c.Client_Name_Local_Language__c from salesforce.account c where Id='001d000000zxiZoAAI';

SELECT *
    FROM information_schema.columns
    WHERE table_schema = 'salesforce'
        AND table_name = 'account'
        AND column_name = 'Client_Name_Local_Language__c';
        
SHOW VARIABLES LIKE 'char%';