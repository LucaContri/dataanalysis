
CREATE TABLE `accredia_certified_organisations` (
  `Id` varchar(40) NOT NULL ,
  `CertificateId` varchar(32) NOT NULL,
  `CompanyName` varchar(256) DEFAULT NULL,
  `TaxFileNumber` varchar(256) DEFAULT NULL,
  `Status` varchar(45) DEFAULT NULL,
  `Address` varchar(256) DEFAULT NULL,
  `Scope` text,
  `Standards` varchar(512) DEFAULT NULL,
  `Codes` text,
  `CertificationBody` varchar(256) DEFAULT NULL,
  `DateCertified` datetime DEFAULT NULL,
  `LastUpdatedByCB` timestamp NULL DEFAULT NULL,
  `Created` timestamp NULL DEFAULT NULL,
  `LastUpdated` timestamp NULL DEFAULT NULL,
  `IsDeleted` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `accredia_certified_organisations_history` (
  `Id` varchar(32) NOT NULL,
  `FieldName` varchar(64) NOT NULL,
  `UpdateDateTime` datetime NOT NULL,
  `OldValue` varchar(512) DEFAULT NULL,
  `NewValue` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`Id`,`FieldName`,`UpdateDateTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `accredia_addresses` (
  `Id` INT(11) auto_increment NOT NULL,
  `Address` varchar(256) DEFAULT NULL,
  `FormattedAddress` varchar(256) DEFAULT NULL,
  `locality` varchar(256) DEFAULT NULL,
  `administrative_area_level_3` varchar(256) DEFAULT NULL,
  `administrative_area_level_2` varchar(256) DEFAULT NULL,
  `administrative_area_level_1` varchar(256) DEFAULT NULL, 
  `Country` varchar(256),
  `PostCode` varchar(256),
  `Latitude` double(18,10),
  `Longitude` double(18,10),
  `Valid` boolean,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

select count(*) from accredia_certified_organisations;

(select * from accredia_certified_organisations aco left join accredia_addresses aa on aco.Address = aa.Address);
select count(*) from accredia_certified_organisations_history;

select CertificationBody, count(*) from accredia_certified_organisations group by CertificationBody;

select Standards, count(*) from accredia_certified_organisations group by Standards;

select * from accredia_certified_organisations where standards like '%16%';

(select * from accredia_certified_organisations_history);

select count(*) from accredia_addresses;
(select substring_index(aa.Address, '-', -5), aa.* from accredia_addresses aa);

#explain
(select aco.CertificateId, aco.CertificationBody, aco.CompanyName, aco.Standards, aco.Codes, aco.Status, aco.TaxFileNumber, aco.Address, aa.FormattedAddress, aa.Country, aa.administrative_area_level_1, aa.administrative_area_level_2, aa.administrative_area_level_3, aa.PostCode, aa.Latitude, aa.Longitude 
from accredia_certified_organisations aco
left join accredia_addresses aa on aco.Address = aa.Address
group by aco.CertificateId, aco.CertificationBody, aco.CompanyName, aco.Standards, aco.Codes, aco.Status, aco.TaxFileNumber, aco.Address);

select substring(aco.CompanyName,1,1) as 'Initial', count(*) from accredia_certified_organisations aco group by `Initial`;

select * from analytics.accredia_certified_organisations aco where aco.Address like '%San Nicola Di Crissa%'