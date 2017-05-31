use salesforce;
create or replace view salesforce.enlighten_prc_emea_wip as
select 
t2.*,
if(t2.`PrimaryStandards` like '%British Quality Assured%' or t2.`PrimaryStandards` like '%Quality British%', 
	'AS EMEA Local Scheme Certification',
	'AS EMEA Technical'
) as 'Team', 
if(t2.ProgramBusinessLines like '%Food%' or t2.`PrimaryStandards` like '%BRC%',
	if (t2.Rejections > 0,
		'EMEA Tech-57 Review Rejected ARG Food',
        if(t2.`PrimaryStandards` like '%ASDA%',
			if(t2.WorkItemTypes like '%Follow Up%',
				'EMEA Tech-70 Second Party Audit Report Follow Up',
                'EMEA Tech-69 Second Party Audit Report Review'
			),
			if(t2.WorkItemTypes like '%Follow Up%',
				'EMEA Tech-58 ARG Follow Up (Food)',
				if(t2.`PrimaryStandards` like '%BRC%' or t2.`PrimaryStandards` like '%IFS%',
					if (t2.`PrimaryStandards` like '%IOP%' or t2.`PrimaryStandards` like '%Agents and Brokers%',
						'EMEA Tech-44 ARG Review - BRC, IOP, A&B',
						if(t2.`PrimaryStandards` like '%Storage & Distribution%',
							'EMEA Tech-50 ARG Review - BRC S&D',
							'EMEA Tech-51 ARG Review - BRC, Food, IFS'
						)
					),
					if (t2.`PrimaryStandards` like '%22000%',
						'EMEA Tech-52 ARG Review - Food, FFSC, 22000',
						if(t2.`PrimaryStandards` like '%British Quality Assured%' or t2.`PrimaryStandards` like '%Quality British%', 
							'ASEMSch Cert 23 Review & Certify AR',
							'Not Mapped'
						)
					)
				)
			)
		)
    ),
    if (t2.Rejections > 0,
		'EMEA Tech-56 Review Rejected ARG Mts Systems',
        'EMEA Tech-53 ARG Review - 9001, 14001, 18001'
	)
) as 'Activity',
count(t2.ARG_Id) as 'WIP',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(t2.ARG_Name) as 'ARG Names'
from salesforce.enlighten_wip_sub_2 t2
where 
t2.RevenueOwnerships like 'EMEA%'
and (t2.`PrimaryStandards` not like '%WQA%'
	and t2.`PrimaryStandards` not like '%Woolworths%'
	and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
	and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by 
t2.ARG_Id
union
select 
t3.*,
'AS EMEA Technical ' as 'Team', 
if(t3.`PrimaryStandards` like '%BRC%' or t3.`PrimaryStandards` like '%IFS%',
	if (t3.`PrimaryStandards` like '%IOP%' or t3.`PrimaryStandards` like '%Agents and Brokers%',
		'EMEA Tech-44 ARG Review - BRC, IOP, A&B',
		if(t3.`PrimaryStandards` like '%Storage & Distribution%',
			'EMEA Tech-50 ARG Review - BRC S&D',
			'EMEA Tech-51	ARG Review - BRC, Food, IFS'
		)
	),
	if (t3.`PrimaryStandards` like '%22000%',
		'EMEA Tech-52 ARG Review - Food, FFSC, 22000',
		'Not Mapped'
	)
) as 'Activity',
count(t3.ARG_Id) as 'WIP',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(t3.ARG_Name) as 'ARG Names'
from salesforce.enlighten_wip_sub_2 t3
where 
t3.RevenueOwnerships like 'EMEA%'
and t3.ProgramBusinessLines like '%Food%'
and t3.WorkItemTypes like '%Follow Up%'
and t3.WorkItemsNo > 1
and t3.Rejections = 0
and (t3.`PrimaryStandards` like '%BRC%' or t3.`PrimaryStandards` like '%IFS%' or t3.`PrimaryStandards` like '%22000%')
group by t3.ARG_Id;

select epw.`Team`, '' as 'User', epw.`Activity`, sum(epw.`WIP`) as 'WIP', epw.`Date/Time`, group_concat(distinct epw.`ARG Names`) as 'Notes'
from salesforce.enlighten_prc_emea_wip epw 
group by epw.`Team`, epw.`Activity`;

select * from salesforce.enlighten_prc_emea_wip;
select * from salesforce.standard__c where Name like '%West Country Beef%';

create or replace view salesforce.enlighten_prc_emea_activity as
select 
t2.*,
if(t2.`PrimaryStandards` like '%British Quality Assured%' or t2.`PrimaryStandards` like '%Quality British%' or t2.`PrimaryStandards` like '%Catering Butchers%' or t2.`PrimaryStandards` like '%West Country Beef%', 
	'AS EMEA Local Scheme Certification',
	'AS EMEA Technical'
) as 'Team',
t2.`ActionedBy` as 'User',
if(t2.ProgramBusinessLines like '%Food%' or t2.`PrimaryStandards` like '%BRC%', # BRC Packaging and BRC Transport are erroneously categorised with Business Line = Management Systems
	if (t2.Rejections > 0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`),
		'EMEA Tech-57 Review Rejected ARG Food',
        if(t2.`PrimaryStandards` like '%ASDA%',
			if(t2.WorkItemTypes like '%Follow Up%',
				'EMEA Tech-70 Second Party Audit Report Follow Up',
                'EMEA Tech-69 Second Party Audit Report Review'
			),
			if(t2.WorkItemTypes like '%Follow Up%',
				'EMEA Tech-58 ARG Follow Up (Food)',
				if(t2.`PrimaryStandards` like '%BRC%' or t2.`PrimaryStandards` like '%IFS%',
					if (t2.`PrimaryStandards` like '%IOP%' or t2.`PrimaryStandards` like '%Agents and Brokers%',
						'EMEA Tech-44 ARG Review - BRC, IOP, A&B',
						if(t2.`PrimaryStandards` like '%Storage & Distribution%',
							'EMEA Tech-50 ARG Review - BRC S&D',
							'EMEA Tech-51 ARG Review - BRC, Food, IFS'
						)
					),
					if (t2.`PrimaryStandards` like '%22000%',
						'EMEA Tech-52 ARG Review - Food, FFSC, 22000',
						if(t2.`PrimaryStandards` like '%British Quality Assured%' or t2.`PrimaryStandards` like '%Quality British%' or t2.`PrimaryStandards` like '%Catering Butchers%' or t2.`PrimaryStandards` like '%West Country Beef%', 
							'ASEMSch Cert 23 Review & Certify AR',
							'Not Mapped'
						)
					)
				)
			)
		)
    ),
    if (t2.Rejections > 0 and not(t2.`First_Rejected`=t2.`ActionDate/Time`),
		'EMEA Tech-56 Review Rejected ARG Mts Systems',
        'EMEA Tech-53 ARG Review - 9001, 14001, 18001'
	)
) as 'Activity',
count(t2.ARG_Id) as 'Completed',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(t2.ARG_Name) as 'ARG Names'
from salesforce.enlighten_prc_activity_sub2 t2
where 
t2.`Action` in ('Approved','Rejected') and
t2.Reporting_Business_Units__c like 'EMEA%' and
(t2.`PrimaryStandards` not like '%WQA%'
	and t2.`PrimaryStandards` not like '%Woolworths%'
	and (t2.`Standard Families` not like '%WQA%' or t2.`Standard Families` is null)
	and (t2.`Standard Families` not like '%Woolworths%' or t2.`Standard Families` is null))
group by 
t2.`ARG_Id`, t2.`ActionDate/Time`
union
select 
t3.*,
'AS EMEA Technical ' as 'Team', 
t3.`ActionedBy` as 'User',
if(t3.`PrimaryStandards` like '%BRC%' or t3.`PrimaryStandards` like '%IFS%',
	if (t3.`PrimaryStandards` like '%IOP%' or t3.`PrimaryStandards` like '%Agents and Brokers%',
		'EMEA Tech-44 ARG Review - BRC, IOP, A&B',
		if(t3.`PrimaryStandards` like '%Storage & Distribution%',
			'EMEA Tech-50 ARG Review - BRC S&D',
			'EMEA Tech-51	ARG Review - BRC, Food, IFS'
		)
	),
	if (t3.`PrimaryStandards` like '%22000%',
		'EMEA Tech-52 ARG Review - Food, FFSC, 22000',
		'Not Mapped'
	)
) as 'Activity',
count(t3.ARG_Id) as 'WIP',
date_format(now(), '%d/%m/%Y') as 'Date/Time',
group_concat(t3.ARG_Name) as 'ARG Names'
from salesforce.enlighten_prc_activity_sub2 t3
where 
t3.`Action` in ('Approved','Rejected') and
t3.Reporting_Business_Units__c like 'EMEA%'
and t3.ProgramBusinessLines like '%Food%'
and t3.WorkItemTypes like '%Follow Up%'
and t3.WorkItemsNo > 1
and t3.Rejections = 0
and (t3.`PrimaryStandards` like '%BRC%' or t3.`PrimaryStandards` like '%IFS%' or t3.`PrimaryStandards` like '%22000%')
group by t3.ARG_Id, t3.`ActionDate/Time`; 

select * from salesforce.enlighten_prc_emea_activity where `User` = 'Liz Narborough';

select epa.`Team`, epa.`User`, epa.`Activity`, sum(epa.`Completed`) as 'Completed', epa.`Date/Time`, group_concat(distinct epa.`ARG Names`) as 'Notes' 
from salesforce.enlighten_prc_emea_activity epa 
group by epa.`Team`, epa.`User`, epa.`Activity`, epa.`Date/Time`;

select s.Id, s.Name, p.Business_Line__c
from salesforce.standard__c s 
inner join salesforce.program__c p on s.Program__c = p.Id
where s.Name like '%BRC%';