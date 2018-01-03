create database if not exists fsa;
use fsa;
CREATE TABLE `establishments` (
  `FHRSID` int(11) NOT NULL,
  `BusinessName` varchar(256) DEFAULT NULL,
  `BusinessType` varchar(256) DEFAULT NULL,
  `AddressLine1` varchar(256) DEFAULT NULL,
  `AddressLine2` varchar(256) DEFAULT NULL,
  `AddressLine3` varchar(256) DEFAULT NULL,
  `AddressLine4` varchar(256) DEFAULT NULL,
  `PostCode` varchar(20) DEFAULT NULL,
  `Phone` varchar(20) DEFAULT NULL,
  `RatingValue` varchar(20) DEFAULT NULL,
  `RatingDate` datetime NOT NULL,
  `LocalAuthorityName` varchar(256) DEFAULT NULL,
  `LocalAuthorityWebSite` varchar(256) DEFAULT NULL,
  `LocalAuthorityEmailAddress` varchar(256) DEFAULT NULL,
  `longitude` decimal(18,10) DEFAULT NULL,
  `latitude` decimal(18,10) DEFAULT NULL,
  `NewRatingPending` tinyint(1) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `LastUpdatedDate` datetime DEFAULT NULL,
  `ISDeleted` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`FHRSID`,`RatingDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

select count(*) from fsa.establishments;

# Top rated Hotels within 10 km from SAI Office in MK
(select 
	e.FHRSID,
	e.BusinessName,
	e.BusinessType,
    e.AddressLine1,
    e.AddressLine2, 
    e.AddressLine3, 
    e.AddressLine4, 
    e.PostCode,
    e.Phone,
    e.RatingDate,
    e.RatingValue,
    e.LastUpdatedDate as 'Last Updated by SAI!!!',
    analytics.distance(e.latitude, e.longitude,  52.023571, -0.768216) as 'Distance from SAI Office'
from fsa.establishments e
where 
	analytics.distance(e.latitude, e.longitude,  52.023571, -0.768216) < 10
	and e.RatingValue = 5
    and e.BusinessName like '%hotel%'
order by `Distance From SAI Office`);

