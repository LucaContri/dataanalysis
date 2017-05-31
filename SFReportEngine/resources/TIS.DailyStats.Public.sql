use training;

(select * from 
	((select 
		t.`Date` as 'Class_Begin_Date__c', 
        t.`Date` as 'Class_End_Date__c', 
        sum(t.Amount) as 'Amount', t.CreatedDate, t.Id, t.Name, t.Coles_Brand_Employee__c, t.NZ_AFS__c from (
			select 
				date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
                i.Total_Amount__c/1.1 as 'Amount',
                r.CreatedDate, i.Id, i.Name, r.Coles_Brand_Employee__c, r.NZ_AFS__c
			from registration__c r 
            inner join invoice_ent__c i ON i.Registration__c = r.Id 
            left join invoice_ent__history ih on ih.ParentId = i.id 
            where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
            and i.Bill_Type__c = 'ADF' 
            #and r.NZ_AFS__c = 0 
            #and r.Coles_Brand_Employee__c = 0 
            and r.Error__c = 0 
            and r.Status__c not in ('Pending') 
            and i.Processed__c = 1 
            and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
            group by i.Id) t 
		where t.`Date`>= '2015-07-01' 
        and t.`Date`<= '2016-06-30' 
        and t.`Amount` is not null 
        group by t.Id, t.`Date` order by t.`Date`) 
	union 
    (select 
    t.`Date` as 'Class_Begin_Date__c', 
    t.`Date` as 'Class_End_Date__c', 
    sum(t.Amount) as 'Amount',
    t.CreatedDate, t.Id, t.Name, t.Coles_Brand_Employee__c, t.NZ_AFS__c  from 
		( select 
			date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
			if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
			if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
			if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount',
            r.CreatedDate, i.Id, i.Name, r.Coles_Brand_Employee__c, r.NZ_AFS__c
		from registration__c r 
        inner join invoice_ent__c i ON i.Registration__c = r.Id 
        left join invoice_ent__history ih on ih.ParentId = i.id 
        where 
			(r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
            and i.Bill_Type__c not in ('ADF') 
            #and r.NZ_AFS__c = 0 
            #and r.Coles_Brand_Employee__c = 0 
            and r.Error__c = 0 
            and r.Status__c not in ('Pending') 
            and i.Processed__c = 1 
            and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) 
		group by i.Id) t 
	where t.`Date`>= '2015-07-01' 
    and t.`Date`<= '2016-06-30' 
    and (t.`Date` >= t.Class_Begin_Date__c or t.Class_Begin_Date__c is null) 
    and t.`Amount` is not null 
    group by t.Id, t.`Date` 
    order by t.`Date`) 
	union 
    (select 
		t.Class_Begin_Date__c, 
        t.Class_End_Date__c, 
        sum(t.Amount) as 'Amount',
        t.CreatedDate, t.Id, t.Name, t.Coles_Brand_Employee__c, t.NZ_AFS__c 
	from ( 
		select 
			date_format(date_add(max(if(ih.Field='Processed__c' and ih.NewValue='true', ih.CreatedDate, i.CreatedDate)), INTERVAL 10 HOUR), '%Y-%m-%d') as 'Date', 
            if(i.From_Date__c is null, r.Class_Begin_Date__c, i.From_Date__c ) as 'Class_Begin_Date__c', 
            if(i.To_Date__c is null, r.Class_End_Date__c, i.To_Date__c) as 'Class_End_Date__c', 
            if(i.GST_Exempt__c, i.Total_Amount__c, i.Total_Amount__c/1.1) as 'Amount',
            r.CreatedDate, i.Id, i.Name, r.Coles_Brand_Employee__c, r.NZ_AFS__c
		from registration__c r 
        inner join invoice_ent__c i ON i.Registration__c = r.Id 
        left join invoice_ent__history ih on ih.ParentId = i.id 
        where (r.Course_Type__c not in ('eLearning') or i.Accounting__c is null) 
			and i.Bill_Type__c not in ('ADF') 
            #and r.NZ_AFS__c = 0 
            #and r.Coles_Brand_Employee__c = 0 
            and r.Error__c = 0 
            and r.Status__c not in ('Pending') 
            and i.Processed__c = 1 
            and (i.Accounting__c not like ('PRC_HACCP%') or i.Accounting__c is null) group by i.Id) t 
	where 
		t.`Date` < t.Class_Begin_Date__c 
        and t.Class_Begin_Date__c <= '2016-06-30' 
        and t.Class_End_Date__c >= '2015-07-01' 
        and t.`Amount` is not null 
	group by t.Id, t.Class_Begin_Date__c, t.Class_End_Date__c 
    order by t.Class_Begin_Date__c)) t2 
order by t2.Class_Begin_Date__c);