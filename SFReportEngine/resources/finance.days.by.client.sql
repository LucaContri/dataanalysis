# Finance - MS + Food Days by client YTD
(select t2.*, 
	count(distinct csp.Id) as '# Active Licences',
    count(distinct if(csp.Expires__c<now(),csp.Id,null)) as '# Expired Liences',
    max(csp.Expires__c) as 'Last Expiry Date',
    count(distinct wi.Id) as '# Upcoming Audits',
    group_concat(distinct csp.Id) as 'Cert Std Ids', 
    if(count(distinct csp.Id)=0,false,true) as 'Is Active Client',
    if(count(distinct wi.Id)=0,false,true) as 'Has Upcoming Audits',
    if(count(distinct csp.Id)=count(distinct if(csp.Expires__c<now(),csp.Id,null)),true,false) as 'Has only expired licences'
from
	(select 
		group_concat(distinct if(t.`Revenue_Ownership__c` like '%Food%', 'Food', 'MS') order by if(t.`Revenue_Ownership__c` like '%Food%', 'Food', 'MS')) as 'Business Line',
		t.`Client Id`, 
		t.`Client Name`, 
		sum(if(t.`F.Y.`='2015',t.`Days`,0)) as '2015', 
		sum(if(t.`F.Y.`='2016',t.`Days`,0)) as '2016' ,
        if (sum(if(t.`F.Y.`='2015',t.`Days`,0))=0, 
			'New',
			if(sum(if(t.`F.Y.`='2016',t.`Days`,0))=0,
				'Lost',
				if(sum(if(t.`F.Y.`='2015',t.`Days`,0))<sum(if(t.`F.Y.`='2016',t.`Days`,0)),
					'Growth',
					if(sum(if(t.`F.Y.`='2015',t.`Days`,0))>sum(if(t.`F.Y.`='2016',t.`Days`,0)),
						'Decline',
						'Same'
					)
				)
			)
		) as 'Type'
	from
		(select 
			client.Id as 'Client Id', 
			client.Name as 'Client Name', 
			wi.Id as 'Work Item Id', 
			wi.Name as 'Work Item Name',
			wi.Status__c as 'Work Item Status',
			if(month(wi.Work_Item_Date__c)<7, year(wi.Work_Item_Date__c), year(wi.Work_Item_Date__c)+1) as 'F.Y.',
			wi.Required_Duration__c/8 as 'Days',
            wi.Revenue_Ownership__c
		from salesforce.work_item__c wi
			inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
			inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
			inner join salesforce.account site on sc.Primary_client__c = site.Id
			inner join salesforce.account client on site.ParentId = client.Id
		where wi.IsDeleted = 0
			and wi.Status__c not in ('Cancelled', 'Initiate Service', 'Draft','Open', 'Scheduled', 'Scheduled - Offered')
			and wi.Revenue_Ownership__c like 'AUS%'
			and wi.Revenue_Ownership__c not like '%Product%'
            and (wi.Work_Item_Date__c between '2014-07-01' and '2015-03-31'
				or wi.Work_Item_Date__c between '2015-07-01' and '2016-03-31')
		) t
	group by t.`Client Id`) t2
left join salesforce.certification__c cert on cert.Primary_client__c = t2.`Client Id`
left join salesforce.certification_standard_program__c csp on csp.Certification__c = cert.Id and csp.Status__c in ('Registered', 'Customised', 'Applicant') and csp.IsDeleted = 0
left join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id and scsp.IsDeleted = 0
left join salesforce.work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id and wi.IsDeleted = 0 and wi.Status__c not in ('Cancelled') and date_format(wi.Work_Item_Date__c, '%Y-%m')>=date_format(now(), '%Y-%m')
group by t2.`Client Id`);
