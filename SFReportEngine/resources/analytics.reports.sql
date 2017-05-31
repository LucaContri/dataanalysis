drop table reports;
CREATE TABLE `analytics`.`reports` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(128) NOT NULL,
  `datasource` VARCHAR(45) NOT NULL,
  `group` VARCHAR(128) NOT NULL,
  `description` TEXT NULL,
  `query` TEXT NOT NULL,
  `filters` TEXT NULL,
  PRIMARY KEY (`id`));

insert into analytics.reports VALUES(null, 'Work Items with Contact Details', 'compass', 'Scheduling', 'Work Items with Contact Details', 
'select wi.Id, wi.Name as \'Work Item\', wi.Primary_Standard__c, wi.Work_Item_Date__c, wi.Revenue_Ownership__c, c.Name, c.Email, c.Phone, c.MobilePhone
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
left join salesforce.Contact_Role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact c on cr.Contact__c = c.Id
group by wi.Id;', 'wi.Primary_Standard__c,Primary Standard,LIST;wi.Revenue_Ownership__c,Revenue Ownership,LIST;wi.Work_Item_Date__c,Work Item Date,DATE');

select wi.Id, wi.Name, wi.Primary_Standard__c, wi.Work_Item_Date__c, wi.Revenue_Ownership__c, c.Name, c.Email, c.Phone, c.MobilePhone
from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
left join salesforce.Contact_Role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact c on cr.Contact__c = c.Id
group by wi.Id;

select group_concat(distinct wi.Revenue_Ownership__c) as 'valuesList' from salesforce.work_item__c wi
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
left join salesforce.Contact_Role__c cr on cr.Site_Certification__c = sc.Id
left join salesforce.contact c on cr.Contact__c = c.Id
