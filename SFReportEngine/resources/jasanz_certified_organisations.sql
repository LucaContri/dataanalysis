SELECT * FROM analytics.jasanz_certified_organisations where Id='ad1cec27-e452-4a8d-9991-790a5763282e';

select * from jasanz_certified_organisations_history;
CREATE TABLE `analytics`.`jasanz_certified_organisations_history` (
  `Id` VARCHAR(54) NOT NULL,
  `FieldName` VARCHAR(64) NOT NULL,
  `UpdateDateTime` DATETIME NOT NULL,
  `OldValue` VARCHAR(512),
  `NewValue` VARCHAR(512),
  PRIMARY KEY (`Id`,`FieldName`,`UpdateDateTime`));
  
  (select * from jasanz_certified_organisations_history)