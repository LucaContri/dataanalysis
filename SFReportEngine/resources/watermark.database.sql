drop table `analytics`.`watermark_coc`;
CREATE TABLE `analytics`.`watermark_coc` (
  `coc` varchar(128) NOT NULL,
  `certificationBody` varchar(128) NOT NULL,
  `supplierName` varchar(128) NOT NULL,
  `certificateDate` date DEFAULT NULL,
  `expiryDate` date DEFAULT NULL,
  `standard` varchar(256) DEFAULT NULL,
  `watermark_level` varchar(124) DEFAULT NULL,
  `lastUpdated` datetime NOT NULL,
  PRIMARY KEY (`coc`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table `analytics`.`watermark_sites`;
CREATE TABLE `analytics`.`watermark_sites` (
  `coc` varchar(128) NOT NULL,
  `siteName` varchar(256) DEFAULT NULL,
  `address` varchar(512) DEFAULT NULL,
  `country` varchar(128) DEFAULT NULL,
  `lastUpdated` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table `analytics`.`watermark_product`;
CREATE TABLE `analytics`.`watermark_product` (
  `coc` varchar(128) NOT NULL,
  `brand_name` varchar(256) DEFAULT NULL,
  `model_name` varchar(256) DEFAULT NULL,
  `model_no` varchar(256) DEFAULT NULL,
  `lastUpdated` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

select coc.certificationBody, count(coc) 
from analytics.watermark_coc coc
group by coc.certificationBody;

select coc.standard, count(coc) 
from analytics.watermark_coc coc
group by coc.standard;

(select coc.*, site.*
#, count(distinct concat(ifnull(site.siteName, ''), ifnull(site.Address,''), ifnull(site.Country, ''))) as '# Sites', group_concat(distinct site.Country) as 'Site Countries'
from analytics.watermark_coc coc
left join analytics.watermark_sites site on coc.coc = site.coc
group by coc.coc, concat(ifnull(site.siteName, ''), ifnull(site.Address,''), ifnull(site.Country, '')));

(select coc.certificationBody, count(product.brand_name)
from analytics.watermark_coc coc
left join analytics.watermark_product product on coc.coc = product.coc);

#explain
select csp.Id, csp.Name, coc.coc, coc.CertificationBody, count(product.brand_name), group_concat(product.brand_name)
from analytics.watermark_coc coc
inner join salesforce.certification_standard_program__c csp on coc.coc like concat(csp.External_provided_certificate__c, '%') 
inner join analytics.watermark_product product on coc.coc = product.coc
where coc.certificationBody = 'SAI Global'
group by coc.coc;

create index certification_standard_program_External_provided_certificate on salesforce.certification_standard_program__c(External_provided_certificate__c(50));
create index watermark_coc_product on analytics.watermark_product(coc);
select Id, External_provided_certificate__c from salesforce.certification_standard_program__c  where External_provided_certificate__c is not null;

select * 
from analytics.watermark_coc coc
inner join analytics.watermark_product product on coc.coc = product.coc
where coc.coc like 'SAIG-WM-001368-I06-R00%'