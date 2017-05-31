DROP TABLE IF EXISTS `saig_schedulingapi_log`;
CREATE TABLE `saig_schedulingapi_log` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `LastUpdate` DateTime NOT NULL, 
  `Request` varchar(1024) NOT NULL,
  `Client` varchar(254),
  `Outcome` varchar(254),
  `TimeMs` bigint,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=16743 DEFAULT CHARSET=utf8;