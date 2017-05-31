use enlighten;

show tables;

select vc.Activity_Code, vc.Activity_Name,date_format(vc.Date_Completed, '%Y-%m-%d') as 'Date', sum(vc.Units*60/acs.Units_Per_Hour) as 'mins'
from volume_completion vc 
left join activity_standard acs on acs.Activity_Code = vc.Activity_Code
where acs.Activity_Code='Sched-07'
group by vc.Activity_Code, vc.Activity_Name, `Date`;

select vc.Activity_Code, vc.Activity_Name,date_format(vc.Date_Completed, '%Y-%m-%d') as 'Date', sum(vc.Units) as 'Volume In'
from volume_completion vc 
where vc.Activity_Code='Sched-07'
group by vc.Activity_Code, vc.Activity_Name, `Date`;

describe activity_standard;

SELECT 
	*
FROM
    activity_standard ;
select t2.*, t2.`Forecast mins`-t2.`Actual mins` as 'Var', (t2.`Forecast mins`-t2.`Actual mins`)/t2.`Forecast mins`*100 as 'Var%' from ( 
select t.Org_Chart_Entry, t.Activity_Name, t.Date, sum(t.`Actual mins`) as 'Actual mins', sum(t.`Actual units`) as 'Actual units', sum(t.`Forecast mins`) as 'Forecast mins', sum(t.`Forecast units`) as 'Forecast units', sum(t.`Plan mins`) as 'Plan mins', date_format(t.`Date`, '%Y-%v') as 'Week' from (
select Org_Chart_Entry, acs.Activity_Name, date_add(str_to_date(Week, '%d/%m/%Y'), interval -4 day) as 'Date', 0 as 'Actual mins', 0 as 'Actual units', Volume_In_Mon *60/acs.Units_Per_Hour as 'Forecast mins', Volume_In_Mon as 'Forecast units', 0 as 'Plan mins' from forecast_volume_in fvi left join activity_standard acs on acs.Activity_Code = SUBSTR(Activity, LOCATE('(', Activity)+1, (CHAR_LENGTH(Activity) - LOCATE(')',REVERSE(Activity)) - LOCATE('(', Activity)))
union
select Org_Chart_Entry, acs.Activity_Name , date_add(str_to_date(Week, '%d/%m/%Y'), interval -3 day) as 'Date', 0 as 'Actual mins', 0 as 'Actual units', Volume_In_Tue *60/acs.Units_Per_Hour as 'mins', Volume_In_Mon as 'Units', 0 as 'Plan mins' from forecast_volume_in fvi left join activity_standard acs on acs.Activity_Code = SUBSTR(Activity, LOCATE('(', Activity)+1, (CHAR_LENGTH(Activity) - LOCATE(')',REVERSE(Activity)) - LOCATE('(', Activity)))
union
select Org_Chart_Entry, acs.Activity_Name , date_add(str_to_date(Week, '%d/%m/%Y'), interval -2 day) as 'Date', 0 as 'Actual mins', 0 as 'Actual units', Volume_In_Wed *60/acs.Units_Per_Hour as 'mins', Volume_In_Mon as 'Units', 0 as 'Plan mins' from forecast_volume_in fvi left join activity_standard acs on acs.Activity_Code = SUBSTR(Activity, LOCATE('(', Activity)+1, (CHAR_LENGTH(Activity) - LOCATE(')',REVERSE(Activity)) - LOCATE('(', Activity)))
union
select Org_Chart_Entry, acs.Activity_Name , date_add(str_to_date(Week, '%d/%m/%Y'), interval -1 day) as 'Date', 0 as 'Actual mins', 0 as 'Actual units', Volume_In_Thu *60/acs.Units_Per_Hour as 'mins', Volume_In_Mon as 'Units', 0 as 'Plan mins' from forecast_volume_in fvi left join activity_standard acs on acs.Activity_Code = SUBSTR(Activity, LOCATE('(', Activity)+1, (CHAR_LENGTH(Activity) - LOCATE(')',REVERSE(Activity)) - LOCATE('(', Activity)))
union
select Org_Chart_Entry, acs.Activity_Name , date_add(str_to_date(Week, '%d/%m/%Y'), interval -0 day) as 'Date', 0 as 'Actual mins', 0 as 'Actual units', Volume_In_Fri *60/acs.Units_Per_Hour as 'mins', Volume_In_Mon as 'Units', 0 as 'Plan mins' from forecast_volume_in fvi left join activity_standard acs on acs.Activity_Code = SUBSTR(Activity, LOCATE('(', Activity)+1, (CHAR_LENGTH(Activity) - LOCATE(')',REVERSE(Activity)) - LOCATE('(', Activity)))
union
select vi.Org_Chart_Entry, vi.Activity_Name, date_format(vi.Volume_In_Date, '%Y-%m-%d') as 'Date', sum(vi.Units*60/acs.Units_Per_Hour) as 'Actual mins', sum(vi.Units) as 'Actual Units', 0 as 'Forecast mins', 0 as 'Forecast Units', 0 as 'Plan mins'
from volume_in vi
left join activity_standard acs on acs.Activity_Code = vi.Activity_Code
group by vi.Org_Chart_Entry, vi.Activity_Name, `Date`
union 
select Org_Chart_Entry, 'All' as 'Activity Name', date_format(Plan_Date, '%Y-%m-%d') as 'Date', 0 as 'Actual mins', 0 as 'Actual Units', 0 as 'Forecast mins', 0 as 'Forecast Units', sum(Work_In)*60 as 'Plan mins'
from plan
group by Org_Chart_Entry, `Date`) t
group by t.Org_Chart_Entry, t.Activity_Name, t.`Date`) t2
limit 100000;



select Org_Chart_Entry, 'All' as 'Activity Name', date_format(Plan_Date, '%Y-%m-%d') as 'Date', 0 as 'Actual mins', 0 as 'Actual Units', 0 as 'Forecast mins', 0 as 'Forecast Units', sum(Work_In)*60 as 'Plan mins'
from plan
group by Org_Chart_Entry, `Date`;

select vi.Org_Chart_Entry, vi.Activity_Name, date_format(vi.Volume_In_Date, '%Y-%v') as 'Date', acs.Units_Per_Hour, sum(vi.Units*60/acs.Units_Per_Hour) as 'Actual mins', sum(vi.Units) as 'Actual Units', 0 as 'Forecast mins', 0 as 'Forecast Units' 
from volume_in vi
left join activity_standard acs on acs.Activity_Code = vi.Activity_Code
group by vi.Org_Chart_Entry, `Date`;


use Enlighten;


show tables;
select date_format(Date_Completed,'%d/%m/%Y') as 'Date', concat(First_Name, Last_Name) as 'Name', Units from volume_completion where Activity_Code='Sched-07';