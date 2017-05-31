use salesforce;		

create index work_item_history_index on work_item__history (ParentId);
create index pricebookentry_index on pricebookentry (Product2Id);
create index certification_pricing_index on certification_pricing__c (Product__c,Certification__c);
create index certification_effective_price_index on certification_effective_price__c (Certification_Pricing__c);
create index standard_name_index on standard__c (Name (100));

# Views
# Interim lost_business_audits based on de-registration date and previous year work items
create or replace view lost_business_audits as 
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		wi.Client_Id__c, 
		if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Service_Change_Reason__c,
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wi.Status__c, 
		date_format(scsp.Withdrawn_Date__c, '%Y %m') as 'Cancelled Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		wp.Site_Certification__c,
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		#inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		#and wi.Status__c not in ('Cancelled')
		#and wih.Field = 'Status__c'
		#and wih.NewValue = 'Cancelled'
        and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(scsp.Withdrawn_Date__c,'%Y %m')
		and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(scsp.Withdrawn_Date__c, interval -12 month),'%Y %m')
		and date_format(scsp.Withdrawn_Date__c,'%Y %m') >= '2013 07'
		#and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		and scsp.De_registered_Type__c in ('Client Initiated','SAI Initiated') 
        and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue')
	group by wi.Id;

select date_format(scsp.Withdrawn_Date__c,'%Y %m') as 'period',count(scsp.Id)#, scsp.Name, scsp.Withdrawn_Date__c, wi.Id, wi.Name, wi.Status__c, wi.Work_Item_Date__c 
from 
site_certification_standard_program__c scsp
inner join work_item__c wi on wi.Site_Certification_Standard__c = scsp.Id
inner join standard__c s ON s.Name = wi.Primary_Standard__c
inner join work_package__c wp ON wp.Id = wi.Work_Package__c
inner join standard__c sp ON sp.Id = s.Parent_Standard__c
where
scsp.IsDeleted=0
and wi.IsDeleted=0
and scsp.De_registered_Type__c in ('Client Initiated','SAI Initiated') 
and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue')
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
and date_format(scsp.Withdrawn_Date__c,'%Y %m') in ( '2014 07','2014 08', '2014 09')
and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(scsp.Withdrawn_Date__c,'%Y %m')
and date_format(wi.Work_Item_Date__c, '%Y %m') >= date_format(date_add(scsp.Withdrawn_Date__c, interval -12 month),'%Y %m')
#and wi.Status__c not in ('Cancelled')
group by `period`;#wi.Id;

select scsp.Id, scsp.Name, scsp.Withdrawn_Date__c,De_registered_Type__c, wi.Id, wi.Name, wi.Status__c, wi.Work_Item_Date__c
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') in ( '2013 07','2013 08', '2013 09')
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		#and 	#(
				#	(De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue')) # deregistrations
				#	or 
				#	(De_registered_Type__c is null and Site_Certification_Status_Reason__c is null and Cancellation_Reason__c = 'Other' and Sample_Site__c='No') # others - no sample sites 
				#	or
				#	(De_registered_Type__c is null and Site_Certification_Status_Reason__c is null and (Cancellation_Reason__c not in ('Other','Lifecycle Frequency Decrease', 'Lifecycle Line Deleted', 'Site Relocation') or Cancellation_Reason__c is null) ) # others
				#)
                #(
				#	if(wi.Service_Change_Reason__c = ('De-Registered') and De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue'),
				#		1,
				#		Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status', 'SAI did not win re-tender','New client not wishing to go ahead with S1 and S2','Financial difficulties', 'Client complaint of service and is leaving SAI')
				#	)
				#)
				
	group by wi.Id limit 100000;

select scsp.Id, scsp.Name, scsp.Withdrawn_Date__c, wi.Id, wi.Name, wi.Status__c, wi.Work_Item_Date__c
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') = '2014 08'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
				
	group by wi.Id;
    
create or replace view lost_business_audits as 
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		wi.Client_Id__c, 
		if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		wi.Revenue_Ownership__c,
        scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Service_Change_Reason__c,
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wih.Field, 
		date_format(max(wih.CreatedDate), '%Y %m') as 'Cancelled Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		scsp.Site_Certification__c,
        sc.Pricebook2Id__c,
        if(ig.CurrencyIsoCode is null, sc.CurrencyIsoCode, ig.CurrencyIsoCode ) as 'CurrencyIsoCode',
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join certification__c sc on scsp.Site_Certification__c = sc.Id
        left join invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		#inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') >= '2013 07'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		and if(date_format(date_add(wih.CreatedDate, interval 11 hour),'%Y %m') <= '2014 09',
				(
					(De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue')) # deregistrations
					or 
					(De_registered_Type__c is null and Site_Certification_Status_Reason__c is null and Cancellation_Reason__c = 'Other' and Sample_Site__c='No') # others - no sample sites 
					or
					(De_registered_Type__c is null and Site_Certification_Status_Reason__c is null and (Cancellation_Reason__c not in ('Other','Lifecycle Frequency Decrease', 'Lifecycle Line Deleted', 'Site Relocation') or Cancellation_Reason__c is null) ) # others
				)
				,
				 #New Logic here !!!
				(
					if(wi.Service_Change_Reason__c = ('De-Registered') and De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue'),
						1,
						Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status', 'SAI did not win re-tender','New client not wishing to go ahead with S1 and S2','Financial difficulties', 'Client complaint of service and is leaving SAI')
					)
				)
			)
		#and (if	(wi.Service_Change_Reason__c = 'De-Registered',
		#			if (De_registered_Type__c in ('Client Initiated','SAI Initiated') and Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue'),true,false),
		#			if 	(wi.Cancellation_Reason__c = 'Other',
		#					if (wi.Sample_Site__c='No', true, false),
		#					if (wi.Cancellation_Reason__c not in ('Lifecycle Frequency Decrease', 'Lifecycle Line Deleted', 'Site Relocation') or Cancellation_Reason__c is null, true, false)
		#				)
		#		)
		#	)
	group by wi.Id;

create or replace view lost_business_audits_v2 as 
select 
		wi.Id as 'WorkItemId', 
        wi.Name as 'WorkItemName',
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		client.Id as `Client_Id__c`, 
        client.Name as 'Client Name',
        clientSite.Name as 'Client Site',
		if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		wi.Revenue_Ownership__c,
        scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Service_Change_Reason__c,
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wih.Field, 
		date_format(max(wih.CreatedDate), '%Y %m') as 'Cancelled Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		scsp.Site_Certification__c,
        sc.Pricebook2Id__c,
        if(ig.CurrencyIsoCode is null, sc.CurrencyIsoCode, ig.CurrencyIsoCode ) as 'CurrencyIsoCode',
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId',
        wi.Open_Sub_Status__c
		from work_item__c wi 
        inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join certification__c sc on scsp.Site_Certification__c = sc.Id
        inner join account clientSite on sc.Primary_client__c = clientSite.Id
        inner join account client on clientSite.ParentId = client.Id
        left join invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Cancelled'
		and wih.Field = 'Status__c'
		and wih.NewValue = 'Cancelled'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') >= '2013 07'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
		and if (wi.Service_Change_Reason__c= 'De-Registered',
			if (scsp.De_registered_Type__c in ('Maintenance'),
				0, # Maintenance
                1 # Churn
            ),
            if(wi.Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status', 'SAI did not win re-tender','New client not wishing to go ahead with S1 and S2','Financial difficulties', 'Client complaint of service and is leaving SAI'),
				1, # Churn
                if(wi.Cancellation_Reason__c in ('Lifecycle Frequency Decrease'),
					0, # Shrinkage
                    if (wi.Revenue_Ownership__c like '%Food%' and wi.Work_Item_Stage__c = 'Follow Up',
						0, # Maintenance
                        if (wi.Sample_Site__c = 'Yes',
							0, # Maintenance
                            if (wi.Cancellation_Reason__c in ('Site Relocation'),
								0, #Maintenance
                                1 # Churn - Catch All 
                            )
                        )
					)
                )
			)
		)
	group by wi.Id;

create or replace view pending_lost_business_audits_v2 as 
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Package_Type__c, 
		wi.Work_Item_Stage__c, 
		client.Id as `Client_Id__c`, 
        client.Name as 'Client Name',
        clientSite.Name as 'Client Site',
		if (wi.Revenue_Ownership__c like '%Food%', 'Food',if(wi.Revenue_Ownership__c like '%Product%','PS','MS')) as 'Stream',
		wi.Revenue_Ownership__c,
        scsp.De_registered_Type__c, 
		scsp.Site_Certification_Status_Reason__c, 
		wi.Cancellation_Reason__c, 
		wi.Service_Change_Reason__c,
		wi.Work_Item_Date__c,
		date_format(wi.LastModifiedDate, '%Y %m') as 'Last Modified Period', 
		wih.Field, 
		date_format(max(wih.CreatedDate), '%Y %m') as 'Cancelled Period',  
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wi.Sample_Site__c,
		scsp.Site_Certification__c,
        sc.Pricebook2Id__c,
        if(ig.CurrencyIsoCode is null, sc.CurrencyIsoCode, ig.CurrencyIsoCode ) as 'CurrencyIsoCode',
		wi.Required_Duration__c as 'RequiredDuration',
		floor(wi.Required_Duration__c / 8) as 'Days',
		floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4) as 'HalfDays',
		(wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8) - 4 * floor((wi.Required_Duration__c - 8 * floor(wi.Required_Duration__c / 8)) / 4)) as 'Hours',
		sp.Name as 'StandardName',
		sp.Id as 'StandardId' 
		from work_item__c wi 
        inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
        inner join certification__c sc on scsp.Site_Certification__c = sc.Id
        inner join account clientSite on sc.Primary_client__c = clientSite.Id
        inner join account client on clientSite.ParentId = client.Id
        left join invoice_group__c ig on sc.Invoice_Group_Work_Item__c = ig.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wi.IsDeleted=0
		and scsp.IsDeleted=0
		and wi.Status__c='Open'
        and wi.Open_Sub_Status__c like 'Pending%'
		and wih.Field = 'Open_Sub_Status__c'
		and wih.NewValue like 'Pending%'
		and date_format(wi.Work_Item_Date__c, '%Y %m') <= date_format(date_add(wih.CreatedDate, interval 12 month),'%Y %m')
		and date_format(wih.CreatedDate,'%Y %m') >= '2013 07'
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
	group by wi.Id;
    
# Verify Cancellation with Other by Date
select wi.Id, wi.Client_Name_No_Hyperlink__c, wi.Name, u.Name as 'Cancelled by', wi.Work_Item_Stage__c, wi.Sample_Site__c, wi.Service_Change_Reason__c ,wi.Cancellation_Reason__c, wi.Comments__c 
from work_item__c wi
inner join work_item__history wih on wih.ParentId = wi.Id
inner join user u on u.Id = wih.CreatedById
where
wi.Status__c = 'Cancelled'
and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
and wih.Field = 'Status__c'
and wih.NewValue = 'Cancelled'
and date_format(date_add(wih.CreatedDate, interval 11 hour), '%Y-%m-%d') = '2014-10-02';
#and wi.Cancellation_Reason__c='Other';
#and wi.Cancellation_Reason__c='Lifecycle Line Deleted';


create or replace view lost_business_revenue_sub as 
select t.*, 	
	p.Id as 'ProductId',	
	p.Name as 'ProductName',	
	p.UOM__c as 'Unit',
	if(p.UOM__c = 'DAY', t.Days, if(p.UOM__c = 'HFD', t.HalfDays, t.Hours)) as 'Quantity',	
	cep.New_End_Date__c,
	cep.New_Start_Date__c,
    if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c,cep.New_Start_Date__c,'1970-01-01') as 'CEP Order',
	pbe.UnitPrice as 'ListPrice',
	if(cp.Sales_Price_Start_Date__c is not null and cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
	if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'	
	from lost_business_audits_v2 t 
	inner join product2 p ON t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
	inner join pricebookentry pbe ON pbe.Product2Id = p.Id 
	left join certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = t.Site_Certification__c	
	left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
	Where	
	p.Category__c = 'Audit'
	and p.IsDeleted=0
	and pbe.IsDeleted=0
	and (cep.IsDeleted=0 or cep.IsDeleted is null)
	and (cp.IsDeleted=0 or cp.IsDeleted is null)
    and pbe.Pricebook2Id = '01s90000000568BAAQ' 
    and pbe.CurrencyIsoCode = 'AUD'
	and (cp.Status__c = 'Active' or cp.Status__c is null)
	and if(p.UOM__c = 'DAY', t.Days, if(p.UOM__c = 'HFD', t.HalfDays, t.Hours)) > 0	
	order by `WorkItemId` , `ProductId`, `CEP Order` desc, cep.CreatedDate desc;

create or replace view lost_business_revenue as 
select t3.*, if(t3.`Site Cert Effective Pricing` is not null, t3.`Site Cert Effective Pricing`, if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing`, t3.`ListPrice`)) as 'EffectivePrice' 
from lost_business_revenue_sub t3
group by t3.`WorkItemId`, t3.`ProductId`;

select * from lost_business_revenue_sub;

create or replace view deregistered_site_cert_standard as
select 
        if(pg.Business_Line__c like '%Food%', 'Food', if(pg.Business_Line__c = 'Product Services','PS','MS')) as 'Stream',
            scsp.Site_Certification__c,
            p.Name,
            p.Id as 'ProductId',
            min(date_add(scsph.CreatedDate,interval 11 hour)) as 'DeRegistered Date',
            ig.Recurring_Fee_Frequency__c,
            pbe.UnitPrice as 'ListPrice'
    from
        site_certification_standard_program__c scsp
    inner join certification__c site ON scsp.Site_Certification__c = site.Id
    inner join product2 p ON site.Registration_Fee_Product__c = p.Id
    left join standard__c s ON p.Standard__c = s.Id
    left join program__c pg ON s.Program__c = pg.Id
    inner join Invoice_Group__c ig ON site.Invoice_Group_Registration__c = ig.Id
    inner join site_certification_standard_program__history scsph ON scsph.ParentId = scsp.Id
    inner join pricebookentry pbe ON pbe.Product2Id = p.Id
    where
        scsp.De_registered_Type__c in ('Client Initiated' , 'SAI Initiated')
            and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data' , 'Customer consolidation of licences', 'Other – no loss of revenue')
            and scsp.Status__c = 'De-registered'
            and scsph.Field = 'Status__c'
            and scsph.NewValue = 'De-registered'
            and scsp.IsDeleted = 0
            and scsph.IsDeleted = 0
            and (site.Revenue_Ownership__c LIKE 'AUS-Food%' OR site.Revenue_Ownership__c LIKE 'AUS-Global%' OR site.Revenue_Ownership__c LIKE 'AUS-Managed%' OR site.Revenue_Ownership__c LIKE 'AUS-Direct%')
            and pbe.Pricebook2Id = '01s90000000568BAAQ'
            and pbe.CurrencyIsoCode = 'AUD'
            and pbe.isDeleted = 0
    group by scsp.Site_certification__c;

create or replace view deregistered_site_cert_standard_with_price as 
select 
        t . *,
            if(cp.IsDeleted = 0
                and cp.Sales_Price_Start_Date__c <= t.`DeRegistered Date`
                and cp.Sales_Price_End_Date__c >= t.`DeRegistered Date`, cp.FSales_Price__c, null) as 'Site Cert Pricing',
            if(cep.IsDeleted = 0
                and cep.New_Start_Date__c is not null
                and cep.New_Start_Date__c <= t.`DeRegistered Date`
                and cep.New_End_Date__c >= t.`DeRegistered Date`, if(cep.Adjustment_Type__c = 'Percentage', t.`ListPrice` * (100 + cep.Adjustment__c) / 100, if(cep.Adjustment_Type__c = 'Amount', t.`ListPrice` + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'
    from deregistered_site_cert_standard t
    left join certification_pricing__c cp ON cp.Product__c = t.`ProductId`
        and cp.Certification__c = t.Site_Certification__c
    left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c
    order by t.Site_certification__c , cep.New_Start_Date__c desc , cep.CreatedDate desc;

create or replace view deregistered_site_cert_standard_with_effective_price as 
select 
        t2 . *,
            if(t2.`Site Cert Effective Pricing` is not null, t2.`Site Cert Effective Pricing`, if(t2.`Site Cert Pricing` is not null, t2.`Site Cert Pricing`, t2.`ListPrice`)) * if(t2.`Recurring_Fee_Frequency__c` = 'Monthly', 12, if(t2.`Recurring_Fee_Frequency__c` = '3 Months', 4, if(t2.`Recurring_Fee_Frequency__c` = '6 Month', 2, 1))) as 'EffectivePrice'
    from
        deregistered_site_cert_standard_with_price t2
    group by t2.Site_certification__c;

select 
	dscs.`Stream` as 'Stream',
    'Revenue Lost (Fees)' as 'Type',
    date_format(dscs.`DeRegistered Date`, '%Y %m') as 'Period',
    sum(dscs.`EffectivePrice`) as 'Amount'
from deregistered_site_cert_standard_with_effective_price dscs
where date_format(dscs.`DeRegistered Date`, '%Y %m') >= '2014 07' 
and date_format(dscs.`DeRegistered Date`, '%Y %m') <= '2015 06' 
group by `Stream` , `Period`;

create or replace view shrink_business_audits as 
select 
		wi.Id as 'WorkItemId', 
		wi.Work_Item_Stage__c, 
		if (wi.Revenue_Ownership__c like '%Food%', 'Food','MS') as 'Stream',
		wi.Work_Item_Date__c,
		max(wih.CreatedDate) as 'Shrink Date',
		date_format(wi.Work_Item_Date__c, '%Y %m') as 'Scheduled Period', 
		wp.Site_Certification__c,
		(wih.OldValue - wih.NewValue) / 8 as 'Shrink Days',
		sp.Id as 'StandardId' 
		from work_item__c wi 
		inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
		inner join work_item__history wih on wih.ParentId = wi.Id
		inner join standard__c s ON s.Name = wi.Primary_Standard__c
		inner join work_package__c wp ON wp.Id = wi.Work_Package__c
		inner join standard__c sp ON sp.Id = s.Parent_Standard__c
		where wih.Field='Required_Duration__c'
		#and wih.CreatedDate >= '2013-07-01' # Include only changes done in 1st half 2014
		#and wih.CreatedDate <= '2014-09-30'
		and wi.IsDeleted = 0
		and wi.Status__c not in ('Cancelled', 'Budget')
		and (wi.Revenue_Ownership__c LIKE 'AUS-Food%' OR wi.Revenue_Ownership__c LIKE 'AUS-Global%' OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%' OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
	group by wi.Id;

create or replace view shrink_business_revenue_sub as 
select t.*, 	
	p.Id as 'ProductId',	
	p.Name as 'ProductName',	
	pbe.UnitPrice as 'ListPrice',	
	if(cp.Sales_Price_Start_Date__c<= t.Work_Item_Date__c and cp.Sales_Price_End_Date__c>= t.Work_Item_Date__c, cp.FSales_Price__c, null) as 'Site Cert Pricing',
	if(cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=Work_Item_Date__c and cep.New_End_Date__c>=t.Work_Item_Date__c, if(cep.Adjustment_Type__c='Percentage', pbe.UnitPrice*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', pbe.UnitPrice + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'	
	from shrink_business_audits t 
	inner join product2 p ON t.Work_Item_Stage__c = p.Product_Type__c and t.StandardId = p.Standard__c
	inner join pricebookentry pbe ON pbe.Product2Id = p.Id	
	left join certification_pricing__c cp ON cp.Product__c = p.Id and cp.Certification__c = t.Site_Certification__c	
	left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c	
	where	
	p.Category__c = 'Audit'
	and p.IsDeleted=0
	and p.UOM__c = 'DAY'
	and pbe.IsDeleted=0
	and (cep.IsDeleted=0 or cep.IsDeleted is null)
	and (cp.IsDeleted=0 or cp.IsDeleted is null)
	and pbe.Pricebook2Id = '01s90000000568BAAQ'	
	and pbe.CurrencyIsoCode = 'AUD'
	and (cp.Status__c = 'Active' or cp.Status__c is null)
	
	order by `WorkItemId` , `ProductId`, cep.New_Start_Date__c desc, cep.CreatedDate desc;

create or replace view shrink_business_revenue as 
select t3.*, if(t3.`Site Cert Effective Pricing` is not null, t3.`Site Cert Effective Pricing`, if(t3.`Site Cert Pricing` is not null, t3.`Site Cert Pricing`, t3.`ListPrice`)) as 'EffectivePrice' 
from shrink_business_revenue_sub t3
group by t3.`WorkItemId`, t3.`ProductId`;

select date_format(sbr.`Shrink Date`, '%Y %m') as 'Period', sum(sbr.`Shrink Days`), sum(sbr.`Shrink Days`*sbr.`EffectivePrice`) as 'Amount' 
from shrink_business_revenue sbr group by `Period`;

#Lost Audit Revenues
select t5.`Period`,t5.`Audit Revenue Lost`,(1-t5.`Audit Revenue Lost`/t5.`FY 2014 Audit Revenue`) as '% Customer Revenue Retained' from (
select t4.`Cancelled Period` as 'Period', t4.`Stream`, sum(t4.`Revenues`) as 'Audit Revenue Lost', sum(t4.`RequiredDuration`)/8 as 'Audit Days Lost', 
if( t4.`Stream`='MS',
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'MS' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30'),
	(select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data where DataType='PeopleSoft' and DataSubType = 'Audit Revenue' and RefName = 'Food' and RefDate >= '2013-07-01' and RefDate <= '2014-06-30')
) as 'FY 2014 Audit Revenue'
from (
select t2.WorkItemId,		
	t2.Work_Package_Type__c, 	
	t2.Work_Item_Stage__c, 	
	t2.Client_Id__c, 	
	t2.Stream,	
	t2.De_registered_Type__c, 	
	t2.Site_Certification_Status_Reason__c, 	
	t2.Cancellation_Reason__c, 	
	t2.Work_Item_Date__c,	
	t2.`Last Modified Period`, 	
	t2.`Cancelled Period`,  	
	t2.`Scheduled Period`, 	
	t2.Sample_Site__c,	
	t2.Site_Certification__c,	
	t2.`RequiredDuration`,	
	t2.`Days`,	
	t2.`HalfDays`,	
	t2.`Hours`,	
	t2.`StandardName`,	
	t2.`StandardId`,
	sum(t2.`Quantity`*t2.`EffectivePrice`) as 'Revenues' 
from lost_business_revenue t2
where t2.`Cancelled Period`>='2014 07'	
group by `WorkItemId`) t4
group by `Period`, `Stream`) t5
where t5.`Stream` = 'Food';

select sum(RefValue) as 'Audit Days Revenue fy 2014' from sf_data
where DataType='PeopleSoft'
and DataSubType = 'Audit Revenue' 
and RefName = 'MS'
and RefDate >= '2013-07-01' and RefDate <= '2014-06-30';

#Lost Registrtion Fees Revenues
select 
'Revenue Lost (Fees)' as 'Type',
date_format(t3.`DeRegistered Date`, '%Y %m') as 'Period', sum(t3.`EffectivePrice`) as 'Amount' from (
select t2.*, if(t2.`Site Cert Effective Pricing` is not null, t2.`Site Cert Effective Pricing`, if(t2.`Site Cert Pricing` is not null, t2.`Site Cert Pricing`, t2.`ListPrice`)) as 'EffectivePrice' 
from (
select t.*,
if(cp.IsDeleted = 0 and cp.Sales_Price_Start_Date__c<= t.`DeRegistered Date` and cp.Sales_Price_End_Date__c>= t.`DeRegistered Date`, cp.FSales_Price__c, null) as 'Site Cert Pricing',
if(cep.IsDeleted=0 and cep.New_Start_Date__c is not null and cep.New_Start_Date__c<=t.`DeRegistered Date` and cep.New_End_Date__c>=t.`DeRegistered Date`, if(cep.Adjustment_Type__c='Percentage', t.`ListPrice`*(100+cep.Adjustment__c)/100, if(cep.Adjustment_Type__c= 'Amount', t.`ListPrice` + cep.Amount_Adjustment__c, cep.New_Price__c)), null) as 'Site Cert Effective Pricing'
from (
select 
scsp.Site_Certification__c, 
p.Name, 
p.Id as 'ProductId',
min(scsph.CreatedDate) as 'DeRegistered Date',
ig.Recurring_Fee_Frequency__c, 
pbe.UnitPrice as 'ListPrice'
from site_certification_standard_program__c scsp
inner join certification__c site on scsp.Site_Certification__c = site.Id
inner join product2 p on site.Registration_Fee_Product__c = p.Id
inner join Invoice_Group__c ig on site.Invoice_Group_Registration__c = ig.Id
inner join site_certification_standard_program__history scsph on scsph.ParentId = scsp.Id
inner join pricebookentry pbe ON pbe.Product2Id = p.Id
where scsp.De_registered_Type__c in ('Client Initiated','SAI Initiated') 
and scsp.Site_Certification_Status_Reason__c not in ('Correction of customer data','Customer consolidation of licences', 'Other – no loss of revenue')
and scsp.Status__c='De-registered'
and scsph.Field='Status__c'
and scsph.NewValue='De-registered'
and date_format(scsph.CreatedDate,'%Y %m') = '2014 07'
and scsp.IsDeleted=0
and scsph.IsDeleted=0
and (site.Revenue_Ownership__c LIKE 'AUS-Food%' OR site.Revenue_Ownership__c LIKE 'AUS-Global%' OR site.Revenue_Ownership__c LIKE 'AUS-Managed%' OR site.Revenue_Ownership__c LIKE 'AUS-Direct%')
and pbe.Pricebook2Id = '01s90000000568BAAQ'	
and pbe.CurrencyIsoCode = 'AUD'
and pbe.isDeleted = 0 
group by scsp.Site_certification__c) t
left join certification_pricing__c cp ON cp.Product__c = t.`ProductId` and cp.Certification__c = t.Site_Certification__c
left join certification_effective_price__c cep ON cp.Id = cep.Certification_Pricing__c
order by t.Site_certification__c, cep.New_Start_Date__c desc, cep.CreatedDate desc) t2 
group by t2.Site_certification__c) t3 
group by `Period`;

select * from sf_tables where TableName='certification_effective_price__c';
select count(*) from certification_effective_price__c;