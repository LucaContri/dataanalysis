drop TABLE `analytics`.`fssc22000_certified_organisations`;
CREATE TABLE `analytics`.`fssc22000_certified_organisations` (
  `Id` VARCHAR(40) NOT NULL,
  `companyName` VARCHAR(128) NULL,
  `address` VARCHAR(128) NULL,
  `city` VARCHAR(128) NULL,
  `state` VARCHAR(40) NULL,
  `country` VARCHAR(128) NULL,
  `scope` VARCHAR(1024) NULL,
  `auditScope` TEXT NULL,
  `standard` VARCHAR(256) NULL,
  `accredited` VARCHAR(10) NULL,
  `status` VARCHAR(15) NULL,
  `issueDate` DATE NULL,
  `expiryDate` DATE NULL,
  `lastUpdated` DATETIME NOT NULL,
  `isDeleted` BOOLEAN,
  PRIMARY KEY (`Id`));
