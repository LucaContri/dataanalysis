# Accruals - Clients invoices not yet in Accounting System
#lock tables salesforce.work_item__c as wi WRITE,
# salesforce.resource__c as r WRITE,
# salesforce.site_certification_standard_program__c as scsp WRITE,
# salesforce.certification__c AS sc WRITE,
# analytics.audit_values as av WRITE,
# salesforce.invoice_line_item__c as ili WRITE,
# salesforce.invoice__c as i WRITE;
(select t.*, t.`Value`/ct.ConversionRate as 'Value (AUD)' from
	(select 
	 'Accrue' as 'Type',
	 wi.Client_Name_No_Hyperlink__c as 'Client', 
	 wi.Client_Site__c as 'Client Site', 
	 wi.Id as 'Work Item Id', 
	 wi.Name as 'Work Item', 
	 wi.Work_Item_Date__c as 'Work Item Date', 
	 date_format(wi.Work_Item_Date__c, '%Y') as 'Work Item Year',
	 date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Work Item Month',
	 wi.Status__c as 'Work Item Status', 
	 wi.Work_Item_Stage__c as 'Work Item Type', 
	 wi.Primary_Standard__c as 'Primary Standard', 
	 wi.Required_Duration__c as 'Required Duration',
	 sc.Revenue_Ownership__c as 'Site Cert Revenue Ownership',
	 r.Name as 'Work Item Owner',
	 r.Reporting_Business_Units__c as 'Reporting Business Unit',
	 group_concat(distinct i.External_Invoice_No__c) as 'External Invoice No',
	 group_concat(distinct i.Status__c) as 'Invoice Status',
	 ifnull(sum(if(i.Status__c not in ('Open','Closed','Cancelled'), ili.Total_Line_Amount__c,null)), av.`Calculated Value`) as 'Value',
	 ifnull(if(i.Status__c not in ('Open','Closed','Cancelled'), ili.CurrencyIsoCode,null), av.`Calculated Currency`) as 'Currency',
	 if(sum(if(i.Status__c not in ('Open','Closed','Cancelled'), ili.Total_Line_Amount__c,null)) is null, 'Pricebook', 'Pending Invoice Value') as 'Calculation'
	from salesforce.work_item__c wi
	 inner join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
	 inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	 inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	 left join analytics.audit_values av on av.`Work Item Id` = wi.Id
	 left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted = 0 and ili.Invoice_Status__c not in ('Cancelled')
	 left join salesforce.invoice__c i on ili.Invoice__c = i.Id and i.Status__c not in ('Cancelled')
	where (sc.Revenue_Ownership__c like 'EMEA%')
	 and wi.Status__c in ('Confirmed','In Progress','Submitted','Completed', 'Under Review', 'Under Review - Rejected', 'Support')
	 and (i.Id is null or i.Status__c not in ('Open','Closed'))
	 and wi.Work_Item_Stage__c not in ('Follow Up')
	 and date_format(wi.Work_Item_Date__c, '%Y-%m') < date_format(now(), '%Y-%m')
	 #and wi.Id in ('a3Id0000000ISlIEAW')
	group by wi.Id, `Currency`) t
left join salesforce.currencytype ct on t.`Currency` = ct.IsoCode)
union
# Accruals - Intercompany Charges invoices not yet in Accounting System
# Output: All Audits charged to clients wher Revenue Ownership != Reporting Business Unit and not intercompany invoice raised
(select t.*, t.`Value`/ct.ConversionRate as 'Value (AUD)' from
	(select t2.*
	from
		(select 
		'Inter-company' as 'Type',
		 wi.Client_Name_No_Hyperlink__c as 'Client', 
		 wi.Client_Site__c as 'Client Site', 
		 wi.Id as 'Work Item Id', 
		 wi.Name as 'Work Item', 
		 wi.Work_Item_Date__c as 'Work Item Date', 
		 date_format(wi.Work_Item_Date__c, '%Y') as 'Work Item Year',
		 date_format(wi.Work_Item_Date__c, '%Y-%m') as 'Work Item Month',
		 wi.Status__c as 'Work Item Status', 
		 wi.Work_Item_Stage__c as 'Work Item Type', 
		 wi.Primary_Standard__c as 'Primary Standard', 
		 wi.Required_Duration__c as 'Required Duration',
		 sc.Revenue_Ownership__c as 'Site Cert Revenue Ownership',
		 r.Name as 'Work Item Owner',
		 r.Reporting_Business_Units__c as 'Reporting Business Unit',
		 group_concat(distinct i.External_Invoice_No__c) as 'External Invoice No',
		 group_concat(distinct i.Status__c) as 'Invoice Status',
		 sum(ili.Total_Line_Amount__c) as 'Value',
		 ili.CurrencyIsoCode as 'Currency',
		 'Invoice Value' as 'Calculation'
		from salesforce.work_item__c wi
		 inner join salesforce.resource__c r on wi.Work_Item_Owner__c = r.Id
		 inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
		 inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
		 inner join salesforce.invoice_line_item__c ili on ili.Work_Item__c = wi.Id and ili.IsDeleted = 0
		 inner join salesforce.invoice__c i on ili.Invoice__c = i.Id and i.Status__c in ('Open', 'Closed')
		 inner join salesforce.account bc on i.Billing_Client__c = bc.Id and bc.Name not like 'SAI Global%'
		where 
		 r.Reporting_Business_Units__c like 'EMEA%'
		 and wi.IsDeleted = 0
		 and wi.Status__c in ('Submitted','Completed', 'Under Review', 'Under Review - Rejected', 'Support')
		 and sc.Revenue_Ownership__c <> r.Reporting_Business_Units__c
		 and wi.Work_Item_Stage__c not in ('Follow Up')
		group by wi.Id, `Currency`) t2
	left join salesforce.invoice_line_item__c ili2 on t2.`Work Item Id` = ili2.Work_Item__c and ili2.IsDeleted = 0 and ili2.Invoice_Status__c not in ('Cancelled')
	left join salesforce.invoice__c i2 on ili2.Invoice__c = i2.Id and i2.IsDeleted = 0 and i2.Status__c not in ('Cancelled')
	left join salesforce.account bc2 on i2.Billing_Client__c = bc2.Id and bc2.Name like 'SAI Global%'
	where bc2.Id is null
	group by t2.`Work Item Id`, t2.`Currency`) t
left join salesforce.currencytype ct on t.`Currency` = ct.IsoCode);
#unlock tables;