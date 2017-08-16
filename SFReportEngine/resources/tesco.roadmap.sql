use analytics;
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
(select t.* from
(SELECT 
 site.Name as 'Client Site',
	ifnull(csp.External_provided_certificate__c,'') as 'Site Code',
    analytics.getRegionFromCountry(ccs.NAme) as 'Site Region',
    ccs.Name as 'Site Country',
    wi.Id AS 'Work Item Id',
    wi.Name AS 'Work Item Name',
    wi.Status__c AS 'Work Item Status',
    if (wi.Status__c  in ('Open','Service change'), 'Open',
  if (wi.Status__c  in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress'), 'Planned',
        'Delivered')
    ) as 'Simple Status',
    ifnull(wi.Open_Sub_Status__c, '') as 'Open Sub Status',
    wi.Work_Item_Date__c AS 'Work Item Date',
    str_to_date(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y-%m-%d') as 'Work Item Target Date',
    ifnull(date_format(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y %m'),'') as 'Work Item Target Period',
    str_to_date(ifnull(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month),''),'%Y-%m-%d') as 'WI Audit Window Start',
	str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d') as 'WI Audit Window End',
	wi.Work_Item_Date__c 
		between date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month) 
		and str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d')
		as 'Scheduling Within SLA',
    1 as '# Audits',
	ifnull(group_concat(distinct r.Name order by r.Name), '') as 'Auditor(s)',
    wi.Required_Duration__c/8 as 'Days',
    sc.Operational_Ownership__c AS 'Scheduling Ownership',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    wi.Primary_Standard__c AS 'Primary Standard',
    wi.Work_Item_Stage__c as 'Work Item Type',
    ifnull(group_concat(distinct if(scsf.IsDeleted = 0, spf.Standard_Service_Type_Name__c, null)), '') as 'FoS',
    ifnull(wi.Comments__c,'') as 'Comments'
FROM
    salesforce.work_item__c wi
    left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.ID and wir.IsDeleted = 0
    left join salesforce.resource__c r on wir.Resource__c = r.Id
    inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
    left join salesforce.delivery_strategy__c ds on c.Delivery_Strategy__c = ds.Id
    left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
    left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
WHERE
    wi.Status__c NOT IN ('Cancelled' , 'Draft', 'Initiate Service')
 AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= DATE_FORMAT(DATE_ADD(UTC_TIMESTAMP(),INTERVAL 13 MONTH),'%Y-%m')
    AND year(wi.Work_Item_Date__c) > 2014
    AND analytics.getRegionFromCountry(ccs.NAme) = 'EMEA'
group by wi.Id) t
where
 t.`Primary Standard` like '%Tesco%' 
    or t.`Primary Standard` like '%TFMS%'
    or t.`FoS` like '%Tesco%'
    or t.`FoS` like '%TFMS%');
    
# V3 - Adding codes
set @audit_window_months_before_target  = 1;
set @audit_window_months_after_target = 1;
    
(select t.* from
(SELECT 
 site.Name as 'Client Site',
 ifnull(csp.External_provided_certificate__c,'') as 'Site Code',
    analytics.getRegionFromCountry(ccs.NAme) as 'Site Region',
    ccs.Name as 'Site Country',
    wi.Id AS 'Work Item Id',
    wi.Name AS 'Work Item Name',
    wi.Status__c AS 'Work Item Status',
    if (wi.Status__c  in ('Open','Service change'), 'Open',
  if (wi.Status__c  in ('Scheduled', 'Scheduled - Offered', 'Confirmed', 'In Progress'), 'Planned',
        'Delivered')
    ) as 'Simple Status',
    ifnull(wi.Open_Sub_Status__c, '') as 'Open Sub Status',
    wi.Work_Item_Date__c AS 'Work Item Date',
    str_to_date(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y-%m-%d') as 'Work Item Target Date',
    ifnull(date_format(ifnull(wi.Service_target_date__c,'1970-01-01'),'%Y %m'),'') as 'Work Item Target Period',
    str_to_date(ifnull(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month),''),'%Y-%m-%d') as 'WI Audit Window Start',
 str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d') as 'WI Audit Window End',
 wi.Work_Item_Date__c 
  between date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval -@audit_window_months_before_target month) 
  and str_to_date(ifnull(date_add(date_add(ifnull(wi.Service_target_date__c,'1970-01-01'), interval @audit_window_months_after_target+1 month), interval -1 day),''),'%Y-%m-%d')
  as 'Scheduling Within SLA',
    1 as '# Audits',
 ifnull(group_concat(distinct r.Name order by r.Name), '') as 'Auditor(s)',
    wi.Required_Duration__c/8 as 'Days',
    sc.Operational_Ownership__c AS 'Scheduling Ownership',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    wi.Primary_Standard__c AS 'Primary Standard',
    wi.Work_Item_Stage__c as 'Work Item Type',
    ifnull(group_concat(distinct if(scsf.IsDeleted = 0, spf.Standard_Service_Type_Name__c, null)), '') as 'FoS',
    ifnull(group_concat(distinct if(scspc.IsDeleted = 0, code.Code_Description__c, null)), '') as 'Codes',
    ifnull(wi.Comments__c,'') as 'Comments'
FROM
    salesforce.work_item__c wi
    left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.ID and wir.IsDeleted = 0
    left join salesforce.resource__c r on wir.Resource__c = r.Id
    inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
    left join salesforce.code__c code on scspc.Code__c = code.Id
    inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    inner join salesforce.certification__c c on sc.Primary_Certification__c = c.Id
    left join salesforce.delivery_strategy__c ds on c.Delivery_Strategy__c = ds.Id
    left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id
    left join salesforce.standard_program__c spf on scsf.Standard_Program__c = spf.Id
WHERE
    wi.Status__c NOT IN ('Cancelled' , 'Draft', 'Initiate Service')
 AND DATE_FORMAT(wi.Work_Item_Date__c, '%Y-%m') <= DATE_FORMAT(DATE_ADD(UTC_TIMESTAMP(),INTERVAL 13 MONTH),'%Y-%m')
    AND year(wi.Work_Item_Date__c) > 2014
    AND analytics.getRegionFromCountry(ccs.NAme) = 'EMEA'
group by wi.Id) t
where
 t.`Primary Standard` like '%Tesco%' 
    or t.`Primary Standard` like '%TFMS%'
    or t.`FoS` like '%Tesco%'
    or t.`FoS` like '%TFMS%');