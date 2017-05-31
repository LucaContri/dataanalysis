CREATE TABLE IF NOT EXISTS `sf_data` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `CreateDate` datetime NOT NULL,
  `DataType` varchar(20) NOT NULL,
  `DataSubType` varchar(20) NOT NULL,
  `RefName` varchar(127),
  `RefDate` datetime,
  `RefValue` double(18,10),
  `RefValueText` varchar(255),
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'MS', 'Forecast', '2014-04-01', 1194);
insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'MS', 'Forecast', '2014-05-01', 1579);
insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'MS', 'Forecast', '2014-06-01', 1253);

insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'Food', 'Forecast', '2014-04-01', 228);
insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'Food', 'Forecast', '2014-05-01', 253);
insert into salesforce.sf_data (CreateDate, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Audit Days Forecast', 'Food', 'Forecast', '2014-06-01', 195);