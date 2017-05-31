# Auditors individual rates
#drop table analytics.`auditor_rates_2`;
CREATE TABLE analytics.`auditor_rates_2` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Resource Id` varchar(18) DEFAULT NULL,
  `period` date NOT NULL,
  `value` decimal(16,6) NOT NULL,
  `currency_iso_code` varchar(3) NOT NULL,
  `type` enum('Average','Actual') NOT NULL DEFAULT 'Average',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=276 DEFAULT CHARSET=utf8;

#Tesco Auditors Rates
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IA34AAG', '2015-01-01',35,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IA2uAAG', '2015-01-01',23.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002GD3RAAW', '2015-01-01',43.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHVuAAO', '2015-01-01',21.25,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000003Z7OQAA0', '2015-01-01',62.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000003Z7MNAA0', '2015-01-01',62.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002GD3XAAW', '2015-01-01',62.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000005YBPhAAO', '2015-01-01',56.25,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000005YBM4AAO', '2015-01-01',62.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002GD38AAG', '2015-01-01',78.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002HMLnAAO', '2015-01-01',62.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004qXtGAAU', '2015-01-01',40,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000005YBNCAA4', '2015-01-01',40,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004rxS3AAI', '2015-01-01',40,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHTPAA4', '2015-01-01',27.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002GD39AAG', '2015-01-01',27.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHUhAAO', '2015-01-01',27.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHRvAAO', '2015-01-01',27.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHSaAAO', '2015-01-01',27.5,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000000hAzZAAU', '2015-01-01',50,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002HIUaAAO', '2015-01-01',14,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000002IHPyAAO', '2015-01-01',14,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000000w1WkAAI', '2015-01-01',14,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000000w1WaAAI', '2015-01-01',22.625,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000005YlQqAAK', '2015-01-01',79.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004s2P6AAI', '2015-01-01',79.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004rxhLAAQ', '2015-01-01',79.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000005Yg1GAAS', '2015-01-01',79.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004s2O3AAI', '2015-01-01',59.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004s2OhAAI', '2015-01-01',55.75,'EUR','Actual');
insert into analytics.auditor_rates_2 values (null,'a0nd0000004rn64AAA', '2015-01-01',59.75,'EUR','Actual');

# Average Auditors Rates
insert into analytics.auditor_rates_2
(select 
null, r.Id, '1970-01-01',avg(ar.value),ar.currency_iso_code,'Average'
#ar.country, ar.business_line, ar.resource_type, 
#avg(ar.value) as 'Avg Hourly Rate', ar.currency_iso_code,
#r.Id, r.Name, r.Reporting_Business_Units__c, r.Job_Family__c, r.Resource_Type__c,
#ccs.Name
from salesforce.resource__c r 
inner join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
inner join `analytics`.`auditor_rates` ar on 
	ar.resource_type = r.Resource_Type__c 
    and if(ar.country='Australia',if(r.Reporting_Business_Units__c like '%Food%', 'Agri-Food', 'Management Systems'),'All')=ar.business_line 
    and ar.country = ccs.Name
where 
r.IsDeleted = 0
#and r.Reporting_Business_Units__c like 'AUS%' 
and r.Reporting_Business_Units__c not like '%Product%'
and r.Job_Family__c like '%Audit%'
group by r.Id);
