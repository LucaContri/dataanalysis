# Add saig_resource_utilization as cache of resource utilization in order to make scheduling tool faster
CREATE TABLE `saig_resource_utilization` (
  `id` varchar(20) NOT NULL,
  `period` varchar(20) NOT NULL, 
  `wiDays` decimal(18,10),
  `utilization` decimal(18,10),
  PRIMARY KEY (`id`, `period`)
) ENGINE=InnoDB AUTO_INCREMENT=16743 DEFAULT CHARSET=utf8;

#Script to update saig_resource_utilization
# To be run daily as part of custom data processor included in the download process
INSERT INTO saig_resource_utilization (id, period, wiDays, utilization) 
SELECT 
	t.id as 'id',
	t.fy as 'period',
	sum(t.DurationInMinutes)/60/8 as 'wiDays',
	if (r.Resource_Target_Days__c is not null and r.Resource_Target_Days__c>0, sum(t.DurationInMinutes)/60/8/r.Resource_Target_Days__c,null) as 'utilization'
FROM salesforce.Resource__c r
        INNER JOIN
(
SELECT 
        r.Id,
		e.DurationInMinutes,
        if(month(e.ActivityDate)<7, concat(year(e.ActivityDate)-1,'-',year(e.ActivityDate)),concat(year(e.ActivityDate),'-',year(e.ActivityDate)+1)) as 'fy'
    FROM
        salesforce.event e
    INNER JOIN salesforce.user u ON u.Id = e.OwnerId
    INNER JOIN salesforce.Resource__c r ON u.Id = r.User__c
    INNER JOIN salesforce.work_item_resource__c wir ON wir.Id = e.WhatId
    WHERE
        e.IsDeleted = 0
            AND e.ActivityDate >= '2013-07-01'
            AND e.ActivityDate <= '2016-06-30'
            AND wir.Work_Item_Type__c IN ('Audit' , 'Travel')) t ON t.Id = r.Id
GROUP BY t.Id , t.fy
ON DUPLICATE KEY UPDATE wiDays = wiDays, utilization = utilization;