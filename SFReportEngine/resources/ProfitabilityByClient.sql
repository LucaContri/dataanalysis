# Step 1 - Revenue by Client
select 
    p.Name as 'Parent',
    a.Name as 'Client',
	a.Id as 'ClientId',
	a.Client_Segmentation__c as 'ClientSegmentation',
	a.client_Number__c as 'ClientNumber',
	i.Id as 'InvoiceId',
	i.Total_Amount__c as 'InvoiceAmount',
	i.CurrencyIsoCode as 'Currency',
	ili.Id as 'LineId',
	ili.Total_Line_Amount__c as 'LineAmount',
	ili.Product__c as 'ProductId',
	pr.Name as 'ProductName',
	pr.Family as 'ProductFamily',
	pr.Category__c as 'ProductCategory'
from
	salesforce.invoice__c i 
		inner join 
	salesforce.invoice_line_item__c ili on ili.invoice__c = i.Id
		inner join    
	salesforce.account a on a.Id = i.Billing_Client__c 
		inner join
	salesforce.product2 pr on pr.Id = ili.Product__c
        left join
    salesforce.account p ON a.ParentId = p.Id
        left join
    salesforce.account gp ON gp.Id = p.ParentId

where i.Closed_Date__c >= '2014-01-01' and i.Closed_Date__c <= '2014-12-31'
and a.Client_Ownership__c = 'Australia'
and i.IsDeleted=0 
and i.CurrencyIsoCode = 'AUD'
and i.Status__c IN ('Closed', 'Open')
and ili.IsDeleted=0
limit 100000;

# Step 2 - Detailed Expenses by Client

select tsli.client__c as 'ClientId', dts.Date__c as 'Date', tsli.Category__c as 'Category', tsli.Billable__c as 'Billable', r.Resource_Type__c as 'ResourceType', tsli.Work_Item_Type__c as 'WorkItemType', tsli.Actual_Hours__c as 'Amount', 'Hours' as 'Unit', tsli.Actual_Hours__c as 'ConvertedActualAmount', 'Hours' as 'ConvertedUnit'
from salesforce.timesheet_line_item__c tsli
inner join salesforce.daily_timesheet__c dts on dts.Id = tsli.Daily_Timesheet__c
left join resource__c r on r.Name = tsli.Resource_Name__c
where dts.Date__c >= '2013-01-01' and dts.Date__c <= '2013-12-31'
and tsli.IsDeleted = 0
and dts.IsDeleted = 0
and tsli.Client__c is not null
LIMIT 100000;

select eli.client__c as 'ClientId', dts.Date__C as 'Date', eli.Category__c as 'Category', eli.Billable__c as 'Billable', r.Resource_Type__c as 'ResourceType', eli.Work_Item_Type__c as 'WorkItemType', eli.FTotal_Amount_Ex_Tax__c as 'Amount', eli.CurrencyIsoCode as 'Unit', eli.FTotal_Amount_Ex_Tax__c/cur.ConversionRate as 'ConvertedActualAmount', 'AUD' as 'ConvertedUnit'
from expense_line_item__c eli 
inner join salesforce.daily_timesheet__c dts on dts.Id = eli.Daily_Timesheet__c
left join salesforce.currencytype cur on cur.IsoCode = eli.CurrencyIsoCode
left join resource__c r on r.Name = eli.Resource_Name__c
where dts.Date__c >= '2013-12-01' and dts.Date__c <= '2013-12-31'
and eli.IsDeleted = 0
and dts.IsDeleted = 0
and eli.client__c is not null
LIMIT 100000;