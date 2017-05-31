select * from analytics.sla_arg_v2 arg
where arg.`Metric` in ('ARG Submission - Waiting On Client')
and arg.`Region` like 'EMEA%';

(select t.*, 
timestampdiff(second, t.`First Submitted`, t.`First Reviewed`)/3600/24 as 'First Submitted to First Reviewed (Days)',
timestampdiff(second, t.`First Submitted`, t.`CA Approved`)/3600/24 as 'First Submitted to CA Approved (Days)',
ca.Reporting_Business_Units__c as 'CA RBU' from
(select 
	arg.Id, 
    arg.Name, 
    arg.`Business Line`, arg.`Pathway`, arg.`Program`, arg.`Standards`,ifnull(arg.`Standard Families`,'') as 'Standard Family',
    r.Name as 'ARG Author',
    r.Reporting_Business_Units__c as 'ARG Author RBU',
    site.Name as 'Client Site',
    ccs.Name as 'Site Country',
    arg2.`Non_Conformance__c` as 'Non Conformance',
    max(if(arg.`Metric` = 'ARG Revision - First', arg.Owner, null)) as 'CA', 
    #sum(if(arg.`Metric` = 'ARG Submission - Waiting On Client', timestampdiff(second, arg.`From`, arg.`To`)/3600/24,0)) as 'Waiting on Client minor NCR',
    max(if(arg.`Metric` = 'ARG Revision - First', arg.`From`, null)) as 'First Submitted',
    max(if(arg.`Metric` = 'ARG Revision - First', arg.`To`, null)) as 'First Reviewed',
    date_format(max(if(arg.`Metric` = 'ARG Revision - First', arg.`From`, null)), '%Y-%m') as 'First Submitted Period',
    date_format(max(if(arg.`Metric` = 'ARG Revision - First', arg.`To`, null)), '%Y-%m') as 'First Reviewed Period',
    count(distinct ah.Id) as '# Rejections',
    ifnull(group_concat(distinct ah.Rejection_Reason__c separator ';'),'') as 'Rejection Reasons',
    max(if(arg.`Metric` = 'ARG Completion/Hold', arg.`From`, null)) as 'CA Approved',
    date_format(max(if(arg.`Metric` = 'ARG Completion/Hold', arg.`From`, null)), '%Y-%m') as 'CA Approved Period'
from analytics.sla_arg_v2 arg
inner join salesforce.audit_report_group__c arg2 on arg.Id = arg2.Id
inner join salesforce.arg_work_item__c argwi on arg2.Id = argwi.RAudit_Report_Group__c and argwi.IsDeleted = 0
inner join salesforce.work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
inner join salesforce.resource__c r on arg2.RAudit_Report_Author__c = r.Id
left join salesforce.approval_history__c ah on arg.Id = ah.RAudit_Report_Group__c and ah.Status__c in ('Rejected')
where arg.`Metric` in ('ARG Revision - First', 'ARG Revision - Resubmission', 'ARG Completion/Hold')#, 'ARG Submission - Waiting On Client')
and arg.`To` is not null
group by arg.`Id`) t 
left join salesforce.resource__c ca on t.`CA` = ca.Name
where t.`CA Approved` between '2015-10-01' and '2016-11-01'
#and ca.Reporting_Business_Units__c like 'EMEA%'
);