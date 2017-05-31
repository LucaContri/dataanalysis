DROP TABLE IF EXISTS `saig_postcodes_to_sla4`;
CREATE TABLE `saig_postcodes_to_sla4` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Postcode` varchar(4) NOT NULL,
  `SLAName` varchar(254) NOT NULL,
  `Latitude` double(18,10),
  `Longitude` double(18,10),
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=16743 DEFAULT CHARSET=utf8;