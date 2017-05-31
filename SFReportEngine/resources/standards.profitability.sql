# Revenues
drop temporary table standards_revenues;
create temporary table standards_revenues as
SELECT 
	if(month(i.createdDate)<7, Year(i.createdDate),Year(i.createdDate)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    pr.Business_Line__c AS 'BusinessLine',
    pr.Pathway__c AS 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    s.Name AS 'Standard',
    count(distinct i.Billing_Client__c) as '# Billing Clients',
    count(distinct sc.Primary_client__c) as '# Sites',
    #sum(if(pr.Category__c like 'Audit%', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue Audit',
    #sum(if(pr.Category__c in ('Application', 'Registration Fee'), ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue Fees',
    #sum(if(pr.Category__c like 'Travel%', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue Travel',
    sum(if(pr.Category__c = 'Application', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Application',
	sum(if(pr.Category__c = 'Audit', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Audit',
	sum(if(pr.Category__c = 'Audit - Additional Day', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Audit - Additional Day',
	sum(if(pr.Category__c = 'Audit - CE', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Audit - CE',
	sum(if(pr.Category__c = 'Audit Planning', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Audit Planning',
	sum(if(pr.Category__c = 'Cancellation', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Cancellation',
	sum(if(pr.Category__c = 'Certificate Change', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Certificate Change',
	sum(if(pr.Category__c = 'Client Management', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Client Management',
	sum(if(pr.Category__c = 'Client Management - Day', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Client Management - Day',
	sum(if(pr.Category__c = 'Project Time', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Project Time',
	sum(if(pr.Category__c = 'Project Time - Other', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Project Time - Other',
	sum(if(pr.Category__c = 'Project Time - Simple', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Project Time - Simple',
	sum(if(pr.Category__c = 'Registration Fee', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Registration Fee',
	sum(if(pr.Category__c = 'Report Writing', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Report Writing',
	sum(if(pr.Category__c = 'Royalty Fee', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Royalty Fee',
	sum(if(pr.Category__c = 'Technical Advisor', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Technical Advisor',
	sum(if(pr.Category__c = 'Technical Advisor Hours', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Technical Advisor Hours',
	sum(if(pr.Category__c = 'Technical Review', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Technical Review',
	sum(if(pr.Category__c = 'Testing', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Testing',
	sum(if(pr.Category__c = 'Translation', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Translation',
	sum(if(pr.Category__c = 'Travel', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Travel',
	sum(if(pr.Category__c = 'Travel Cost', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Travel Cost',
	sum(if(pr.Category__c = 'Travel Cost - Distance', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Travel Cost - Distance',
	sum(if(pr.Category__c = 'Travel Cost - Metro', ili.Total_Line_Amount__c/cur.ConversionRate, 0)) as 'Revenue - Travel Cost - Metro',
    SUM(ili.Total_Line_Amount__c/cur.ConversionRate) AS 'TotalInvoiced (AUD)'
FROM
    salesforce.invoice__c i
	INNER JOIN salesforce.invoice_line_item__c ili ON ili.invoice__c = i.Id and ili.IsDeleted = 0
    left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id
    left join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
    left join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
    INNER JOIN salesforce.currencytype cur ON cur.IsoCode = ili.CurrencyIsoCode
	INNER JOIN salesforce.product2 pr ON pr.Id = ili.Product__c
	INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id
    INNER JOIN salesforce.Program__c p on s.Program__c = p.Id
	INNER JOIN salesforce.account a ON a.Id = i.Billing_Client__c
WHERE
        i.IsDeleted = 0
        #AND i.Status__c IN ('Closed' , 'Open')
        AND i.Status__c NOT IN ('Cancelled')
GROUP BY `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`;

(select * from standards_revenues);
# Expenses
#drop temporary table standards_expenses;
create temporary table standards_expenses as
SELECT 
    if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name AS 'Standard',
    sum(if (eli.Category__c = 'Travel Costs - Airfares', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Airfares',
    sum(if (eli.Category__c = 'Travel Costs - Accommodation', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Accommodation',
    sum(if (eli.Category__c in ('Travel Costs - Meals','Travel Costs - Meals / Incidentals'), eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Meals',
    sum(if (eli.Category__c in ('Travel Costs - Car Hire','Travel Costs - Car Hire / Taxis'), eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Car Hire',
    sum(if (eli.Category__c = 'Travel Costs - Taxis', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Taxis',
    sum(if (eli.Category__c = 'Travel Costs - Other', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Other',
    sum(if (eli.Category__c = 'Travel Cost - Metro', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Metro',
    sum(if (eli.Category__c = 'Travel Cost - Distance', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Costs - Distance',
    sum(if (eli.Category__c = 'Technical Advisor Hours', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Technical Advisor Hours',
    sum(if (eli.Category__c = 'Travel Cost - Per Diem', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Travel Cost - Per Diem',
    sum(if (eli.Billable__c = 'Billable', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Expenses (Billable) (AUD)',
    sum(if (eli.Billable__c != 'Billable', eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate, 0)) as 'Expenses (Non-Billable) (AUD)'
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
GROUP BY `F.Y.`, `ClientOwnership`, `Standard`;

(select * from standards_expenses);

# CoGS - Resource Cost
set @employee_rate = 115;
set @contractor_rate = 106;
#drop temporary table standards_resources_cost;
create temporary table standards_resources_cost as
(select t.`F.Y.`, t.`ClientOwnership`, t.`Program`, t.`Standard`, sum(t.`Resource Cost (Billable)`) as 'Resource Cost (Billable)', sum(t.`Resource Cost (Non-Billable)`) as 'Resource Cost (Non-Billable)', count(t.Id) as '# Audit', sum(t.`Required_Duration__c`/8) as '# Required Days', sum(t.`Actual Hours`/8) as '# Actual Days', sum(t.`Employee Actual Hours`) as 'Employee Actual Hours', sum(t.`Contractor Actual Hours`) as 'Contractor Actual Hours' from 
(select 
wi.Id,
if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name as 'Standard',
    sp.Program_Business_Line__c,
    sum(if(tsli.Billable__c='Billable',tsli.Actual_Hours__c*ifnull(ar.`Avg Hourly Rate (AUD)`,if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate)),0)) as 'Resource Cost (Billable)', 
    sum(if(tsli.Billable__c='Non-Billable',tsli.Actual_Hours__c*ifnull(ar.`Avg Hourly Rate (AUD)`,if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate)),0)) as 'Resource Cost (Non-Billable)',
    sum(if(r.Resource_Type__c='Employee',tsli.Actual_Hours__c, 0)) as 'Employee Actual Hours',
    sum(if(r.Resource_Type__c='Contractor ',tsli.Actual_Hours__c, 0)) as 'Contractor Actual Hours',
    wi.required_duration__c,
    sum(tsli.Actual_Hours__c) as 'Actual Hours'
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
left join (
	select ar.country, ar.business_line, ar.resource_type,
	avg(ar.value/ct.ConversionRate) as 'Avg Hourly Rate (AUD)'
	from `analytics`.`auditor_rates` ar
	left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode
    where ar.value>0
	group by ar.country, ar.business_line, ar.resource_type) ar on 
			ar.country = if(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%', 'Australia', if(r.Reporting_Business_Units__c='China-MS','China', substring_index(r.Reporting_Business_Units__c, '-',-1))) 
            and ar.resource_type = r.Resource_Type__c 
            and ar.business_line = if(r.Reporting_Business_Units__c like 'AUS%' and r.Reporting_Business_Units__c not like '%Product%' and sp.Program_Business_Line__c not like '%Product%', sp.Program_Business_Line__c, 'All')
where 
tsli.IsDeleted = 0 
and dts.IsDeleted = 0 
and r.Resource_Type__c in ('Employee', 'Contractor')
group by wi.Id) t
group by t.`F.Y.`, t.`ClientOwnership`, t.`Standard`);


# Scheduling/PRC Weights for back-office expenses allocation
create temporary table back_office_costs as
select 
'Scheduling' as 'Team',
sc.`Region` as 'Region',
'Scheduling Ownership' as 'Region Type',
sc.`Activity`,
date_format(sc.`To`, '%Y-%m') as 'Period Processed', 
if(month(sc.`To`)<7, Year(sc.`To`),Year(sc.`To`)+1) as 'F.Y. Processed',
p.Business_Line__c as 'Business Line', 
p.Pathway__c as 'Pathway', 
p.Name as 'Program', 
p.Program_Code__c as 'Program Code', 
ps.Name as 'Standard',
count(sc.Id) as '# Items',
if(sc.`Activity`='Create Work Item', 1,
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
) as 'Activity Unit Time (min)'
from analytics.sla_scheduling_completed sc
left join salesforce.work_item__c wi on sc.`Id` = wi.`Id`
left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.program__c p on sp.Program__c = p.Id
left join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
WHERE 
(sc.`Region` LIKE 'AUS%' OR sc.`Region` LIKE 'ASS%')
and sc.`Activity` in ('Cancelled','Confirmed','Create Work Item','Scheduled','Scheduled Offered', 'Unable To Schedule')
and sc.`Owner` not in ('Castiron User', 'Data Migration','Exact Target','Sam Allen','Timothy Moore')
group by sc.`Region`, sc.`Activity`,`Period Processed`, p.Business_Line__c, p.Pathway__c, p.Name, p.Program_Code__c, sp.Standard_Service_Type_Name__c,`Activity Unit Time (min)`
union
select 
'PRC' as 'Team', 
t2.Reporting_Business_Units__c as 'Region',
'Reporting Business Unit' as 'Region Type',
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
) as 'Activity',
date_format(t2.`ActionDate/Time`, '%Y-%m') as 'Period Processed',
if(month(t2.`ActionDate/Time`)<7, Year(t2.`ActionDate/Time`),Year(t2.`ActionDate/Time`)+1) as 'F.Y. Processed',
t2.`Program Business Line` as 'Business Line',
t2.Pathway__c as 'Pathway',
t2.`Program`,
t2.`Program Code`,
t2.`Primary Standard` as 'Standard',
count(t2.ARG_Id) as '# Items',
if (t2.`Action`='Requested Technical Review', 5,
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
) as 'Activity Unit Time (min)'
from (select t.*, 
		r.Name as 'ActionedBy',
		r.Reporting_Business_Units__c,
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
        and r.Reporting_Business_Units__c like 'AUS%'
		group by ah.Id) t2
left join salesforce.Resource__c ca on t2.Assigned_CA__c = ca.Id
where (t2.`PrimaryStandards` not like '%WQA%'
	and t2.`PrimaryStandards` not like '%Woolworths%'
	and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
	and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by  `Period Processed`, `Activity`, t2.`ProgramBusinessLines`, t2.`PrimaryStandards`, t2.`Program`, t2.`Program Code`;

#drop temporary table back_office_durations;
create temporary table back_office_durations as
select Team, sum(`# Items`*`Activity Unit Time (min)`) as 'Duration (min)' from back_office_costs where Region not like 'AUS-Product%' and `F.Y. Processed` = 2015 group by Team;
set @scheduling_total_cost = 900000;
set @prc_total_cost = 800000;
set @admin_total_cost = 360000;

select * from `analytics`.`auditor_rates` group by Country;
#explain
(select sr.`F.Y.`,
	sr.`ClientOwnership`,
    sr.`BusinessLine`,
    sr.`Pathway`,
    sr.`Program`,
    sr.`Program Code`,
    sr.`Standard`,
    #sr.`Revenue Audit`,
    #sr.`Revenue Fees`,
    #sr.`Revenue Travel`,
    sr.`# Billing Clients`,
    sr.`# Sites`,
    sr.`Revenue - Application`,
	sr.`Revenue - Audit`,
	sr.`Revenue - Audit - Additional Day`,
	sr.`Revenue - Audit - CE`,
	sr.`Revenue - Audit Planning`,
	sr.`Revenue - Cancellation`,
	sr.`Revenue - Certificate Change`,
	sr.`Revenue - Client Management`,
	sr.`Revenue - Client Management - Day`,
	sr.`Revenue - Project Time`,
	sr.`Revenue - Project Time - Other`,
	sr.`Revenue - Project Time - Simple`,
	sr.`Revenue - Registration Fee`,
	sr.`Revenue - Report Writing`,
	sr.`Revenue - Royalty Fee`,
	sr.`Revenue - Technical Advisor`,
	sr.`Revenue - Technical Advisor Hours`,
	sr.`Revenue - Technical Review`,
	sr.`Revenue - Testing`,
	sr.`Revenue - Translation`,
	sr.`Revenue - Travel`,
	sr.`Revenue - Travel Cost`,
	sr.`Revenue - Travel Cost - Distance`,
	sr.`Revenue - Travel Cost - Metro`,
    sr.`TotalInvoiced (AUD)`,
    se.`Travel Costs - Airfares`,
    se.`Travel Costs - Accommodation`,
    se.`Travel Costs - Meals`,
    se.`Travel Costs - Car Hire`,
    se.`Travel Costs - Taxis`,
    se.`Travel Costs - Other`,
    se.`Travel Costs - Metro`,
    se.`Travel Costs - Distance`,
    se.`Technical Advisor Hours`,
    se.`Travel Cost - Per Diem`,
    se.`Expenses (Billable) (AUD)`,
    se.`Expenses (Non-Billable) (AUD)`,
    src.`Resource Cost (Billable)`,
    src.`Resource Cost (Non-Billable)`,
    src.`# Audit`, 
    src.`# Required Days`,
    src.`# Actual Days`,
    src.`Employee Actual Hours`,
    src.`Contractor Actual Hours`,
    lp.`Avg List Price`,
    ifnull(if(sr.`ClientOwnership`='Australia', bc.`Scheduling Cost`, null),0) as 'BackOffice Scheduling Costs',
    ifnull(if(sr.`ClientOwnership`='Australia', bc.`PRC Cost`, null),0) as 'BackOffice PRC Costs',
    ifnull(if(sr.`ClientOwnership`='Australia', bc.`Admin Cost`, null),0) as 'BackOffice Admin Costs'
from standards_revenues sr
left join standards_expenses se on sr.`F.Y.` = se.`F.Y.` and sr.`ClientOwnership`=se.`ClientOwnership` and sr.`Standard`=se.`Standard`
left join standards_resources_cost src on sr.`F.Y.` = src.`F.Y.` and sr.`ClientOwnership`=src.`ClientOwnership` and sr.`Standard`=src.`Standard`
left join (
select 
	boc.`Standard`, 
    sum(if(boc.`Team`='Scheduling',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/
		max(if(bod.`Team` = 'Scheduling', bod.`Duration (min)`,0)) as 'Scheduling %',
	sum(if(boc.`Team`='Scheduling',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/
		max(if(bod.`Team` = 'Scheduling', bod.`Duration (min)`,0)) as 'Admin %',
	sum(if(boc.`Team`='PRC',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/ 
		max(if(bod.`Team` = 'PRC', bod.`Duration (min)`,0)) as 'PRC %',
	sum(if(boc.`Team`='Scheduling',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/
		max(if(bod.`Team` = 'Scheduling', bod.`Duration (min)`,0))*@scheduling_total_cost as 'Scheduling Cost',
	sum(if(boc.`Team`='Scheduling',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/
		max(if(bod.`Team` = 'Scheduling', bod.`Duration (min)`,0))*@admin_total_cost as 'Admin Cost',
	sum(if(boc.`Team`='PRC',boc.`# Items`*boc.`Activity Unit Time (min)`,0))/ 
		max(if(bod.`Team` = 'PRC', bod.`Duration (min)`,0))*@prc_total_cost as 'PRC Cost'
from back_office_costs boc
left join back_office_durations bod on bod.`Team` = boc.`Team` 
where boc.`Region` not like 'AUS-Product%'
and boc.`F.Y. Processed` = 2015
group by boc.`Standard`) bc on sr.`Standard`=bc.`Standard`
left join (
		# Sanity Check
		select 
			pr.Business_Line__c AS 'BusinessLine',
			pr.Pathway__c AS 'Pathway',
			p.Name as 'Program',
			p.Program_Code__c as 'Program Code',
			s.Name as 'Standard',
			avg(pbe.UnitPrice) as 'Avg List Price'
		from 
			salesforce.product2 pr
			INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id
			INNER JOIN salesforce.Program__c p on s.Program__c = p.Id
			INNER JOIN salesforce.pricebookentry pbe on pbe.Product2Id = pr.Id
		where 
			pr.Category__c = 'Audit'
			and pbe.Pricebook2Id = '01s90000000568BAAQ'
			and pr.UOM__c = 'DAY'
			and pr.Business_Line__c not in ('Product Services')
		group by `BusinessLine`, `Pathway`, `Program`) lp on sr.`ClientOwnership`='Australia' and sr.`Standard`=lp.`Standard`);

# Details
# Revenues			
SELECT 			
    if(month(i.createdDate)<7, Year(i.createdDate),Year(i.createdDate)+1) as 'F.Y.',			
	a.Client_Ownership__c as 'ClientOwnership',		
    pr.Business_Line__c AS 'BusinessLine',			
    pr.Pathway__c AS 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    s.Name AS 'Standard',			
    'Revenues' as 'Type',			
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
GROUP BY `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`
union			
# Expenses			
SELECT 			
    if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',			
	a.Client_Ownership__c as 'ClientOwnership',		
	p.Business_Line__c AS 'BusinessLine',		
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name AS 'Standard',			
    if(eli.Billable__c = 'Billable', 'Expenses (Billable)', 'Expenses (Non Billable)') as 'Type',			
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
GROUP BY `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`
union			
select 			
if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',			
	a.Client_Ownership__c as 'ClientOwnership',		
    p.Business_Line__c AS 'BusinessLine',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard',			
    if(tsli.Billable__c='Billable', 'Resource Cost (Billable)', 'Resource Cost (Non Billable)') as 'Type',			
    tsli.Category__c as 'SubType',			
    sum(tsli.Actual_Hours__c*ifnull(ar.`Avg Hourly Rate (AUD)`,if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate))) as 'Value',			
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
left join (			
	select ar.country, ar.business_line, ar.resource_type,		
	avg(ar.value/ct.ConversionRate) as 'Avg Hourly Rate (AUD)'		
	from `analytics`.`auditor_rates` ar		
	left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode		
    where ar.value>0			
	group by ar.country, ar.business_line, ar.resource_type) ar on 		
			ar.country = if(r.Reporting_Business_Units__c like 'AUS%' or r.Reporting_Business_Units__c like 'ASS%', 'Australia', if(r.Reporting_Business_Units__c='China-MS','China', substring_index(r.Reporting_Business_Units__c, '-',-1))) 
            and ar.resource_type = r.Resource_Type__c 			
            and ar.business_line = if(r.Reporting_Business_Units__c like 'AUS%' and r.Reporting_Business_Units__c not like '%Product%' and sp.Program_Business_Line__c not like '%Product%', sp.Program_Business_Line__c, 'All')			
where 			
tsli.IsDeleted = 0 			
and dts.IsDeleted = 0 			
and r.Resource_Type__c in ('Employee', 'Contractor')			
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`			
union			
select 			
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',			
	wi.Client_Ownership__c as 'ClientOwnership',		
    p.Business_Line__c AS 'BusinessLine',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard',			
    'Audit' as 'Type',			
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
and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service')			
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`			
union			
select 			
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',			
	wi.Client_Ownership__c as 'ClientOwnership',		
    p.Business_Line__c AS 'BusinessLine',			
    p.Pathway__c as 'Pathway',			
    p.Name as 'Program',			
    p.Program_Code__c as 'Program Code',			
    ps.Name as 'Standard',			
    'Audit' as 'Type',			
    'Days' as 'SubType',			
    sum(distinct wi.Required_Duration__c/8) as 'Value',			
    '#' as 'Unit'			
from salesforce.work_item__c wi 			
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id			
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id			
inner join salesforce.standard__c s on sp.Standard__c = s.Id			
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id			
inner join salesforce.program__c p on s.Program__c = p.Id			
where 			
wi.IsDeleted = 0			
and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service')			
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`;