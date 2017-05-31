select 
date_format(arg.`To`, '%Y-%m') as 'Period', 
'ARG' as 'Metric',
count(distinct Id) as 'Value' 
from analytics.sla_arg_v2 arg 
where Metric = 'ARG Completion/Hold'
and arg.`To` is not null
and arg.Region like 'AUS%'
and arg.`To` >= '2015-01-01'
group by `Period`
union
select 
date_format(arg.`To`, '%Y-%m') as 'Period', 
'ARG (IATF)' as 'Metric',
count(distinct Id) as 'Value' 
from analytics.sla_arg_v2 arg 
where arg.Metric = 'ARG Completion/Hold'
and arg.`To` is not null
and arg.Region like 'AUS%'
and arg.`To` >= '2015-01-01'
and arg.`Standards` like '%16949%'
group by `Period`
union
select 
date_format(arg.`To`, '%Y-%m') as 'Period', 
'ARG (BRC,SQF,IATF, DISAB)' as 'Metric',
count(distinct Id) as 'Value' 
from analytics.sla_arg_v2 arg 
where arg.Metric = 'ARG Completion/Hold'
and arg.`To` is not null
and arg.Region like 'AUS%'
and arg.`To` >= '2015-01-01'
and (arg.`Standards` like '%16949%' or arg.`Standards` like '%BRC%' or arg.`Standards` like 'SQF%' or arg.`Standards` like '%disability%')
group by `Period`;

select date_format(csph.CreatedDate, '%Y-%m') as 'Period',
'Certification - De-Registered' as 'Metric',
count(distinct csp.Id) as 'Value'
from salesforce.certification_standard_program__c csp
inner join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id
where csph.Field = 'Status__c'
and csph.NewValue= 'De-Registered'
and csph.CreatedDate>= '2015-01-01'
and csp.Administration_Ownership__c in ('a1fd000000091AIAAY','a1fd000000091AMAAY','a1fd000000091ARAAY')
group by `Period`
union
select date_format(csph.CreatedDate, '%Y-%m') as 'Period',
'Certification - On Hold' as 'Metric',
count(distinct csp.Id) as 'Value'
from salesforce.certification_standard_program__c csp
inner join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id
where csph.Field = 'Status__c'
and csph.NewValue= 'On Hold'
and csph.CreatedDate>= '2015-01-01'
and csp.Administration_Ownership__c in ('a1fd000000091AIAAY','a1fd000000091AMAAY','a1fd000000091ARAAY')
group by `Period`
union
select date_format(csph.CreatedDate, '%Y-%m') as 'Period',
'Certification - Concluded' as 'Metric',
count(distinct csp.Id) as 'Value'
from salesforce.certification_standard_program__c csp
inner join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id
where csph.Field = 'Status__c'
and csph.NewValue= 'Concluded'
and csph.CreatedDate>= '2015-01-01'
and csp.Administration_Ownership__c in ('a1fd000000091AIAAY','a1fd000000091AMAAY','a1fd000000091ARAAY')
group by `Period`
union
select date_format(csph.CreatedDate, '%Y-%m') as 'Period',
'Certification - Under Suspension' as 'Metric',
count(distinct csp.Id) as 'Value'
from salesforce.certification_standard_program__c csp
inner join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id
where csph.Field = 'Status__c'
and csph.NewValue= 'Under Suspension'
and csph.CreatedDate>= '2015-01-01'
and csp.Administration_Ownership__c in ('a1fd000000091AIAAY','a1fd000000091AMAAY','a1fd000000091ARAAY')
group by `Period`
union
select date_format(csph.CreatedDate, '%Y-%m') as 'Period',
'Certification - Transferred' as 'Metric',
count(distinct csp.Id) as 'Value'
from salesforce.certification_standard_program__c csp
inner join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id
where csph.Field = 'Status__c'
and csph.NewValue= 'Transferred'
and csph.CreatedDate>= '2015-01-01'
and csp.Administration_Ownership__c in ('a1fd000000091AIAAY','a1fd000000091AMAAY','a1fd000000091ARAAY')
group by `Period`;

select * 
from analytics.change_request_completed_sub t 
where t.`To` >= '2015-01-01'
and `Region` like 'AUS%';

select * from salesforce.administration_group__c;

select 'WI' as 'Metric', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia (inc PS)', 'China') as 'Region', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period', count(wi.Id) as 'Value'
from salesforce.work_item__c wi
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service')
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like '%China%')
and wi.Work_Item_Date__c >= '2015-01-01'
and wi.Work_Item_Date__c < '2016-10-01'
group by `Metric`, `Region`, `Period`
union
select 'WI (BRC,SQF,IATF, DISAB)' as 'Metric', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia (inc PS)', 'China') as 'Region', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period', count(wi.Id)
from salesforce.work_item__c wi
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service')
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like '%China%')
and wi.Work_Item_Date__c >= '2015-01-01'
and wi.Work_Item_Date__c < '2016-10-01'
and (wi.Primary_Standard__c like '%16949%' or wi.Primary_Standard__c  like '%BRC%' or wi.Primary_Standard__c like 'SQF%' or wi.Primary_Standard__c like '%disability%')
group by `Metric`, `Region`, `Period`
union
select 'WI (SQF)' as 'Metric', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia (inc PS)', 'China') as 'Region', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period', count(wi.Id)
from salesforce.work_item__c wi
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service')
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like '%China%')
and wi.Work_Item_Date__c >= '2015-01-01'
and wi.Work_Item_Date__c < '2016-10-01'
and wi.Primary_Standard__c like 'SQF%'
group by `Metric`, `Region`, `Period`
union
select 'WI(IATF)' as 'Metric', if(wi.Revenue_Ownership__c like 'AUS%', 'Australia (inc PS)', 'China') as 'Region', date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Period', count(wi.Id)
from salesforce.work_item__c wi
where wi.IsDeleted = 0
and wi.Status__c not in ('Cancelled', 'Draft', 'Inititate Service')
and (wi.Revenue_Ownership__c like 'AUS%' or wi.Revenue_Ownership__c like '%China%')
and wi.Work_Item_Date__c >= '2015-01-01'
and wi.Work_Item_Date__c < '2016-10-01'
and wi.Primary_Standard__c like '%16949%'
group by `Metric`, `Region`, `Period`
union
select 'Opportunity Won' as 'Metric', if (o.Business_1__c = 'Asia - China', 'China', 'Australia (inc PS)') as 'Region', date_format(o.CloseDate, '%Y-%m') as 'Period', count(Id) 
from salesforce.opportunity o
where o.IsDeleted = 0
and o.StageName = 'Closed Won'
and o.CloseDate >= '2015-01-01'
and o.CloseDate < '2015-10-01'
and o.Business_1__c in ('Australia','Product Services','Asia - China')
and o.Type like 'New Bus%'
group by `Metric`, `Region`, `Period`;

