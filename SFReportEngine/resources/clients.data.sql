create temporary table client_contacts as
	select client.Id as 'Client Id', c.Id as 'Contact Id', c.Name as 'Contact', c.Title, c.DoNotCall, c.Email, c.Phone
	from salesforce.contact c 
	left join salesforce.account site on c.AccountId = site.Id
	left join salesforce.account client on site.ParentId = client.Id
	group by c.Id
	union
	select client.Id as 'Client Id', c.Id as 'Contact Id', c.Name as 'Contact', c.Title, c.DoNotCall, c.Email, c.Phone 
	from salesforce.contact c 
	inner join salesforce.contact_role__c cr on cr.Contact__c = c.Id and cr.IsDeleted = 0 and cr.Status__c = 'Active'
	inner join salesforce.certification__c sc on cr.Site_Certification__c = sc.Id
	inner join salesforce.account site on site.Id = sc.Primary_client__c
	inner join salesforce.account client on site.ParentId = client.Id
	group by client.Id
	union
	select client.Id as 'Client Id', c.Id as 'Contact Id', c.Name as 'Contact', c.Title, c.DoNotCall, c.Email, c.Phone
	from salesforce.contact c 
	inner join salesforce.contact_role__c cr on cr.Contact__c = c.Id and cr.IsDeleted = 0 and cr.Status__c = 'Active'
	inner join salesforce.certification__c cert on cr.Certification__c = cert.Id
	inner join salesforce.account client on cert.Primary_client__c = client.Id
	group by c.Id
	union
	select client.Id as 'Client Id', c.Id as 'Contact Id', c.Name as 'Contact', c.Title, c.DoNotCall, c.Email, c.Phone
	from salesforce.contact c 
	inner join salesforce.contact_role__c cr on cr.Contact__c = c.Id and cr.IsDeleted = 0 and cr.Status__c = 'Active'
	inner join salesforce.account client on cr.Account__c = client.Id
	group by c.Id
	union
	select client.Id as 'Client Id', c.Id as 'Contact Id', c.Name as 'Contact', c.Title, c.DoNotCall, c.Email, c.Phone
	from salesforce.contact c 
	inner join salesforce.certification__c sc on c.Id = sc.Site_Certification_Contact__c
	inner join salesforce.account site on site.Id = sc.Primary_client__c
	inner join salesforce.account client on site.ParentId = client.Id
	group by c.Id;

(select t2.*, c.`Contact Id`, c.`Contact`, c.`Title`, if(c.`DoNotCall`, 'Yes', 'No') as 'Do Not Call', c.`Email`, c.`Phone`
from	
    (select
		t.`Corporate Client Name`,
		t.`Client Name`,
		t.`Client Id`,
        t.`Client_Segmentation__c`,
        t.`Service Delivery Coordinator`,
		sum(t.`# Sites`) as '# Active Sites',
		sum(t.`# Site Certifications`) as '# Site Certifications',
		sum(t.`# Certifications`) as '# Certifications',
        sum(t.`# Active Site Certifications`) as '# Active Site Certifications',
		sum(t.`# Active Certifications`) as '# Active Certifications',
		sum(t.`# Countries`) as '# Countries',
        t.`Finance Statement Country`,
        t.`H/O Country`,
		group_concat(distinct t.`Countries`) as 'Countries',
        if(t.`H/O Country` is not null, t.`H/O Country`,
			if(t.`Finance Statement Country` is not null, t.`Finance Statement Country`,
				if(sum(t.`# Countries`)=1, group_concat(distinct t.`Countries`), null))) as 'Client Country',
		group_concat(distinct t.`SAI Regions`) as 'SAI Regions',
		sum(t.`Total_Number_of_Employees__c`) as 'Total Number of Employees', 
        count(t.`Total_Number_of_Employees__c`) = count(t.`Site Id`) as 'All Sites have Employees data'
	from (
		select 
			pc.name as 'Corporate Client Name',
            client.name as 'Client Name',
			client.Id as 'Client Id',
            client.Client_Segmentation__c,
            sdc.Name as 'Service Delivery Coordinator',
            site.Id as 'Site Id',
			count(distinct site.Id) as '# Sites',
            count(distinct sc.Id) as '# Site Certifications',
            count(distinct c.Id) as '# Certifications',
			count(distinct if(sc.Status__c='Active', sc.Id, null)) as '# Active Site Certifications',
			count(distinct if(c.Status__c='Active', c.Id, null)) as '# Active Certifications',
			count(distinct country.code) as '# Countries',
            max(if(site.Head_Office__c , country.name, null)) as 'H/O Country',
            max(if(site.Finance_Statement_Site__c , country.name, null)) as 'Finance Statement Country',
			group_concat(distinct country.name) as 'Countries',
			group_concat(distinct country.sai_region ) as 'SAI Regions',
			max(sc.Total_Number_of_Employees__c) as 'Total_Number_of_Employees__c'
		from salesforce.account client
        left join salesforce.user sdc on client.Service_Delivery_Coordinator__c = sdc.Id
		left join salesforce.account pc on client.ParentId = pc.Id
        left join salesforce.account site on site.ParentId = client.Id
		left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
		left join analytics.countries_names cn on ccs.Name = cn.name
		left join analytics.countries country on cn.code = country.code
		left join salesforce.certification__c sc on sc.Primary_client__c = site.Id
		left join salesforce.certification__c c on c.Primary_client__c = client.Id
		inner join salesforce.recordtype rt on client.RecordTypeId = rt.Id
		where
			rt.Name = 'Client'
		group by client.Id, site.Id) t
	group by t.`Client Id`) t2
    left join client_contacts c on c.`Client Id` = t2.`Client Id`
where t2.`Client Country` in ('Australia','Germany', 'India', 'South Africa')
);

