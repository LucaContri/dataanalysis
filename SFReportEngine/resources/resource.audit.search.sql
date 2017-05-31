select * from (
select wi.Id, wi.Name as 'WorkItem', wi.Work_Item_Stage__c as 'Stage', wi.Status__c as 'Status', r.Name as 'Resource', wi.Work_Item_Date__c as 'Date', wi.Client_Name_No_Hyperlink__c as 'Client', wi.Client_Site__c as 'Site' , 
s.Name as 'PrimaryStd',
group_concat(distinct if(scspf.IsDeleted=0,sf.Name,null)) as 'StdFamily',
group_concat(distinct if(scspc.IsDeleted=0,c.Name,null)) as 'Codes'
from salesforce.work_item__c wi
inner join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.id
inner join salesforce.resource__c r on wir.Resource__c = r.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.site_certification_standard_family__c scspf on scspf.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c spf on scspf.Standard_Program__c = spf.Id
left join salesforce.standard__c sf on spf.Standard__c = sf.Id
left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
left join salesforce.code__c c on scspc.Code__c = c.Id
where r.Name='Robert Libbis'
and wi.Status__c not in ('Cancelled')
group by wi.Id) t 
where t.Codes like '%RAB5%';