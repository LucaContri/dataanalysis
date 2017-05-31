# Add sf_data_processors to define post download processors to be run at scheduled times during the data download process
# Examples
CREATE TABLE IF NOT EXISTS `sf_data_processors` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `ProcessorName` varchar(100) DEFAULT NULL,
  `ProcessorClass` varchar(512) DEFAULT NULL,
  `LastExecDate` datetime DEFAULT NULL,
  `MinSecondsBetweenExec` INT UNSIGNED NOT NULL DEFAULT 3600,
  PRIMARY KEY (`Id`),
  CONSTRAINT uc_Name UNIQUE (ProcessorName)
) ENGINE=InnoDB AUTO_INCREMENT=510 DEFAULT CHARSET=utf8;

INSERT INTO `sf_data_processors` (ProcessorName, ProcessorClass, LastExecDate, MinSecondsBetweenExec) 
	VALUES ('EventCleaner', 'com.saiglobal.sf.downloader.processor.DataProcessor_EventCleaner', '1970-01-01', 60);

INSERT INTO `sf_data_processors` (ProcessorName, ProcessorClass, LastExecDate, MinSecondsBetweenExec) 
	VALUES ('ResourceUtilizationUpdater', 'com.saiglobal.sf.downloader.processor.DataProcessor_UpdateResourceUtilization', '1970-01-01', 86400);