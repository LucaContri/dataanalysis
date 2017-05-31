set @fy = (year(utc_timestamp()) + if(month(utc_timestamp())<7, 0,1));
set @date_start = (concat(@fy-1,'-01-01')); # 6 months before start of FY
set @date_end = (concat(@fy,'-12-31')); # 6 months after end of FY

select @fy, @pfy, @date_start, @date_end;

(select
	analytics.getRegionFromCountry(analytics.getBUFromReportingBusinessUnit(i.`Business Unit`)) as 'Region',
	analytics.getBUFromReportingBusinessUnit(i.`Business Unit`) as 'Country',
	i.`Manager`, 
	i.`Name`, 
	i.`Resource Capacitiy (%)` as 'Resource Capacitiy (%)', 
	i.`Period`, 
	j.`Working Days`, 
	i.`TSLI Audit Days`, 
	i.`TSLI Travel Days`, 
    i.`WIR Audit Days`,
    i.`WIR Follow Up Audit Days`,
    i.`WIR Travel Days`,
	i.`BOP Holiday Days`, 
	i.`BOP Leave Days`, 
	if(j.`Working Days`-(i.`BOP Holiday Days`+i.`BOP Leave Days`)=0,null, (i.`WIR Audit Days`+i.`WIR Travel Days`)/((j.`Working Days`-(i.`BOP Holiday Days`+i.`BOP Leave Days`))*i.`Resource Capacitiy (%)`/100)*100) as 'Utilisation %', 
	i.`Other BOPs`,
	i.`Other BOP Types`,
	(j.`Working Days` - i.`WIR Audit Days` - i.`WIR Travel Days` - i.`BOP Holiday Days` - i.`BOP Leave Days` - i.`Other BOPs`) as 'Spare Capacity',
	(j.`Working Days`-(i.`BOP Holiday Days`+i.`BOP Leave Days`))*(i.`Resource Capacitiy (%)`/100) as 'Days Avaialble',
	i.`TSLI Billable` as 'Billable Days',
	i.`TSLI Non Billable` as 'Non Billable Days',
    if(i.`Period`<date_format(utc_timestamp(), '%Y %m'), 1, 0) as 'Past Data'
from  
	(select
		t.Id, 
		t.Name, 
		t.Resource_Capacitiy__c as 'Resource Capacitiy (%)', 
		t.Reporting_Business_Units__c as 'Business Unit', 
		t.Manager, 
		date_format(t.ActivityDate, '%Y %m') AS 'Period', 
		sum(IF(t.source='TSLI' and t.SubType = 'Audit', t.DurationDays, 0)) as 'TSLI Audit Days', 
		sum(IF(t.source='TSLI' and t.SubType = 'Travel', t.DurationDays, 0)) as 'TSLI Travel Days',
        sum(IF(t.source='WIR' and t.SubType = 'Audit', t.DurationDays, 0)) as 'WIR Audit Days',
        sum(IF(t.source='WIR' and t.SubType = 'Audit' and t.`Work Item Type` = 'Follow Up', t.DurationDays, 0)) as 'WIR Follow Up Audit Days',
		sum(IF(t.source='WIR' and t.SubType = 'Travel', t.DurationDays, 0)) as 'WIR Travel Days',
		sum(IF(t.source='BOP' and t.SubType = 'Public Holiday', t.DurationDays, 0)) as 'BOP Holiday Days', 
		sum(IF(t.source='BOP' and t.SubType like 'Leave%', t.DurationDays, 0)) as 'BOP Leave Days', 
		sum(IF(t.source='BOP' and t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.DurationDays,0)) as 'Other BOPs',
		sum(IF(t.source='TSLI' and t.Billable in ('Billable', 'Pre-paid'), t.DurationDays, 0)) as 'TSLI Billable',
		sum(IF(t.source='TSLI' and t.Billable in ('Non-Billable'), t.DurationDays,0)) as 'TSLI Non Billable',
		group_concat(distinct if(t.source='BOP' and t.SubType not like 'Leave%' and t.Subtype not in ('Audit','Travel','Public Holiday'), t.Subtype ,null)) as 'Other BOP Types'
	from
		(select 
			'TSLI' as 'source',
			r.Id, 
			r.Name, 
			r.Resource_Capacitiy__c, 
			r.Resource_Type__c, 
			r.Work_Type__c, 
			r.Reporting_Business_Units__c, 
			m.Name as 'Manager', 
			tsli.Category__c as 'SubType',
            'N/A' as 'Work Item Type',
			tsli.Billable__c as 'Billable',
			tsli.Actual_Hours__c*60 as 'DurationMin', 
			tsli.Actual_Hours__c / 8 as 'DurationDays', 
			tsli.Timesheet_Date__c as 'ActivityDate'
		from salesforce.resource__c r     
			inner join salesforce.user u on u.Id = r.User__c     
			inner join salesforce.user m on u.ManagerId = m.Id
			left join salesforce.timesheet_line_item__c tsli 
				on tsli.Resource_Name__c = r.Name 
                and tsli.IsDeleted = 0 
                and tsli.Timesheet_Date__c between @date_start and @date_end
		where
			r.Resource_Type__c not in ('Client Services')             
			and r.Reporting_Business_Units__c not like '%Product%'
            and r.Resource_Type__c not in ('Client Services')
            and r.Reporting_Business_Units__c not in ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS', 'ASS-CORP')
			and r.Status__c = 'Active'             
			and r.Resource_Type__c = 'Employee'             
			and r.Resource_Capacitiy__c is not null           
			and r.Resource_Capacitiy__c >= 30
		union all
		select
			'BOP' as 'source',
			r.Id, 
			r.Name, 
			r.Resource_Capacitiy__c, 
			r.Resource_Type__c, 
			r.Work_Type__c, 
			r.Reporting_Business_Units__c, 
			m.Name as 'Manager', 
			bop.Resource_Blackout_Type__c as 'SubType',
            'N/A' as 'Work Item Type',
			'N/A' as 'Billable',
			e.DurationInMinutes AS 'DurationMin', 
			e.DurationInMinutes / 60 / 8 AS 'DurationDays', 
			e.ActivityDate 
		from salesforce.resource__c r     
			inner join salesforce.user u on u.Id = r.User__c     
			inner join salesforce.user m on u.ManagerId = m.Id     
			left join salesforce.event e 
				on u.Id = e.OwnerId 
				and e.IsDeleted = 0 
				and e.ActivityDate between @date_start and @date_end
				and e.RecordTypeId = '012900000003IjqAAE' # 'Blackout Period Resource'
			left join salesforce.blackout_period__c bop on bop.Id = e.WhatId and bop.IsDeleted = 0
		where
			r.Resource_Type__c not in ('Client Services')             
			and r.Reporting_Business_Units__c not like '%Product%'
            and r.Resource_Type__c not in ('Client Services')
            and r.Reporting_Business_Units__c not in ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS', 'ASS-CORP')
			and r.Status__c = 'Active'             
			and r.Resource_Type__c = 'Employee'             
			and r.Resource_Capacitiy__c is not null           
			and r.Resource_Capacitiy__c >= 30
		union all
        select
			'WIR' as 'source',
			r.Id, 
			r.Name, 
			r.Resource_Capacitiy__c, 
			r.Resource_Type__c, 
			r.Work_Type__c, 
			r.Reporting_Business_Units__c, 
			m.Name as 'Manager', 
			wir.Work_Item_Type__c as 'SubType',
            wi.Work_Item_Stage__c as 'Work Item Type',
			'N/A' as 'Billable',
			e.DurationInMinutes AS 'DurationMin', 
			e.DurationInMinutes / 60 / 8 AS 'DurationDays', 
			e.ActivityDate 
		from salesforce.resource__c r     
			inner join salesforce.user u on u.Id = r.User__c     
			inner join salesforce.user m on u.ManagerId = m.Id     
			left join salesforce.event e 
				on u.Id = e.OwnerId 
				and e.IsDeleted = 0 
				and e.ActivityDate between @date_start and @date_end
                #and e.RecordTypeId = '012900000003IjuAAE' # 'Work Item Resource'
			left join salesforce.work_item_resource__c wir on wir.Id = e.WhatId and wir.IsDeleted = 0
            left join salesforce.work_item__c wi on wir.Work_Item__c = wi.Id and wi.Status__c not in ('Cancelled') and wi.IsDeleted = 0
		where
			r.Resource_Type__c not in ('Client Services')             
			and r.Reporting_Business_Units__c not like '%Product%'
            and r.Resource_Type__c not in ('Client Services')
            and r.Reporting_Business_Units__c not in ('AUS-CSC' , 'AUS-MGT', 'AUS-OPS', 'ASS-CORP')
			and r.Status__c = 'Active'             
			and r.Resource_Type__c = 'Employee'             
			and r.Resource_Capacitiy__c is not null           
			and r.Resource_Capacitiy__c >= 30
            AND r.Name = 'Pezhman Motlagh'
            AND DATE_FORMAT(e.ActivityDate, '%Y %m') = '2016 05') t  
	group by `Period`, t.Id) i
	inner join
	(select
		date_format(wd.date, '%Y %m') as 'Period', 
		count(wd.date) AS 'Working Days' 
	from salesforce.`sf_working_days` wd 
	where 
		wd.date between @date_start and @date_end
	group by `Period`) j on i.Period = j.Period     
group by Id, i.Period);


select * from salesforce.recordtype where Name = 'Work Item Resource';