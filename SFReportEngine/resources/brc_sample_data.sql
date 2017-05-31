#explain
select arg.Id, brc.Site_Name, brc.Country, brc.Region, brc.Auditor_First_and_Last_Name, brc.Audit_finish_date, brc.Certificate_Issue_Date, brc.Validation_Date, max(arg.`To`) as 'Compass Completed', max(arg_prc.`To`) as 'Compass PRC Approved', timestampdiff(day,max(arg.`To`), brc.Validation_Date)
from analytics.brc_sample_Data brc
left join analytics.sla_arg_v2 arg_auditor on arg_auditor.`Owner` = brc.Auditor_First_and_Last_Name and arg_auditor.Metric in ('ARG Submission - First', 'ARG Submission - Resubmission') and date_format(arg_auditor.`From`, '%Y-%m-%d') = date_format(brc.Audit_finish_date, '%Y-%m-%d') and arg_auditor.Tags not like '%Follow Up%'
left join analytics.sla_arg_v2 arg_prc on arg_auditor.id = arg_prc.Id and arg_prc.Metric in ('ARG Revision - First', 'ARG Revision - Resubmission')
left join analytics.sla_arg_v2 arg_admin on arg_auditor.id = arg_admin.Id and arg_prc.Metric in ('ARG Completion/Hold')
left join analytics.sla_arg_v2 arg on arg_auditor.id = arg.Id and arg.Metric in ('ARG Process Time (BRC)')
group by brc.brc_sample_data_id;
#a1Wd0000001nSoLEAU
#a1Wd0000001nUGAEA2

select * from analytics.sla_arg_v2 where Id='a1Wd00000028KQIEA2';

use analytics;

show tables;
describe brc_sample_data;
select count(*) from brc_sample_data;