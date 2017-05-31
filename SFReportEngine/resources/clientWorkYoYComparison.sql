select 
	ma.Name as 'Client',
	ma.Id as 'ClientId',
    a.Name as 'ClientSite',
    a.Id as 'ClientSiteId',
    c.Name as 'SiteCert',
    c.Id as 'SiteCertId',
	c.Status__c as 'SiteCertStatus',
	c.FSample_Site__c as 'SampleSite',
    s.Name as 'PrimaryStandard',
    wp.Type__c as 'WorkPackageType',
    wi.Id as 'WorkItemId',
    wi.Name as 'WorkItem',
	wi.Revenue_Ownership__c as 'RevenueOwnership',
    wi.Work_Item_Stage__c as 'WorkItemType',
    wi.Work_Item_Date__c as 'ServiceDate',
	DATE_FORMAT(Required_Duration__c, '%Y %m') as 'Period',
    wi.Status__c as 'WorkItemStatus',
    wi.Required_Duration__c as 'WorkItemDuration'
from
    salesforce.work_item__c wi
	    inner join
    salesforce.work_package__c wp ON wi.Work_Package__c = wp.Id
        inner join
    salesforce.certification__c c ON wp.Site_Certification__c = c.Id
        inner join
    salesforce.account a ON a.Id = c.Primary_client__c
inner join salesforce.account ma on ma.Id = a.ParentId
        inner join
    salesforce.standard_program__c sp ON sp.Id = c.Primary_Standard__c
        inner join
    salesforce.standard__c s ON s.Id = sp.Standard__c
where
		#wi.Work_Item_Date__c >= '2013-04-01'
        #and wi.Work_Item_Date__c <= '2013-06-30'
        wi.Work_Item_Date__c >= '2014-04-01'
        and wi.Work_Item_Date__c <= '2014-06-30'
		#and wi.Status__c in ('Completed' , 'Under Review', 'Under Review - Rejected', 'Support')
		and wi.Status__c not in ('Cancelled')
        #and ma.Id = '001d000000IeOaIAAV'
		and  c.Operational_Ownership__c in ('AUS - Management Systems', 'AUS - Food')
		#and a.Business_Country2__c='a0Y90000000CGI8EAO' # Australia
order by `ClientSite` , `SiteCert` , `ServiceDate`
limit 10000;

select 
    ma.Name as 'Client',
    ma.Id as 'ClientId',
    a.Name as 'ClientSite',
    a.Id as 'ClientId',
    c.Name as 'SiteCert',
    c.Id as 'SiteCertId',
    c.Status as 'SiteCertStatus',
    s.Name as 'PrimaryStandard',
    wp.Type__c as 'WorkPackageType',
    wi.Id as 'WorkItemId',
    wi.Name as 'WorkItem',
    wi.Work_Item_Stage__c as 'WorkItemType',
    wi.Work_Item_Date__c as 'ServiceDate',
    wi.Status__c as 'WorkItemStatus',
    wi.Required_Duration__c as 'WorkItemDuration'
from
    salesforce.work_item__c wi
        inner join
    salesforce.work_package__c wp ON wi.Work_Package__c = wp.Id
        inner join
    salesforce.certification__c c ON wp.Site_Certification__c = c.Id
        inner join
    salesforce.account a ON a.Id = c.Primary_client__c
        inner join
    salesforce.account ma ON ma.Id = a.ParentId
        inner join
    salesforce.standard_program__c sp ON sp.Id = c.Primary_Standard__c
        inner join
    salesforce.standard__c s ON s.Id = sp.Standard__c
where
    wi.Work_Item_Date__c >= '2014-01-01'
        and wi.Work_Item_Date__c <= '2014-06-30'
        and ma.Id = '001d000000IeOaIAAV'
        and a.Business_Country2__c = 'a0Y90000000CGI8EAO'
order by `ClientSite` , `SiteCert` , `ServiceDate`
limit 10000;

select 
    t.ClientSite,
    t.ClientSiteId,
    t.SiteCert,
    t.SiteCertId,
    t.PrimaryStandard,
    t.WorkPackageType,
    t.WorkItemId,
    t.WorkItemType,
    t.ServiceDate,
    t.WorkItemStatus,
    t.WorkItemDuration,
    wi3.Id as '2014.WorkItemId',
    wi3.Name as '2014.WorkItem',
    wi3.Work_Item_Stage__c as '2014.WorkItemType',
    wi3.Work_Item_Date__c as '2014.ServiceDate',
    wi3.Status__c as '2014.WorkItemStatus',
    wi3.Required_Duration__c as '2014.WorkItemDuration'
from
    (select 
        a.Name as 'ClientSite',
            a.Id as 'ClientSiteId',
            c.Name as 'SiteCert',
            c.Id as 'SiteCertId',
            s.Name as 'PrimaryStandard',
            wp.Type__c as 'WorkPackageType',
            wi.Id as 'WorkItemId',
            wi.Name as 'WorkItem',
            wi.Work_Item_Stage__c as 'WorkItemType',
            wi.Work_Item_Date__c as 'ServiceDate',
            wi.Status__c as 'WorkItemStatus',
            wi.Required_Duration__c as 'WorkItemDuration',
            (select 
                    wi2.Id
                from
                    salesforce.work_item__c wi2
                inner join salesforce.work_package__c wp2 ON wi2.Work_Package__c = wp2.Id
                inner join salesforce.certification__c c2 ON wp2.Site_Certification__c = c2.Id
                where
                    wi2.Work_Item_Date__c > '2013-06-30'
                        and c2.Primary_client__c = a.Id
                        and c2.Id = c.Id
                order by wi2.Work_Item_Date__c
                limit 1) as workItem2
    from
        salesforce.work_item__c wi
    inner join salesforce.work_package__c wp ON wi.Work_Package__c = wp.Id
    inner join salesforce.certification__c c ON wp.Site_Certification__c = c.Id
    inner join salesforce.account a ON a.Id = c.Primary_client__c
    inner join salesforce.standard_program__c sp ON sp.Id = c.Primary_Standard__c
    inner join salesforce.standard__c s ON s.Id = sp.Standard__c
    where
        wi.Work_Item_Date__c >= '2013-04-01'
            and wi.Work_Item_Date__c <= '2013-06-30'
            and a.Id = '001d000000IeQF4AAN'
            and wi.Status__c in ('Completed' , 'Under Review', 'Under Review - Rejected', 'Support')) t
        left join
    salesforce.work_item__c wi3 ON wi3.Id = t.workItem2
limit 10000;