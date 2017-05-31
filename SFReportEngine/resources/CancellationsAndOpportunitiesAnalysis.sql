use salesforce;

# Work Item Cancelled
select 
		wi.Revenue_Ownership__c as 'Revenue Ownership',
        wi.Id as 'WorkItemId', 
        wi.Work_Item_Stage__c as 'Type', 
		wi.Name as 'WorkItem',
        #wi.work_package__c,
		wi.Work_Package_Type__c as 'Work Package Type', 
		#if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		#wi.Revenue_Ownership__c,
        wi.Sample_Site__c as 'Sample Site',
        if (wi.Service_Change_Reason__c is null, '', wi.Service_Change_Reason__c) as 'Work Item Service Change Reason',
        if (scsp.De_registered_Type__c is null, '',scsp.De_registered_Type__c) as 'SiteCert DeRegistered Type', 
		if (scsp.Site_Certification_Status_Reason__c is null, '', scsp.Site_Certification_Status_Reason__c) as 'SiteCert DeRegistered Reason', 
		if (wi.Cancellation_Reason__c is null, '', wi.Cancellation_Reason__c ) as 'Work Item Cancellation Reason', 
		wi.Work_Item_Date__c 'Work Item Date',
		max(wih.CreatedDate) as 'Cancelled Date',  
        cb.Name as 'Cancelled By',
		#wi.Required_Duration__c as 'RequiredDuration',
        #wi.Sample_Site__c,
        #if(wi.Service_Change_Reason__c = ('De-Registered') and De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences'),
		#	'Churn',
        #    if(Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status', 'SAI did not win re-tender','New client not wishing to go ahead with S1 and S2','Financial difficulties', 'Client complaint of service and is leaving SAI'),'Churn',
		#		if (Cancellation_Reason__c='Lifecycle Frequency Decrease',
		#			'Shrinkage',
        #            'Maintenance')
        #    )
		#) as 'Category',
        if (wi.Service_Change_Reason__c= 'De-Registered',
			if (scsp.De_registered_Type__c in ('Maintenance'),
				'Maintenance',
                'Churn'
            ),
            if(wi.Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status', 'SAI did not win re-tender','New client not wishing to go ahead with S1 and S2','Financial difficulties', 'Client complaint of service and is leaving SAI'),
				'Churn',
                if(wi.Cancellation_Reason__c in ('Lifecycle Frequency Decrease'),
					'Shrinkage',
                    if (wi.Revenue_Ownership__c like '%Food%' and wi.Work_Item_Stage__c = 'Follow Up',
						'Maintenance',
                        if (wi.Sample_Site__c = 'Yes',
							'Maintenance',
                            if (wi.Cancellation_Reason__c in ('Site Relocation'),
								'Maintenance',
                                'Churn' # - Catch All 
                            )
                        )
					)
                )
			)
		) as 'Category'
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join certification__c sc on scsp.Site_Certification__c = sc.Id
        inner join work_item__history wih on wih.ParentId = wi.Id
        inner join User cb on wih.CreatedById = cb.Id
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(date_add(wih.CreatedDate, interval 11 hour),'%Y-%m-%d') in ('2015-03-16')
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
        #and wi.Revenue_Ownership__c LIKE 'Asia%'
	group by wi.Id;
    
select wi.Id, wi.Open_Sub_Status__c 
from work_item__c wi 
inner join work_item__history wih on wih.ParentId = wi.Id
where wi.Open_Sub_Status__c = 'Pending Cancellation'
and wih.Field = 'Open_Sub_Status__c'
and wih.NewValue = 'Pending Cancellation'
and date_format(date_add(wih.CreatedDate, interval 9 hour), '%Y-%m-%d')='2015-01-05';

select t.Client_Name_No_Hyperlink__c, date_format(t.`Change Date`, '%Y-%m') as 'Period Cancelled', sum(t.RequiredDuration/8) as 'Days' from (
select
	wi.Id as 'WorkItemId', 
	wi.Name as 'WorkItem',
	wi.work_package__c,
	wi.Work_Package_Type__c, 
	wi.Work_Item_Stage__c, 
    wi.Client_Name_No_Hyperlink__c,
	if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
	wi.Revenue_Ownership__c,
    scsp.De_registered_Type__c, 
	scsp.Site_Certification_Status_Reason__c, 
	wi.Cancellation_Reason__c, 
	wi.Service_Change_Reason__c,
	wi.Work_Item_Date__c,
	wi.Required_Duration__c as 'RequiredDuration',
	max(wih.CreatedDate) as 'Change Date',  
	wi.Sample_Site__c
from work_item__c wi
inner join work_item__history wih on wih.ParentId = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join certification__c sc on scsp.Site_Certification__c = sc.Id
where 
wih.Field='Open_Sub_Status__c' 
and wih.NewValue= 'Pending Cancellation'
#and date_format(wih.CreatedDate, '%Y-%m') in ('2014-12')
and wi.Revenue_Ownership__c like 'AUS%'
#and wi.Status__c = 'Open'
group by wi.Id) t 
group by t.Client_Name_No_Hyperlink__c, `Period Cancelled`;

# New Business
select 
if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'Stream',
t.Id, 
t.`Period`, 
t.`CreatedDate`,
sum(if(oli.IsDeleted=0 and oli.First_Year_Revenue__c=1 and oli.Days__c>0, oli.`TotalPrice`, null)) as 'New Business Won (Audit)',
sum(if(oli.IsDeleted=0 and oli.First_Year_Revenue__c=1 and oli.Days__c<=0, oli.`TotalPrice`, null)) as 'New Business Won (Fees)'
from 
(select * from (
select 
o.Id, 
date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR),'%Y %m') as 'Period', 
date_format(date_add(oh.CreatedDate, INTERVAL 11 HOUR),'%Y-%m-%d') as 'CreatedDate', 
o.Total_First_Year_Revenue__c 
from opportunity o 
inner join opportunityfieldhistory oh ON oh.OpportunityId = o.Id 
where o.Business_1__c in ('Australia') 
#and o.Manual_Certification_Finalised__c=0 
and o.IsDeleted = 0 
and o.Status__c = 'Active' 
and o.StageName = 'Closed Won' 
and oh.Field = 'StageName' 
and oh.NewValue = 'Closed Won' 
group by o.Id) t2 
where 
#t2.`Period` >= '2015 01' 
#and t2.`Period` <= '2015 01' 
t2.`CreatedDate` = '2015-01-07'
) t 
left join opportunitylineitem oli on oli.OpportunityId = t.Id 
left join standard__c s on oli.Standard__c = s.Id 
left join program__c pg on s.Program__c = pg.Id 
group by `Stream`,t.`Id`;


select lba.`Cancelled Period`, 
sum(if(lba.`Stream`='Food',lba.RequiredDuration/8,0)) as 'Food',
sum(if(lba.`Stream`='MS',lba.RequiredDuration/8,0)) as 'MS'  
from lost_business_audits_v2 lba
where lba.`Cancelled Period` >= '2012 07'
and lba.`Cancelled Period` <= '2015 06'
group by lba.`Cancelled Period`;