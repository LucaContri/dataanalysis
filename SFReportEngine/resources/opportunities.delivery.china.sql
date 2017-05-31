(select 
	t.Business_1__c as 'Business', 
    t.`Opportunity Id`, 
    t.`Opportunity`, 
    t.`Opportunity Created Date`,
    t.`Closed Won Date`,
    date_format(t.`Closed Won Date`, '%Y-%m') as 'Closed Won Period',
    t.`Delivery Strategy Created Date`, 
    t.`Site Certification Id`, 
    t.`Site Certification`,
    t.`Site Cert Std Status`,
    t.`Business Line`,
    t.`Program`,
    t.`Standard`,
	t.`Work Item Id` as 'First Work Item Id', 
    t.`Work Item` as 'First Work Item', 
    t.`Work Item Type` as 'First Work Item Type', 
    t.`Work Item Status` as 'First Work Item Status', 
    t.`Work Item Date` as 'First Work Item Date',
    timestampdiff(day, t.`Opportunity Created Date`, t.`Closed Won Date`) as 'Opportunity Created to Closed Won (Days)',
    timestampdiff(day, t.`Closed Won Date`, t.`Delivery Strategy Created Date`) as 'Closed Won to Delivery Startegy Created (Days)',
    timestampdiff(day, t.`Closed Won Date`, t.`Work Item Date`) as 'Closed Won to First Delivery (Days)'
from
	(select
		o.Business_1__c, 
        o.Id as 'Opportunity Id', 
        o.Name as 'Opportunity', 
        o.createdDate as 'Opportunity Created Date',
        o.CloseDate, 
        max(if(ofh.Field='StageName', ofh.createdDate,null)) as 'Closed Won Date', 
        ifnull(o.Delivery_Strategy_Created__c,max(if(ofh.Field='Manual_Certification_Finalised__c', ofh.createdDate,null))) as 'Delivery Strategy Created Date',
		sc.Id as 'Site Certification Id', 
        sc.Name as 'Site Certification', 
        scsp.status__c as 'Site Cert Std Status',
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
        s.Name as 'Standard',
        wi.Id as 'Work Item Id', 
        wi.Name as 'Work Item', 
        wi.Work_Item_Stage__c as 'Work Item Type', 
        wi.Status__c as 'Work Item Status', 
        wi.Work_Item_Date__c as 'Work Item Date'
	from salesforce.opportunity o
		left join salesforce.opportunityfieldhistory ofh on ofh.OpportunityId = o.Id and ofh.ISDeleted = 0 and ((ofh.Field = 'StageName' and ofh.NewValue = 'Closed Won') or (ofh.Field = 'Manual_Certification_Finalised__c' and ofh.NewValue = 'true'))
		left join salesforce.certification__c sc on sc.Opportunity_Created_From__c = o.Id and sc.IsDeleted = 0 and sc.Primary_Certification__c is not null
		left join salesforce.site_certification_standard_program__c scsp on scsp.Site_Certification__c = sc.Id and scsp.IsDeleted = 0
        left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
        left join salesforce.program__c p on sp.Program__c = p.Id
        left join salesforce.standard__c s on sp.Standard__c = s.Id
		left join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.IsDeleted = 0 and wi.Status__C not in ('Cancelled', 'Budget')
	where 
		o.IsDeleted = 0
		and o.StageName = 'Closed Won'
		and o.Business_1__c like '%China%'
	group by o.Id, sc.Id, wi.Id
	order by o.Id, sc.Id, wi.Work_Item_Date__c asc) t
group by t.`Opportunity Id`, t.`Site Certification Id`);


select * from salesforce.opportunityfieldhistory where Field like '%Manual%';