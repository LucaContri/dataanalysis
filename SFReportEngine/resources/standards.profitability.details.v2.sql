set @employee_rate = 100;
set @contractor_rate = 110;

SELECT    
    if(month(i.createdDate)<7, Year(i.createdDate),Year(i.createdDate)+1) as 'F.Y.',
    date_format(i.createdDate, '%Y-%m') as 'Invoice Created Period',
	ili.Revenue_Ownership__c as 'RevenueOwnership',  
    pr.Business_Line__c AS 'BusinessLine',   
    pr.Pathway__c AS 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',
    s.Name AS 'Standard',   
    'Revenues' as 'Type',   
    pr.Category__c as 'SubType',
    'n/a' as 'SubType 2', 
    'n/a' as 'SubType 3',
    'Billable' as 'Billable',
    sum(ili.Total_Line_Amount__c) as 'Value',
    group_concat(distinct ili.CurrencyIsoCode) as 'Units',
    SUM(ili.Total_Line_Amount__c/cur.ConversionRate) AS 'Amount',   
    'AUD' as 'Currency',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    '' as 'Auditor'
FROM salesforce.invoice__c i   
INNER JOIN salesforce.invoice_line_item__c ili ON ili.invoice__c = i.Id
left join salesforce.work_item__c wi on ili.Work_Item__c = wi.Id and wi.IsDeleted = 0
INNER JOIN salesforce.currencytype cur ON cur.IsoCode = ili.CurrencyIsoCode   
INNER JOIN salesforce.product2 pr ON pr.Id = ili.Product__c  
INNER JOIN salesforce.standard__c s ON pr.Standard__c = s.Id  
INNER JOIN salesforce.Program__c p on s.Program__c = p.Id   
INNER JOIN salesforce.account a ON a.Id = i.Billing_Client__c  
WHERE i.IsDeleted = 0
	and ili.IsDeleted =0 
    AND i.Status__c NOT IN ('Cancelled')   
    #and s.ID='a36d0000000Chj3AAC'
    #and a.Client_Ownership__c = 'EMEA - UK'
    #and date_format(i.createdDate, '%Y-%m') in ('2016-07','2016-08','2016-09')
GROUP BY ili.Id,`F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`   
union   
# Expenses   
SELECT    
    #if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',
    if(month(iid.`Invoice Created Date`)<7, Year(iid.`Invoice Created Date`),Year(iid.`Invoice Created Date`)+1) as 'F.Y.',
    date_format(iid.`Invoice Created Date`, '%Y-%m') as 'Invoice Created Period',
	wi.Revenue_Ownership__c as 'RevenueOwnership',  
	p.Business_Line__c AS 'BusinessLine',  
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',   
    ps.Name AS 'Standard',   
    'Expenses' as 'Type',   
    eli.Category__c as 'SubType', 
    'n/a' as 'SubType 2', 
    r.Resource_Type__c as 'SubType 3',
    eli.Billable__c as 'Billable',
    sum(eli.FTotal_Amount_Ex_Tax__c) as 'Value',
    group_concat(distinct eli.CurrencyIsoCode) as 'Units',
    sum(eli.FTotal_Amount_Ex_Tax__c / cur.ConversionRate) as 'Amount',   
    'AUD' as 'Currency',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.NAme as 'Auditor'
FROM   
    salesforce.expense_line_item__c eli   
	INNER JOIN salesforce.daily_timesheet__c dts ON dts.Id = eli.Daily_Timesheet__c
	INNER JOIN salesforce.currencytype cur ON cur.IsoCode = eli.CurrencyIsoCode  
	INNER JOIN salesforce.resource__c r ON r.Name = eli.Resource_Name__c  
	INNER JOIN salesforce.work_item__c wi ON eli.Work_Item__c = wi.Id
    inner join (select ili.Work_Item__c, ili.Invoice__c, min(i.CreatedDate) as 'Invoice Created Date' from salesforce.invoice_line_item__c ili inner join salesforce.invoice__c i on ili.Invoice__c = i.Id group by ili.Work_Item__c) iid on iid.Work_Item__c = wi.Id
    INNER join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
    inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
    inner join salesforce.standard__c s on sp.Standard__c = s.Id   
    inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
    inner join salesforce.program__c p on s.Program__c = p.Id   
	INNER JOIN salesforce.account a ON a.Id = eli.Client__c  
WHERE eli.IsDeleted = 0   
      AND dts.IsDeleted = 0   
      #and ps.ID='a36d0000000Chj3AAC'
	  #and a.Client_Ownership__c = 'EMEA - UK'
      #and date_format(iid.`Invoice Created Date`, '%Y-%m') in ('2016-07','2016-08','2016-09')
GROUP BY eli.Id,`F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable` 
union   
select    
	#if(month(dts.Date__c)<7, Year(dts.Date__c),Year(dts.Date__c)+1) as 'F.Y.',   
	if(month(iid.`Invoice Created Date`)<7, Year(iid.`Invoice Created Date`),Year(iid.`Invoice Created Date`)+1) as 'F.Y.',
    date_format(iid.`Invoice Created Date`, '%Y-%m') as 'Invoice Created Period',
	wi.Revenue_Ownership__c as 'RevenueOwnership',  
    p.Business_Line__c AS 'BusinessLine',   
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',   
    ps.Name as 'Standard',   
    'Resource Cost' as 'Type',   
    tsli.Category__c as 'SubType',
	if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2', 
    r.Resource_Type__c as 'SubType 3',
    tsli.Billable__c as 'Billable',
    sum(tsli.Actual_Hours__c) as 'Value',
    'Hours' as 'Unit',
    sum(tsli.Actual_Hours__c*ifnull(if(r.Reporting_Business_Units__c like '%UK' and r.Resource_Type__c='Contractor' and wi.Work_Item_Stage__c='Follow Up',0, ar.`Avg Hourly Rate (AUD)`),if(r.Resource_Type__c='Employee',@employee_rate, @contractor_rate))) as 'Amount',   
    'AUD' as 'Currency',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.Name as 'Auditor'
from salesforce.timesheet_line_item__c tsli    
	inner join salesforce.daily_timesheet__c dts on dts.Id = tsli.Daily_Timesheet__c    
	inner join salesforce.resource__c r on r.Name = tsli.Resource_Name__c    
	inner join salesforce.work_item__c wi on tsli.Work_Item__c = wi.Id    
	inner join (select ili.Work_Item__c, ili.Invoice__c, min(i.CreatedDate) as 'Invoice Created Date' from salesforce.invoice_line_item__c ili inner join salesforce.invoice__c i on ili.Invoice__c = i.Id group by ili.Work_Item__c) iid on iid.Work_Item__c = wi.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
	inner join salesforce.account a on a.Id = tsli.Client__c    
	left join (   
	 select ar.`Resource Id`, ar.period, ar.value/ct.ConversionRate as 'Avg Hourly Rate (AUD)'  
	 from `analytics`.`auditor_rates_2` ar  
	 left join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode  
	 where ar.value>0  
     order by ar.`Resource Id` desc, ar.period desc) ar on ar.`resource id` = r.Id and ar.period<wi.Work_Item_Date__c
       
		
where tsli.IsDeleted = 0    
	and dts.IsDeleted = 0    
	and r.Resource_Type__c in ('Employee', 'Contractor')   
    #and ps.ID='a36d0000000Chj3AAC'
    #and a.Client_Ownership__c = 'EMEA - UK'
    #and date_format(iid.`Invoice Created Date`, '%Y-%m') in ('2016-07','2016-08','2016-09')
group by tsli.Id,`F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`  
union   
select    
	#if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.', 
	if(month(iid.`Invoice Created Date`)<7, Year(iid.`Invoice Created Date`),Year(iid.`Invoice Created Date`)+1) as 'F.Y.',
	date_format(iid.`Invoice Created Date`, '%Y-%m') as 'Invoice Created Period',  
	wi.Revenue_Ownership__c as 'RevenueOwnership',  
    p.Business_Line__c AS 'BusinessLine',   
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',   
    ps.Name as 'Standard',
    'Audit' as 'Type',
    'Count' as 'SubType',
    if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2',
    r.Resource_Type__c as 'SubType 3',
    'n/a' as 'Billable',
    count(distinct wi.Id) as 'Value',   
    '#' as 'Unit',
    count(distinct wi.Id) as 'Amount',   
    '#' as 'Currency',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.NAme as 'Auditor'
from salesforce.work_item__c wi  
	inner join (select ili.Work_Item__c, ili.Invoice__c, min(i.CreatedDate) as 'Invoice Created Date' from salesforce.invoice_line_item__c ili inner join salesforce.invoice__c i on ili.Invoice__c = i.Id group by ili.Work_Item__c) iid on iid.Work_Item__c = wi.Id
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
where wi.IsDeleted = 0   
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   
    #and ps.ID='a36d0000000Chj3AAC'
    #and wi.Client_Ownership__c = 'EMEA - UK'
    #and date_format(iid.`Invoice Created Date`, '%Y-%m') in ('2016-07','2016-08','2016-09')
group by wi.ID,`F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`
union   
select    
	#if(month(wi.Work_Item_Date__c)<7, Year(wi.Work_Item_Date__c),Year(wi.Work_Item_Date__c)+1) as 'F.Y.',  
	if(month(iid.`Invoice Created Date`)<7, Year(iid.`Invoice Created Date`),Year(iid.`Invoice Created Date`)+1) as 'F.Y.',
	date_format(iid.`Invoice Created Date`, '%Y-%m') as 'Invoice Created Period',
	wi.Revenue_Ownership__c as 'RevenueOwnership',  
    p.Business_Line__c AS 'BusinessLine',   
    p.Pathway__c as 'Pathway',   
    p.Name as 'Program',   
    p.Program_Code__c as 'Program Code',   
    ps.Name as 'Standard',   
    'Audit' as 'Type',   
    'Days' as 'SubType',
    if(wi.Work_Item_Stage__c='Follow Up', 'Follow Up','Other') as 'SubType 2',
    r.Resource_Type__c as 'SubType 3',
    'n/a' as 'Billable',
    sum(wi.Required_Duration__c/8) as 'Value',   
    '#' as 'Unit',
    sum(wi.Required_Duration__c/8) as 'Amount',   
    '#' as 'Currency',
    group_concat(distinct wi.Name) as 'Work Items',
    count(distinct wi.Id) as '# Work Items',
    r.Name as 'Auditor'
from salesforce.work_item__c wi
	inner join (select ili.Work_Item__c, ili.Invoice__c, min(i.CreatedDate) as 'Invoice Created Date' from salesforce.invoice_line_item__c ili inner join salesforce.invoice__c i on ili.Invoice__c = i.Id group by ili.Work_Item__c) iid on iid.Work_Item__c = wi.Id
	inner join salesforce.resource__c r on r.Id = wi.Work_Item_Owner__c
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id   
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id   
	inner join salesforce.standard__c s on sp.Standard__c = s.Id   
	inner join salesforce.standard__c ps on s.Parent_Standard__c = ps.Id   
	inner join salesforce.program__c p on s.Program__c = p.Id   
where wi.IsDeleted = 0   
	and wi.Status__c not in ('Draft', 'Open', 'Scheduled', 'Scheduled - Offered', 'Cancelled', 'Budget', 'Initiate Service', 'Confirmed', 'In Progress', 'Service Change')   
    #and ps.ID='a36d0000000Chj3AAC'
    #and wi.Client_Ownership__c = 'EMEA - UK'
    #and date_format(iid.`Invoice Created Date`, '%Y-%m') in ('2016-07','2016-08','2016-09')
group by wi.Id, `F.Y.`, `Invoice Created Period`, `ClientOwnership`, `BusinessLine` , `Pathway` , `Standard`, `Type`, `SubType`, `SubType 2`,`SubType 3`, `Billable`; 
