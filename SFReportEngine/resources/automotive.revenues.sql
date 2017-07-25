(select 
	'Compass' as 'Source',
	t.*,
    p.Business_Line__c as 'Business Line',
    p.Pathway__c as 'Pathway',
    p.Name as 'Program',
    p.Program_Code__c as 'Program Code',
    s.Name as 'Standard',
    pr.Category__c as 'Category',
    sum(ili.Total_Line_Amount__c/ct.ConversionRate) as 'Total Invoiced (AUD)',
    sum(if(pr.UOM__c = 'DAY', ili.Quantity__c*8 , if(pr.UOM__c = 'HFD', ili.Quantity__c*4 , if(pr.UOM__c = 'HR', ili.Quantity__c ,0))))/8 as 'Days',
    count(distinct ili.Work_Item__c) as '# Audits'
from
	(select 
        a.Client_Ownership__c as 'Client Ownership', 
		a.Name as 'Billing Client',
		a.Id as 'Billing Client Id',
		a.Client_Number__c as 'Billing Client Number',
		year(i.CreatedDate) as 'Invoice Created Year',
		year(i.CreatedDate) + if(month(i.CreatedDate)<7,0,1) as 'Invoice Created FY',
		group_concat(distinct p.Business_Line__c order by p.Business_Line__c) as 'Business Lines',
		group_concat(distinct p.Pathway__c order by p.Pathway__c) as 'Pathways',
		group_concat(distinct p.Name order by p.Name) as 'Programs',
		group_concat(distinct p.Program_Code__c order by p.Program_Code__c) as 'Program Codes'
	from salesforce.invoice__c i
		inner join salesforce.invoice_line_item__c ili on ili.Invoice__c = i.Id
		inner join salesforce.product2 pr on ili.Product__c = pr.Id
		inner join salesforce.standard__c s on pr.Standard__c = s.Id
		inner join salesforce.program__c p on s.Program__c = p.Id
		inner join salesforce.account a on i.Billing_Client__c = a.Id
	where 
		i.IsDeleted = 0
        and ili.IsDeleted = 0
		and i.Status__c not in ('Pending', 'Cancelled')
	group by `Client Ownership`, `Billing Client Id`, `Invoice Created Year`, `Invoice Created FY`) t 
	left join salesforce.invoice__c i on 
		t.`Billing Client Id` = i.Billing_Client__c 
        and year(i.CreatedDate) = t.`Invoice Created Year`
        and year(i.CreatedDate) + if(month(i.CreatedDate)<7,0,1) = t.`Invoice Created FY`
        and i.IsDeleted = 0 
        and i.Status__c not in ('Pending','Cancelled')
	left join salesforce.invoice_line_item__c ili on ili.Invoice__c = i.Id and ili.IsDeleted = 0
    left join salesforce.currencytype ct on ili.CurrencyIsoCode = ct.IsoCode
    left join salesforce.product2 pr on ili.Product__c = pr.Id
    left join salesforce.standard__c s on pr.Standard__c = s.Id
    left join salesforce.program__c p on s.Program__c = p.Id
where t.`Programs` like '%Automotive%'
group by t.`Billing Client Id`, t.`Invoice Created Year`, t.`Invoice Created FY`, p.Business_Line__c, p.Pathway__c, p.Name, p.Program_Code__c, s.Name, pr.Category__c);

# PostgreSQL query for SICE data
select 
	cast('SICE' as varchar) as "Source",
	t.*,
	cast('' as  char) as "Business Lines",
	cast('' as  char)as "Pathways",
	cast('' as  char) as "Programs",
	CASE WHEN n.codice like '%16949%' THEN cast('AUTO' as varchar) ELSE cast(n.codice_sai as varchar) END as "Program Code",
    n.codice as "Standard",
	cast('Audit' as varchar) as "Category",
	sum(camp.prezzo/0.687200) as  "Total Invoiced (AUD)",
    sum(camp.giornate) as "Days",
    count(distinct p.pk_pratica) as "# Audits"
from (
	select 
		cast('EMEA-Italy' as  varchar) as  "Client Ownership",
		a.ragsoc as "Billing Client",
		a.pk_azienda as "Billing Client Id",
		a.pk_azienda as "Billing Client No.",
		cast(to_char(p.data,'YYYY') as int) as "Audit Year",
		cast(to_char(p.data,'YYYY') as int) + (CASE WHEN cast(to_char(p.data, 'MM') as int)<7 THEN 0 ELSE 1 END) as "Audit FY",
		cast('' as  char) as "Business Lines",
		cast('' as  char)as "Pathways",
		cast('' as  char) as "Programs",
		array_agg(distinct CASE WHEN n.codice like '%16949%' THEN cast('AUTO' as varchar) ELSE cast(n.codice_sai as varchar) END) as "Program Codes"
	from public.tbl_pratiche as p
		inner join public.tbl_certificati as c on p.fk_certificato = c.pk_certificato
		inner join public.tbl_norme n on c.fk_norma = n.pk_norma
		inner join public.tbl_aziende a on c.fk_azienda = a.pk_azienda 
	group by "Billing Client", "Billing Client Id", "Audit Year", "Audit FY") as  t
	inner join public.tbl_certificati as c on t."Billing Client Id" = c.fk_azienda
	inner join public.tbl_norme n on c.fk_norma = n.pk_norma
	inner join public.tbl_pratiche as p on 
		p.fk_certificato = c.pk_certificato and 
		t."Audit Year" = cast(to_char(p.data,'YYYY') as int) and 
		t."Audit FY" = cast(to_char(p.data,'YYYY') as int) + (CASE WHEN cast(to_char(p.data, 'MM') as int)<7 THEN 0 ELSE 1 END)
	inner join public.tbl_stabilimenti_certificati sc on sc.fk_certificato = c.pk_certificato
	inner join public.tbl_stabilimenti s on sc.fk_stabilimento = s.pk_stabilimento
	inner join public.tbl_campionamenti as camp on camp.fk_stabilimento = s.pk_stabilimento and camp.fk_pratica = p.pk_pratica
where t."Program Codes" @> array[cast('AUTO' as varchar)]
group by t."Client Ownership", t."Billing Client", t."Billing Client Id", t."Billing Client No.", t."Business Lines", t."Pathways", t."Programs", t."Program Codes", t."Audit Year", t."Audit FY", "Program Code", "Standard"