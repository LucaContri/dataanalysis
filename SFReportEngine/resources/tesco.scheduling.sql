# Resource Competencies
(select r.Id as 'Resource Id', r.Name as 'Resource', ccs.Name as 'Country', r.Home_City__c as 'City', r.Resource_Type__c as 'Resource Type', s.Name as 'Standard', rc.Rank__c as 'Rank', c1.Name as 'Code', r.Job_Family__c, rc.Standard_or_Code__c
from salesforce.resource__c r
inner join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
inner join salesforce.resource_competency__c rc on rc.Resource__c = r.Id
inner join salesforce.standard__c s on rc.Standard__c = s.Id
inner join salesforce.standard_code__c sc on sc.Standard__c = s.Id
inner join salesforce.code__c c on sc.Code_Type__c = c.Type__c
left join salesforce.resource_competency__c rcc on rcc.Code__c = c.Id and rcc.Resource__c = r.Id and rcc.Status__c = 'Active'
left join salesforce.code__c c1 on rcc.Code__c = c1.Id
where (s.NAme like 'Tesco Food Manufacturing Standard%' or s.Name like 'Tesco Produce Packhouse Standard%')
and rc.Status__c = 'Active'
group by r.Id, s.Id, c1.Id);

select c.Id, c.Name, c.Code_Description__c
from salesforce.resource_competency__c  rc
inner join salesforce.code__c c on rc.Code__c = c.Id
where c.Type__c='TFMS' 
and c.Name in ('TFMS: CAT-1', 'TFMS: CAT-7', 'TFMS: CAT-7a', 'TFMS: CAT-9', 'TFMS: CAT-9b', 'TFMS: CAT-10', 'TFMS: CAT-16') 
and rc.Id in ('fake_resource_0001', 'fake_resource_0002', 'fake_resource_0003');

# Updating Resource
update salesforce.resource__c r set Home_City__c = 'Pontevedra' where r.Name = 'Yobana Bermudez' and Id='a0nd00000065otnAAA';

update salesforce.resource__c r set Home_City__c = 'Pordenone' where r.Name = 'Enrico Girotto' and r.Id='a0nd0000005YBNCAA4';
update salesforce.resource__c r set Home_City__c = 'Torino' where r.Name = 'Giulia Bughi Peruglia' and r.Id='a0nd0000004rxS3AAI';

update salesforce.resource__c r set Home_City__c = 'Kwidzyn' where r.Name = 'Beata Biezunska' and r.Id='a0nd0000002GD39AAG';
update salesforce.resource__c r set Home_City__c = 'Ketsch' where r.Name = 'Franz Gropp' and r.Id='a0nd0000002HMLnAAO';
update salesforce.resource__c r set Home_City__c = 'Andrychow' where r.Name = 'Joanna Rylko' and r.Id='a0nd0000002IHU8AAO';
update salesforce.resource__c r set Home_City__c = 'Prague' where r.Name = 'Renata Chramostova' and r.Id='a0nd0000002IHVuAAO';
update salesforce.resource__c r set Home_City__c = 'Olsztyn' where r.Name = 'Tatiana Wiktorowicz' and r.Id='a0nd0000002IHUhAAO';
update salesforce.resource__c r set Home_City__c = 'Gdansk' where r.Name = 'Wojciech Kowalczyk' and r.Id='a0nd0000002IHRvAAO';

update salesforce.resource__c r set Home_City__c = 'Floirac' where r.Name = 'Daniela Da Silva' and r.Id='a0nd0000003Z7MNAA0';
update salesforce.resource__c r set Home_City__c = 'Paris' where r.Name = 'Taghrid Paresys' and r.Id='a0nd0000002GD3XAAW';
update salesforce.resource__c r set Home_City__c = 'Bordeaux' where r.Name = 'Bruce Maurice' and r.Id='a0nd0000005YBM4AAO';

select ccs.Name as 'Country', r.Home_City__c, r.Id, r.Name
from salesforce.resource__c r 
inner join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
where r.Name in ('Stefano Stefanucci','Giulia Bughi Peruglia','Giulio Milan');


#delete from salesforce.resource__c where Id in ('fake_resource_0001', 'fake_resource_0002', 'fake_resource_0003');

# New Resources for Spain
INSERT INTO `salesforce`.`resource__c`
(`Id`,`OwnerId`,`Name`,`CreatedDate`,`LastModifiedDate`,`Home_City__c`,`Home_Country1__c`,`Resource_Type__c`, `Reporting_Business_Units__c`, `Job_Family__c`, `Status__c`, `Resource_Capacitiy__c`)
VALUES
('fake_resource_0001','fake_resource_0001','Esther',utc_timestamp(),utc_timestamp(),'Valencia','a0Y90000000CGL5EAO','Contractor', 'EMEA-Spain', '04 – 03 Assessing & Auditing', 'Active', 100);

INSERT INTO `salesforce`.`resource__c`
(`Id`,`OwnerId`,`Name`,`CreatedDate`,`LastModifiedDate`,`Home_City__c`,`Home_Country1__c`,`Resource_Type__c`, `Reporting_Business_Units__c`, `Job_Family__c`, `Status__c`, `Resource_Capacitiy__c`)
VALUES
('fake_resource_0002','fake_resource_0001','Elise',utc_timestamp(),utc_timestamp(),'Madrid','a0Y90000000CGL5EAO','Contractor', 'EMEA-Spain', '04 – 03 Assessing & Auditing', 'Active', 100);

INSERT INTO `salesforce`.`resource__c`
(`Id`,`OwnerId`,`Name`,`CreatedDate`,`LastModifiedDate`,`Home_City__c`,`Home_Country1__c`,`Resource_Type__c`, `Reporting_Business_Units__c`, `Job_Family__c`, `Status__c`, `Resource_Capacitiy__c`)
VALUES
('fake_resource_0003','fake_resource_0001','Maribel',utc_timestamp(),utc_timestamp(),'Valencia','a0Y90000000CGL5EAO','Contractor', 'EMEA-Spain', '04 – 03 Assessing & Auditing', 'Active', 100);

# New Resource Competenticies same as 'Yobana Bermudez'
select 'fake_rescompe_0001',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001',rc.Code__C,'Lead Auditor',rc.Standard__C,rc.Standard_or_Code__c ,rc.Status__c
from salesforce.resource__c r 
inner join salesforce.resource_competency__c rc on r.Id = rc.Resource__c
where 
r.Id='a0nd00000065otnAAA'
and (rc.Standard_or_Code__c like 'Tesco%' or rc.Standard_or_Code__c like 'TFMS%')
and rc.Status__c = 'Active';

#SET SQL_SAFE_UPDATES = 0;
#delete from salesforce.resource_competency__c where Id like 'fake%';
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_1',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MrAAK','Lead Auditor',null,'TFMS: CAT-15','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_2',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001',null,'Lead Auditor','a36d0000000Cz0QAAS','Tesco Produce Packhouse Standard Local - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_3',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001',null,'Lead Auditor','a36d0000000CvZYAA0','Tesco Food Manufacturing Standard Local - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_4',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_5',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MmAAK','Lead Auditor',null,'TFMS: CAT-14','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_6',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LjAAK','Lead Auditor',null,'TFMS: CAT-3a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_7',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LoAAK','Lead Auditor',null,'TFMS: CAT-4','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_8',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LtAAK','Lead Auditor',null,'TFMS: CAT-5','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_9',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001',null,'Lead Auditor','a36d0000000Cz0VAAS','Tesco Produce Packhouse Standard Global - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_10',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LyAAK','Lead Auditor',null,'TFMS: CAT-6','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_11',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001',null,'Lead Auditor','a36d0000000CvZTAA0','Tesco Food Manufacturing Standard Global - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_12',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MDAA0','Lead Auditor',null,'TFMS: CAT-8','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_13',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LeAAK','Lead Auditor',null,'TFMS: CAT-3','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_14',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MIAA0','Lead Auditor',null,'TFMS: CAT-8a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_15',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_16',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MSAA0','Lead Auditor',null,'TFMS: CAT-9a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_17',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5McAAK','Lead Auditor',null,'TFMS: CAT-11','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_18',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MOAA0','Lead Auditor',null,'TFMS: CAT-12','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_19',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MhAAK','Lead Auditor',null,'TFMS: CAT-13','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_20',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5N6AAK','Lead Auditor',null,'TFMS: CAT-18','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_21',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MrAAK','Lead Auditor',null,'TFMS: CAT-15','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_22',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002',null,'Lead Auditor','a36d0000000Cz0QAAS','Tesco Produce Packhouse Standard Local - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_23',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002',null,'Lead Auditor','a36d0000000CvZYAA0','Tesco Food Manufacturing Standard Local - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_24',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_25',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MmAAK','Lead Auditor',null,'TFMS: CAT-14','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_26',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LjAAK','Lead Auditor',null,'TFMS: CAT-3a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_27',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LoAAK','Lead Auditor',null,'TFMS: CAT-4','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_28',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LtAAK','Lead Auditor',null,'TFMS: CAT-5','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_29',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002',null,'Lead Auditor','a36d0000000Cz0VAAS','Tesco Produce Packhouse Standard Global - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_30',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LyAAK','Lead Auditor',null,'TFMS: CAT-6','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_31',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002',null,'Lead Auditor','a36d0000000CvZTAA0','Tesco Food Manufacturing Standard Global - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_32',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MDAA0','Lead Auditor',null,'TFMS: CAT-8','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_33',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LeAAK','Lead Auditor',null,'TFMS: CAT-3','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_34',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MIAA0','Lead Auditor',null,'TFMS: CAT-8a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_35',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_36',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MSAA0','Lead Auditor',null,'TFMS: CAT-9a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_37',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5McAAK','Lead Auditor',null,'TFMS: CAT-11','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_38',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MOAA0','Lead Auditor',null,'TFMS: CAT-12','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_39',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MhAAK','Lead Auditor',null,'TFMS: CAT-13','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_40',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5N6AAK','Lead Auditor',null,'TFMS: CAT-18','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_41',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MrAAK','Lead Auditor',null,'TFMS: CAT-15','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_42',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003',null,'Lead Auditor','a36d0000000Cz0QAAS','Tesco Produce Packhouse Standard Local - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_43',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003',null,'Lead Auditor','a36d0000000CvZYAA0','Tesco Food Manufacturing Standard Local - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_44',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_45',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MmAAK','Lead Auditor',null,'TFMS: CAT-14','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_46',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LjAAK','Lead Auditor',null,'TFMS: CAT-3a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_47',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LoAAK','Lead Auditor',null,'TFMS: CAT-4','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_48',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LtAAK','Lead Auditor',null,'TFMS: CAT-5','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_49',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003',null,'Lead Auditor','a36d0000000Cz0VAAS','Tesco Produce Packhouse Standard Global - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_50',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LyAAK','Lead Auditor',null,'TFMS: CAT-6','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_51',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003',null,'Lead Auditor','a36d0000000CvZTAA0','Tesco Food Manufacturing Standard Global - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_52',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MDAA0','Lead Auditor',null,'TFMS: CAT-8','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_53',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LeAAK','Lead Auditor',null,'TFMS: CAT-3','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_54',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MIAA0','Lead Auditor',null,'TFMS: CAT-8a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_55',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_56',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MSAA0','Lead Auditor',null,'TFMS: CAT-9a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_57',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5McAAK','Lead Auditor',null,'TFMS: CAT-11','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_58',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MOAA0','Lead Auditor',null,'TFMS: CAT-12','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_59',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MhAAK','Lead Auditor',null,'TFMS: CAT-13','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_60',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5N6AAK','Lead Auditor',null,'TFMS: CAT-18','Active');

INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_61',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LPAA0','Lead Auditor','','TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_62',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M3AAK','Lead Auditor','','TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_63',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M4AAK','Lead Auditor','','TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_64',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M8AAK','Lead Auditor','','TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_65',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MNAA0','Lead Auditor','','TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_66',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MwAAK','Lead Auditor','','TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_67',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MXAA0','Lead Auditor','','TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_68',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LPAA0','Lead Auditor','','TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_69',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M3AAK','Lead Auditor','','TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_70',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M4AAK','Lead Auditor','','TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_71',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M8AAK','Lead Auditor','','TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_72',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MNAA0','Lead Auditor','','TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_73',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MwAAK','Lead Auditor','','TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_74',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MXAA0','Lead Auditor','','TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_75',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LPAA0','Lead Auditor','','TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_76',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M3AAK','Lead Auditor','','TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_77',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M4AAK','Lead Auditor','','TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_78',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M8AAK','Lead Auditor','','TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_79',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MNAA0','Lead Auditor','','TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_80',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MwAAK','Lead Auditor','','TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_81',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MXAA0','Lead Auditor','','TFMS: CAT-10','Active');

INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_61',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5LPAA0','Lead Auditor',null,'TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_62',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M3AAK','Lead Auditor',null,'TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_63',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M4AAK','Lead Auditor',null,'TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_64',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5M8AAK','Lead Auditor',null,'TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_65',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_66',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MwAAK','Lead Auditor',null,'TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_67',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0003','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_68',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5LPAA0','Lead Auditor',null,'TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_69',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M3AAK','Lead Auditor',null,'TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_70',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M4AAK','Lead Auditor',null,'TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_71',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5M8AAK','Lead Auditor',null,'TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_72',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_73',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MwAAK','Lead Auditor',null,'TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_74',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0002','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_75',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5LPAA0','Lead Auditor',null,'TFMS: CAT-1','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_76',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M3AAK','Lead Auditor',null,'TFMS: CAT-7','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_77',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M4AAK','Lead Auditor',null,'TFMS: CAT-9b','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_78',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5M8AAK','Lead Auditor',null,'TFMS: CAT-7a','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_79',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MNAA0','Lead Auditor',null,'TFMS: CAT-9','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_80',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MwAAK','Lead Auditor',null,'TFMS: CAT-16','Active');
INSERT INTO `salesforce`.`resource_competency__c` (`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES ('fake_rescompe_81',0,'Fake',utc_timestamp(),utc_timestamp(),'fake_resource_0001','a1sd0000000M5MXAA0','Lead Auditor',null,'TFMS: CAT-10','Active');

INSERT INTO `salesforce`.`resource_competency__c` 
	(`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES 
    ('fake_rescompe_82',0,'Fake',utc_timestamp(),utc_timestamp(),'a0nd0000005YBM4AAO',null,'Lead Auditor','a36d0000000Cz0VAAS','Tesco Produce Packhouse Standard Global - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` 
	(`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES 
    ('fake_rescompe_83',0,'Fake',utc_timestamp(),utc_timestamp(),'a0nd0000005YBM4AAO',null,'Lead Auditor','a36d0000000Cz0QAAS','Tesco Produce Packhouse Standard Local - 2015 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` 
	(`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES 
    ('fake_rescompe_84',0,'Fake',utc_timestamp(),utc_timestamp(),'a0nd0000005YBM4AAO',null,'Lead Auditor','a36d0000000CvZYAA0','Tesco Food Manufacturing Standard Local - Version 6 | Verification','Active');
INSERT INTO `salesforce`.`resource_competency__c` 
	(`Id`,`IsDeleted`,`Name`,`CreatedDate`,`LastModifiedDate`,`Resource__c`,`Code__c`,`Rank__c`,`Standard__c`,`Standard_or_Code__c`,`Status__c`) VALUES 
    ('fake_rescompe_85',0,'Fake',utc_timestamp(),utc_timestamp(),'a0nd0000005YBM4AAO',null,'Lead Auditor','a36d0000000CvZTAA0','Tesco Food Manufacturing Standard Global - Version 6 | Verification','Active');

#select * from salesforce.saig_geocode_cache limit 1;
insert into salesforce.saig_geocode_cache values (null, 'DCOOP, S.COOP.AND. Ctra. Córdoba s/n Apdo. 300 29200 – Antequera Malaga Spain', 37.020001, -4.5593676);
insert into salesforce.saig_geocode_cache values (null, 'Av. Jaume de Codorniu s/n Sant Sadurni d´Anoia Barcelona Spain 8770', 41.4261755, 1.7867506);

(SELECT s.*, 
site.Name as 'Client Site',
wi.Required_Duration__c as 'Audit Duration',
wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country'    ,
r.Reporting_Business_Units__c,
rgeo.Latitude as 'Resource Latitude', 
rgeo.Longitude as 'Resource Longitude',
wigeo.Latitude as 'Site Latitude', 
wigeo.Longitude as 'Site Longitude',
if (r.NAme='Elise', 'small_red',if (r.NAme='Esther', 'small_yellow',if (r.NAme='Christel Kaberghs', 'small_green',if (r.NAme='Maribel', 'small_blue',if (r.NAme='Yobana Bermudez', 'small_purple','small_turquoise'))))) as 'Resource Marker'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache wigeo on concat(
 ifnull(concat(site.Business_Address_1__c ,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c ,' '),''),
 ifnull(concat(sscs.Name,' '),''),
 ifnull(concat(sccs.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = wigeo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache rgeo on concat(r.Home_City__c, ' ', ccs.Name) = rgeo.Address
where BatchId='EMEA Tesco Capacity Planning - 2017' and SubBatchId=8);

(SELECT s.*, 
site.Name as 'Client Site',
wi.Required_Duration__c as 'Audit Duration',
wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country'    ,
r.Reporting_Business_Units__c,
rgeo.Latitude as 'Resource Latitude', 
rgeo.Longitude as 'Resource Longitude',
wigeo.Latitude as 'Site Latitude', 
wigeo.Longitude as 'Site Longitude',
if (r.NAme='Enrico Girotto', 'small_red',if (r.NAme='Giulia Bughi Peruglia', 'small_yellow',if (r.NAme='Giulio Milan', 'small_green',if (r.NAme='Stefano Stefanucci', 'small_blue',if (r.NAme='Yobana Bermudez', 'small_purple','small_turquoise'))))) as 'Resource Marker'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache wigeo on concat(
 ifnull(concat(site.Business_Address_1__c ,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c ,' '),''),
 ifnull(concat(sscs.Name,' '),''),
 ifnull(concat(sccs.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = wigeo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache rgeo on concat(r.Home_City__c, ' ', ccs.Name) = rgeo.Address
where BatchId='EMEA Tesco Italy Capacity Planning - 2017' and SubBatchId=2);

(SELECT s.*, 
site.Name as 'Client Site',
wi.Required_Duration__c as 'Audit Duration',
wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country'    ,
r.Reporting_Business_Units__c,
rgeo.Latitude as 'Resource Latitude', 
rgeo.Longitude as 'Resource Longitude',
wigeo.Latitude as 'Site Latitude', 
wigeo.Longitude as 'Site Longitude',
if (r.NAme='Beata Biezunska', 'small_red',if (r.NAme='Franz Gropp', 'small_yellow',if (r.NAme='Joanna Rylko', 'small_green',if (r.NAme='Renata Chramostova', 'small_blue',if (r.NAme='Tatiana Wiktorowicz', 'small_purple',if (r.NAme='Wojciech Kowalczyk', 'measle_white','small_turquoise')))))) as 'Resource Marker'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache wigeo on concat(
 ifnull(concat(site.Business_Address_1__c ,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c ,' '),''),
 ifnull(concat(sscs.Name,' '),''),
 ifnull(concat(sccs.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = wigeo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache rgeo on concat(r.Home_City__c, ' ', ccs.Name) = rgeo.Address
where BatchId='EMEA Tesco Germany Capacity Planning - 2017' and SubBatchId=1);

(SELECT s.*, 
site.Name as 'Client Site',
wi.Required_Duration__c as 'Audit Duration',
wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country'    ,
r.Reporting_Business_Units__c,
rgeo.Latitude as 'Resource Latitude', 
rgeo.Longitude as 'Resource Longitude',
wigeo.Latitude as 'Site Latitude', 
wigeo.Longitude as 'Site Longitude',
# Germany
if (r.Name='Beata Biezunska', 'small_red',
if (r.NAme='Franz Gropp', 'small_yellow',
if (r.NAme='Joanna Rylko', 'small_green',
if (r.NAme='Renata Chramostova', 'small_blue',
if (r.NAme='Tatiana Wiktorowicz', 'small_purple',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white',
if (r.NAme='Wojciech Kowalczyk', 'measle_white','small_turquoise'))))))))))))))))))) as 'Resource Marker'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache wigeo on concat(
 ifnull(concat(site.Business_Address_1__c ,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c ,' '),''),
 ifnull(concat(sscs.Name,' '),''),
 ifnull(concat(sccs.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = wigeo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache rgeo on concat(r.Home_City__c, ' ', ccs.Name) = rgeo.Address
where BatchId='EMEA Tesco Capacity Planning - 2017' and SubBatchId=8);

(SELECT s.*, 
site.Name as 'Client Site',
wi.Required_Duration__c as 'Audit Duration',
wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country'    ,
r.Reporting_Business_Units__c,
rgeo.Latitude as 'Resource Latitude', 
rgeo.Longitude as 'Resource Longitude',
wigeo.Latitude as 'Site Latitude', 
wigeo.Longitude as 'Site Longitude',
if (r.NAme='Taghrid Paresys', 'small_red',if (r.NAme='Daniela Da Silva', 'small_yellow',if (r.NAme='Bruce Maurice', 'small_green',if (r.NAme='Renata Chramostova', 'small_blue',if (r.NAme='Tatiana Wiktorowicz', 'small_purple',if (r.NAme='Wojciech Kowalczyk', 'measle_white','small_turquoise')))))) as 'Resource Marker'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
left join salesforce.saig_geocode_cache wigeo on concat(
 ifnull(concat(site.Business_Address_1__c ,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c ,' '),''),
 ifnull(concat(sscs.Name,' '),''),
 ifnull(concat(sccs.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = wigeo.Address
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache rgeo on concat(r.Home_City__c, ' ', ccs.Name) = rgeo.Address
where BatchId='EMEA Tesco France Capacity Planning - 2017' and SubBatchId=3);

select * from salesforce.allocator_schedule_batch s order by Id desc limit 10;