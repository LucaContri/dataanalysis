CREATE TABLE `analytics`.`brc_certified_organisations` (
  `BRCSiteCode` INT NOT NULL,
  `companyName` VARCHAR(128) NULL,
  `contact` VARCHAR(128) NULL,
  `contactEMail` VARCHAR(128) NULL,
  `contactPhone` VARCHAR(128) NULL,
  `contactFax` VARCHAR(128) NULL,
  `address` VARCHAR(128) NULL,
  `city` VARCHAR(128) NULL,
  `postCode` VARCHAR(40) NULL,
  `regionState` VARCHAR(40) NULL,
  `latitude` DECIMAL(16,10) NULL,
  `longitude` DECIMAL(16,10) NULL,
  `country` VARCHAR(128) NULL,
  `phone` VARCHAR(128) NULL,
  `fax` VARCHAR(128) NULL,
  `email` VARCHAR(128) NULL,
  `website` VARCHAR(256) NULL,
  `grade` VARCHAR(256) NULL,
  `scope` VARCHAR(1024) NULL,
  `exclusion` VARCHAR(1024) NULL,
  `certificationBody` VARCHAR(128) NULL,
  `auditCategory` VARCHAR(256) NULL,
  `standard` VARCHAR(256) NULL,
  `issueDate` DATE NULL,
  `expiryDate` DATE NULL,
  `lastUpdated` DATETIME NOT NULL,
  PRIMARY KEY (`BRCSiteCode`));
  
ALTER TABLE `analytics`.`brc_certified_organisations` 
ADD COLUMN `commercialContact` VARCHAR(128) NULL AFTER `contactFax`,
ADD COLUMN `commercialContactEmail` VARCHAR(128) NULL AFTER `commercialContact`,
ADD COLUMN `commercialContactPhone` VARCHAR(128) NULL AFTER `commercialContactEmail`;

ALTER TABLE `analytics`.`brc_certified_organisations` 
ADD COLUMN `codes` VARCHAR(1024) NULL AFTER `standard`;

ALTER TABLE `analytics`.`brc_certified_organisations` 
CHANGE COLUMN `address` `address` VARCHAR(512) NULL DEFAULT NULL ,
CHANGE COLUMN `regionState` `regionState` VARCHAR(128) NULL DEFAULT NULL ;

ALTER TABLE `analytics`.`brc_certified_organisations` 
ADD COLUMN `created` DATETIME NOT NULL DEFAULT '1970-01-01' AFTER `expiryDate`;

ALTER TABLE `analytics`.`brc_certified_organisations` 
ADD COLUMN `isDeleted` BOOLEAN NOT NULL DEFAULT FALSE AFTER `lastUpdated`;

CREATE TABLE `analytics`.`brc_certified_organisations_history` (
  `BRCSiteCode` INT NOT NULL,
  `FieldName` VARCHAR(64) NOT NULL,
  `UpdateDateTime` DATETIME NOT NULL,
  `OldValue` VARCHAR(512),
  `NewValue` VARCHAR(512),
  PRIMARY KEY (`BRCSiteCode`,`FieldName`,`UpdateDateTime`));
  
drop function getRegionFromCountry;
DELIMITER $$
CREATE DEFINER=`luca`@`%` FUNCTION `getRegionFromCountry`(country VARCHAR(255)) RETURNS ENUM('EMEA', 'APAC', 'AMERICAs') 
BEGIN
	DECLARE region ENUM('EMEA', 'APAC', 'AMERICAs') DEFAULT 'APAC';
    SET region = 
    (SELECT 
		if(country in ('ALBANIA','AUSTRIA','BAHRAIN','BELARUS','BELGIUM','BOSNIA AND HERZEGOVINA','BOTSWANA','BULGARIA','CAMEROON','CROATIA','CYPRUS','CZECH REPUBLIC','DENMARK','EGYPT','ESTONIA','ETHIOPIA','FAROE ISLANDS','FINLAND','FRANCE','GAMBIA','GEORGIA','GERMANY','GHANA','GREECE','GUINEA-BISSAU','HUNGARY','ICELAND','IRELAND','ISRAEL','ITALY','JORDAN','KENYA','KUWAIT','LATVIA','LEBANON','LIECHTENSTEIN','LITHUANIA','LUXEMBOURG','MADAGASCAR','MALTA','MAURITIUS','MOROCCO','MOZAMBIQUE','NAMIBIA','NETHERLANDS','NIGERIA','NORWAY','OMAN','POLAND','PORTUGAL','ROMANIA','SAN MARINO','SAUDI ARABIA','SENEGAL','SERBIA','SLOVAKIA','SLOVENIA','SOUTH AFRICA','SPAIN','SWAZILAND','SWEDEN','SWITZERLAND','TUNISIA','TURKEY','UGANDA','UKRAINE','UNITED ARAB EMIRATES','UNITED KINGDOM','ZAMBIA','ARMENIA','AZERBAIJAN','GREENLAND','IRAN, ISLAMIC REPUBLIC OF','MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','RUSSIAN FEDERATION','SERBIA AND MONTENEGRO','ZIMBABWE'),
			'EMEA',
			if(country in ('TRINIDAD AND TOBAGO','AMERICAN SAMOA','ARGENTINA','BAHAMAS','BELIZE','BOLIVIA','BRAZIL','CANADA','CHILE','COLOMBIA','COSTA RICA','COTE D\'IVOIRE','DOMINICAN REPUBLIC','ECUADOR','EL SALVADOR','FRENCH GUIANA','GUATEMALA','GUYANA','HONDURAS','MEXICO','NICARAGUA','PANAMA','PARAGUAY','PERU','PUERTO RICO','SURINAME','UNITED STATES','URUGUAY'), 
				'AMERICAs',
                'APAC'
			)
		)
	);
 	RETURN region;
 END$$
DELIMITER ;


(select *, 
if(country in ('ALBANIA','AUSTRIA','BAHRAIN','BELARUS','BELGIUM','BOSNIA AND HERZEGOVINA','BOTSWANA','BULGARIA','CAMEROON','CROATIA','CYPRUS','CZECH REPUBLIC','DENMARK','EGYPT','ESTONIA','ETHIOPIA','FAROE ISLANDS','FINLAND','FRANCE','GAMBIA','GEORGIA','GERMANY','GHANA','GREECE','GUINEA-BISSAU','HUNGARY','ICELAND','IRELAND','ISRAEL','ITALY','JORDAN','KENYA','KUWAIT','LATVIA','LEBANON','LIECHTENSTEIN','LITHUANIA','LUXEMBOURG','MADAGASCAR','MALTA','MAURITIUS','MOROCCO','MOZAMBIQUE','NAMIBIA','NETHERLANDS','NIGERIA','NORWAY','OMAN','POLAND','PORTUGAL','ROMANIA','SAN MARINO','SAUDI ARABIA','SENEGAL','SERBIA','SLOVAKIA','SLOVENIA','SOUTH AFRICA','SPAIN','SWAZILAND','SWEDEN','SWITZERLAND','TUNISIA','TURKEY','UGANDA','UKRAINE','UNITED ARAB EMIRATES','UNITED KINGDOM','ZAMBIA','ARMENIA','AZERBAIJAN','GREENLAND','IRAN, ISLAMIC REPUBLIC OF','MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','RUSSIAN FEDERATION','SERBIA AND MONTENEGRO','ZIMBABWE'),
	'EMEA',
    if(country in ('AMERICAN SAMOA','ARGENTINA','BAHAMAS','BELIZE','BOLIVIA','BRAZIL','CANADA','CHILE','COLOMBIA','COSTA RICA','COTE D\'IVOIRE','DOMINICAN REPUBLIC','ECUADOR','EL SALVADOR','FRENCH GUIANA','GUATEMALA','GUYANA','HONDURAS','MEXICO','NICARAGUA','PANAMA','PARAGUAY','PERU','PUERTO RICO','SURINAME','UNITED STATES','URUGUAY'), 
		'AMERICAs','APAC')
) as 'Region',
concat(ifnull(concat(address,', '),''),ifnull(concat(city,', '),''), ifnull(concat(regionState, ', '),''), ifnull(concat(postCode, ', '),''),ifnull(country,'')) as 'location',
if(certificationBody like 'Bureau%','Bureau Veritas',
	if(certificationBody like 'Intertek%', 'Intertek Certification',
		if(certificationBody like 'Kiwa%','Kiwa',
			if(certificationBody like 'NSF%','NSF',
				if(certificationBody like '%SAI%','SAI Global',
					if(certificationBody like 'SGS%','SGS',
						if(certificationBody like 'TUV%','TUV',
							if(certificationBody like 'TV%','TV Nord',
								certificationBody 
							)
						)
					)
                )
            )
        )
    )
) as 'CertificationBodyShort',
if(certificationBody like 'Bureau%','small_yellow',
	if(certificationBody like 'Intertek%', 'small_green',		
		if(certificationBody like 'NSF%','small_blue',
			if(certificationBody like '%SAI%','small_red',
				if(certificationBody like 'SGS%','small_purple',
					if(certificationBody like 'DNV%','measle_brown',
						if(certificationBody like 'LRQA%','measle_turquoise',
							'measle_grey' 
						)
					)
				)
			)
		)
    )
) as 'marker_CB_Top',
if(certificationBody like '%SAI%', 'small_red', 'measle_grey') as 'marker_CB_SAI',
if(standard like '%Food%','small_red',
	if(standard like '%Products%','small_green',
		if(standard like '%packaging%','small_blue',
			if(standard like '%Storage%','small_purple',
				'measle_turquoise' # Agents and Brokers
			)
		)
	)
) as 'marker_standard'
 from brc_certified_organisations where CertificationBody is not null and CompanyName is not null);

select country, certificationBody, count(*) from brc_certified_organisations group by country, certificationBody;

select country, count(*), count(If(IssueDate is null, null, BRCSiteCode)) as '# Details' from brc_certified_organisations group by country;

(select *, if(certificationBody is null, 'small_green',if(certificationBody like '%SAI%', 'small_yellow', 'small_red')) as 'marker' from analytics.brc_certified_organisations where country in ('ALBANIA','AUSTRIA','BAHRAIN','BELARUS','BELGIUM','BOSNIA AND HERZEGOVINA','BOTSWANA','BULGARIA','CAMEROON','CROATIA','CYPRUS','CZECH REPUBLIC','DENMARK','EGYPT','ESTONIA','ETHIOPIA','FAROE ISLANDS','FINLAND','FRANCE','GAMBIA','GEORGIA','GERMANY','GHANA','GREECE','GUINEA-BISSAU','HUNGARY','ICELAND','IRELAND','ISRAEL','ITALY','JORDAN','KENYA','KUWAIT','LATVIA','LEBANON','LIECHTENSTEIN','LITHUANIA','LUXEMBOURG','MADAGASCAR','MALTA','MAURITIUS','MOROCCO','MOZAMBIQUE','NAMIBIA','NETHERLANDS','NIGERIA','NORWAY','OMAN','POLAND','PORTUGAL','ROMANIA','SAN MARINO','SAUDI ARABIA','SENEGAL','SERBIA','SLOVAKIA','SLOVENIA','SOUTH AFRICA','SPAIN','SWAZILAND','SWEDEN','SWITZERLAND','TUNISIA','TURKEY','UGANDA','UKRAINE','UNITED ARAB EMIRATES','UNITED KINGDOM','ZAMBIA'));


select standard, count(*) from brc_certified_organisations where CertificationBody is not null and CompanyName is not null group by standard;

select country from brc_certified_organisations
where country not in ('ALBANIA','AUSTRIA','BAHRAIN','BELARUS','BELGIUM','BOSNIA AND HERZEGOVINA','BOTSWANA','BULGARIA','CAMEROON','CROATIA','CYPRUS','CZECH REPUBLIC','DENMARK','EGYPT','ESTONIA','ETHIOPIA','FAROE ISLANDS','FINLAND','FRANCE','GAMBIA','GEORGIA','GERMANY','GHANA','GREECE','GUINEA-BISSAU','HUNGARY','ICELAND','IRELAND','ISRAEL','ITALY','JORDAN','KENYA','KUWAIT','LATVIA','LEBANON','LIECHTENSTEIN','LITHUANIA','LUXEMBOURG','MADAGASCAR','MALTA','MAURITIUS','MOROCCO','MOZAMBIQUE','NAMIBIA','NETHERLANDS','NIGERIA','NORWAY','OMAN','POLAND','PORTUGAL','ROMANIA','SAN MARINO','SAUDI ARABIA','SENEGAL','SERBIA','SLOVAKIA','SLOVENIA','SOUTH AFRICA','SPAIN','SWAZILAND','SWEDEN','SWITZERLAND','TUNISIA','TURKEY','UGANDA','UKRAINE','UNITED ARAB EMIRATES','UNITED KINGDOM','ZAMBIA','ARMENIA','AZERBAIJAN','GREENLAND','IRAN, ISLAMIC REPUBLIC OF','MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','RUSSIAN FEDERATION','SERBIA AND MONTENEGRO','ZIMBABWE')
group by country;