drop temporary table if exists standard_revenues ;
create temporary table standard_revenues as
(SELECT 			
    if(month(i.createdDate)<7, Year(i.createdDate),Year(i.createdDate)+1) as 'F.Y.',			
	analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c)) as 'Client Ownership Country',		
	a.Client_Ownership__c as 'Client Ownership',
    pr.Business_Line__c AS 'Business Line',			
    pr.Pathway__c AS 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',
	s.Name as 'Standard (Compass)',		
	analytics.getSimpleStandardFromStandard(s.Name, p.Name) as 'Standard',
    'Revenues' as 'DataType',
    pr.Category__c as 'SubType',			
    SUM(ili.Total_Line_Amount__c/cur.ConversionRate) AS 'Value',
    'AUD' as 'Unit'			
FROM			
    salesforce.invoice__c i			
	INNER JOIN salesforce.invoice_line_item__c ili ON ili.invoice__c = i.Id		
    INNER JOIN salesforce.currencytype cur ON cur.IsoCode = ili.CurrencyIsoCode			
	INNER JOIN salesforce.product2 pr ON pr.Id = ili.Product__c		
	INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id		
    INNER JOIN salesforce.Program__c p on s.Program__c = p.Id			
	INNER JOIN salesforce.account a ON a.Id = i.Billing_Client__c		
WHERE			
        i.IsDeleted = 0			
        AND i.Status__c NOT IN ('Cancelled')			
GROUP BY `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`);

# Expenses			
drop temporary table if exists standard_expenses;
create temporary table standard_expenses as
(SELECT 			
    if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
    analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c)) as 'Client Ownership Country',
	a.Client_Ownership__c as 'Client Ownership',		
	p.Business_Line__c AS 'Business Line',		
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard (Compass)',
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',
    if(eli.Billable__c in ('Billable','Pre-paid'), 'Expenses (Billable)', 'Expenses (Non Billable)') as 'DataType',			
    eli.Category__c as 'SubType',			
    sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate) as 'Value',
    'AUD' as 'Unit'	
FROM			
    salesforce.expense_line_item__c eli			
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c		
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode		
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c		
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id		
    INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id			
    inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id			
    inner join salesforce.standard__c s on sp.Standard__c = s.Id			
    inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id			
    inner join salesforce.program__c p on s.Program__c = p.Id			
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c		
WHERE
	eli.IsDeleted = 0			
	AND dts.IsDeleted = 0			
GROUP BY `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`);

drop temporary table if exists standard_auditors_cost;
create temporary table standard_auditors_cost as
(select 			
if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',			
	analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(a.Client_Ownership__c)) as 'Client Ownership Country',
    a.Client_Ownership__c as 'Client Ownership',		
    p.Business_Line__c AS 'Business Line',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard (Compass)',
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',
    if(tsli.Billable__c in ('Billable', 'Pre-paid'), 'Resource Cost (Billable)', 'Resource Cost (Non Billable)') as 'DataType',			
    tsli.Category__c as 'SubType',
	sum(tsli.Actual_Hours__c*ifnull(ar.`Avg Hourly Rate (AUD)`,ar2.`Avg Hourly Rate (AUD)`)) as 'Value',
    'AUD' as 'Unit'
from salesforce.timesheet_line_item__c tsli 			
inner join salesforce.daily_timesheet__c dts on dts.Id = tsli.Daily_Timesheet__c 			
inner join salesforce.resource__c r on r.Name = tsli.Resource_Name__c 			
inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id 			
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id			
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id			
inner join salesforce.standard__c s on sp.Standard__c = s.Id			
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id			
inner join salesforce.program__c p on s.Program__c = p.Id			
inner join salesforce.account a on a.Id = tsli.Client__c 			
left join 
	(select * from (		
		select ar.`Resource Id`, ar.period, ar.value/ct.ConversionRate as 'Avg Hourly Rate (AUD)', ar.`type`		
		from `analytics`.`auditor_rates_2` ar  		
			left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode  		
		where ar.value>0 		
		order by ar.`Resource Id` desc, ar.period desc limit 1) t group by t.`Resource Id`) ar on ar.`resource id` = r.Id
left join 
	(select * from (
		select ar.`Reporting_Business_Unit__c`, ar.value/ct.ConversionRate as 'Avg Hourly Rate (AUD)', ar.`type`		
		from `analytics`.`auditor_rates_2` ar  		
			left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode  		
		where 
			ar.value>0 		
			and ar.`Resource Id` is null
		order by ar.`Reporting_Business_Unit__c`, ar.period desc) t group by t.`Reporting_Business_Unit__c`) ar2 on ar2.`Reporting_Business_Unit__c` = r.Reporting_Business_Units__c
	
where 
	tsli.IsDeleted = 0 			
	and dts.IsDeleted = 0 
group by `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`);

drop temporary table if exists standard_audits;
create temporary table standard_audits as
(select 			
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c)) as 'Client Ownership Country',
    wi.Client_Ownership__c as 'Client Ownership',		
    p.Business_Line__c AS 'Business Line',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard (Compass)',
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',
    'Audit' as 'DataType',			
    'Count' as 'SubType',			
    count(distinct wi.Id) as 'Value',
    '#' as 'Unit'
from salesforce.work_item__c wi 			
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id			
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id			
inner join salesforce.standard__c s on sp.Standard__c = s.Id			
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id			
inner join salesforce.program__c p on s.Program__c = p.Id			
where 			
wi.IsDeleted = 0			
and wi.Status__c in ('Submitted', 'Under Review','Under Review - Rejected','Support','Completed')
and wi.Work_Item_Date__c is not null
group by `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`);

drop temporary table if exists standard_days;
create temporary table standard_days as
(select
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',			
	analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c)) as 'Client Ownership Country',
    wi.Client_Ownership__c as 'Client Ownership',		
    p.Business_Line__c AS 'Business Line',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard (Compass)',
	analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',
    'Audit' as 'DataType',			
    'Days' as 'SubType',			
    sum(wi.Required_Duration__c/8) as 'Value',			
    '#' as 'Unit'
from salesforce.work_item__c wi 			
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id			
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id			
inner join salesforce.standard__c s on sp.Standard__c = s.Id			
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id			
inner join salesforce.program__c p on s.Program__c = p.Id			
where 			
wi.IsDeleted = 0			
and wi.Status__c in ('Submitted', 'Under Review','Under Review - Rejected','Support','Completed')			
and wi.Work_Item_Date__c is not null
group by `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`);			

# Scheduling/PRC Weights for back-office expenses allocation									
drop temporary table if exists back_office_costs;
create temporary table back_office_costs as							
select 									
if(month(sc.`To`)<7, Year(sc.`To`),Year(sc.`To`)+1) as 'F.Y.',
analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c))) as 'Client Ownership Region',
    trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c)) as 'Client Ownership Country',
    wi.Client_Ownership__c as 'Client Ownership',
p.Business_Line__c AS 'Business Line',
p.Pathway__c as 'Pathway',			
p.Name as 'Program',			
p.Program_Code__c as 'Program Code',			
ps.Name as 'Standard (Compass)',
analytics.getSimpleStandardFromStandard(ps.Name, p.Name) as 'Standard',
'Scheduling' as 'DataType',			
sc.`Activity` as 'SubType',			
sum(if(sc.`Activity`='Create Work Item', 1,									
	if(sc.`Activity`='Cancelled', 5,								
		if(sc.`Activity`='Scheduled', 60/8.8,							
			if(sc.`Activity`='Scheduled Offered', 60/39.7,						
				if(sc.`Activity`='Unable To Schedule', 6,					
					if(sc.`Activity`='Confirmed', 60/30.2,				
						0			
					)				
				)					
			)						
		)							
	)								
)) as 'Value',			
'min' as 'Unit'								
from analytics.sla_scheduling_completed sc
left join salesforce.work_item__c wi on sc.`Id` = wi.`Id`									
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id									
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id									
left join salesforce.program__c p on sp.Program__c = p.Id									
left join salesforce.standard__c s on sp.Standard__c = s.Id									
left join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id									
WHERE 									
sc.`Activity` in ('Cancelled','Confirmed','Create Work Item','Scheduled','Scheduled Offered', 'Unable To Schedule')									
and sc.`Owner` not in ('Castiron User', 'Data Migration','Exact Target','Sam Allen','Timothy Moore')									
group by `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`
union									
select 									
if(month(t2.`ActionDate/Time`)<7, Year(t2.`ActionDate/Time`),Year(t2.`ActionDate/Time`)+1) as 'F.Y.',
t2.`Client Ownership Region`,
t2.`Client Ownership Country`,
t2.`Client Ownership`,
t2.`Program Business Line` as 'Business Line',									
t2.Pathway__c as 'Pathway',									
t2.`Program`,									
t2.`Program Code`,									
t2.`Primary Standard` as 'Standard (Compass)',
analytics.getSimpleStandardFromStandard(t2.`Primary Standard`, t2.`Program`) as 'Standard',
'PRC' as 'DataType',			
if (t2.`Action`='Requested Technical Review', 'Requested TR',									
	if(t2.`Rejections`>0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`), 'Re-Submission',								
			if (t2.RevenueOwnerships like '%Food%',						
				#Food					
				if(t2.PrimaryStandards like '%BRC%',					
					#BRC				
					if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',				
						'BRC/SQF/FSSC Follow Up/Gap',			
						'BRC Cert/Recert'			
					),				
					if(t2.PrimaryStandards like '%SQF%' or t2.PrimaryStandards like '%FSSC%',				
						#SQF/FSSC			
						if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',			
							'BRC/SQF/FSSC Follow Up/Gap',		
							'SQF/FSSC Cert/Recert'		
						),			
						#General Food			
						if(t2.WorkItemTypes like '%Follow Up%',			
							'Food - Follow Up',		
							if(t2.WorkItemsNo<3,		
								'Food - Low Complexity',	
								if(t2.WorkItemsNo<6,	
									'Food - Medium Complexity',
									'Food - High Complexity'
								)	
							)		
						)			
					)				
				),					
				if(t2.PrimaryStandards like '%16949%',					
					# Automotive				
					if(t2.WorkItemTypes like '%Follow Up%',				
						'Automotive - Follow Up',			
						'Automotive'			
					),				
					# Management Systems				
					if(t2.WorkItemTypes like '%Follow Up%',				
						'MS - Follow Up',			
						if(t2.WorkItemsNo<4,			
							'MS - Low Complexity',		
							if(t2.WorkItemsNo<12,		
								'MS - Medium Complexity',	
								'MS - High Complexity'	
							)		
						)			
					)				
				)					
			)						
		#)							
	)								
) as 'SubType',			
sum(if (t2.`Action`='Requested Technical Review', 5,									
	if(t2.`Rejections`>0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`), 5,								
			if (t2.RevenueOwnerships like '%Food%',						
				#Food					
				if(t2.PrimaryStandards like '%BRC%',					
					#BRC				
					if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',				
						15,			
						60			
					),				
					if(t2.PrimaryStandards like '%SQF%' or t2.PrimaryStandards like '%FSSC%',				
						#SQF/FSSC			
						if(t2.WorkItemTypes like '%Follow Up%' or t2.WorkItemTypes like '%Gap%',			
							15,		
							25		
						),			
						#General Food			
						if(t2.WorkItemTypes like '%Follow Up%',			
							10,		
							if(t2.WorkItemsNo<3,		
								6,	
								if(t2.WorkItemsNo<6,	
									15,
									25
								)	
							)		
						)			
					)				
				),					
				if(t2.PrimaryStandards like '%16949%',					
					# Automotive				
					if(t2.WorkItemTypes like '%Follow Up%',				
						60/3.5,			
						25			
					),				
					# Management Systems				
					if(t2.WorkItemTypes like '%Follow Up%',				
						5,			
						if(t2.WorkItemsNo<4,			
							8,		
							if(t2.WorkItemsNo<12,		
								15,	
								24	
							)		
						)			
					)				
				)					
			)						
		#)							
	)								
)) as 'Value',			
'min' as 'Unit'
from (select t.*, 									
		r.Name as 'ActionedBy',							
		r.Reporting_Business_Units__c,
        analytics.getRegionFromCountry(trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c))) as 'Client Ownership Region',
		trim(analytics.getBUFromReportingBusinessUnit(wi.Client_Ownership__c)) as 'Client Ownership Country',
        wi.Client_Ownership__c as 'Client Ownership',
		ah.Timestamp__c as 'ActionDate/Time',							
		ah.Id as 'ActionId',							
		ah.Status__c as 'Action',							
		ah.Assigned_To__c as 'Assigned To',							
		group_concat(distinct wi.Revenue_Ownership__c) as 'RevenueOwnerships',							
		count(distinct wi.Id) as 'WorkItemsNo',							
		group_concat(distinct wi.Work_Item_Stage__c) as 'WorkItemTypes',							
		group_concat(distinct st.Name) as 'PrimaryStandards',
		group_concat(distinct stpr.Program_Business_Line__c) as 'ProgramBusinessLines',							
		pst.Name as 'Primary Standard',							
		stpr.Program_Business_Line__c as 'Program Business Line',							
        p.Name as 'Program',									
        p.Program_Code__c as 'Program Code',									
        p.Pathway__c,									
		GROUP_CONCAT(DISTINCT IF((`scsf`.`IsDeleted` OR `sp`.`IsDeleted`OR `s`.`IsDeleted`),NULL,`s`.`Name`) SEPARATOR ',') AS `Standard Families`							
		from salesforce.enlighten_prc_activity_sub t							
		inner join salesforce.Approval_History__c ah on ah.RAudit_Report_Group__c = t.ARG_Id							
		inner join salesforce.Resource__c r on ah.RApprover__c = r.Id							
		inner join salesforce.arg_work_item__c argwi on argwi.RAudit_Report_Group__c = t.Arg_Id 							
		inner join salesforce.work_item__c wi on wi.id = argwi.RWork_Item__c 							
		inner join salesforce.`site_certification_standard_program__c` `scsp` ON `wi`.`Site_Certification_Standard__c` = `scsp`.`Id`							
		inner join salesforce.`standard_program__c` `stpr` on scsp.Standard_Program__c = stpr.Id							
        left join salesforce.`standard__c` st on stpr.Standard__c = st.Id									
		left join salesforce.standard__c pst on st.Parent_Standard__c = pst.Id							
        LEFT JOIN salesforce.Program__c p on st.Program__c = p.Id									
		LEFT JOIN salesforce.`site_certification_standard_family__c` `scsf` ON `scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`							
		LEFT JOIN salesforce.`standard_program__c` `sp` ON `scsf`.`Standard_Program__c` = `sp`.`Id`							
		LEFT JOIN salesforce.`standard__c` `s` ON `sp`.`Standard__c` = `s`.`Id`							
		where							
		wi.IsDeleted=0 and wi.Status__c not in ('Cancelled') and argwi.IsDeleted=0 							
		and ah.IsDeleted=0							
		and ah.Status__c in ('Approved','Rejected', 'Requested Technical Review')							
        group by ah.Id) t2							
left join salesforce.Resource__c ca on t2.Assigned_CA__c = ca.Id
group by `F.Y.`, `Client Ownership`, `Business Line` , `Pathway` , `Standard`, `DataType`, `SubType`;

select * from standard_revenues
union
select * from standard_expenses
union
select * from standard_auditors_cost 
union
select * from standard_audits
union
select * from standard_days
union
select * from back_office_costs;

(select t.Reporting_Business_Unit__c as 'Reporting Business Unit', t.`Resource Id`, r.Name as 'Resource Name', t.`Hourly Rate (AUD)`, t.`Rate Type` from (
	select ar.`Resource Id`, ar.Reporting_Business_Unit__c, value/ct.ConversionRate as 'Hourly Rate (AUD)', ar.type as 'Rate Type'
	from analytics.auditor_rates_2 ar
    inner join salesforce.currencytype ct on ct.IsoCode = ar.currency_iso_code
	order by ar.`Resource Id`, ar.Reporting_Business_Unit__c, ar.period desc) t
left join salesforce.resource__c r on t.`Resource Id` = r.Id
group by t.`Resource Id`, t.Reporting_Business_Unit__c);