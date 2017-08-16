#drop function getProductPortfolioFromLeadRecordType;
DELIMITER $$
create function getProductPortfolioFromLeadRecordType(recordType VARCHAR(128), solutionType VARCHAR(128)) returns ENUM('Property', 'Assurance','Knowledge','Risk','Learning', 'TIS', '?')
BEGIN
	DECLARE portfolio VARCHAR(64) DEFAULT '';
    SET portfolio = (select 
		IF(recordType = 'Compass Lead', 'Assurance',
        IF(recordType = 'AS-AMER', 'Assurance', 
		IF(recordType = 'AS-AUS-Mgmt Sys', 'Assurance', 
		IF(recordType = 'AS-AUS-Prod Cert', 'Assurance', 
		IF(recordType = 'AS-EMEA-Lead', 'Assurance', 
		IF(recordType = 'CMPL - APAC - Lead Record Type', 'Risk', 
		IF(recordType = 'Compliance Americas Lead Record Type' and solutionType = 'Learning', 'Learning', 
		IF(recordType = 'Compliance Americas Lead Record Type', 'Risk', 
		IF(recordType = 'Compliance Asia Pacific Lead Record Type', 'Knowledge', 
		IF(recordType = 'Compliance EMEA Lead Record Type' and solutionType = 'Learning', 'Learning', 
		IF(recordType = 'Compliance EMEA Lead Record Type', 'Risk', 
		IF(recordType = 'IS - APAC - Lead - Marketing', 'Knowledge', 
		IF(recordType = 'IS - APAC - Lead - Top 2000', 'Knowledge', 
		IF(recordType = 'PTY - APAC - Lead', 'Property', 
		IF(recordType = 'PUB - APAC - Lead - General', 'Knowledge', 
		IF(recordType = 'PUB - APAC - Lead - Newsletters', 'Knowledge', 
		IF(recordType = 'PUB - APAC - Lead - Support', 'Knowledge', 
		IF(recordType = 'PUB-UK', 'Knowledge', 
		IF(recordType = 'PUB-UK-Marketing Leads', 'Knowledge', 
		IF(recordType = 'PUB-US', 'Knowledge', 
		IF(recordType = 'PUB-US-Marketing Leads', 'Knowledge', 
		IF(recordType = 'TIS - AMER - Lead (IH)', 'TIS', 
		IF(recordType = 'TIS - AMER - Lead (Marketing)', 'TIS', 
		IF(recordType = 'TIS - AMER - Lead (Public)', 'TIS', 
		IF(recordType = 'TIS - AMER - Lead (Web)', 'TIS', 
		IF(recordType = 'TIS APAC Lead Record Type', 'TIS', '?')))))))))))))))))))))))))));

	RETURN portfolio;
END$$
DELIMITER ;

#drop function getRegionFromLeadRecordType;
DELIMITER $$
create function getRegionFromLeadRecordType(recordType VARCHAR(128)) returns ENUM('Americas', 'APAC','EMEA', '?')
BEGIN
	DECLARE region VARCHAR(64) DEFAULT '';
    SET region = (select 
		IF(recordType = 'Compass Lead', 'APAC',
        IF(recordType='AS-AMER', 'Americas', 
		IF(recordType='AS-AUS-Mgmt Sys', 'APAC', 
		IF(recordType='AS-AUS-Prod Cert', 'APAC', 
		IF(recordType='AS-EMEA-Lead', 'EMEA', 
		IF(recordType='CMPL - APAC - Lead Record Type', 'APAC', 
		IF(recordType='Compliance Americas Lead Record Type', 'Americas', 
		IF(recordType='Compliance Americas Lead Record Type', 'Americas', 
		IF(recordType='Compliance Asia Pacific Lead Record Type', 'APAC', 
		IF(recordType='Compliance EMEA Lead Record Type', 'EMEA', 
		IF(recordType='Compliance EMEA Lead Record Type', 'EMEA', 
		IF(recordType='IS - APAC - Lead - Marketing', 'APAC', 
		IF(recordType='IS - APAC - Lead - Top 2000', 'APAC', 
		IF(recordType='PTY - APAC - Lead', 'APAC', 
		IF(recordType='PUB - APAC - Lead - General', 'APAC', 
		IF(recordType='PUB - APAC - Lead - Newsletters', 'APAC', 
		IF(recordType='PUB - APAC - Lead - Support', 'APAC', 
		IF(recordType='PUB-UK', 'EMEA', 
		IF(recordType='PUB-UK-Marketing Leads', 'EMEA', 
		IF(recordType='PUB-US', 'Americas', 
		IF(recordType='PUB-US-Marketing Leads', 'Americas', 
		IF(recordType='TIS - AMER - Lead (IH)', 'Americas', 
		IF(recordType='TIS - AMER - Lead (Marketing)', 'Americas', 
		IF(recordType='TIS - AMER - Lead (Public)', 'Americas', 
		IF(recordType='TIS - AMER - Lead (Web)', 'Americas', 
		IF(recordType='TIS APAC Lead Record Type', 'APAC', '?')))))))))))))))))))))))))));

	RETURN region;
END$$
DELIMITER ;

set @now = (select utc_timestamp());
set @week_start = (select date_format(date_add(@now, interval -WEEKDAY(@now) day), '%Y-%m-%d'));
set @period_1_start = (select date_add(@now, interval -1 month));
set @period_1_end = (select @now);
set @period_2_start = (select date_add(@now, interval -12 month));
set @period_2_end = (select @now);
set @portfolio_1 = 'Knowledge';
set @portfolio_2 = 'Risk';
set @portfolio_3 = 'Learning';
set @portfolio_4 = 'TIS';
set @portfolio_5 = 'Assurance';
set @region_1 = 'Americas';
set @region_2 = 'APAC';
set @region_3 = 'EMEA';

(select t.* from
	(select 
		analytics.getRegionFromLeadRecordType('Compass Lead') as 'Region',
		analytics.getProductPortfolioFromLeadRecordType('Compass Lead', null) as 'Product Portfolio', 
		'Compass Lead' as 'Record Type',
		'' as 'Solution Type',
		l.Id as 'Lead Id', 
		l.Title,
		l.Name as 'Lead Name', 
		l.Company,
		l.Email,
		l.Rating,
		l.FState_Province_Name__c as 'State',
		l.FCountry_Name__c as 'Country',
		l.createdDate as 'Created Date',
		timestampdiff(day, l.CreatedDate, utc_timestamp()) as 'Ageing (Day)',
		if(timestampdiff(month, l.CreatedDate, utc_timestamp())>=4, '4+', timestampdiff(month, l.CreatedDate, utc_timestamp())) as 'Ageing (Month)',
		l.LeadSource as 'Lead Source', 
		getLeadSourceCategorySimple(l.LeadSource) as 'Lead Source Category Simple',
		getLeadSourceCategory(l.LeadSource) as 'Lead Source Category',
		l.Status as 'Status',
		analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) as 'Status Simple',
        '' as 'Area of Interest',
		o.Name as 'Owner', 
		m.Name as 'Manager',
		mm.Name as 'Manager\'s Manager',
		i.Name as 'Industry', 
		null as 'Industry Vertical',
		l.Program__c,
		l.IsConverted,
		if(opp.StageName = 'Closed Won',1,0) as 'HasGeneratedOpportunityWon',
        if(opp.StageName = 'Closed Lost',1,0) as 'HasGeneratedOpportunityLost',
		l.ConvertedDate,
		if(opp.StageName = 'Closed Won', opp.CloseDate, '') as 'ClosedWonDate',
		timestampdiff(day,l.ConvertedDate,if(opp.StageName = 'Closed Won', opp.CloseDate, null)) as 'Converted to Won Days',
		if(opp.StageName = 'Closed Won', opp.Total_First_Year_Revenue__c/ct.ConversionRate, '') as 'ACV (AUD)',	
		if(l.CreatedDate between @period_1_start and @period_1_end, true, false) as 'Period 1',
		if(l.CreatedDate between @period_2_start and @period_2_end, true, false) as 'Period 2',
		if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) in ('Archived', 'Converted', 'Qualified'), false, true) as 'isWIP',
		if(l.isConverted and l.ConvertedDate>=@week_start,1,0) as 'IsConvertedLastWeek',
		if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) = 'Open' and timestampdiff(day, l.CreatedDate, utc_timestamp())>2,true,false) as 'NotAddressedWithinTwoDays'
	from salesforce.lead l
		left join salesforce.user o on l.OwnerId = o.Id
		left join salesforce.user m on o.ManagerId = m.Id
		left join training.user mm on m.ManagerId = mm.Id
		left join salesforce.industry__c i on l.Industry_2__c = i.Id
		left join salesforce.opportunity opp on opp.Id = l.ConvertedOpportunityId
		left join salesforce.currencytype ct on opp.CurrencyIsoCode = ct.IsoCode
	where 
		l.IsDeleted = 0 
		and l.CreatedDate >= least(@period_1_start, @period_2_start) 
	union all
	select 
		analytics.getRegionFromLeadRecordType(rt.Name) as 'Region',
		analytics.getProductPortfolioFromLeadRecordType(rt.Name, l.Solution_Type__c) as 'Product Portfolio', 
		rt.Name as 'Record Type', 
		ifnull(l.Solution_Type__c, '') as 'Solution Type',
		l.Id as 'Lead Id', 
		l.Title,
		l.Name as 'Lead Name', 
		l.Company,
		l.Email,
		l.Rating,
		l.State,
		l.Country,
		l.createdDate, 
		timestampdiff(day, l.CreatedDate, utc_timestamp()) as 'Ageing',
		if(timestampdiff(month, l.CreatedDate, utc_timestamp())>=4, '4+', timestampdiff(month, l.CreatedDate, utc_timestamp())) as 'Ageing (Month)',
		l.LeadSource as 'Source', 
		getLeadSourceCategorySimple(l.LeadSource) as 'Lead Source Category Simple',
		getLeadSourceCategory(l.LeadSource) as 'Lead Source Category',
		l.Status as 'Status', 
		analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) as 'Status Simple',
        l.Area_s_of_Interest__c as 'Area of Interest',
		o.Name as 'Owner', 
		m.Name as 'Manager',
		mm.Name as 'Manager\'s Manager',
		l.Industry as 'Industry',
		l.Industry_Vertical__c as 'Industry Vertical', 
		l.Program__c as 'Program',
		l.IsConverted,
		if(opp.Stages__c like '%Won%',1,
			if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,1,0)
		) as 'HasGeneratedOpportunityWon',
        if(opp.Stages__c like '%Lost%',1,
			if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is null,1,0)
		) as 'HasGeneratedOpportunityLost',
		l.ConvertedDate,
		if(opp.Stages__c like '%Won%',opp.CloseDate,
			ifnull(min(if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,r.CreatedDate ,null)),'')
		) as 'Closed Won Date',
		timestampdiff(day, l.ConvertedDate, 
			if(opp.Stages__c like '%Won%',opp.CloseDate,
				min(if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,r.CreatedDate ,null))
			)
		) as 'Converted To Won Days',
		if(opp.Stages__c like '%Won%', opp.Global_ACV__c/ct.ConversionRate, '') as 'ACV (AUD)',
		if(l.CreatedDate between @period_1_start and @period_1_end, true, false) as 'Period 1',
		if(l.CreatedDate between @period_2_start and @period_2_end, true, false) as 'Period 2',
		if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) in ('Archived', 'Converted', 'Qualified'), false, true) as 'isWIP',
		if(l.isConverted and l.ConvertedDate>=@week_start,1,0) as 'IsConvertedLastWeek',
		if(analytics.getSimpleLeadStatusFromStatus(l.Status, l.IsConverted) = 'Open' and timestampdiff(day, l.CreatedDate, utc_timestamp())>2,true,false) as 'NotAddressedWithinTwoDays'
	from training.lead l
		left join training.user o on l.OwnerId = o.Id
		left join training.user m on o.ManagerId = m.Id
		left join training.user mm on m.ManagerId = mm.Id
		left join training.recordtype rt on l.RecordTypeId = rt.Id
		left join training.opportunity opp on opp.Id = l.ConvertedOpportunityId
		left join salesforce.currencytype ct on opp.CurrencyIsoCode = ct.IsoCode
		left join training.contact c on l.ConvertedContactId = c.Id
		left join training.registration__c r on r.Attendee__c = c.Id and r.Status__c = 'Confirmed' and r.IsDeleted = 0    
	where 
		l.IsDeleted = 0 
		and (l.CreatedDate >= least(@period_1_start, @period_2_start) )	
	group by l.Id) t
where t.`Region` in (@region_1, @region_2, @region_3)
and t.`Product Portfolio` in (@portfolio_1,@portfolio_2,@portfolio_3,@portfolio_4,@portfolio_5));

select length(name) from training.recordtype where SobjectType = 'Lead'