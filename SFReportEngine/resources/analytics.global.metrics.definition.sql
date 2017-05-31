use analytics;

CREATE TABLE IF NOT EXISTS `analytics`.`metrics` (
  `Id` INT(11) NOT NULL AUTO_INCREMENT,
  `Region` ENUM('APAC', 'EMEA', 'AMERICAs') NOT NULL,
  `Product Portfolio` ENUM('Assurance', 'Learning', 'Knowledge', 'Risk') NOT NULL,
  `Metric Group` ENUM('Utilisation', 'Quality', 'Timeliness', 'Retention') NOT NULL,
  `Metric` VARCHAR(128) NOT NULL,
  `Business Owner` VARCHAR(128) NOT NULL,
  `Volume Definition` TEXT NOT NULL,
  `Volume Unit` VARCHAR(64) NOT NULL,
  `Value Definition` TEXT NOT NULL,
  `Value Target` DOUBLE(18,10) NOT NULL,
  `Value Target Min/Max` ENUM('MIN', 'MAX') NOT NULL,
  `Value Unit` VARCHAR(64) NOT NULL,
  `SLA Definition` TEXT NOT NULL,
  `SLA Target Amber` DOUBLE (18,10) NOT NULL,
  `SLA Target Green` DOUBLE (18,10) NOT NULL,
	PRIMARY KEY (`Id`),
  UNIQUE(`Region`, `Product Portfolio`, `Metric Group`, `Metric`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

ALTER TABLE `analytics`.`metrics` 
ADD COLUMN `Reporting Period` ENUM('Year', 'Quarter', 'Month', 'Week', 'Day') NOT NULL DEFAULT 'Month' AFTER `SLA Target Green`;

ALTER TABLE `analytics`.`metrics` 
ADD COLUMN `Weight` DOUBLE (18,10) AFTER `SLA Target Green`;

CREATE TABLE IF NOT EXISTS `analytics`.`metrics_data` (
  `Id` INT(11) NOT NULL AUTO_INCREMENT,
  `Metric Id` INT(11) NOT NULL,
  `SubRegion` VARCHAR(128) NOT NULL,
  `Period` DATE NOT NULL,
  `Prepared By` VARCHAR(128) NOT NULL,
  `Prepared Date/Time` DATETIME NOT NULL,
  `Volume` DOUBLE(18,10) NOT NULL,
  `Value` DOUBLE(18,10) NOT NULL,
  `SLA` DOUBLE(18,10) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE(`Metric Id`, `SubRegion`, `Period`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;