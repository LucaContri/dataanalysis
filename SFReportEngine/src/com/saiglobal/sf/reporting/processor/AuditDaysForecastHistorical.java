package com.saiglobal.sf.reporting.processor;

import java.sql.ResultSet;
import java.util.Calendar;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class AuditDaysForecastHistorical {

	public static void main(String[] args) throws Exception {
		GlobalProperties properties = Utility.getProperties();
		DbHelper db = new DbHelper(properties);
		
		Calendar today = Calendar.getInstance();
		Calendar end = Calendar.getInstance();
		today.set(2017, Calendar.JANUARY, 1, 0, 0, 0);
		end.set(2017, Calendar.MARCH, 15, 0, 0, 0);
		boolean header = true;
		while (today.before(end)) {
			ResultSet rs = db.executeSelect(getQuery(today), -1);
			System.out.println(Utility.resultSetToCsv(rs));
			today.add(Calendar.DAY_OF_MONTH, +7);
			header = false;
		}
	}
	
	private static String getQuery(Calendar date) {
		String query = "(select  " +
"	now() as 'Report Date',  " +
"    analytics.getRegionFromCountry(ad.`Country`) as 'Region',  " +
"    ad.`Country`,  " +
"    ad.`Revenue Stream` as 'Stream',  " +
"    replace(ad.`forecast period`,' ', '-') as 'Period',  " +
"    ad.`Available Days`, " +
"    forecast.`Forecast Factor`, " +
"    ad.`Available Days`/forecast.`Forecast Factor` as 'Forecast Calculated' " +
"from  " +
"	(select  " +
"		`Region`,  " +
"		analytics.getCountryFromRevenueOwnership(`Region`) as 'Country',  " +
"		`Revenue Stream`,  " +
"		fp.`forecast period`,  " +
"		sum(Value) as 'Available Days'  " +
"	from salesforce.financial_visisbility,  " +
"		(select date_format(wd.`date`, '%Y %m') as 'forecast period'  " +
"        from salesforce.sf_working_days wd  " +
"        where date between now() and date_add(now(), interval 6 month) group by `forecast period`) fp " +
"	where  " +
"		(analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia') )  " +
"        and `Region` not like '%Product%'  " +
"        and `Period` = fp.`forecast period`   " +
"        and `Audit Status` not in ('Cancelled')  " +
"        and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null) " +
"        and date_format(str_to_date(`Report Date-Time`,'%d/%m/%Y - %T'), '%Y-%m-%d') = now() " +
"group by `Country`, `Revenue Stream`, fp.`forecast period`) as ad " +
"left join " +
"	(select  " +
"		t1.`Country`,  " +
"        t1.`Revenue Stream`,  " +
"        t1.`forecast period`,  " +
"        t1.`Available Days`, " +
"        t2.`Final Confirmed`, " +
"        avg(t1.`Available Days`/t2.`Final Confirmed`) as 'Forecast Factor' from ( " +
"			select  " +
"				analytics.getCountryFromRevenueOwnership(`Region`) as 'Country',  " +
"				`Revenue Stream`,  " +
"                str_to_date(`Report Date-Time`,'%d/%m/%Y - %T') as 'Snapshot Date',  " +
"                fp.`forecast period`,  " +
"                `Period`,  " +
"                sum(Value) as 'Available Days'  " +
"			from salesforce.financial_visisbility, " +
"				(select date_format(wd.`date`, '%Y %m') as 'forecast period' from salesforce.sf_working_days wd where date between now() and date_add(now(), interval 6 month) group by `forecast period`) fp " +
"			where  " +
"				(analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia') )  " +
"                and `Region` not like '%Product%'  " +
"                and `Period` < fp.`forecast period`  " +
"                and `Period` > date_format(date_Add(now(), interval -4 month), '%Y %m')  " +
"                and `Period` < date_format(now(), '%Y %m')  " +
"                and `Audit Status` not in ('Cancelled')  " +
"                and (`Audit Open SubStatus` not in ('Pending Cancellation', 'Pending Suspension') or `Audit Open SubStatus` is null)  " +
"                and datediff(str_to_date(concat(`Period`, ' 01'), '%Y %m %d'), str_to_date(`Report Date-Time`,'%d/%m/%Y - %T')) = datediff(str_to_date(concat(fp.`forecast period`,' 01'), '%Y %m %d'),now())  " +
"                 " +
"			group by `Country`,`Revenue Stream`, `Snapshot Date`, fp.`forecast period`, `Period`  " +
"            order by `Country`,`Revenue Stream`, `Period` ) t1  " +
"		left join (  " +
"			select  " +
"				analytics.getCountryFromRevenueOwnership(`Region`) as 'Country',  " +
"                if(RowName like '%Food%', 'Food', if(RowName like '%Product%', 'PS', 'MS')) as `Revenue Stream`,  " +
"                ColumnName as `Period`,  " +
"                sum(value) as 'Final Confirmed'  " +
"			from salesforce.sf_report_history  " +
"			where  " +
"				ReportName='Audit Days Snapshot'  " +
"                and Date = (select max(Date) from salesforce.sf_report_history where ReportName='Audit Days Snapshot')  " +
"                and `Region` not like '%Product%'  " +
"                and (analytics.getCountryFromRevenueOwnership(`Region`) in ('Australia') )  " +
"                and ColumnName < date_format(now(), '%Y %m')  " +
"                and (RowName not like '%Open%' and RowName not like '%Service Change%' and RowName not like '%Scheduled%' and RowName not like '%Cancelled%')  " +
"			group by `Country`,`Revenue Stream`,`Period`) t2 on t2.`Period` = t1.`Period` and t2.`Country` = t1.`Country` and t2.`Revenue Stream` = t1.`Revenue Stream` " +
"		group by t1.`Country`, t1.`Revenue Stream`, t1.`forecast period`) forecast on ad.Country = forecast.Country and ad.`Revenue Stream` = forecast.`Revenue Stream` and ad.`forecast period`= forecast.`forecast period` " +
"group by ad.`Country`, ad.`Revenue Stream`, ad.`forecast period`);";
	query = query.replace("now()", "'" +Utility.getActivitydateformatter().format(date.getTime()) + "'");
	return query;
	}
}
