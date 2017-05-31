select 
    client.Name as 'Client',
    client.Status__C as 'Client Status',
    cs.Name as 'Client Site',
    client.Scheduling_Complexity__c as 'Scheduling Complexity',
    cs.Business_Zip_Postal_Code__c as 'Postcode',
    (select 
            SLAName
        from
            salesforce.saig_postcodes_to_sla4
        where
            postcode = cs.Business_Zip_Postal_Code__c
        limit 1) as 'Region',
    scs.Name as 'State',
    ccs.Name as 'Country',
    c.name as 'Site Cert',
    st.Name as 'Primary Standard',
    p.Name as 'Program',
    c.Revenue_Ownership__c as 'Revenue Ownership',
    s.Name as 'Scheduler Name',
    concat(if(r1.Name is null, '', r1.Name),
            if(r2.Name is null,
                '',
                concat(', ', r2.Name)),
            if(r3.Name is null,
                '',
                concat(', ', r3.Name))) as 'Preferred Resources',
    concat(if(r1.Name is null,
                '',
                r1.Resource_Type__c),
            if(r2.Name is null,
                '',
                concat(', ', r2.Resource_Type__c)),
            if(r3.Name is null,
                '',
                concat(', ', r3.Resource_Type__c))) as 'Preferred Resources Type',
    if(r1.name is null and r2.Name is null
            and r3.Name is null,
        false,
        true) as 'Has Preferred Resources'
from
    salesforce.certification__c c	
        inner join
    salesforce.account cs ON cs.Id = c.Primary_client__c
        inner join
    salesforce.account client ON client.Id = cs.ParentId
        left join
    salesforce.standard_program__c sp ON sp.Id = c.Primary_Standard__c
        left join
    salesforce.standard__c st ON st.Id = sp.standard__c
        left join
    salesforce.program__c p ON p.Id = sp.Program__c
        left join
    salesforce.user s ON s.Id = c.Scheduler__c
        left join
    salesforce.resource__c r1 ON r1.Id = c.Preferred_Resource_1__c
        left join
    salesforce.resource__c r2 ON r2.Id = c.Preferred_Resource_2__c
        left join
    salesforce.resource__c r3 ON r3.Id = c.Preferred_Resource_3__c
        left join
    salesforce.state_code_setup__c scs ON scs.Id = cs.Business_State__c
        left join
    salesforce.country_code_setup__c ccs ON ccs.Id = cs.Business_Country2__c
where
    c.Revenue_Ownership__c like 'AUS%'
	and c.Status__c='Active'
	and ccs.Name = 'Australia'
group by `Client` , `Client Status` , `Client Site` , `Scheduling Complexity` , `Postcode` , `Region` , `State` , `Country` , `Site Cert` , `Primary Standard` , `Program` , `Revenue Ownership` , `Scheduler Name` , `Preferred Resources` , `Preferred Resources Type` , `Has Preferred Resources`
limit 1000000;