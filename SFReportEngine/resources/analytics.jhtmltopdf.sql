DROP TABLE `analytics`.`jhtmltopdf_queue`;
CREATE TABLE `analytics`.`jhtmltopdf_queue` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `createdBy` VARCHAR(128) NOT NULL,
  `createdTimestamp` DATETIME NOT NULL,
  `processedTimestamp` DATETIME,
  `wkhtmltopdf_exe` VARCHAR(1024) NOT NULL,
  `wkhtmltopdf_opt` VARCHAR(1024),
  `webpage` VARCHAR(1024) NOT NULL,
  `pdfFileName` VARCHAR(1024) NOT NULL,
  `processed` BOOLEAN NOT NULL DEFAULT 0,
  `tries` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`Id`));
  
  select * from analytics.jhtmltopdf_queue;
  