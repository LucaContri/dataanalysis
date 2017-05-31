CREATE TABLE `sf_business_process_details` (
  `Type` varchar(25) NOT NULL DEFAULT '',
  `Name` varchar(50) NOT NULL DEFAULT '',
  `Record Id` varchar(18) NOT NULL,
  `Record Name` varchar(50) NOT NULL,
  `Client Ownership` varchar(50),
  `Standards` varchar(512),
  `Standard Families` varchar(512),
  `From` datetime DEFAULT NULL,
  `To` datetime DEFAULT NULL,
  `Duration` double(7,2) DEFAULT NULL,
  `Unit` varchar(10) NOT NULL DEFAULT '',
  `Owner` varchar(50),
  `Executed By` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `salesforce`.`sf_tables` 
(`Id`,`TableName`,`RowCount`,`UpdateValue`,`LastSyncDate`,`ToSync`,`MinSecondsBetweenSyncs`) 
VALUES (null,'sf_business_process_details',null,null,'1970-01-01',0,0);