drop function `getCountryFromRevenueOwnership`;
DELIMITER $$
CREATE DEFINER=`luca`@`%` FUNCTION `getCountryFromRevenueOwnership`(ro VARCHAR(256)) RETURNS varchar(256) CHARSET utf8
BEGIN
	DECLARE country VARCHAR(256) DEFAULT null;
    SET country = (SELECT 
		if(ro like '%Product%', 
			'Product Services', 
			if(ro like 'AUS%', 
				'Australia', 
                if (ro like '%AMERICAS%',
					'AMERICA',
					if (ro like 'Asia-Regional Desk%',
						'Asia Regional Desk',
						if (ro like 'EMEA%',
							if(ro='EMEA-MS', 'UK', substring_index(ro,'-',-1)),
							substring_index(substring_index(ro,'-',-2),'-',1)
						)
					)
				)
			)
		)
	);
		
    RETURN country;
END$$
DELIMITER ;


set @fy = if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1);
set @startDate = concat(@fy-2,'-07-01');
set @endDate = concat(@fy+1,'-06-30');

select @startDate, @endDate;
        
INSERT INTO salesforce.sf_report_history 
(SELECT 
	null as 'Id',
    'Audit Days Snapshot' as 'ReportName',
    now() as 'Date',
    sc.Revenue_Ownership__c as 'Region', 
	concat(IF(sc.Revenue_Ownership__c LIKE '%Food%', 'Food', IF(sc.Revenue_Ownership__c LIKE '%Product%', 'ProductService', 'MS')), 
		' - Audit - Days - ', 
		if(wi.Status__c='Open' and wi.Open_Sub_Status__c is not null, wi.Open_Sub_Status__c,''), 
		' - ',
		REPLACE(wi.Status__c, 'Scheduled - Offered', 'Scheduled Offered'))  AS 'RowName', 
	DATE_FORMAT(wi.Work_Item_Date__c, '%Y %m') as 'ColumnName', 
	SUM(wi.Required_Duration__c)/8 as 'Value' 
FROM salesforce.`work_item__c` wi 
	LEFT JOIN salesforce.`recordtype` rt ON wi.RecordTypeId = rt.Id 
	inner join salesforce.site_certification_standard_program__c scs on wi.Site_Certification_Standard__c = scs.Id 
    inner join salesforce.certification__c sc on scs.Site_Certification__c = sc.Id
WHERE rt.Name = 'Audit' 
	and wi.IsDeleted=0 and (wi.Status__c ='Open' or (wi.Status__c ='Cancelled' and (scs.De_registered_Type__c not in ('Maintenance') or scs.De_registered_Type__c is null) and ( scs.Site_Certification_Status_Reason__c in ('System failure / Unresolved non conformances', 'Unpaid account', 'Failed product testing', 'Application / Certification abandoned', 'Misuse of Mark', 'Change to other CB (Cost)', 'Change to other CB (Service delivery)', 'Change to other CB (Other)', 'No added value / interest', 'Business / site closed down', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'Company takeover / Liquidation', 'Global certification decision', 'Scheme / Program expired') 
	or  wi.Cancellation_Reason__c in ('De-registered Site Certification Standard status', 'Concluded Site Certification Standard status') ))) 
	AND wi.Work_Item_Date__c >= @startDate
	AND wi.Work_Item_Date__c <= @endDate 
GROUP BY `Region`, `RowName`, `ColumnName`) 

UNION

(SELECT 
	null as 'Id',
	'Audit Days Snapshot' as 'ReportName', 
	now() as 'Date',
    sc.Revenue_Ownership__c as 'Region', 
	concat(IF(sc.Revenue_Ownership__c LIKE '%Food%', 'Food', IF(sc.Revenue_Ownership__c LIKE '%Product%', 'ProductService', 'MS')), 
		' - Audit - Days - ', REPLACE(wi.Status__c, 'Scheduled - Offered', 'Scheduled Offered'))  AS 'RowName', 
	DATE_FORMAT(wird.FStartDate__c, '%Y %m') as 'ColumnName', 
	sum(if(Budget_Days__c is null, wird.Scheduled_Duration__c / 8, wird.Scheduled_Duration__c / 8 + Budget_Days__c)) AS 'Value' 
FROM salesforce.`work_item__c` wi 
	inner join salesforce.site_certification_standard_program__c scs on wi.Site_Certification_Standard__c = scs.Id 
    inner join salesforce.certification__c sc on scs.Site_Certification__c = sc.Id
	LEFT JOIN salesforce.`work_item_resource__c` wir ON wir.work_item__c = wi.Id 
	LEFT JOIN salesforce.`work_item_resource_day__c` wird ON wird.Work_Item_Resource__c = wir.Id 
	LEFT JOIN salesforce.`recordtype` rt ON wi.RecordTypeId = rt.Id 
WHERE rt.Name = 'Audit' 
	AND wir.IsDeleted = 0 
	AND wird.IsDeleted = 0 
	AND wir.Work_Item_Type__c IN ('Audit' , 'Audit Planning', 'Client Management', 'Budget') 
	AND wir.Role__c NOT IN ('Observer' , 'Verifying Auditor', 'Verifier') 
	and wi.Status__c NOT IN ('Open', 'Cancelled', 'Budget') 
	AND wird.FStartDate__c >= @startDate 
	AND wird.FStartDate__c <= @endDate 
	GROUP BY `Region`, `RowName`, `ColumnName`);

(select rh.* 
from salesforce.sf_report_history rh 
where rh.ReportName='Audit Days Snapshot'
and rh.`date` = (select max(Date) from salesforce.sf_report_history where ReportName='Audit Days Snapshot'));