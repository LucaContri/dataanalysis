set @period = '2016 05';

(select analytics.getRegionFromCountry(t2.country) as 'Region', t2.`Period`, t2.country, t2.CB, sum(t2.Lost) as 'Lost', sum(t2.Won) as 'Won', t4.`# Sites`, sum(t2.Lost)/t4.`# Sites` as '% Lost', sum(t2.Won)/t4.`# Sites` as '% Won' from
(select * from (
(select date_format(UpdateDateTime, '%Y %m') as 'Period', t.country, t.OldValue as 'CB', count(distinct t.BRCSiteCode) as 'Lost', 0 as 'Won' from
(select brc.BRCSiteCode, brc.companyName, brc.country, brch.OldValue, brch.NewValue, brch.UpdateDateTime 
from analytics.brc_certified_organisations brc
inner join analytics.brc_certified_organisations_history brch on brc.BRCSiteCode = brch.BRCSiteCode
where date_format(UpdateDateTime, '%Y %m') >= '2016' 
and not (brch.OldValue is null and brch.NewValue is null)
group by brc.BRCSiteCode) t
group by `Period`, t.country, t.OldValue)
union
(select date_format(UpdateDateTime, '%Y %m') as 'Period', t.country, t.NewValue as 'CB', 0, count(distinct t.BRCSiteCode) as 'Won' from
(select brc.BRCSiteCode, brc.companyName, brc.country, brch.OldValue, brch.NewValue, brch.UpdateDateTime 
from analytics.brc_certified_organisations brc
inner join analytics.brc_certified_organisations_history brch on brc.BRCSiteCode = brch.BRCSiteCode
where date_format(UpdateDateTime, '%Y %m') >= '2016'
and not (brch.OldValue is null and brch.NewValue is null)
group by brc.BRCSiteCode) t
group by `Period`, t.country, t.NewValue) 
) t3)
t2
left join 
(select Country, CertificationBody, count(distinct BRCSiteCode) as '# Sites' from analytics.brc_certified_organisations where isDeleted = 0 group by Country, CertificationBody) t4 on t2.country = t4.country and t2.CB = t4.CertificationBody
group by t2.`Period`, t2.country, t2.CB);


(select analytics.getRegionFromCountry(t2.country) as 'Region', t2.`Period`, t2.country, t2.CB, sum(t2.Lost) as 'Lost', sum(t2.Won) as 'Won', t4.`# Sites`, sum(t2.Lost)/t4.`# Sites` as '% Lost', sum(t2.Won)/t4.`# Sites` as '% Won' from
(select * from (
(select date_format(UpdateDateTime, '%Y %m') as 'Period', t.country, t.OldValue as 'CB', count(distinct t.Id) as 'Lost', 0 as 'Won' from
(select brc.Id, brc.name, brc.country, brch.OldValue, brch.NewValue, brch.UpdateDateTime 
from analytics.jasanz_certified_organisations brc
inner join analytics.jasanz_certified_organisations_history brch on brc.Id = brch.Id
where date_format(UpdateDateTime, '%Y %m') >= '2016' 
and not (brch.OldValue is null and brch.NewValue is null)
group by brc.Id) t
group by `Period`, t.country, t.OldValue)
union
(select date_format(UpdateDateTime, '%Y %m') as 'Period', t.country, t.NewValue as 'CB', 0, count(distinct t.Id) as 'Won' from
(select brc.Id, brc.name, brc.country, brch.OldValue, brch.NewValue, brch.UpdateDateTime 
from analytics.jasanz_certified_organisations brc
inner join analytics.jasanz_certified_organisations_history brch on brc.Id = brch.Id
where date_format(UpdateDateTime, '%Y %m') >= '2016'
and not (brch.OldValue is null and brch.NewValue is null)
group by brc.Id) t
group by `Period`, t.country, t.NewValue) 
) t3)
t2
left join 
(select Country, CertificationBody, count(distinct ID) as '# Sites' from analytics.jasanz_certified_organisations where isDeleted = 0 group by Country, CertificationBody) t4 on t2.country = t4.country and t2.CB = t4.CertificationBody
group by t2.`Period`, t2.country, t2.CB);
