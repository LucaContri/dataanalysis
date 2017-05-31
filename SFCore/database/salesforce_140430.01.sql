CREATE TABLE IF NOT EXISTS `saig_client_category` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `ClientId` varchar(20) NOT NULL,
  `ClientName` varchar(254),
  `Category` varChar(20),
  `AuditDaysNext12Months` integer,
  PRIMARY KEY (`Id`),
  UNIQUE(ClientId)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

insert into saig_client_category (ClientId, ClientName, Category, AuditDaysNext12Months) 
select 
	c.Id as 'ClientId',
	c.Name as 'ClientName',
	if (sum(wi.Required_Duration__c/8) >= 50, '>=50', if (sum(wi.Required_Duration__c/8) >= 20, '>=20 & <50', '<20')) as 'Category',
	sum(wi.Required_Duration__c/8) as 'AuditDaysNext12Months'
from work_item__c wi
inner join work_package__c wp on wp.Id = wi.Work_Package__c
inner join certification__c sc on sc.Id = wp.Site_Certification__c
inner join certification__c pc on sc.Primary_Certification__c = pc.Id
inner join account c on c.Id = pc.Primary_client__c
where 
wi.Status__c not in ('Cancelled')
AND (wi.Revenue_Ownership__c LIKE 'AUS-Food%'
OR wi.Revenue_Ownership__c LIKE 'AUS-Global%'
OR wi.Revenue_Ownership__c LIKE 'AUS-Managed%'
OR wi.Revenue_Ownership__c LIKE 'AUS-Direct%')
AND wi.Work_Item_Date__c<(DATE_ADD(now(), INTERVAL +12 MONTH)) 
AND wi.Work_Item_Date__c>(DATE_ADD(now(), INTERVAL -0 MONTH)) 
group by c.Id 
ON DUPLICATE KEY UPDATE ClientId=ClientId, ClientName=ClientName, Category=Category, AuditDaysNext12Months=AuditDaysNext12Months;