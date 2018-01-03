select * from analytics.deregistration_acv;
truncate analytics.deregistration_acv;
call analytics.DeRegistrationACVUpdate();
create index deregistration_acv_client_index on deregistration_acv(`Client Id`);
create index deregistration_acv_currency_index on deregistration_acv(`Currency`);

create index certification_standard_program_history_index on certification_standard_program__history(ParentId);

drop PROCEDURE analytics.DeRegistrationACVUpdate;
# Stored Procedure calculating ACV site certs.
DELIMITER //
CREATE PROCEDURE analytics.DeRegistrationACVUpdate()
 BEGIN
declare start_time datetime;
declare lastUpdate datetime;
set start_time = utc_timestamp();
#set lastUpdate = (select ifnull(max(`De-Registered Date`), '1970-01-01') from analytics.deregistration_acv);
set lastUpdate = (select '1970-01-01');

# Tmp table to store value os audits linked to site cert de-registered
truncate analytics.audit_values;
insert into analytics.audit_values 
select t3.*,  ili.CurrencyIsoCode as 'Invoiced Currency', sum(if(ip.Category__c like 'Audit%', ili.Total_Line_Amount__c, null)) as 'Invoiced Amount - Audit', sum(if(ip.Category__c like 'Travel%', ili.Total_Line_Amount__c, null)) as 'Invoiced Amount - Travel', sum(ili.Total_Line_Amount__c) as 'Total Invoiced Amount' from
(select t2.`Work Item Id`, t2.`Pricebook currency` as 'Calculated Currency', sum(t2.`Quantity`*t2.`Effective Price`) as 'Calculated Value' from (
select t.* from (
select 
		wi.Id as 'Work Item Id',
        wi.Name as 'Work Item',
		wi.Required_Duration__c as 'RequiredDuration',
        ps.Name as 'StandardName',
		ps.Id as 'StandardId',
        if(ig.CurrencyIsoCode is null, sc.CurrencyIsoCode, ig.CurrencyIsoCode ) as 'CurrencyIsoCode',
        pbe.CurrencyIsoCode as 'Pricebook currency',
        p.Id as 'Product Id',	
		p.Name as 'Product',	
		p.UOM__c as 'Unit',
		if(p.UOM__c = 'DAY', 
			floor(wi.Required_Duration__c / 8), 
            if(p.UOM__c = 'HFD', 
				floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4), 
                (wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) )) as 'Quantity',	
		cep.New_End_Date__c,
		cep.New_Start_Date__c,
		if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=wi.Work_Item_Date__c and cep.New_End_Date__c>=wi.Work_Item_Date__c,cep.New_Start_Date__c,'1970-01-01') as 'CEP Order',
		pbe.UnitPrice as 'ListPrice',
		if(cp.Sales_Price_Start_Date__c<= wi.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= wi.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
		if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=wi.Work_Item_Date__c and cep.New_End_Date__c>=wi.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing',
		if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=wi.Work_Item_Date__c and cep.New_End_Date__c>=wi.Work_Item_Date__c, 
			if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, 
				if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, 
                cep.New_Price__c)), 
			if(cp.Sales_Price_Start_Date__c<= wi.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= wi.Work_Item_Date__c, 
				cp.FSales_Price__c, 
                pbe.UnitPrice)
		) as 'Effective Price'

		from salesforce.work_item__c wi 
			inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
			inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
			left join salesforce.invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
			inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
			inner join salesforce.standard__c s ON sp.Standard__c = s.Id
			inner join salesforce.standard__c ps ON ps.Id = s.Parent_Standard__c
			left join salesforce.product2 p ON wi.Work_Item_Stage__c = p.Product_Type__c and ps.Id = p.Standard__c and p.Category__c = 'Audit' and p.IsDeleted = 0
			left join salesforce.pricebookentry pbe ON pbe.Product2Id = p.Id and pbe.Pricebook2Id = sc.Pricebook2Id__c and pbe.IsDeleted = 0
			left join salesforce.certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = sc.Id and cp.IsDeleted = 0 and cp.Status__c = 'Active'
			left join salesforce.certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c and cep.IsDeleted = 0
		where wi.IsDeleted=0
			and scsp.IsDeleted = 0
		order by wi.Id , p.Id, `CEP Order` desc, cep.CreatedDate desc
        ) t
        group by t.`Work Item Id`, t.`Product Id`) t2
        group by t2.`Work Item Id`) t3
	left join salesforce.invoice_line_item__c ili on ili.Work_Item__c = t3.`Work Item Id` and ili.IsDeleted = 0 and ili.Invoice_Status__c not in ('Cancelled')
    left join salesforce.product2 ip on ili.Product__c = ip.Id 
    group by t3.`Work Item Id`;

truncate analytics.deregistration_acv;
insert ignore into analytics.deregistration_acv
(select t2.`Client Id`, t2.`Client`, t2.`Site Id`, t2.`Site`, t2.`Site Cert Std Id`, t2.`Site Cert Std`, t2.`Site Cert Std Status`, t2.`De-Registered Type`, t2.`De-Registered Reason`, t2.`De-Registered Date`,
t2.`Admin Ownership`, t2.`Revenue Ownership`, t2.`Business Line`, t2.`Primary Std`, 
if(t2.`Invoiced Audits last 12 months` is not null,
	t2.`Invoiced Audits last 12 months`,
	if(t2.`Closest WI` is not null,
		if(t2.`Closest WI Invoiced Amount` is not null,
			t2.`Closest WI Invoiced Amount`,
            if(t2.`Sample Service`,
				0,
                t2.`Closest WI Calculated Amount`
			)
        ),
        0 
	)
) as 'ACV',
ifnull(t2.`Invoiced Currency`,t2.`Calculated Value Currency`) as 'Currency',
if(t2.`Invoiced Audits last 12 months` is not null,
	'Invoiced Audits last 12 months',
	if(t2.`Closest WI` is not null,
		if(t2.`Closest WI Invoiced Amount` is not null,
			'Closest WI Invoiced Amount',
            if(t2.`Sample Service`,
				'N/A - Sample Service',
				'Closest WI Calculated Amount'
			)
        ),
        'N/A' 
	)
) as 'ACV Calculation',
if(t2.`Duration Audits last 12 months` is not null,
	t2.`Duration Audits last 12 months`,
	if(t2.`Closest WI Duration` is not null,
		t2.`Closest WI Duration`,
        0 
	)
) as 'ACV - Duration'

from
(select t.`Client Id`, t.`Client`, t.`Site Id`, t.`Site`, t.`Site Cert Std Id`, t.`Site Cert Std`, t.`Site Cert Std Status`, t.`De-Registered Type`, t.`De-Registered Reason`, t.`De-Registered Date`,
t.`Admin Ownership`, t.`Sample Service`, t.`Revenue Ownership`, t.`Primary Std`, t.`Business Line`,
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
group_concat(if(t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month),t.`Work_Item_Stage__c`,null)) as 'WI Types Last 12 months',
sum(if(t.`Work_Item_Date__c`< t.`De-Registered Date` and t.`Work_Item_Date__c`>date_add(ifnull(t.`De-Registered Date`,utc_timestamp()), interval -12 month) and t.`Work_Item_Stage__c` not in ('Follow Up') and t.`WI Status` not in ('Cancelled'), t.`Required_Duration__c`,null)) as 'Duration Audits last 12 months'
from 
	(select 
		client.Id as 'Client Id', 
        client.Name as 'Client', 
        site.Id as 'Site Id', 
        site.Name as 'Site', 
        scsp.Id as 'Site Cert Std Id', 
        scsp.Name as 'Site Cert Std', 
        scsp.Status__c as 'Site Cert Std Status', 
        #ifnull(scsp.De_registered_Type__c, 'To Be Deregistered at future date') as 'De-Registered Type',
			ifnull(scsp.De_registered_Type__c, csp.De_registered_Type__c) as 'De-Registered Type',
        #scsp.Site_Certification_Status_Reason__c as 'De-Registered Reason',
			ifnull(scsp.Site_Certification_Status_Reason__c, csp.Certification_Status_Reason__c) as 'De-Registered Reason',
		#if(scsp.De_register_Effective_Date__c is null, scsp.Withdrawn_Date__c, scsp.De_register_Effective_Date__c) as 'De-Registered Date', 
			least(ifnull(scsp.Withdrawn_Date__c, '9999-12-31'), ifnull(csph.createdDate, '9999-12-31')) as 'De-Registered Date',
            if(csph.createdDate is null, 'Actual De-Registration', if(scsp.Withdrawn_Date__c is null, 'Future De-Registration', if(scsp.Withdrawn_Date__c<csph.createdDate, 'Actual De-Registration', 'Future De-Registration'))) as 'De-Registration Source',
        scsp.Administration_Ownership__c as 'Admin Ownership', 
        c.Sample_Service__c as 'Sample Service', 
        sc.Revenue_Ownership__c as 'Revenue Ownership',
        sp.Program_Business_Line__c as 'Business Line',
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
		inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
        left join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id and csph.Field = 'De_register_Effective_Date__c' and csph.IsDeleted = 0
	inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
	inner join salesforce.account site on sc.Primary_client__c = site.Id
	inner join salesforce.account client on site.ParentId = client.Id
	left join salesforce.work_item__c wi on scsp.Id = wi.Site_Certification_Standard__c and wi.IsDeleted = 0 and wi.Work_Item_Stage__c not in ('Follow Up') and wi.Status__c not in ('Inititate service', 'Draft')
	left join analytics.audit_values calc on calc.`Work Item Id` = wi.Id
    #where 
	#scsp.Id in 
		#(select Id from salesforce.site_certification_standard_program__c 
		#	where IsDeleted = 0 
		#	and ((Status__c in ('De-registered', 'Concluded') 
		#			and De_registered_Type__c in ('Client Initiated','SAI Initiated')
		#			and scsp.Withdrawn_Date__c >= lastUpdate)
		#		or scsp.De_register_Effective_Date__c>= lastUpdate)
		#)
        #(select scsp.Id
		#	from salesforce.certification_standard_program__c csp 
		#	inner join salesforce.site_certification_standard_program__c scsp on scsp.Certification_Standard__c = csp.Id
		#	left join salesforce.certification_standard_program__history csph on csph.ParentId = csp.Id and csph.Field = 'De_register_Effective_Date__c' and csph.IsDeleted = 0
		#where 
		#	csp.IsDeleted = 0 
		#	and scsp.IsDeleted = 0
		#	and scsp.Status__c not in ('Transferred')
		#	and ((scsp.Status__c in ('De-registered', 'Concluded') 
		#		and scsp.De_registered_Type__c in ('Client Initiated','SAI Initiated')
		#		and scsp.Withdrawn_Date__c >= lastUpdate)
		#	or (csp.De_register_Effective_Date__c is not null
		#		and csph.CreatedDate >= lastUpdate
		#		and csp.De_registered_Type__c in ('Client Initiated','SAI Initiated')
		#	))
		#)
    group by scsp.Id, wi.Id
	order by client.Id, site.Id, scsp.Id, abs(timestampdiff(day,ifnull(scsp.Withdrawn_Date__c,utc_timestamp()),wi.Work_Item_Date__c)) #field(wi.Status__c,'Completed', 'Complete', 'Support', 'Under Review', 'Under Review - Rejected', 'Submitted', 'In Progress', 'Scheduled - Offered','Scheduled', 'Open','Service Change', 'Cancelled', 'Incomplete', 'Allocated', 'Application Unpaid'), 
	) t
group by t.`Site Cert Std Id`) t2);

insert into analytics.sp_log VALUES(null,'DeRegistrationACVUpdate',utc_timestamp(), timestampdiff(MICROSECOND, start_time, utc_timestamp()));

 END //
DELIMITER ;
use analytics;
drop event DeRegistrationACVUpdateEvent;
CREATE EVENT DeRegistrationACVUpdateEvent
    ON SCHEDULE EVERY 6 hour DO 
		call DeRegistrationACVUpdate();

show events;
select *, exec_microseconds/1000000 from analytics.sp_log where sp_name='DeRegistrationACVUpdate' order by exec_time desc limit 10;

select count(*) from analytics.deregistration_acv;

(select analytics.getRegionFromReportingBusinessUnit(d.`Revenue Ownership`) as 'Region',
analytics.getCountryFromRevenueOwnership(d.`Revenue Ownership`) as 'Country',
csp.NAme, csp.Status__c, csp.De_register_Effective_Date__c, csp.Withdrawn_Date__c, scsp.Status__c, scsp.De_register_Effective_Date__c, scsp.Withdrawn_Date__c,  
d.*
from analytics.deregistration_acv d
left join salesforce.site_certification_standard_program__c scsp on d.`Site Cert Std Id` = scsp.Id
left join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
where `De-Registered Date` >= '2016-01-01'
and analytics.getCountryFromRevenueOwnership(d.`Revenue Ownership`) = 'Australia');

select Id, scsp.De_register_Effective_Date__c  from salesforce.certification_standard_program__c scsp where scsp.De_register_Effective_Date__c is not null;

drop table sla_sales_leadoppfollowup_backlog;
drop table sla_sales_proposalcr_backlog;
drop table sla_sales_qualifylead_backlog;
drop table sla_sales_risk_assessment_backlog;

drop event SlaUpdateEventSalesLeadOppFollowUpBacklog;
drop event SlaUpdateEventSalesProposalAndCRBacklog;
drop event SlaUpdateEventSalesProposalAndCRCompleted;
drop event SlaUpdateEventSalesQualifyLeadBacklog;
drop event SlaUpdateEventSalesRiskAssessmentBacklog;

drop view salesforce.sales_pipeline_certification_australia;
drop view salesforce.sales_pipeline_certification_australia_sub;
drop view salesforce.sales_pipeline_metrics;