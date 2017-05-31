select count(*) from salesforce.certification__c;

update salesforce.sf_tables set LastSyncDate='1970-01-01' where TableName = 'certification__c' and Id = 103;

select count(*), wi.Revenue_Ownership__c from salesforce.work_item__c wi where wi.Revenue_Ownership__c like 'AUS%' group by wi.Revenue_Ownership__c ;

(select sc.Revenue_Ownership__c, sc.Status__C, count(*), sc.Id from salesforce.certification__c sc where sc.Primary_Certification__c is not null group by sc.Revenue_Ownership__c, sc.Status__C);

select rt.Name , a.Id, a.Name, a.Location__c
from salesforce.account a 
inner join salesforce.recordtype rt on rt.Id = a.RecordTypeId
where a.Name like '%telarc%' or a.Location__c like '%Telarc%';

(select 
	client.Name as 'Client Name', 
	site.Name as 'Site Name', 
	ccs.Name as 'Country', 
	sc.Id as 'Site Cert Id', 
	sc.Name as 'Site Cert', 
	scsp.Id as 'Site cert Std Id', 
	scsp.Name as 'Site Cert Std', 
	scsp.Status__c as 'Site Cert Std Status', 
	scsp.Standard_Service_Type_Name__c as 'Primary Standard',
	wi.Name as 'Work Item',
    wi.Work_Item_Date__c as 'Work Item Date', 
    year(wi.Work_Item_Date__c) as 'Work Item Year',
    date_format(wi.Work_Item_Date__c , '%Y %m') as 'Work Item Period',
    wi.Status__c as 'Work Item Status',
    wi.Required_Duration__c as 'Required Duration',
    wir.Work_Item_Type__c as 'Work Item Resource Type',
    wir.Rank__c as 'Work Item Resource Rank',
    sum(wir.Total_Duration__c)/8 as 'Work Item Resource Days',
    r.Name as 'Resource',
    m.Name as 'Manager',
    r.Reporting_Business_Units__c as 'Reporting Buisness Unit',
    rccs.Name as 'Resource Country',
    r.Email__c as 'Resource Email',
    if(r.Email__c like '%telarc%', true, false) as 'Telarc Resource',
    if (sc.Site_Classification2__c= 'Telarc', true, false) as 'Telarc Site'
    
from salesforce.certification__c sc 
	inner join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id
	left join salesforce.work_item__c wi on scsp.Id = wi.Site_Certification_Standard__c and wi.IsDeleted = 0 and wi.Status__c in ('Completed', 'Submitted', 'Under Review', 'Under Review - Rejected', 'Support', 'In Progress')
    left join salesforce.work_item_resource__c wir on wi.Id = wir.Work_Item__c and wir.IsDeleted = 0 and wir.Work_Item_Type__c in ('Audit')
    left join salesforce.resource__c r on wir.Resource__c = r.Id
    left join salesforce.country_code_setup__c rccs on r.Home_Country1__c = rccs.Id
    left join salesforce.user u on r.User__c = u.Id
    left join salesforce.user m on u.ManagerId = m.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
where (sc.Site_Classification2__c= 'Telarc' or r.email__c like '%telarc%')
group by wi.Id, r.Id);

(select r.*, ccs.Name as 'Country' 
from salesforce.resource__c r
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
where  r.Email__c like '%telarc%'
);

