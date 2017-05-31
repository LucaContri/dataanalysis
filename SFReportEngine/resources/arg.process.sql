use salesforce;
select count(*) from salesforce.sf_business_process_details where Name='ARG_TAKEN_NOT_REVIEWED';

drop function salesforce.getARGProcessTags;
DELIMITER //
CREATE FUNCTION salesforce.getARGProcessTags(ClientOwnership TEXT, BusinessLine TEXT, Program TEXT, Standards TEXT, StandardFamily TEXT, BusinessUnit TEXT) RETURNS TEXT
BEGIN
	DECLARE tag TEXT DEFAULT '';
    SET tag = (SELECT CONCAT(tag, IF(BusinessLine like '%Food%', 'Food;',IF(BusinessLine like '%Product%', 'PS;', 'MS;'))));
    SET tag = (SELECT CONCAT(tag, IF(Standards like '%Woolworths%' or Standards like '%WQA%' or StandardFamily like '%Woolworths%' or StandardFamily like '%WQA%', 'Woolworths;','')));
    SET tag = (SELECT CONCAT(tag, IF(Standards not like '%Woolworths%' and Standards not like '%WQA%' and (StandardFamily like '%Woolworths%' or StandardFamily is null) and (StandardFamily like '%WQA%' or StandardFamily is null), 'Not Woolworths;','')));
	RETURN tag;
 END //
DELIMITER ;

# Auditing Operations - WI In Progress and Audit Done (Backlog for activity Submit WI)
CREATE OR REPLACE VIEW `wi_finished_not_submitted` AS
    SELECT 
        'Queue' AS `Type`,
        'WI_FINISHED_NOT_SUBMMITTED' AS `Name`,
        `wi`.`Id` AS `Record Id`,
        `wi`.`Name` AS `Record Name`,
        `wi`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
        group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name)
            SEPARATOR ',') AS `Standard Families`,
        `wi`.`End_Service_Date__c` AS `From`,
        NULL AS `To`,
        (TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS(`wi`.`End_Service_Date__c`)) AS `Duration`,
        'Days' AS `Unit`,
        `r`.`Name` AS `Owner`,
        NULL AS `Executed By`,
        r.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`wi`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            r.Reporting_Business_Units__c) as 'Tags'
    FROM
        (((((`work_item__c` `wi`
        JOIN `site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `resource__c` `r` ON ((`wi`.`Work_Item_Owner__c` = `r`.`Id`)))
        LEFT JOIN `site_certification_standard_family__c` `scsf` ON ((`scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        LEFT JOIN `standard_program__c` `sp` ON ((`scsf`.`Standard_Program__c` = `sp`.`Id`)))
        LEFT JOIN `standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
        LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
        LEFT JOIN program__c p on psp.Program__c = p.Id
    WHERE
        ((`wi`.`IsDeleted` = 0)
            AND (`wi`.`Status__c` = 'In Progress')
            AND (`wi`.`End_Service_Date__c` <= DATE_FORMAT(NOW(), '%Y-%m-%d')))
    GROUP BY `wi`.`Id`;

CREATE OR REPLACE VIEW `wi_submitted_without_arg` AS
    SELECT 
        'Queue' AS `Type`,
        'WI_SUBMITTED_WITHOUT_ARG' AS `Name`,
        `wi`.`Id` AS `Record Id`,
        `wi`.`Name` AS `Record Name`,
        `wi`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
        group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name)
            SEPARATOR ',') AS `Standard Families`,
        DATE_FORMAT(`wih`.`CreatedDate`, '%Y-%m-%d') AS `From`,
        NULL AS `To`,
        (TO_DAYS(NOW()) - TO_DAYS(DATE_FORMAT(`wih`.`CreatedDate`, '%Y-%m-%d'))) AS `Duration`,
        'Days' AS `Unit`,
        `r`.`Name` AS `Owner`,
        NULL AS `Executed By`,
        r.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`wi`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            r.Reporting_Business_Units__c) as 'Tags'
    FROM
        ((((((((`work_item__c` `wi`
        JOIN `site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        JOIN `resource__c` `r` ON ((`wi`.`Work_Item_Owner__c` = `r`.`Id`)))
        LEFT JOIN `resource__c` `a` ON ((`wi`.`RAudit_Report_Author__c` = `a`.`Id`)))
        JOIN `work_item__history` `wih` ON ((`wih`.`ParentId` = `wi`.`Id`)))
        LEFT JOIN `arg_work_item__c` `argwi` ON ((`argwi`.`RWork_Item__c` = `wi`.`Id`)))
        LEFT JOIN `site_certification_standard_family__c` `scsf` ON ((`scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        LEFT JOIN `standard_program__c` `sp` ON ((`scsf`.`Standard_Program__c` = `sp`.`Id`)))
        LEFT JOIN `standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
        LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
        LEFT JOIN program__c p on psp.Program__c = p.Id
    WHERE
        ((`wi`.`IsDeleted` = 0)
            AND (`wi`.`Status__c` = 'Submitted')
            AND ISNULL(`argwi`.`Id`)
            AND (`wih`.`Field` = 'Status__c')
            AND (`wih`.`NewValue` = 'Submitted'))
    GROUP BY `wi`.`Id`;

CREATE OR REPLACE VIEW `WI_SUBMITTED_ARG_PENDING` AS
select
'Queue' AS `Type`,
        'WI_SUBMITTED_ARG_PENDING' AS `Name`,
        `arg`.`Id` AS `Record Id`,
        `arg`.`Name` AS `Record Name`,
        `wi`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
        group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name)  SEPARATOR ',') AS `Standard Families`,
         `arg`.`CreatedDate` AS `From`,
        NULL AS `To`,
        (TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS( max(`arg`.`End_Date__c`))) AS `Duration`,
        'Days' AS `Unit`,
        `a`.`Name` AS `Owner`,
        NULL AS `Executed By`,
        a.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`wi`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.Audit_Report_Status__c = 'Pending'
and wi.Status__c in ('Submitted')
group by arg.Id;

select * from WI_SUBMITTED_ARG_PENDING;

CREATE OR REPLACE VIEW `arg_rejected_to_be_resubmitted` AS
select
'Queue' AS `Type`,
        'ARG_REJECTED_TO_BE_RESUBMITTED' AS `Name`,
        `arg`.`Id` AS `Record Id`,
        `arg`.`Name` AS `Record Name`,
        `wi`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
        group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name)  SEPARATOR ',') AS `Standard Families`,
         max(`argah`.`Timestamp__c`) AS `From`,
        NULL AS `To`,
        (TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS( max(`argah`.`Timestamp__c`))) AS `Duration`,
        'Days' AS `Unit`,
        `a`.`Name` AS `Owner`,
        NULL AS `Executed By`,
        a.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`wi`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            a.Reporting_Business_Units__c) as 'Tags'

from audit_report_group__c arg
left join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.Audit_Report_Status__c = 'Under Review - Rejected'
and argah.Status__c = 'Rejected' and argah.Assigned_To__c is null
group by arg.Id;

select * from arg_rejected_to_be_resubmitted;

# Auditing Operations - WI Submission Activity - Timing
CREATE OR REPLACE VIEW `wi_finished_to_arg_submitted` AS
    SELECT 
        'Performance' AS `Type`,
        'WI_FINISHED_TO_ARG_SUBMMITTED' AS `Name`,
        `arg`.`Id` AS `Record Id`,
        `arg`.`Name` AS `Record Name`,
        `arg`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
		GROUP_CONCAT(DISTINCT `wi`.`Primary_Standard__c` SEPARATOR ',') AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
        MAX(IF((`wir`.`IsDeleted` = 1),
            NULL,
            `wir`.`End_Time__c`)) AS `From`,
        `arg`.`First_Submitted__c` AS `To`,
        GREATEST((TO_DAYS(`arg`.`First_Submitted__c`) - TO_DAYS(MAX(IF((`wir`.`IsDeleted` = 1),
                            NULL,
                            `wir`.`End_Time__c`)))),
                0) AS `Duration`,
        'Days' AS `Unit`,
        `cb`.`Name` AS `Owner`,
        `a`.`Name` AS `Excecuted By`,
        a.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`arg`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            a.Reporting_Business_Units__c) as 'Tags'
    FROM
        (((((((((`audit_report_group__c` `arg`
        JOIN `user` `cb` ON ((`arg`.`OwnerId` = `cb`.`Id`)))
        JOIN `resource__c` `a` ON ((`arg`.`RAudit_Report_Author__c` = `a`.`Id`)))
        JOIN `arg_work_item__c` `argwi` ON ((`argwi`.`RAudit_Report_Group__c` = `arg`.`Id`)))
        JOIN `work_item__c` `wi` ON ((`argwi`.`RWork_Item__c` = `wi`.`Id`)))
        JOIN `work_item_resource__c` `wir` ON ((`wir`.`Work_Item__c` = `wi`.`Id`)))
        JOIN `site_certification_standard_program__c` `scsp` ON ((`wi`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        LEFT JOIN `site_certification_standard_family__c` `scsf` ON ((`scsf`.`Site_Certification_Standard__c` = `scsp`.`Id`)))
        LEFT JOIN `standard_program__c` `sp` ON ((`scsf`.`Standard_Program__c` = `sp`.`Id`)))
        LEFT JOIN `standard__c` `s` ON ((`sp`.`Standard__c` = `s`.`Id`)))
        LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
		LEFT JOIN program__c p on psp.Program__c = p.Id
    WHERE
        ((`arg`.`IsDeleted` = 0)
            AND (`arg`.`First_Submitted__c` >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01'))
            AND (`arg`.`First_Submitted__c` <= DATE_FORMAT(NOW(), '%Y-%m-%d'))
            AND (`arg`.`First_Submitted__c` IS NOT NULL))
    GROUP BY `arg`.`Id`;



# PRC - ARG Submitted (backlog for ARG Taken Activity)
create or replace view arg_submitted_not_taken as 
select
'Queue' AS `Type`,
        'ARG_SUBMITTED_NOT_TAKEN' AS `Name`,
        `arg`.`Id` AS `Record Id`,
        `arg`.`Name` AS `Record Name`,
        `wi`.`Client_Ownership__c` AS `Client Ownership`,
        p.Business_Line__c as 'Business Line',
        p.Name as 'Program',
		group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
        GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name)  SEPARATOR ',') AS `Standard Families`,
        `arg`.`First_Submitted__c` AS `From`,
        NULL AS `To`,
        (TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS(`arg`.`First_Submitted__c`)) AS `Duration`,
        'Days' AS `Unit`,
        `a`.`Name` AS `Owner`,
        NULL AS `Executed By`,
        a.Reporting_Business_Units__c as 'Business Unit',
        getARGProcessTags(
			`wi`.`Client_Ownership__c`,
            p.Business_Line__c,
            p.Name,
			group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
            GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
            a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and arg.Assigned_CA__c is null
and arg.Audit_Report_Status__c = 'Under Review'
group by arg.Id;

select arg.Id, arg.name from audit_report_group__C arg where arg.Audit_Report_Status__c = 'Under Review';

# PRC - ARG Submitted to Approved
create or replace view arg_submitted_to_arg_approved as
select 
'Performance' AS `Type`,
'ARG_SUBMITTED_TO_ARG_APPROVED' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
`arg`.`First_Submitted__c` AS `From`,
max(`argah`.`Timestamp__c`) AS `To`,
(TO_DAYS(DATE_FORMAT(max(`argah`.`Timestamp__c`), '%Y-%m-%d')) - TO_DAYS(`arg`.`First_Submitted__c`)) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
ca.Name AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
inner join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join resource__c ca on argah.RApprover__c = ca.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and argah.Status__c = 'Approved'
and argah.Assigned_To__c = 'Client Administration'
and argah.Timestamp__c >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01')
and argah.Timestamp__c <= DATE_FORMAT(NOW(), '%Y-%m-%d')
group by arg.Id;

create or replace view arg_submitted_to_arg_approved_with_rejections_sub as
select 
'Performance' AS `Type`,
'ARG_SUBMITTED_TO_ARG_APPROVED_WITH_REJECTION' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
`arg`.`First_Submitted__c` AS `From`,
max(if (`argah`.`Status__c` = 'Approved', `argah`.`Timestamp__c`, null)) AS `To`,
(TO_DAYS(DATE_FORMAT(max(if (`argah`.`Status__c` = 'Approved', `argah`.`Timestamp__c`, null)), '%Y-%m-%d')) - TO_DAYS(`arg`.`First_Submitted__c`)) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
ca.Name AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags',
sum(if (`argah`.`Status__c` = 'Rejected',1,0)) as 'Rejections',
sum(if (`argah`.`Status__c` = 'Approved',1,0)) as 'Approvals'
from audit_report_group__c arg
inner join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join resource__c ca on argah.RApprover__c = ca.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and ((argah.Status__c = 'Approved' and argah.Assigned_To__c = 'Client Administration') or (argah.Status__c = 'Rejected'))
and if (`argah`.`Status__c` = 'Approved',argah.Timestamp__c >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01'),1)
and argah.Timestamp__c <= DATE_FORMAT(NOW(), '%Y-%m-%d')
group by arg.Id;

create or replace view arg_submitted_to_arg_approved_with_rejections as 
select t.`Type`, t.`Name`, t.`Record Id`, t.`Record Name`, t.`Client Ownership`, t.`Business Line`, t.`Program`, t.`Standards`, t.`Standard Families`, t.`From`, t.`To`, t.`Duration`, t.`Unit`, t.`Owner`, t.`Executed By`, t.`Business Unit`, t.`Tags`
from arg_submitted_to_arg_approved_with_rejections_sub t where t.Rejections>0 and t.Approvals > 0;

create or replace view arg_submitted_to_arg_approved_with_ta_sub as
select 
'Performance' AS `Type`,
'ARG_SUBMITTED_TO_ARG_APPROVED_WITH_TA' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
`arg`.`First_Submitted__c` AS `From`,
max(if (`argah`.`Status__c` = 'Approved', `argah`.`Timestamp__c`, null)) AS `To`,
(TO_DAYS(DATE_FORMAT(max(if (`argah`.`Status__c` = 'Approved', `argah`.`Timestamp__c`, null)), '%Y-%m-%d')) - TO_DAYS(`arg`.`First_Submitted__c`)) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
ca.Name AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags',
sum(if (`argah`.`Status__c` = 'Requested Technical Review',1,0)) as 'TAs',
sum(if (`argah`.`Status__c` = 'Approved',1,0)) as 'Approvals'
from audit_report_group__c arg
inner join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join resource__c ca on argah.RApprover__c = ca.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and ((argah.Status__c = 'Approved' and argah.Assigned_To__c = 'Client Administration') or (argah.Status__c = 'Requested Technical Review'))
and if (`argah`.`Status__c` = 'Approved',argah.Timestamp__c >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01'),1)
and argah.Timestamp__c <= DATE_FORMAT(NOW(), '%Y-%m-%d')
group by arg.Id;

create or replace view arg_submitted_to_arg_approved_with_ta as 
select t.`Type`, t.`Name`, t.`Record Id`, t.`Record Name`, t.`Client Ownership`, t.`Business Line`, t.`Program`, t.`Standards`, t.`Standard Families`, t.`From`, t.`To`, t.`Duration`, t.`Unit`, t.`Owner`, t.`Executed By`, t.`Business Unit`, t.`Tags`
from arg_submitted_to_arg_approved_with_ta_sub t where t.TAs>0 and t.Approvals > 0;

# PRC - ARG Taken (backlog for ARG Review Activity)
create or replace view arg_taken_not_reviewed as 
select
'Queue' AS `Type`,
'ARG_TAKEN_NOT_REVIEWED' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
max(`argah`.`Timestamp__c`) AS `From`,
NULL AS `To`,
(TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS(max(`argah`.`Timestamp__c`))) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
ca.Name AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
inner join resource__c ca on arg.Assigned_CA__c = ca.Id
left join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and arg.Assigned_CA__c is not null
and arg.Audit_Report_Status__c = 'Under Review'
group by arg.Id;

# Admin - ARG Queue(backlog for ARG Taken Activity)
create or replace view ARG_APPROVED_NOT_ASSIGNED_ADMIN as 
select
'Queue' AS `Type`,
'ARG_APPROVED_NOT_ASSIGNED_ADMIN' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
max(`argah`.`Timestamp__c`) AS `From`,
NULL AS `To`,
(TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS(max(`argah`.`Timestamp__c`))) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
null AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
#inner join resource__c ca on arg.Assigned_Admin__c = ca.Id
left join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and arg.Assigned_Admin__c is null
and arg.Audit_Report_Status__c = 'Support'
and argah.Status__c = 'Approved' and argah.Assigned_To__c = 'Client Administration'
group by arg.Id;

# Admin - ARG Queue(backlog for ARG Complete Activity)
create or replace view ARG_ASSIGNED_ADMIN_NOT_COMPLETED as
select
'Queue' AS `Type`,
'ARG_ASSIGNED_ADMIN_NOT_COMPLETED' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
max(`argah`.`Timestamp__c`) AS `From`,
NULL AS `To`,
(TO_DAYS(DATE_FORMAT(NOW(), '%Y-%m-%d')) - TO_DAYS(max(`argah`.`Timestamp__c`))) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
`ca`.`Name` AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags'
from audit_report_group__c arg
inner join resource__c ca on arg.Assigned_Admin__c = ca.Id
left join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and arg.Assigned_Admin__c is not null
and arg.Audit_Report_Status__c = 'Support'
and argah.Status__c in ('Taken', 'Assigned') and argah.Assigned_To__c = 'Client Administration'
group by arg.Id;

# Admin - ARG Approved to ARG Completed or on Hold
create or replace view ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD_SUB as
select 
'Performance' AS `Type`,
'ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
max(if(`argah`.`Status__c`='Approved' and argah.Assigned_To__c = 'Client Administration', argah.Timestamp__c,null)) AS `From`,
min(if (`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold' , `argah`.`Timestamp__c`, '9999-12-31')) AS `To`,
(TO_DAYS(DATE_FORMAT(min(if (`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold' , `argah`.`Timestamp__c`, '9999-12-31')), '%Y-%m-%d')) - TO_DAYS(max(if(`argah`.`Status__c`='Approved' and argah.Assigned_To__c = 'Client Administration', argah.Timestamp__c,null)))) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
max(if(`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold',ca.Name,'')) AS `Executed By`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags',
sum(if (`argah`.`Status__c` = 'Completed' or argah.Status__c = 'Hold',1,0)) as 'Completed',
argah.Comments__c as 'Comment'
from audit_report_group__c arg
inner join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
left join resource__c ca on argah.RApprover__c = ca.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and ((argah.Status__c = 'Approved' and argah.Assigned_To__c = 'Client Administration') or (argah.Status__c = 'Completed') or (argah.Status__c = 'Hold'))
#and if (`argah`.`Status__c` = 'Completed' or argah.Status__c = 'Hold',argah.CreatedDate >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01'),1)
#and argah.CreatedDate <= DATE_FORMAT(NOW(), '%Y-%m-%d')
and arg.Audit_Report_Status__c not in ('Cancelled')
group by arg.Id;

create or replace view ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD as 
select t.`Type`, t.`Name`, t.`Record Id`, t.`Record Name`, t.`Client Ownership`, t.`Business Line`, t.`Program`, t.`Standards`, t.`Standard Families`, if(t.`From` is null and t.`Comment`='Auto Approved',t.`To`,t.`From`) as 'From', t.`To`, if(t.`From` is null and t.`Comment`='Auto Approved',0,t.`Duration`) as 'Duration', t.`Unit`, t.`Owner`, t.`Executed By`, t.`Business Unit`, t.`Tags`
from ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD_SUB t where t.Completed > 0 and t.`To` >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01');

#wi_finished_to_arg_completed_or_on_hold
create or replace view WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD_SUB as
select 
'Performance' AS `Type`,
'WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD' AS `Name`,
`arg`.`Id` AS `Record Id`,
`arg`.`Name` AS `Record Name`,
`wi`.`Client_Ownership__c` AS `Client Ownership`,
p.Business_Line__c as 'Business Line',
p.Name as 'Program',
group_concat(DISTINCT `wi`.`Primary_Standard__c`) AS `Standards`,
GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ',') AS `Standard Families`,
max(wi.End_Service_Date__c) AS `From`,
min(if (`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold' , `argah`.`Timestamp__c`, '9999-12-31')) AS `To`,
(TO_DAYS(DATE_FORMAT(min(if (`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold' , `argah`.`Timestamp__c`, '9999-12-31')), '%Y-%m-%d')) - TO_DAYS(max(wi.End_Service_Date__c))) AS `Duration`,
'Days' AS `Unit`,
`a`.`Name` AS `Owner`,
a.Reporting_Business_Units__c as 'Business Unit',
getARGProcessTags(
	`wi`.`Client_Ownership__c`,
	p.Business_Line__c,
	p.Name,
	group_concat(DISTINCT `wi`.`Primary_Standard__c`), 
	GROUP_CONCAT(DISTINCT if(scsf.IsDeleted or sp.isDeleted or s.IsDeleted, null,s.Name) SEPARATOR ','),
	a.Reporting_Business_Units__c) as 'Tags',
max(if(`argah`.`Status__c` = 'Completed' or `argah`.`Status__c` = 'Hold',ca.Name,'')) AS `Executed By`,
sum(if (`argah`.`Status__c` = 'Completed' or argah.Status__c = 'Hold',1,0)) as 'Completed',
argah.Comments__c as 'Comment'
from audit_report_group__c arg
inner join Approval_History__c argah on argah.RAudit_Report_Group__c = arg.Id
inner join resource__c a on arg.RAudit_Report_Author__c = a.Id
left join resource__c ca on argah.RApprover__c = ca.Id
inner join arg_work_item__c argwi on argwi.RAudit_Report_Group__c = arg.Id
inner join work_item__c wi on argwi.RWork_Item__c = wi.Id
inner join site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
left join site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id 
left join standard_program__c sp on scsf.Standard_Program__c = sp.Id
left join standard__c s on sp.Standard__c = s.Id
LEFT JOIN standard_program__c psp on scsp.Standard_Program__c = psp.Id
LEFT JOIN program__c p on psp.Program__c = p.Id
where 
arg.IsDeleted = 0
and arg.First_Submitted__c is not null
and ( (argah.Status__c = 'Completed') or (argah.Status__c = 'Hold'))
and arg.Audit_Report_Status__c not in ('Cancelled')
and wi.Work_Package_Type__c not in ('Initial Project','Product Update','Standard Change')
#and arg.Id='a1Wd0000000Mwq7EAC'
group by arg.Id;

create or replace view WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD as 
select t.`Type`, t.`Name`, t.`Record Id`, t.`Record Name`, t.`Client Ownership`, t.`Business Line`, t.`Program`, t.`Standards`, t.`Standard Families`, if(t.`Comment`='Auto Approved',t.`To`,t.`From`) as 'From', t.`To`, if(t.`Comment`='Auto Approved',0,t.`Duration`) as 'Duration', t.`Unit`, t.`Owner`, t.`Executed By`, t.`Business Unit`, t.`Tags`
from WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD_SUB t where t.`To` >= CONCAT(DATE_FORMAT((NOW() + INTERVAL -(6) MONTH), '%Y-%m'),'-01') and t.`From` is not null;

select * from arg_work_item__c where RAudit_Report_Group__c = 'a1Wd0000000A0IlEAK';

# Admin - WI Submitted to ARG Completed or on Hold

select distinct(tags) 
from sf_business_process_details;

select count(*) from sf_business_process_details;
select * from sf_tables where TableNAme='sf_business_process_details';
select Name from sf_business_process_details group by name;
select * from arg_submitted_to_arg_approved_with_rejections;
TRUNCATE sf_business_process_details;
INSERT INTO sf_business_process_details 
select * from wi_finished_not_submitted union 
select * from wi_submitted_without_arg union 
select * from wi_finished_to_arg_submitted where `From` is not null and `To` is not null union 
select * from arg_submitted_not_taken union 
select * from arg_taken_not_reviewed union 
select * from arg_submitted_to_arg_approved where `From` is not null and `To` is not null union 
select * from arg_submitted_to_arg_approved_with_rejections where `From` is not null and `To` is not null union
select * from arg_submitted_to_arg_approved_with_ta where `From` is not null and `To` is not null union 
select * from ARG_APPROVED_NOT_ASSIGNED_ADMIN union
select * from ARG_ASSIGNED_ADMIN_NOT_COMPLETED union
select * from ARG_APPROVED_TO_ARG_COMPLETED_OR_HOLD where `From` is not null and `To` is not null union
select * from arg_rejected_to_be_resubmitted union
select * from WI_FINISHED_TO_ARG_COMPLETED_OR_HOLD where `From` is not null and `To` is not null ;
use salesforce;

select count(*) from sf_business_process_details;