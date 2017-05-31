# Leads in open/unqualified status – what needs to be actioned? 
# Leads in working contacted – What is working but yet to be converted?
# Qualified Leads – What is qualified but not converted?
# Disqualified leads – Quality of leads / qualification?
# This weeks converted leads – View on newly created opportunities for focus?
# Lead levels (count) aggregated per person by type, lead source and state – How many leads do each get and where does it come from?

create index lead_recordtype_index on training.lead(recordtypeId);
create index opportunity_account_index on training.opportunity(AccountId);

set @today = (select date_format(now(), '%Y-%m-%d'));
set @week_start = (select date_format(date_add(@today, interval -WEEKDAY(@today) day), '%Y-%m-%d'));
set @period_1_start = (select date_format(date_add(@today, interval -1 month), '%Y-%m-01'));
set @period_1_end = (select date_format(@today, '%Y-%m-01'));
set @period_2_start = (select date_format(date_add(@today, interval -12 month), '%Y-%m-01'));
set @period_2_end = (select date_format(@today, '%Y-%m-01'));

select @period_1_start, @period_1_end, @period_2_start, @period_2_end;

drop function getSimpleLeadStatusFromStatus;
DELIMITER $$
create function getSimpleLeadStatusFromStatus(leadStatus VARCHAR(64), isConverted boolean) returns VARCHAR(64)
BEGIN
	DECLARE simpleStatus VARCHAR(64) DEFAULT '';
    SET simpleStatus = (select 
		if(isConverted, 'Converted', 
		if (leadStatus in ('New', 'Open', 'Open/Unqualified', 'New - Not Contacted', 'Attempted - Not Contacted'), 'Open', 
		if (leadStatus in ('Contacted', 'Working/Contacted', 'Hold', 'On Hold'), 'Working', 
		if (leadStatus in ('Qualified', 'Registered Attended'), 'Qualified', 
		if (leadStatus in ('Disqualified', 'Archived', 'Not Ready (Recycle)', 'Nurture'), 'Archived', 
		'?'))))));
	RETURN simpleStatus;
END$$
DELIMITER ;

DELIMITER $$
create function getLeadSourceCategorySimple(leadSource VARCHAR(64)) returns VARCHAR(64)
BEGIN
	DECLARE category VARCHAR(64) DEFAULT '';
    SET category = (select if(leadSource in ('Ad','Advertisement','Advertising (Hard Copy)','Tile_Banner','Advertising (Online)','Online advertisement','Online Advertising','PRweb','Web advertising','Web banner - External','Brochure','Direct Mailing','ACC-enewsletter','CodeConnect Video Demo Launch EDM','Direct marketing','Direct/E-mail','e - campaigns','e-Campaigns','Email from SAI Global','Email Marketing','E-mail Marketing','Email/Newsletter','ExactTarget','Manticore Email','NL','Pardot','RK','ALPMA','Conference','Conference/Event','Conference/Tradeshow','Event','Exhibition/Event','Seminar - Partner','Seminar Partner','Seminar/Client Briefing','Third Party Marketing','Trade Show','Trade Show/Conference','Tradeshow','Google Ad','Google Adwords','Google Paid Search','Call In','Direct call/email in','Inbound (Web/Call)','Inbound Inquiry (unspecified)','Phone/ Emails','Phone/Email Enquiry','Campaign','GC','GC-DGGuide-Mar11-TL','GC-Guide-BC-Jan11-TL','GCR1','GCT1','Marketing','Marketing Campaign','Marketing/Campaign','Other Mkt','Partner','Public Relations','Facebook','LinkedIn','Social Media -  Blog','Social Media -  LinkedIn','Twitter','Telemarketer','Telemarketing','Live Webinar','SAI Webinar','Web Demo','Webcast','Webcast - Webinar','Webcast-Web Demo','Webcast-Webinar','Webinar','Webinar Replay','Webinar/Workshop','1stopdata Jan 2016','EA Register','EA Request','FST','GRC Community','Gungho','ILI Registration','SAI Global','SEO','Stacey Goodridge','Influitive Referral','Referral - Analyst','Referral - Cross-Divisional Marketing','PDF','Ask.com Natural Search','Bing Natural Search','Google Natural Search','Online Search','Search Engine','Yahoo! Natural Search','Pardot_Video','Connect Form','Contact Us Link','Free_Standards-Infostore','German website','Info.emea Enquiry','IS Microsite','Link','Manticore Webform','Manticore Website','OC Webform','Pardot (Website)','ResearchDownload','SAI Global Website','TIS online feedback','Web','Webpage','Website','Website -  Manual/Checklist','Website - Brochure','Website - Case Study','Website - Contact request','Website - FAQ','Website - Recorded Webinar','Website - Request a Quote','Website - Whitepaper','Website Campaign','Website MA','Website/Contact us','Website/Downloads','Website/Internal Referral','Website_Infostore','Website_Link','Website-Affiliate','Website-C2V','Website-Codeconnect','Website-Lexconnect','Website-MA','Website-MA-Live-Chat','Website-Newsletters','Website-SAIConnect','Wikipedia','Website - Infographic','List Broker','Other (purchased)','2011_04_Tshow_HCCAAnnual','2011_10_Webinar_RACnMACUpdates','2012_06_Event_ABA','Compliance Zone Web Lead','Gungho - UK FTSE 101 - 250','Gungho - UK FTSE 1-100','Gungho Marketing - Own Research','ISO 9001','Training Calendar','Website: Contact Us','SAI Global Website/Web Form','Analysts','Banner Ads','Benchmarking Report','Direct Mail','eBook','Email Marketing','Executive Briefings','Google Adwords','Inbound','Influitive','Webinar/Demo - Live','Offline Advertising','Other Marketing','Partners','Public Relations','Webinar/Demo - On Demand','SAI Global Website/Web Forms','Sales Enablement','Seminar','Social Media (Twitter/FB/LinkedIn)','Telemarketing','Tradeshow/Conference','Web Search (Google, Bing etc)','Whitepapers','Newsletter','e-campaign','BRC Website','Case Study'),
			'Marketing',
            'Non Marketing'));
RETURN category;
END$$
DELIMITER ;

DELIMITER $$
create function getLeadSourceCategory(leadSource VARCHAR(64)) returns VARCHAR(64)
BEGIN
	DECLARE category VARCHAR(64) DEFAULT '';
    SET category = (select 
		if(leadSource='Ad', 'Offline Advertising',
		if(leadSource='Advertisement', 'Offline Advertising',
		if(leadSource='Advertising (Hard Copy)', 'Offline Advertising',
		if(leadSource='Tile_Banner', 'Banner Ads',
		if(leadSource='Advertising (Online)', 'Banner Ads',
		if(leadSource='Online advertisement', 'Banner Ads',
		if(leadSource='Online Advertising', 'Banner Ads',
		if(leadSource='PRweb', 'Public Relations',
		if(leadSource='Web advertising', 'Banner Ads',
		if(leadSource='Web banner - External', 'Banner Ads',
		if(leadSource='Brochure', 'Whitepapers',
		if(leadSource='Direct Mailing', 'Direct Mail',
		if(leadSource='ACC-enewsletter', 'Newsletter',
		if(leadSource='CodeConnect Video Demo Launch EDM', 'Email Marketing',
		if(leadSource='Direct marketing', 'Direct Mail',
		if(leadSource='Direct/E-mail', 'Email Marketing',
		if(leadSource='e - campaigns', 'Email Marketing',
		if(leadSource='e-Campaigns', 'Email Marketing',
		if(leadSource='Email from SAI Global', 'Email Marketing',
		if(leadSource='Email Marketing', 'Email Marketing',
		if(leadSource='E-mail Marketing', 'Email Marketing',
		if(leadSource='Email/Newsletter', 'Email Marketing',
		if(leadSource='ExactTarget', 'Email Marketing',
		if(leadSource='Manticore Email', 'Email Marketing',
		if(leadSource='NL', 'Newsletter',
		if(leadSource='Pardot', 'Email Marketing',
		if(leadSource='RK', 'Email Marketing',
		if(leadSource='ALPMA', 'Tradeshow/Conference',
		if(leadSource='Conference', 'Tradeshow/Conference',
		if(leadSource='Conference/Event', 'Tradeshow/Conference',
		if(leadSource='Conference/Tradeshow', 'Tradeshow/Conference',
		if(leadSource='Event', 'Tradeshow/Conference',
		if(leadSource='Exhibition/Event', 'Tradeshow/Conference',
		if(leadSource='Seminar - Partner', 'Seminar',
		if(leadSource='Seminar Partner', 'Seminar',
		if(leadSource='Seminar/Client Briefing', 'Seminar',
		if(leadSource='Third Party Marketing', 'Other Marketing',
		if(leadSource='Trade Show', 'Tradeshow/Conference',
		if(leadSource='Trade Show/Conference', 'Tradeshow/Conference',
		if(leadSource='Tradeshow', 'Tradeshow/Conference',
		if(leadSource='Google Ad', 'Google Adwords',
		if(leadSource='Google Adwords', 'Google Adwords',
		if(leadSource='Google Paid Search', 'Google Adwords',
		if(leadSource='Call In', 'Inbound',
		if(leadSource='Direct call/email in', 'Inbound',
		if(leadSource='Inbound (Web/Call)', 'Inbound',
		if(leadSource='Inbound Inquiry (unspecified)', 'Inbound',
		if(leadSource='Phone/ Emails', 'Inbound',
		if(leadSource='Phone/Email Enquiry', 'Inbound',
		if(leadSource='Campaign', 'Other Marketing',
		if(leadSource='GC', 'Other Marketing',
		if(leadSource='GC-DGGuide-Mar11-TL', 'Other Marketing',
		if(leadSource='GC-Guide-BC-Jan11-TL', 'Other Marketing',
		if(leadSource='GCR1', 'Other Marketing',
		if(leadSource='GCT1', 'Other Marketing',
		if(leadSource='Marketing', 'Other Marketing',
		if(leadSource='Marketing Campaign', 'Other Marketing',
		if(leadSource='Marketing/Campaign', 'Other Marketing',
		if(leadSource='Other Mkt', 'Other Marketing',
		if(leadSource='Partner', 'Partners',
		if(leadSource='Public Relations', 'Public Relations',
		if(leadSource='Facebook', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='LinkedIn', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='Social Media -  Blog', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='Social Media -  LinkedIn', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='Twitter', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='Telemarketer', 'Telemarketing',
		if(leadSource='Telemarketing', 'Telemarketing',
		if(leadSource='Live Webinar', 'Webinar/Demo - Live',
		if(leadSource='SAI Webinar', 'Webinar/Demo - Live',
		if(leadSource='Web Demo', 'Webinar/Demo - Live',
		if(leadSource='Webcast', 'Webinar/Demo - Live',
		if(leadSource='Webcast - Webinar', 'Webinar/Demo - Live',
		if(leadSource='Webcast-Web Demo', 'Webinar/Demo - Live',
		if(leadSource='Webcast-Webinar', 'Webinar/Demo - Live',
		if(leadSource='Webinar', 'Webinar/Demo - Live',
		if(leadSource='Webinar Replay', 'Webinar/Demo - On Demand',
		if(leadSource='Webinar/Workshop', 'Webinar/Demo - Live',
		if(leadSource='1stopdata Jan 2016', 'Other Marketing',
		if(leadSource='EA Register', 'SAI Global Website/Web Forms',
		if(leadSource='EA Request', 'SAI Global Website/Web Forms',
		if(leadSource='FST', 'Partners',
		if(leadSource='GRC Community', 'SAI Global Website/Web Forms',
		if(leadSource='Gungho', 'Telemarketing',
		if(leadSource='ILI Registration', 'SAI Global Website/Web Forms',
		if(leadSource='SAI Global', 'SAI Global Website/Web Forms',
		if(leadSource='SEO', 'Web Search (Google, Bing etc)',
		if(leadSource='Stacey Goodridge', 'Other Marketing',
		if(leadSource='Influitive Referral', 'Influitive',
		if(leadSource='Referral - Analyst', 'Analysts',
		if(leadSource='Referral - Cross-Divisional Marketing', 'Other Marketing',
		if(leadSource='PDF', 'Whitepapers',
		if(leadSource='Ask.com Natural Search', 'Web Search (Google, Bing etc)',
		if(leadSource='Bing Natural Search', 'Web Search (Google, Bing etc)',
		if(leadSource='Google Natural Search', 'Web Search (Google, Bing etc)',
		if(leadSource='Online Search', 'Web Search (Google, Bing etc)',
		if(leadSource='Search Engine', 'Web Search (Google, Bing etc)',
		if(leadSource='Yahoo! Natural Search', 'Web Search (Google, Bing etc)',
		if(leadSource='Pardot_Video', 'SAI Global Website/Web Forms',
		if(leadSource='Connect Form', 'SAI Global Website/Web Forms',
		if(leadSource='Contact Us Link', 'SAI Global Website/Web Forms',
		if(leadSource='Free_Standards-Infostore', 'SAI Global Website/Web Forms',
		if(leadSource='German website', 'SAI Global Website/Web Forms',
		if(leadSource='Info.emea Enquiry', 'SAI Global Website/Web Forms',
		if(leadSource='IS Microsite', 'SAI Global Website/Web Forms',
		if(leadSource='Link', 'SAI Global Website/Web Forms',
		if(leadSource='Manticore Webform', 'SAI Global Website/Web Forms',
		if(leadSource='Manticore Website', 'SAI Global Website/Web Forms',
		if(leadSource='OC Webform', 'SAI Global Website/Web Forms',
		if(leadSource='Pardot (Website)', 'SAI Global Website/Web Forms',
		if(leadSource='ResearchDownload', 'SAI Global Website/Web Forms',
		if(leadSource='SAI Global Website', 'SAI Global Website/Web Forms',
		if(leadSource='TIS online feedback', 'SAI Global Website/Web Forms',
		if(leadSource='Web', 'SAI Global Website/Web Forms',
		if(leadSource='Webpage', 'SAI Global Website/Web Forms',
		if(leadSource='Website', 'SAI Global Website/Web Forms',
		if(leadSource='Website -  Manual/Checklist', 'SAI Global Website/Web Forms',
		if(leadSource='Website - Brochure', 'SAI Global Website/Web Forms',
		if(leadSource='Website - Case Study', 'Case Study',
		if(leadSource='Website - Contact request', 'SAI Global Website/Web Forms',
		if(leadSource='Website - FAQ', 'SAI Global Website/Web Forms',
		if(leadSource='Website - Recorded Webinar', 'Webinar/Demo - On Demand',
		if(leadSource='Website - Request a Quote', 'SAI Global Website/Web Forms',
		if(leadSource='Website - Whitepaper', 'Whitepapers',
		if(leadSource='Website Campaign', 'SAI Global Website/Web Forms',
		if(leadSource='Website MA', 'SAI Global Website/Web Forms',
		if(leadSource='Website/Contact us', 'SAI Global Website/Web Forms',
		if(leadSource='Website/Downloads', 'SAI Global Website/Web Forms',
		if(leadSource='Website/Internal Referral', 'SAI Global Website/Web Forms',
		if(leadSource='Website_Infostore', 'SAI Global Website/Web Forms',
		if(leadSource='Website_Link', 'SAI Global Website/Web Forms',
		if(leadSource='Website-Affiliate', 'SAI Global Website/Web Forms',
		if(leadSource='Website-C2V', 'SAI Global Website/Web Forms',
		if(leadSource='Website-Codeconnect', 'SAI Global Website/Web Forms',
		if(leadSource='Website-Lexconnect', 'SAI Global Website/Web Forms',
		if(leadSource='Website-MA', 'SAI Global Website/Web Forms',
		if(leadSource='Website-MA-Live-Chat', 'SAI Global Website/Web Forms',
		if(leadSource='Website-Newsletters', 'Newsletter',
		if(leadSource='Website-SAIConnect', 'SAI Global Website/Web Forms',
		if(leadSource='Wikipedia', 'SAI Global Website/Web Forms',
		if(leadSource='Website - Infographic', 'SAI Global Website/Web Forms',
		if(leadSource='List Broker', 'Other Marketing',
		if(leadSource='Other (purchased)', 'Other Marketing',
		if(leadSource='2011_04_Tshow_HCCAAnnual', 'Tradeshow/Conference',
		if(leadSource='2011_10_Webinar_RACnMACUpdates', 'Webinar/Demo - Live',
		if(leadSource='2012_06_Event_ABA', 'Seminar',
		if(leadSource='Compliance Zone Web Lead', 'SAI Global Website/Web Forms',
		if(leadSource='Gungho - UK FTSE 101 - 250', 'Telemarketing',
		if(leadSource='Gungho - UK FTSE 1-100', 'Telemarketing',
		if(leadSource='Gungho Marketing - Own Research', 'Telemarketing',
		if(leadSource='ISO 9001', 'Other Marketing',
		if(leadSource='Training Calendar', 'SAI Global Website/Web Forms',
		if(leadSource='Website: Contact Us', 'SAI Global Website/Web Forms',
		if(leadSource='SAI Global Website/Web Form', 'SAI Global Website/Web Forms',
		if(leadSource='Analysts', 'Analysts',
		if(leadSource='Banner Ads', 'Banner Ads',
		if(leadSource='Benchmarking Report', 'Benchmarking Report',
		if(leadSource='Direct Mail', 'Direct Mail',
		if(leadSource='eBook', 'eBook',
		if(leadSource='Email Marketing', 'Email Marketing',
		if(leadSource='Executive Briefings', 'Executive Briefings',
		if(leadSource='Google Adwords', 'Google Adwords',
		if(leadSource='Inbound', 'Inbound',
		if(leadSource='Influitive', 'Influitive',
		if(leadSource='Webinar/Demo - Live', 'Webinar/Demo - Live',
		if(leadSource='Offline Advertising', 'Offline Advertising',
		if(leadSource='Other Marketing', 'Other Marketing',
		if(leadSource='Partners', 'Partners',
		if(leadSource='Public Relations', 'Public Relations',
		if(leadSource='Webinar/Demo - On Demand', 'Webinar/Demo - On Demand',
		if(leadSource='SAI Global Website/Web Forms', 'SAI Global Website/Web Forms',
		if(leadSource='Sales Enablement', 'Sales Enablement',
		if(leadSource='Seminar', 'Seminar',
		if(leadSource='Social Media (Twitter/FB/LinkedIn)', 'Social Media (Twitter/FB/LinkedIn)',
		if(leadSource='Telemarketing', 'Telemarketing',
		if(leadSource='Tradeshow/Conference', 'Tradeshow/Conference',
		if(leadSource='Web Search (Google, Bing etc)', 'Web Search (Google, Bing etc)',
		if(leadSource='Whitepapers', 'Whitepapers',
		if(leadSource='Newsletter', 'Newsletter',
		if(leadSource='e-campaign', 'Email Marketing',
		if(leadSource='BRC Website', 'SAI Global Website/Web Forms',
		if(leadSource='Case Study', 'Case Study',
		null)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))));
	RETURN category;
END$$
DELIMITER ;

(select 
	'Assurance' as 'Product Portfolio',
	'Compass Lead' as 'Record Type',
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
	o.Name as 'Owner', 
	m.Name as 'Manager',
    mm.Name as 'Manager\'s Manager',
	i.Name as 'Industry', 
	null as 'Industry Vertical',
	l.Program__c,
	l.IsConverted,
	if(opp.StageName = 'Closed Won',1,0) as 'HasGeneratedOpportunityWon',
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
	and (l.CreatedDate >= least(@period_1_start, @period_2_start) ) 
)
union all
(select 
	if(rt.Name in ('CMPL - APAC - Lead Record Type'), 'Risk', if(rt.Name in ('IS - APAC - Lead - Marketing','PUB - APAC - Lead - General','PUB - APAC - Lead - Newsletters', 'Compliance Asia Pacific Lead Record Type'), 'Knowledge', if(rt.Name in ('TIS APAC Lead Record Type'), 'Learning', '?'))) as 'Product Portfolio', 
	rt.Name as 'Record Type', 
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
	o.Name as 'Owner', 
	m.Name as 'Manager',
	mm.Name as 'Manager\'s Manager',
    l.Industry as 'Industry',
	l.Industry_Vertical__c as 'Industry Vertical', 
	l.Program__c as 'Program',
	l.IsConverted,
	#if(opp.Id is not null,
	#	if(opp.Stages__c like '%Won%',1,0),
	#	if(l.IsConverted,
	#		if(rt.Name = 'TIS APAC Lead Record Type',1,
	#			if(group_concat(opp_acc.Stages__c) like '%Won%',1,0)
	#		),
	#		0
	#	)
	#) as 'HasGeneratedOpportunityWon',
    if(opp.Stages__c like '%Won%',1,
		if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,1,0)
    ) as 'HasGeneratedOpportunityWon',
	l.ConvertedDate,
	#ifnull(
	#	if(opp.Id is not null,
	#		if(opp.Stages__c like '%Won%',opp.CloseDate,''),
	#			if(l.IsConverted,
	#				if(rt.Name = 'TIS APAC Lead Record Type',l.ConvertedDate,
	#					if(group_concat(opp_acc.Stages__c) like '%Won%',min(if(opp_acc.Stages__c like '%Won%', opp_acc.CloseDate,null)),'')
	#			),
	#		''
	#	)
	#),'') as 'Closed Won Date',
    if(opp.Stages__c like '%Won%',opp.CloseDate,
		ifnull(min(if(rt.Name = 'TIS APAC Lead Record Type' and r.Id is not null,r.CreatedDate ,null)),'')
    ) as 'Closed Won Date',
	#timestampdiff(day, l.ConvertedDate, 
	#	if(opp.Id is not null,
	#		if(opp.Stages__c like '%Won%',opp.CloseDate,null),
	#		if(l.IsConverted,
	#			if(rt.Name = 'TIS APAC Lead Record Type',l.ConvertedDate,
	#				if(group_concat(opp_acc.Stages__c) like '%Won%',min(if(opp_acc.Stages__c like '%Won%', opp_acc.CloseDate,null)),null)
	#			),
	#			null
	#		)
	#	)
	#) as 'Converted To Won Days',
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
	#left join training.account acc on acc.Id = l.ConvertedAccountId
	#left join training.opportunity opp_acc on opp_acc.AccountId = acc.Id    
where 
	l.IsDeleted = 0 
	and (l.CreatedDate >= least(@period_1_start, @period_2_start) )
	and rt.Name in ('CMPL - APAC - Lead Record Type', 'Compliance Asia Pacific Lead Record Type', 'IS - APAC - Lead - Marketing', 'PUB - APAC - Lead - General', 'PUB - APAC - Lead - Newsletters','TIS APAC Lead Record Type')
group by l.Id
);