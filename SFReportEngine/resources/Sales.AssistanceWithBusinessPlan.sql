describe lead;
select 
'Lead' as 'Type', l.Id as 'Lead/Opp Id', l.Name as 'Lead/Client Name', l.Status as 'Lead/Opp Status', i.Name as 'Industry', i.Industry_Sector__c as 'Sector', l.IsConverted as 'IsConverted', l.LeadSource, '' as 'Opp Stage Name', l.CreatedDate, date_format(l.createdDate, '%Y %m') as 'Created Period', l.ConvertedDate as 'Converted/Closed Date', date_format(l.ConvertedDate, '%Y %m') as 'Converted/Closed Period', datediff(l.ConvertedDate, l.createdDate) as 'Conversion/Closing Days', '' as 'Opp Type', l.NumberOfEmployees, l.State, '' as 'Opp Lost Reason', '' as 'Opp Won Reason', l.Program__c as 'Program(s)', o.Name as 'Owner', o.State
from salesforce.Lead l 
left join industry__c i on l.Industry_2__c = i.Id
inner join salesforce.User o on o.Id = l.OwnerId
inner join  salesforce.RecordType rt on rt.Id = l.RecordTypeId
where 
rt.Name = 'AUS - Lead'
and l.Business__c = 'Australia'
#and l.CreatedDate>='2012-01-01'
and l.isDeleted = 0

union

select
'Opportunity' as 'Type', o.Id, a.Name, o.Status__c, i.Name as 'Industry', i.Industry_Sector__c as 'Sector', '' as 'IsConverted', o.LeadSource, o.StageName, o.CreatedDate, date_format(o.CreatedDate, '%Y %m') as 'Created Period', o.CloseDate as 'Converted/Closed Date', date_format(o.CloseDate, '%Y %m') as 'Converted/Closed Period', datediff(o.CloseDate, o.CreatedDate) as 'Conversion/Closing Days', o.Type, o.No_of_Employess__c, scs.Name as 'State', o.Lost_Reason__c, o.Won_Reason__c, o.Program__c, ow.Name, ow.State
from opportunity o
left join account a on o.AccountId = a.Id
left join industry__c i on a.Industry_2__c = i.Id
left join state_code_setup__c scs on a.Business_State__c = scs.Id
inner join User ow on ow.Id = o.OwnerId
where o.Business_1__c='Australia'
#and o.CreatedDate>'2012-01-01'
and o.IsDeleted=0
limit 100000;


describe industry__c;

select * from industry__c;