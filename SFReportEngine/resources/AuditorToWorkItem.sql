select r.Id, r.Name, group_concat(if(rc.Code__c is null, rc.standard__c, rc.code__c)) as 'Competencies'
from resource__c r 
inner join resource_competency__c rc on rc.Resource__c = r.Id
where 
r.name in  ('Fengdu Li')
and (rc.Rank__c like '%Lead Auditor%' or rc.Code__C is not null)
and rc.IsDeleted=0
group by r.Id;

select s.`Resource`, s.Id, s.`Name` as 'Work Item', s.`Client Site`, s.`Primary Standard`, s.`Work Item Date`, s.`Revenue Ownership` from (
select rc.Id as 'ResourceId', rc.Name as 'Resource', wir.Id, wir.Name, wir.Client_Site__c as 'Client Site', wir.Primary_Standard__c as 'Primary Standard', wir.work_item_Date__c as 'Work Item Date', wir.Revenue_Ownership__c as 'Revenue Ownership',count(wir.Id) as 'Requirements Count', count(if(locate(wir.Requirement,rc.`Competencies`)>0, rc.Id, null)) as 'Matching Competencies' 
from (
select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c, 'Primary Standard' as 'Type', sp.Standard__c as 'Requirement'
from work_item__c wi 
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id
where 
wi.Revenue_Ownership__c like 'AUS-Food%'
and wi.Status__C in ('Open')
and wi.Work_Item_Date__c >= utc_timestamp()
and wi.Work_Item_Date__c <= date_add(utc_timestamp(), interval 5 month)
and wi.IsDeleted = 0
#and wi.ID = 'a3Id000000056wREAQ'
union
select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c,'Standard Family' as 'Type', sp.standard__c
from work_item__c wi 
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
inner join standard_program__c sp on scsf.Standard_Program__c = sp.Id
where 
wi.Revenue_Ownership__c like 'AUS-Food%'
and wi.Status__C in ('Open')
and wi.Work_Item_Date__c >= utc_timestamp()
and wi.Work_Item_Date__c <= date_add(utc_timestamp(), interval 5 month)
and wi.IsDeleted = 0
and scsp.IsDeleted = 0
#and wi.ID = 'a3Id000000056wREAQ'
and scsf.IsDeleted=0
and sp.IsDeleted=0
union
select wi.Id, wi.Name, wi.Client_Site__c, wi.Primary_Standard__c, wi.work_item_Date__c, wi.Revenue_Ownership__c, 'Code' as 'Type', scspc.code__c
from work_item__c wi 
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
where 
wi.Revenue_Ownership__c like 'AUS-Food%'
and wi.Status__C in ('Open')
and wi.Work_Item_Date__c >= utc_timestamp()
and wi.Work_Item_Date__c <= date_add(utc_timestamp(), interval 5 month)
and wi.IsDeleted = 0
and scsp.IsDeleted = 0
and scspc.IsDeleted = 0) wir, (select r.Id, r.Name, group_concat(if(rc.Code__c is null, rc.standard__c, rc.code__c)) as 'Competencies'
from resource__c r 
inner join resource_competency__c rc on rc.Resource__c = r.Id
where 
r.name in  ('Denis Slade')
and (rc.Rank__c like '%Lead Auditor%' or rc.Code__C is not null)
and rc.IsDeleted=0
and rc.Status__c = 'Active'
group by r.Id) rc 
group by wir.Id, rc.Id) s 
where s.`Requirements Count` = s.`Matching Competencies`;
#and wi.Id = 'a3Id000000056wREAQ';