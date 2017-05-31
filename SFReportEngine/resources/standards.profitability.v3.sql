select Id, name from salesforce.standard__c where name like '%Marks & Spencer%';
set @std1 = 'McDonalds';
set @std2 = 'Marks & Spencer';
# Revenues
(select * from (
SELECT 
	i.createdDate as 'Date',
    if(month(i.createdDate)<7, Year(i.createdDate),Year(i.createdDate)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    '' as 'Site Country',
    pr.Business_Line__c AS 'BusinessLine',
    pr.Pathway__c AS 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    s.Name AS 'Standard',
    'Revenues' as 'Type',
    pr.Category__c as 'SubType',
    'Invoice' as 'Id Type',
    i.Id as 'Id',
    ili.Total_Line_Amount__c/cur.ConversionRate AS 'Value',
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
        and (s.Name like concat('%',@std1,'%') or s.Name like concat('%',@std2,'%'))
union
# Expenses
SELECT 
	dts.Date__c as 'Date',
    if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    ccs.Name as 'Site Country',
	p.Business_Line__c AS 'BusinessLine',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name AS 'Standard',
    concat('Expenses (',eli.Billable__c,')') as 'Type',
    eli.Category__c as 'SubType',
    'Expense Line Item' as 'Id Type',
    eli.Id as 'Id',
    eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate as 'Value',
    'AUD' as 'Unit'
    
FROM
    salesforce.expense_line_item__c eli
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id
    INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
    inner join salesforce.standard__c s on sp.Standard__c = s.Id
    inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
    inner join salesforce.program__c p on s.Program__c = p.Id
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c
WHERE
        eli.IsDeleted = 0
        AND dts.IsDeleted = 0
        and (ps.Name like concat('%',@std1,'%') or ps.Name like concat('%',@std2,'%'))
union
select 
dts.Date__c as 'Date',
if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
	a.Client_Ownership__c as 'ClientOwnership',
    ccs.Name as 'Site Country',
    p.Business_Line__c AS 'BusinessLine',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name as 'Standard',
    concat('Resource Cost (',tsli.Billable__c,')') as 'Type',
    tsli.Category__c as 'SubType',
    'Timesheet Line Item' as 'Id Type',
    tsli.Id as 'Id',
    tsli.Actual_Hours__c as 'Value',
    'Hours' as 'Unit'
from salesforce.timesheet_line_item__c tsli 
inner join salesforce.daily_timesheet__c dts on dts.Id = tsli.Daily_Timesheet__c 
inner join salesforce.resource__c r on r.Name = tsli.Resource_Name__c 
inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id 
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
inner join salesforce.program__c p on s.Program__c = p.Id
inner join salesforce.account a on a.Id = tsli.Client__c 
where 
tsli.IsDeleted = 0 
and dts.IsDeleted = 0 
and r.Resource_Type__c in ('Employee', 'Contractor')
and (ps.Name like concat('%',@std1,'%') or ps.Name like concat('%',@std2,'%'))
union
select 
wi.Work_Item_Date__c as 'Date',
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	wi.Client_Ownership__c as 'ClientOwnership',
    ccs.Name as 'Site Country',
    p.Business_Line__c AS 'BusinessLine',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name as 'Standard',
    'Audit' as 'Type',
    'Count' as 'SubType',
    'Work Item' as 'Id Type',
    wi.id as 'Id',
    1 as 'Value',
    '#' as 'Unit'
from salesforce.work_item__c wi 
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
inner join salesforce.program__c p on s.Program__c = p.Id
where 
wi.IsDeleted = 0
and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service')
and (ps.Name like concat('%',@std1,'%') or ps.Name like concat('%',@std2,'%'))
group by wi.Id
union
select 
wi.Work_Item_Date__c as 'Date',
if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',
	wi.Client_Ownership__c as 'ClientOwnership',
    ccs.Name as 'Site Country',
    p.Business_Line__c AS 'BusinessLine',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    ps.Name as 'Standard',
    'Audit' as 'Type',
    'Days' as 'SubType',
    'Work Item' as 'Id Type',
    wi.Id as 'Id',
    sum(distinct wi.Required_Duration__c/8) as 'Value',
    '#' as 'Unit'
from salesforce.work_item__c wi 
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
inner join salesforce.program__c p on s.Program__c = p.Id
where 
wi.IsDeleted = 0
and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service')
and (ps.Name like concat('%',@std1,'%') or ps.Name like concat('%',@std2,'%'))
group by wi.Id
) t where t.`Date` between '2015-01-04' and '2015-10-31');


#No of Individual Auditors
select 
group_concat(distinct r.Name order by r.Name) as 'Individual Auditors'
from salesforce.work_item__c wi 
inner join salesforce.resource__c r on wi.RAudit_Report_Author__c = r.Id
INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id
inner join salesforce.program__c p on s.Program__c = p.Id
where 
wi.IsDeleted = 0
and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service')
and (ps.Name like concat('%',@std1,'%') or ps.Name like concat('%',@std2,'%'))
and ccs.Name = 'United Kingdom'
and wi.Work_Item_Date__c between '2015-01-04' and '2015-10-31';
