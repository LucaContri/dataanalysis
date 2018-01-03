#drop database webscrapers;
create database webscrapers;
use webscrapers;
CREATE TABLE `certified_organisations` (
  `Source` varchar(32) NOT NULL,
  `Id` varchar(54) NOT NULL,
  `status` varchar(16) DEFAULT NULL,
  `companyName` varchar(512) DEFAULT NULL,
  `contact` varchar(128) DEFAULT NULL,
  `contactEMail` varchar(128) DEFAULT NULL,
  `contactPhone` varchar(128) DEFAULT NULL,
  `contactFax` varchar(128) DEFAULT NULL,
  `commercialContact` varchar(128) DEFAULT NULL,
  `commercialContactEmail` varchar(128) DEFAULT NULL,
  `commercialContactPhone` varchar(128) DEFAULT NULL,
  `address` varchar(512) DEFAULT NULL,
  `city` varchar(128) DEFAULT NULL,
  `postCode` varchar(40) DEFAULT NULL,
  `regionState` varchar(128) DEFAULT NULL,
  `latitude` decimal(16,10) DEFAULT NULL,
  `longitude` decimal(16,10) DEFAULT NULL,
  `country` varchar(128) DEFAULT NULL,
  `phone` varchar(128) DEFAULT NULL,
  `fax` varchar(128) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `website` varchar(256) DEFAULT NULL,
  `grade` varchar(256) DEFAULT NULL,
  `scope` text,
  `exclusion` varchar(1024) DEFAULT NULL,
  `certificationBody` varchar(128) DEFAULT NULL,
  `auditCategory` varchar(256) DEFAULT NULL,
  `businessLine` varchar(45) DEFAULT NULL,
  `standard` varchar(256) DEFAULT NULL,
  `codes` varchar(1024) DEFAULT NULL,
  `issueDate` date DEFAULT NULL,
  `expiryDate` date DEFAULT NULL,
  `detailsLink` varchar(1024) DEFAULT NULL,
  `processorId` varchar(45) NOT NULL DEFAULT '1',
  `created` datetime NOT NULL DEFAULT '1970-01-01 00:00:00',
  `lastUpdated` datetime NOT NULL,
  `isDeleted` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Source`,`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `certified_organisations_history` (
  `Source` varchar(32) NOT NULL,
  `Id` varchar(54) NOT NULL,
  `FieldName` varchar(64) NOT NULL,
  `UpdateDateTime` datetime NOT NULL,
  `OldValue` varchar(512) DEFAULT NULL,
  `NewValue` varchar(512) DEFAULT NULL,
  `processorId` varchar(45) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Source`,`Id`,`FieldName`,`UpdateDateTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `scrapers_log` (
  `Source` varchar(32) NOT NULL,
  `Id` varchar(54) NOT NULL,
  `class` varchar(256) DEFAULT NULL,
  `start` datetime DEFAULT NULL,
  `end` datetime DEFAULT NULL,
  `page` varchar(1024) DEFAULT NULL,
  `totalRecords` int(11) DEFAULT NULL,
  `fetched` int(11) DEFAULT NULL,
  `completed` tinyint(1) DEFAULT '0',
  `exception` text,
  PRIMARY KEY (`Source`,`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SELECT 
	`start` as 'Start Time', 
    `end` as 'End Time', 
    substring_index(`page`, '=', -1) as 'Current Page', 
    `totalRecords` as 'Total Records', 
    `recordsToFetch` as 'Records To Fetch', 
    `fetched` as 'Fetched', 
	(timestampdiff(second, `start`, utc_timestamp())/`fetched`) as 'Avg Sec Per Record',
	date_add(utc_timestamp(), interval (`recordsToFetch` - `fetched`)*(timestampdiff(second, `start`, utc_timestamp())/`fetched`) second) as 'ETA'
FROM webscrapers.scrapers_log 
order by `start` desc limit 1;
