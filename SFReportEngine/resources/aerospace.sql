use analytics;
#drop table aerospace_certified_organisations;
CREATE TABLE `aerospace_certified_organisations` (
  `OIN` varchar(25) not null,
  `CertificateId` varchar(32) NOT NULL,
  `CompanyName` varchar(256) DEFAULT NULL,
  `Status` varchar(45) DEFAULT NULL,
  `Address` varchar(256) DEFAULT NULL,
  `StructureType` text,
  `Standards` varchar(512) DEFAULT NULL,
  `CertificationBody` varchar(256) DEFAULT NULL,
  `CentralOffice` varchar(25) DEFAULT NULL,
  `Created` timestamp NULL DEFAULT NULL,
  `LastUpdated` timestamp NULL DEFAULT NULL,
  `IsDeleted` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#truncate analytics.aerospace_certified_organisations;
(select 
	analytics.getRegionFromCountry(trim(substring_index(aco.Address, ',', -1))) as 'Region',
	trim(substring_index(aco.Address, ',', -1)) as 'Country', 
	aco.*,
    aa.*
from analytics.aerospace_certified_organisations aco
left join analytics.accredia_addresses aa on aa.Address = aco.Address
where trim(substring_index(aco.Address, ',', -1)) in ('United Kingdom')
);

create index accredia_addresses_index on accredia_addresses(address(128));
#explain
select count(aco.Address) 
from analytics.aerospace_certified_organisations aco 
left join analytics.accredia_addresses aa on aa.Address = aco.Address
where aa.Address is null;

(select FormattedAddress is not null as 'Resolved',  count(*) from analytics.accredia_addresses where valid is not null group by `Resolved`);

(select * from analytics.accredia_addresses where valid is null);

select * from analytics.accredia_addresses where valid is null and FormattedAddress is null limit 100;

select count(*) from analytics.accredia_certified_organisations;

describe analytics.accredia_addresses ;
(select * from
(select aco.*, aa.FormattedAddress, aa.locality, aa.administrative_area_level_3, aa.administrative_area_level_2, aa.administrative_area_level_1, aa.PostCode, ifnull(aa.Country,trim(substring_index(aco.Address,',',-1))) as 'Country', aa.Latitude, aa.Longitude  
from analytics.aerospace_certified_organisations aco 
left join analytics.accredia_addresses aa on aa.Address = aco.Address) t
#where t.`CertificationBody` like 'Bureau%'
group by t.`OIN`, t.`CertificateId`, t.`CompanyName`, t.`Address`, t.`Standards`
);