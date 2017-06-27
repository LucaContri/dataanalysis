(select 
    site.Client_Number__c as 'Compass site Reference',
    client.Client_Number__c as 'Compass Client Number',
    scsp.External_Site_Code__c as 'NFE Code',
    'TBA' as 'Category',
    s.Name as 'Standard',
    client.Name as 'Producer Name',
    group_concat(
    ifnull(concat(site.Business_Address_1__c, ','),''), 
    ifnull(concat(site.Business_Address_2__c, ','),''),
    ifnull(concat(site.Business_Address_3__c, ','),'')) as 'Address',
    site.Business_City__c as 'City',
    ccs.Name as 'Country',
    site.Business_Zip_Postal_Code__c as 'PostCode',
    cont.name as 'Continent',
    analytics.getregionfromCountry(ccs.Name) as 'SAI Region',
    group_concat(distinct r.Name order by r.Name) as 'Auditor(s)',
    ifnull(c.Code_Description__c, 'TBA') as 'Material Category',
    'TBA' as 'Audit 2017',
    ifnull((select wip.Work_Item_Date__c from salesforce.work_item__c wip where wip.Site_Certification_Standard__c = wi.Site_Certification_Standard__c and wip.Status__c not in ('Cancelled') and wip.IsDeleted = 0 and wip.Work_Item_Date__c < wi.Work_Item_Date__c and wip.Work_Item_Stage__c not in ('Follow Up') order by wip.Work_Item_Date__c desc limit 1),
		(select npa.work_item_Date__c from analytics.nomad_previous_cb_audits npa where npa.site_id = site.Id and npa.work_item_date__c<wi.work_item_date__c order by npa.work_item_date__c desc limit 1) ) as 'Previous Audit',
    '' as 'Comment',
    wi.Name as 'Compass Audit Number',
    wi.Status__c as 'Compass Status',
    if(wi.Status__c in ('Open','Service Change','Initiate Service','Draft', 'Scheduled'),'To Be Booked', 
    if(wi.Status__c in ('Scheduled - Offered'), 'Dates Offered', 
    if(wi.Status__c in ('Confirmed', 'In Progress'), 'Audit Booked',
    if(wi.Status__c in ('Cancelled'), 'Cancelled', 'Completed')))) as 'Nomad Status',
    'TBA' as 'Phase',
    wi.Work_Item_Date__c as 'Audit Date',
    date_add(wi.Work_Item_Date__c, interval 28 day) as '28 Days',
    date_add(wi.Work_Item_Date__c, interval 45 day) as '45 Days',
    year(wi.work_item_date__c ) as 'Year',
    date_format(wi.work_item_date__c, '%Y-%m') as 'Period',
    'TBA' as 'Rating',
    'TBA' as 'Audit Report Sent to Nomad',
	'TBA' as 'Approved / Rejected / Pending'
from salesforce.work_item__c wi
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
    left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id
    left join salesforce.code__c c on scspc.Code__c = c.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    inner join salesforce.account client on site.ParentId = client.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    left join analytics.countries countries on ccs.Name = countries.name
    left join analytics.continents cont on countries.continent_code = cont.code
    left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
    left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.IsDeleted = 0
    left join salesforce.resource__c r on wir.Resource__c = r.Id
where 
	wi.IsDeleted = 0
    and wi.Status__c not in ('Draft','Initiate Service')
    and (s.Name like '%Nomad%' or s.Name like '%NFE%')
    and wi.Work_Item_Stage__c not in ('Follow Up')
    and date_format(wi.Work_Item_Date__c, '%Y-%m') <= date_format(date_add(now(), interval 12 month), '%Y-%m')
group by wi.Id);

# drop temporary table nomad_previous_cb_audits_tmp; 
create temporary table nomad_previous_cb_audits_tmp (
	id int(11) auto_increment,
    client_number varchar(64),
    work_item_date__c datetime,
    primary key (id)
);

#drop table nomad_previous_cb_audits;
create table nomad_previous_cb_audits (
	id int(11) auto_increment,
	site_id varchar(18) not null,
    work_item_date__c datetime,
    primary key (id)
);

insert into nomad_previous_cb_audits 
(select null, site.Id, tmp.work_item_date__c
from analytics.nomad_previous_cb_audits_tmp tmp
left join salesforce.account site on tmp.client_number = site.Client_Number__c
group by tmp.Id);

INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330308','2017-02-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486334','2017-01-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493984','2017-03-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486265','2016-12-21');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486266','2017-03-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491723','2017-01-23');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS452754','2017-01-24');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486274','2017-03-03');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486331','2017-01-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486152','2017-03-02');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS341494','2017-04-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330083','2017-02-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329473','2017-02-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329773','2017-02-09');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330583','2017-01-23');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486158','2017-01-31');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486178','2017-01-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486156','2017-01-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330296','2017-03-03');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486162','2017-03-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS459883','2017-02-14');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486164','2017-02-07');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330891','2017-01-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330501','2017-01-31');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS345448','2017-02-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486166','2016-12-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486322','2016-12-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486168','2016-12-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS343680','2017-01-12');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS343236','2017-01-13');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329277','2016-12-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486170','2017-03-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486263','2017-01-18');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS340043','2017-01-19');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486150','2017-01-18');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS460659','2017-01-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486172','2017-01-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486259','2016-12-09');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS350175','2017-01-17');

INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486400','2016-03-22');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS348549','2016-04-28');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS345079','2016-04-12');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS331458','2016-06-14');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS446247','2016-04-08');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330197','2017-04-01');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492933','2016-11-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495743','2016-05-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS331341','2016-08-03');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492935','2016-01-25');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486483','2016-04-06');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493503','2016-07-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS406958','2016-11-24');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS377768','2016-09-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS344150','2016-11-23');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486487','2016-08-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486489','2016-09-06');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS343559','2016-07-12');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS458495','2016-11-22');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330028','2016-10-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486493','2016-09-08');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486497','2016-08-24');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495818','2016-07-18');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492937','2016-06-06');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495822','2016-05-25');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495881','2017-04-01');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492941','2016-10-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486550','2016-05-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330806','2016-06-09');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS350638','2016-09-01');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329107','2016-04-11');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486555','2016-08-02');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486796','2016-10-05');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486798','2016-01-11');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492943','2016-10-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS484375','2016-02-26');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486800','2016-09-08');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492945','2016-10-18');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492947','2016-06-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495866','2016-09-22');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495868','2016-04-21');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495875','2016-01-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329990','2016-10-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486802','2016-12-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486804','2016-03-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486806','2016-08-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486808','2016-09-28');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS494542','2016-07-18');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486810','2016-09-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493828','2016-10-12');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492922','2016-05-24');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS492924','2016-04-06');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493830','2016-11-14');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS398232','2016-11-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495887','2016-01-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495973','2016-08-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495976','2016-03-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486812','2016-10-10');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486816','2016-04-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS329533','2016-02-02');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS348455','2016-09-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493533','2016-11-25');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493491','2016-11-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486322','2016-12-15');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486818','2016-09-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491115','2016-05-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491117','2016-05-02');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495893','2016-11-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495896','2016-02-29');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS330627','2016-11-10');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493493','2016-06-03');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS345903','2016-09-22');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS341767','2016-09-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS446040','2016-09-28');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS361888','2016-10-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS366618','2016-10-28');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491371','2016-02-24');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495949','2016-04-05');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493806','2016-08-04');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493495','2016-03-30');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491375','2016-10-19');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493826','2016-10-20');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493497','2016-10-21');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495963','2016-04-01');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS494395','2016-11-09');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS339863','2016-07-27');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493808','2016-05-10');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493810','2016-02-17');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS495675','2016-02-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS491377','2016-02-16');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486259','2016-12-09');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS493499','2016-10-05');
INSERT INTO nomad_previous_cb_audits_tmp VALUES(null,'AS486557','2016-08-02');
