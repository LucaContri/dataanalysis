create index timesheet_line_item_index on timesheet_line_item__c(Work_Item__c);
create index timesheet_line_item_resource_index on timesheet_line_item__c(Resource_Name__c(100));
create index resource_name_index on resource__c(Name(100));
create index expense_line_item_resource_index on expense_line_item__c(Resource_Name__c(100));

set @from = '2014-01-01';
set @to = '2014-12-31';
set @ro = 'Australia';
set @contractor_avg_audit_rate = 870/8;
set @employee_avg_audit_rate = 870/8;

# Revenue by Standard Product
select
	c.Name as 'Client',
	i.Invoice_Processed_Date__c as 'Date',
	date_format(i.Invoice_Processed_Date__c, '%Y %m') as 'Period',
	concat(date_format(i.Invoice_Processed_Date__c, '%Y'),'-',quarter(i.Invoice_Processed_Date__c)) as 'Year-Quarter',
	s.Name as 'Standard',
    pr.Business_Line__c as 'BusinessLine',
	pr.Pathway__c as 'Pathway',
    ili.Name as 'Name',
    ili.Id as 'Id',
	'Invoice Line Item' as 'Type',
    pr.Category__c as 'Subtype',
	'Billable' as 'Billable',
    ili.Quantity__c as 'Quantity',
	'Number' as 'Unit',
    pbe.UnitPrice as 'Unit Amount',
    ili.Total_Line_Amount__c as 'Amount',
    pbe.CurrencyIsoCode as 'Currency',
    if (r.Id is null, 'n/a', r.Resource_Type__c) as 'Resource Type', 
    if (r.Id is null, 'n/a', r.Name) as 'Resource'
from salesforce.invoice__c i 
inner join salesforce.invoice_line_item__c ili on ili.invoice__c = i.Id
inner join salesforce.product2 pr on pr.Id = ili.Product__c
inner join salesforce.pricebookentry pbe on pbe.Product2Id = pr.Id
inner join salesforce.standard__c s on pr.Standard__c = s.Id
inner join account c on i.Billing_Client__c = c.Id
left join work_item__c wi on ili.Work_Item__c = wi.Id
left join resource__c r on wi.Work_Item_Owner__c = r.Id
where i.Invoice_Processed_Date__c >= @from 
and i.Invoice_Processed_Date__c <= @to
and i.IsDeleted=0 
and ili.IsDeleted=0
and i.Status__c IN ('Closed', 'Open')
and c.Client_Ownership__c = @ro
and pbe.Pricebook2Id='01s90000000568BAAQ'

union

# Detailed Expenses by Standard - TSLI
select 
c.Name as 'Client',
dts.Date__c as 'Date',
date_format(dts.Date__c, '%Y %m') as 'Period',
concat(date_format(dts.Date__c, '%Y'),'-',quarter(dts.Date__c)) as 'Year-Quarter',	
ps.Name as 'Standard',
p.Business_Line__c as 'Business Line',
p.Pathway__c as 'Pathway',
tsli.Name as 'Name',
tsli.Id as 'Id',
'Timesheet Line Item' as 'Type',
tsli.Category__c as 'Subtype', 
tsli.Billable__c as 'Billable', 
tsli.Actual_Hours__c as 'Quantity', 
'Hours' as 'Unit',
if (tsli.Category__c = 'Audit', if(r.Resource_Type__c='Employee', @employee_avg_audit_rate, @contractor_avg_audit_rate),0) as 'UnitPrice',
if (tsli.Category__c = 'Audit', if(r.Resource_Type__c='Employee', @employee_avg_audit_rate*tsli.Actual_Hours__c, @contractor_avg_audit_rate*tsli.Actual_Hours__c),0) as 'Amount',
'AUD' as 'Currency',
r.Resource_Type__c as 'Resource Type',
r.Name as 'Resource Name'
from salesforce.timesheet_line_item__c tsli
inner join work_item__c wi on tsli.Work_Item__c = wi.Id
inner join daily_timesheet__c dts on tsli.Daily_Timesheet__c = dts.Id
inner join resource__c r on r.Name = tsli.Resource_Name__c
inner join account c on c.Id = tsli.Client__c
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join program__c p on sp.Program__c = p.Id
inner join standard__c s on sp.Standard__c = s.Id
inner join standard__c ps on s.Parent_Standard__c = ps.Id
where dts.Date__c >= @from and dts.Date__c <= @to
and tsli.IsDeleted = 0
and dts.IsDeleted = 0
and tsli.Client__c is not null
and c.Client_Ownership__c = @ro

union 

# Detailed Expenses by Standard - ELI
select 
c.Name as 'Client',
dts.Date__c as 'Date',
date_format(dts.Date__c, '%Y %m') as 'Period',
concat(date_format(dts.Date__c, '%Y'),'-',quarter(dts.Date__c)) as 'Year-Quarter',	
ps.Name as 'Standard', 
p.Business_Line__c as 'Business Line',
p.Pathway__c as 'Pathway',
eli.Name as 'Name',
eli.Id as 'Id',
'Expense Line Item' as 'Type',
eli.Category__c  as 'Subtype',
eli.Billable__c as 'Billable', 
1 as 'Quantity',
'Number' as 'Unit',
eli.FTotal_Amount_Ex_Tax__c/cur.ConversionRate as 'Unit Amount',
eli.FTotal_Amount_Ex_Tax__c/cur.ConversionRate as 'Amount',
'AUD' as 'ConvertedUnit',
r.Resource_Type__c as 'ResourceType',
r.Name as 'Resource Name'
from expense_line_item__c eli 
inner join daily_timesheet__c dts on dts.Id = eli.Daily_Timesheet__c
inner join currencytype cur on cur.IsoCode = eli.CurrencyIsoCode
inner join resource__c r on r.Name = eli.Resource_Name__c
inner join account c on c.Id = eli.Client__c
inner join work_item__c wi on eli.Work_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join program__c p on sp.Program__c = p.Id
inner join standard__c s on sp.Standard__c = s.Id
inner join standard__c ps on s.Parent_Standard__c = ps.Id
where dts.Date__c >= @from 
and dts.Date__c <= @to
and eli.IsDeleted = 0
and dts.IsDeleted = 0
and c.Client_Ownership__c = @ro;

