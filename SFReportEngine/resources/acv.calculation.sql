#explain
create index audit_values_index on audit_values(`Work Item Id`);

#ACV Calculation based on value of past completed and future WI
(select t2.*, t2.`Closest WI` is not null as 'Has Closest WI', t2.`Closest WI Invoiced Amount` is not null as 'Has Closest Invoice', t2.`Invoiced Audits last 12 months` is not null as 'Has Invoiced last 12 months', t2.`Invoiced Audits last 12 months`=t2.`Closest WI Invoiced Amount` as 'Invoiced Last=12months',
if(t2.`Invoiced Audits last 12 months` is not null,
	t2.`Invoiced Audits last 12 months`,
	if(t2.`Closest WI` is not null,
		if(t2.`Closest WI Invoiced Amount` is not null,
			t2.`Closest WI Invoiced Amount`,
            t2.`Closest WI Calculated Amount`
        ),
        -99999 
	)
) as 'ACV',
ifnull(t2.`Invoiced Currency`,t2.`Calculated Value Currency`) as 'Currency'
from
(select t.`Client Id`, t.`Client`, t.`Site Id`, t.`Site`, t.`Site Cert Std Id`, t.`Site Cert Std`, t.`Site Cert Std Status`, t.`De-Registered Type`, t.`De-Registered Date`,
date_format(t.`De-Registered Date`, '%Y %m') as 'De-Registered Period',
date_format(t.`De-Registered Date`, '%Y') as 'De-Registered Year',
if(month(t.`De-Registered Date`)<7, year(t.`De-Registered Date`), year(t.`De-Registered Date`)+1) as 'De-Registered fy',
t.`Admin Ownership`, t.`Revenue Ownership`, t.`Sample Service`, t.`Transferred From`, t.`Primary Std`, 
t.`Work Item Id` as 'Closest WI Id', 
t.`Work Item` as 'Closest WI', 
t.`Work_Item_Date__c` as 'Closest WI Date', 
t.`Work_Item_Stage__c` as 'Closest WI Type', 
t.`Required_Duration__c` as 'Closest WI Duration', 
t.`Invoiced Currency`, t.`Invoiced Amount - Audit` as 'Closest WI Invoiced Amount',
t.`Calculated Value` as 'Closest WI Calculated Amount', t.`Calculated Value Currency`,
sum(if(t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month),t.`Invoiced Amount - Audit`,null)) as 'Invoiced Audits last 12 months',
count(distinct if(t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month),t.`Work Item`,null)) as '# WI Last 12 months',
group_concat(if(t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month),t.`Work Item`,null)) as 'WI Last 12 months',
group_concat(if(t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month),t.`Work_Item_Stage__c`,null)) as 'WI Types Last 12 months'
from 
	(select 
		client.Id as 'Client Id', 
        client.Name as 'Client', 
        site.Id as 'Site Id', 
        site.Name as 'Site', 
        scsp.Id as 'Site Cert Std Id', 
        scsp.Name as 'Site Cert Std', 
        scsp.Status__c as 'Site Cert Std Status', 
        scsp.De_registered_Type__c as 'De-Registered Type',
		scsp.Withdrawn_Date__c as 'De-Registered Date', 
        scsp.Administration_Ownership__c as 'Admin Ownership', 
        sc.Revenue_Ownership__c as 'Revenue Ownership',
        c.Sample_Service__c as 'Sample Service', 
        scsp.Transferred_From__c as 'Transferred From', 
		sp.Standard_Service_Type_Name__c as 'Primary Std', 
		wi.Id as 'Work Item Id',
		wi.Name as 'Work Item', 
		wi.Work_Item_Date__c,
        wi.Status__c as 'WI Status',
		wi.Work_Item_Stage__c,
		wi.Required_Duration__c,
		wi.Work_Package_Type__c,
		calc.`Calculated Value`, 
        calc.`Calculated Currency` as 'Calculated Value Currency',
        calc.`Invoiced Amount - Audit`,
        calc.`Invoiced Currency` as 'Invoiced Currency'
	from salesforce.site_certification_standard_program__c scsp
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	left join salesforce.work_item__c wi on scsp.Id = wi.Site_Certification_Standard__c and wi.IsDeleted = 0 and wi.Work_Item_Stage__c not in ('Follow Up') and wi.Status__c not in ('Inititate service', 'Draft')
	left join analytics.audit_values calc on wi.Id = calc.`Work Item Id`
    where 
	scsp.IsDeleted = 0
    group by scsp.Id, wi.Id
	order by client.Id, site.Id, scsp.Id, abs(timestampdiff(day,ifnull(scsp.Withdrawn_Date__c,utc_timestamp()),wi.Work_Item_Date__c)) #field(wi.Status__c,'Completed', 'Complete', 'Support', 'Under Review', 'Under Review - Rejected', 'Submitted', 'In Progress', 'Scheduled - Offered','Scheduled', 'Open','Service Change', 'Cancelled', 'Incomplete', 'Allocated', 'Application Unpaid'), 
	) t
group by t.`Site Cert Std Id`) t2);

# Comparing Initial vs Ongoing Value of Certifications
(select * from
(SELECT 
scsp.Id as 'Site Cert Std Id', scsp.CreatedDate as 'Site Cert Std Created Date' , sp.Standard_Service_Type_Name__c as 'Standard', sp.Program_Business_Line__c as 'Business Line', 
sum(if(wi.Work_Item_Stage__c in ('Gap', 'Stage 1', 'Stage 2'), ifnull(calc.`Invoiced Amount - Audit`, calc.`Calculated Value`), null)) as 'Gap+Stage1+Stage2',
avg(if(wi.Work_Item_Stage__c in ('Surveillance'), ifnull(calc.`Invoiced Amount - Audit`, calc.`Calculated Value`), null)) as 'Avg Surveillance',
sum(if(wi.Work_Item_Stage__c in ('Surveillance'), ifnull(calc.`Invoiced Amount - Audit`, calc.`Calculated Value`), null)) as 'Sum Surveillance',
count(distinct if(wi.Work_Item_Stage__c in ('Surveillance'), wi.Id, null)) as '# Surveillance',
avg(if(wi.Work_Item_Stage__c in ('Re-Certification'), ifnull(calc.`Invoiced Amount - Audit`, calc.`Calculated Value`), null)) as 'Avg Re-Certification',
sum(if(wi.Work_Item_Stage__c in ('Re-Certification'), ifnull(calc.`Invoiced Amount - Audit`, calc.`Calculated Value`), null)) as 'Sum Re-Certification',
count(distinct if(wi.Work_Item_Stage__c in ('Re-Certification'), wi.Id, null)) as '# Re-Certification'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on scsp.Id = wi.Site_Certification_Standard__c
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join analytics.audit_values calc on calc.`Work Item Id` = wi.Id
where wi.IsDeleted = 0
and wi.Status__c in ('Completed')
and wi.Revenue_Ownership__c like 'AUS%'
and wi.Revenue_Ownership__c not like '%Product%'
group by scsp.Id) t 
where t.`Gap+Stage1+Stage2`>0 
and t.`Avg Surveillance`>0
and t.`Avg Re-Certification`>0
);

(select t.*, sum(oli.TotalPrice) as 'Opp. First Year Revenue - Audit' from
(SELECT 
o.Id as 'Opp Id', o.Name as 'Opportunity', o.CloseDate as 'Closed Won Date', sc.Id as 'Site Cert Id', sc.Name as 'Site Cert', scsp.Id as 'Site Cert Std Id', scsp.Name as 'Site Cert Std', 
sum(if(wi.work_item_date__c >= date_add(o.CloseDate, interval 0 year) and wi.work_item_date__c < date_add(o.CloseDate, interval 1 year), ili.Total_Line_Amount__c, null)) as 'Invoiced 1st year from Closed/Won',
sum(if(wi.work_item_date__c >= date_add(o.CloseDate, interval 1 year) and wi.work_item_date__c< date_add(o.CloseDate, interval 2 year), ili.Total_Line_Amount__c, null)) as 'Invoiced 2nd year from Closed/Won',
sum(if(wi.work_item_date__c >= date_add(o.CloseDate, interval 2 year) and wi.work_item_date__c< date_add(o.CloseDate, interval 3 year), ili.Total_Line_Amount__c, null)) as 'Invoiced 3rd year from Closed/Won'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on scsp.Id = wi.Site_Certification_Standard__c
inner join salesforce.certification__c sc on sc.Id = scsp.Site_Certification__c
inner join salesforce.opportunity o on o.Id = sc.Opportunity_Created_From__c
inner join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted = 0 and ili.Invoice_Status__c not in ('Cancelled')
inner join salesforce.product2 ip on ili.Product__c = ip.Id and ip.Category__c like '%Audit%'
where wi.IsDeleted = 0
and wi.Status__c in ('Completed')
and wi.Revenue_Ownership__c like 'AUS%'
and wi.Revenue_Ownership__c not like '%Product%'
and scsp.Status__c in ('Registered', 'Customised', 'Applicant')
group by o.Id) t 
left join salesforce.opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` and oli.IsDeleted = 0 and oli.Days__c > 0 and oli.First_Year_Revenue__c =1
group by t.`Opp Id`);

# Un-realised value of Open WI in the past
(SELECT 
wi.Work_Item_Date__c, sum(calc.`Calculated Value`) as 'Open Value'
from salesforce.work_item__c wi
inner join salesforce.site_certification_standard_program__c scsp on scsp.Id = wi.Site_Certification_Standard__c
left join analytics.audit_values calc on calc.`Work Item Id` = wi.Id
where wi.IsDeleted = 0
and wi.Status__c in ('Open','Scheduled','Scheduled - Offered')
and wi.Work_Item_Date__c < now()
and wi.Revenue_Ownership__c like 'AUS%'
and wi.Revenue_Ownership__c not like '%Product%'
group by scsp.Id);

# New Business Calculation
select if (pg.Business_Line__c = 'Agri-Food', 'Food', 'MS') as 'stream', 'New Business Won (Audits)' as 'metric', '$' as 'Unit', 50 as 'index', 'Auto Generated' as 'Responsibility',
t.`WonPeriod`,
sum(oli.TotalPrice) as 'New Business'
 from (select if(date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') >= '2013 07' and date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') <= '2016 06', o.Id,null) as 'Opp Id', date_format(date_add(min(oh.CreatedDate),INTERVAL 11 HOUR),'%Y %m') as 'WonPeriod' from salesforce.opportunity o inner join salesforce.opportunityfieldhistory oh ON oh.OpportunityId = o.Id where o.IsDeleted = 0 and o.Business_1__c = 'Australia' and o.StageName='Closed Won' and oh.Field = 'StageName' and oh.NewValue = 'Closed Won' and o.Status__c = 'Active'group by o.Id) t left join salesforce.opportunitylineitem oli on oli.OpportunityId = t.`Opp Id` left join salesforce.standard__c s on oli.Standard__c = s.Id left join salesforce.program__c pg on s.Program__c = pg.Id where oli.IsDeleted=0 and oli.Days__c>0 and oli.First_Year_Revenue__c =1 
 group by `stream`, `metric`, `WonPeriod`;
 

