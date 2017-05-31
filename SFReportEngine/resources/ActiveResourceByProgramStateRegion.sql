select 
    r.Id as 'Resource Id',
    r.Name as 'Resource Name',
    r.Reporting_Business_Units__c as 'Reporting Business Unit',
    r.Resource_Type__c as 'Resource Type',
    scs.Name as 'Resource Home State',
    r.Home_Postcode__c as 'Resource Home Postcode',
    if(SUBSTRING(r.Home_Postcode__c, 1, 1) = '2',
        DISTANCE(r.Latitude__c,
                r.Longitude__c,
                - 33.855601,
                151.20822),
        if(SUBSTRING(r.Home_Postcode__c, 1, 1) = '3',
            DISTANCE(r.Latitude__c,
                    r.Longitude__c,
                    - 37.814563,
                    144.970267),
            if(SUBSTRING(r.Home_Postcode__c, 1, 1) = '4',
                DISTANCE(r.Latitude__c,
                        r.Longitude__c,
                        - 27.46758,
                        153.027892),
                if(SUBSTRING(r.Home_Postcode__c, 1, 1) = '5',
                    DISTANCE(r.Latitude__c,
                            r.Longitude__c,
                            - 34.92577,
                            138.599732),
                    if(SUBSTRING(r.Home_Postcode__c, 1, 1) = '6',
                        DISTANCE(r.Latitude__c,
                                r.Longitude__c,
                                - 31.9522,
                                115.8589),
                        null))))) as 'Distance From State Capital Centre',
    p.Name as 'Program',
    if(p.Name is null,
        rc.standard_or_Code__c,
        null) as 'Code',
    if(p.Name is null,
        null,
        rc.standard_or_Code__c) as 'Standard'
from
    salesforce.resource__c r
        inner join
    salesforce.resource_competency__c rc ON rc.Resource__c = r.Id
        left join
    salesforce.standard_program__c sp ON sp.Standard__c = rc.Standard__c
        left join
    salesforce.program__c p ON p.Id = sp.Program__c
        left join
    salesforce.state_code_setup__c scs ON scs.Id = r.Home_State_Province__c
where
    r.Reporting_Business_Units__c like 'AUS%'
        and r.Active_User__c = 'Yes'
limit 100000;


# Using Region = Statistical Level Area 4 as defined by Australian Beureau of Statistics (abs.gov.au)
select 
    r.Id as 'Resource Id',
    r.Name as 'Resource Name',
    r.Reporting_Business_Units__c as 'Reporting Business Unit',
    r.Resource_Type__c as 'Resource Type',
    scs.Name as 'Resource Home State',
    r.Home_Postcode__c as 'Resource Home Postcode',
	sla.SLAName,
    p.Name as 'Program',
    if(p.Name is null,
        rc.standard_or_Code__c,
        null) as 'Code',
    if(p.Name is null,
        null,
        rc.standard_or_Code__c) as 'Standard'
from
    salesforce.resource__c r
        inner join
    salesforce.resource_competency__c rc ON rc.Resource__c = r.Id
        left join
    salesforce.standard_program__c sp ON sp.Standard__c = rc.Standard__c
        left join
    salesforce.program__c p ON p.Id = sp.Program__c
        left join
    salesforce.state_code_setup__c scs ON scs.Id = r.Home_State_Province__c
        left join
    salesforce.saig_postcodes_to_sla4 sla ON r.Home_Postcode__c = sla.Postcode
where
    r.Reporting_Business_Units__c like 'AUS%'
        and r.Active_User__c = 'Yes'
limit 100000;

select t.State, t.SLAName, t.Latitude, t.Longitude, sum(t.FTEs) as 'ftes', sum(t.Contractors) as 'contractors' from (
select 
    r.Resource_Type__c, scs.Name as 'State', sla.SLAName, sla.Latitude, sla.Longitude,
    if (r.Resource_Type__c='Employee', Count(r.Id),0) as 'FTEs',
	if (r.Resource_Type__c='Contractor', Count(r.Id),0) as 'Contractors'
from
    salesforce.resource__c r inner join
    salesforce.resource_competency__c rc ON rc.Resource__c = r.Id left join
    salesforce.state_code_setup__c scs ON scs.Id = r.Home_State_Province__c left join
    salesforce.saig_postcodes_to_sla4 sla ON r.Home_Postcode__c = sla.Postcode
where
    r.Reporting_Business_Units__c like 'AUS%'
        and r.Active_User__c = 'Yes'
	and rc.standard_or_Code__c='9001:2008 | Certification'
group by r.Resource_Type__c, `State`, sla.SLAName, sla.Latitude, sla.Longitude) t
group by  t.State, t.SLAName, t.Latitude, t.Longitude;