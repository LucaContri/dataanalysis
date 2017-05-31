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
    'Invoice' as 'Id Type',
    i.Id as 'Id',
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
GROUP BY `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `Id Type`, `Id`
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
    'Expense Line Item' as 'Id Type',
    eli.Id as 'Id',
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
GROUP BY `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `Id Type`, `Id`
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
    'Timesheet Line Item' as 'Id Type',
    tsli.Id as 'Id',
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
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `Id Type`, `Id`
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
    null as 'Id Type',
    null as 'Id',
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
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `Id Type`, `Id`
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
    null as 'Id Type',
    null as 'Id',
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
group by `F.Y.`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `Id Type`, `Id`;
