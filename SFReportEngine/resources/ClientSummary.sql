SELECT 
    client.Name as 'Client Name',
    cs.Name as 'Client Site',
    cs.Business_City__c as 'Client Site City',
    scs.Name as 'Client Site State',
    ccs.Name as 'Client Site Country',
    cs.Business_Zip_Postal_Code__c as 'Client Site Postcode',
    if(SUBSTRING(cs.Business_Zip_Postal_Code__c,
            1,
            1) = '2',
        DISTANCE(cs.Latitude__c,
                cs.Longitude__c,
                - 33.855601,
                151.20822),
        if(SUBSTRING(cs.Business_Zip_Postal_Code__c,
                1,
                1) = '3',
            DISTANCE(cs.Latitude__c,
                    cs.Longitude__c,
                    - 37.814563,
                    144.970267),
            if(SUBSTRING(cs.Business_Zip_Postal_Code__c,
                    1,
                    1) = '4',
                DISTANCE(cs.Latitude__c,
                        cs.Longitude__c,
                        - 27.46758,
                        153.027892),
                if(SUBSTRING(cs.Business_Zip_Postal_Code__c,
                        1,
                        1) = '5',
                    DISTANCE(cs.Latitude__c,
                            cs.Longitude__c,
                            - 34.92577,
                            138.599732),
                    if(SUBSTRING(cs.Business_Zip_Postal_Code__c,
                            1,
                            1) = '6',
                        DISTANCE(cs.Latitude__c,
                                cs.Longitude__c,
                                - 31.9522,
                                115.8589),
                        null))))) as 'Distance From State Capital Centre',
    wi.Revenue_Ownership__c as 'Revenue Ownership',
    wi.Name,
    wi.Work_Item_Date__c,
    s.Name as 'Primary Standard',
    sum(wi.Required_Duration__c) as 'Duration'
FROM
    salesforce.work_item__c wi
        INNER JOIN
    salesforce.recordtype rt ON wi.RecordTypeId = rt.Id
        INNER JOIN
    salesforce.work_package__c wp ON wp.Id = wi.Work_Package__c
        INNER JOIN
    salesforce.certification__c c ON c.Id = wp.Site_Certification__c
        inner join
    salesforce.account cs ON c.Primary_client__c = cs.Id
        inner join
    salesforce.account client ON cs.ParentId = client.Id
        inner join
    salesforce.state_code_setup__c scs ON cs.Business_State__c = scs.Id
        inner join
    salesforce.country_code_setup__c ccs ON cs.Business_Country2__c = ccs.Id
        inner join
    salesforce.standard_program__c sp ON c.Primary_Standard__c = sp.Id
        inner join
    salesforce.standard__c s ON sp.Standard__c = s.Id
WHERE
    wi.Status__c in ('Completed' , 'Under Review',
        'Under Review - Rejected',
        'Support')
        AND rt.Name = 'Audit'
        AND c.Operational_Ownership__c IN ('AUS - Management Systems' , 'AUS - Food')
        and wi.Work_Item_Date__c >= '2013-01-02'
        and wi.Work_Item_Date__c < '2014-01-02'
group by c.Client_Site__c
limit 100000;

SELECT 
    ccs.Name as 'Country',
	scs.Name as 'State',
    sla.SLAName 'Region',
    sum(wi.Required_Duration__c) as 'Duration'
FROM
    salesforce.work_item__c wi
        INNER JOIN salesforce.work_package__c wp ON wp.Id = wi.Work_Package__c
        INNER JOIN salesforce.certification__c c ON c.Id = wp.Site_Certification__c
        inner join salesforce.account cs ON c.Primary_client__c = cs.Id
        inner join salesforce.account client ON cs.ParentId = client.Id
        inner join salesforce.state_code_setup__c scs ON cs.Business_State__c = scs.Id
        inner join salesforce.country_code_setup__c ccs ON cs.Business_Country2__c = ccs.Id
        inner join salesforce.standard_program__c sp ON c.Primary_Standard__c = sp.Id
        inner join salesforce.standard__c s ON sp.Standard__c = s.Id
		inner join salesforce.saig_postcodes_to_sla4 sla ON cs.Business_Zip_Postal_Code__c = sla.Postcode
WHERE
    wi.Status__c in ('Completed' , 'Under Review', 'Under Review - Rejected', 'Support')
        AND rt.Name = 'Audit'
        AND c.Operational_Ownership__c IN ('AUS - Management Systems' , 'AUS - Food')
        and wi.Work_Item_Date__c >= '2013-01-02'
        and wi.Work_Item_Date__c < '2014-01-02'
		and s.Name = '9001:2008 | Certification'
group by `Country`, `State`, `Region` 
limit 100000;