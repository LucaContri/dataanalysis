set @start_period = '2015-07-01';
(select 
ah.Timestamp__c as 'Date Occurred',
date_format(ah.Timestamp__c, '%Y-%m') as 'Period',
date_format(ah.Timestamp__c, '%Y') as 'Year',
prc.Reporting_Business_Units__c  as 'Reviewer Business Unit',
analytics.getBUFromReportingBusinessUnit(prc.Reporting_Business_Units__c) as 'Reviewer Business Unit Country',
analytics.getRegionFromCountry(analytics.getBUFromReportingBusinessUnit(prc.Reporting_Business_Units__c)) as 'Reviewer Business Unit Region',
prc.Name as 'Reviewer',
SUBSTRING_INDEX(SUBSTRING_INDEX(ah.Rejection_Reason__c,';',pos.n),';',-1) as 'Rejection Reason',
arg.Name as 'ARG',
ah.Id as 'Rejection Id',
p.Business_Line__c as 'Business Line',
p.Pathway__c as 'Pathway',
p.Name as 'Program',
s.Name as 'Standard',
a.Reporting_Business_Units__c as 'Auditor Business Unit',
analytics.getBUFromReportingBusinessUnit(a.Reporting_Business_Units__c) as 'Auditor Business Unit Country',
analytics.getRegionFromCountry(analytics.getBUFromReportingBusinessUnit(a.Reporting_Business_Units__c)) as 'Auditor Business Unit Region',
a.Name as 'Auditor'
from salesforce.approval_history__c ah 
inner join (select 1 n union all select 2 union all select 3 union all select 4 union all select 5) pos on (CHAR_LENGTH(ah.Rejection_Reason__c) - CHAR_LENGTH(REPLACE(ah.Rejection_Reason__c, ';', ''))>=(pos.n-1))
inner join salesforce.audit_report_group__c arg on ah.RAudit_Report_Group__c = arg.Id
inner join salesforce.resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join salesforce.resource__c prc on ah.RApprover__c = prc.Id
inner join salesforce.arg_work_item__c argwi on arg.Id = argwi.RAudit_Report_Group__c and argwi.IsDeleted = 0
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
inner join salesforce.standard__c s on sp.Standard__c = s.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
where 
ah.Status__c in ('Rejected')
and ah.Timestamp__c>=@start_period
group by ah.Id, `Rejection Reason`);