create or replace view top_opportunities_tis_and_cert as 
select 
'Cert.' as 'Stream',
date_format(o.CreatedDate, '%d/%m/%Y') as 'CreatedOn', 
cb.Name as 'CreatedBy', 
o.Name as 'OppName', 
a.Name as 'Client', 
o.StageName as 'Stage', 
concat(o.Probability, '%') as 'Probability', 
o.Total_First_Year_Revenue__c as 'Amount', 
date_format(o.CloseDate, '%d/%m/%Y') as 'CloseDate', 
date_format(o.LastModifiedDate, '%d/%m/%Y') as 'LastModifiedOn' 
#cb.Name as 'LastModifiedBy' 
from opportunity o 
inner join account a on o.AccountId = a.Id 
inner join user cb on o.CreatedById = cb.Id 
#inner join user lmb on o.LastModifiedById = lmb.Id 
where o.Business_1__c = 'Australia' 
and o.StageName not in ('Closed Won','Closed Lost', 'Budget') 
and o.Total_First_Year_Revenue__c >= 50000 
group by o.id 
#order by o.Total_First_Year_Revenue__c desc limit 30
union
select 
'TIS' as 'Stream',
date_format(o.CreatedDate, '%d/%m/%Y') as 'CreatedOn', 
cb.Name as 'CreatedBy', 
o.Name as 'OppName', 
a.Name as 'Client', 
o.StageName as 'Stage', 
concat(o.Probability, '%') as 'Probability', 
o.Amount as 'Amount', 
date_format(o.CloseDate, '%d/%m/%Y') as 'CloseDate', 
date_format(o.LastModifiedDate, '%d/%m/%Y') as 'LastModifiedOn' 
#cb.Name as 'LastModifiedBy' ,
#rt.Name
from training.opportunity o 
inner join training.account a on o.AccountId = a.Id 
inner join training.user cb on o.CreatedById = cb.Id 
#inner join training.user lmb on o.LastModifiedById = lmb.Id 
inner join training.recordtype rt on rt.Id = o.RecordTypeId
where 
#o.Business_1__c = 'Australia' 
o.Probability not in (0,100)
and o.StageName not like '%Lost%'
and o.StageName not like '%Won%'
and o.StageName not in ('Budget')
and o.Amount >= 50000
and rt.Name like 'ENT - APAC%'
group by o.id limit 30;