create database if not exists knowledge;
#drop database knowledge;
use knowledge;

CREATE TABLE `publications` (
  `Id` INT(11) auto_increment,
  `Title` varchar(64) DEFAULT NULL,
  `Version` varchar(64) DEFAULT NULL,
  `ExternalId` varchar(200) NOT NULL,
  `Publisher` varchar(64) NOT NULL,
  `Type` varchar(64) DEFAULT NULL,
  `Status` varchar(64) DEFAULT NULL,
  `DetailPage` varchar(1024) DEFAULT NULL,
  `ShortDescription` varchar(1024) DEFAULT NULL,
  `Description` text,
  `ICS Codes` varchar(64) DEFAULT NULL,
  `Pages` int(6) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `LastUpdatedDate` datetime DEFAULT NULL,
  `LastCheckedDate` datetime DEFAULT NULL,
  `IsDeleted` tinyint(1) DEFAULT NULL,
  `UpdateDetails` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`Id`),
  UNIQUE(`Publisher`, `ExternalId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `publications_history` (
  `Id` INT(11) auto_increment,
  `PublicationId` int(11) not null,
  `Field` varchar(64) not null,
  `OldValue` text,
  `NewValue` text,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `publications_options` (
  `Id` INT(11) auto_increment,
  `PublicationId` int(11) not null,
  `Language` varchar(64) NOT NULL,
  `Format` varchar(64) NOT NULL DEFAULT '',
  `Licence` varchar(64) NOT NULL,
  `Price` decimal(10,4) DEFAULT NULL,
  `Currency` varchar(3) NOT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `LastUpdatedDate` datetime DEFAULT NULL,
  `LastCheckedDate` datetime DEFAULT NULL,
  `IsDeleted` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE(`PublicationId`, `Language`, `Format`, `Licence`, `Currency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `publications_options_history` (
  `Id` INT(11) auto_increment,
  `PublicationOptionsId` int(11) not null,
  `Field` varchar(64) not null,
  `OldValue` text,
  `NewValue` text,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

select * from knowledge.publications;

update knowledge.publications set Status='Inactive' where id=97;

SET SQL_SAFE_UPDATES = 0;
delete from knowledge.publications;
delete from knowledge.publications_history;
delete from knowledge.publications_options;
delete from knowledge.publications_options_history;

select * from 
knowledge.publications p
inner join knowledge.publications_options po on p.Id = po.PublicationId;

select * from knowledge.publications_options_history;
select * from knowledge.publications_history;

select publisher, count(*) from knowledge.publications group by publisher;
