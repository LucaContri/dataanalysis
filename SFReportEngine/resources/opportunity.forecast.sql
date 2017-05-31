CREATE TABLE `analytics`.`opportunity_forecast` (
  `id` VARCHAR(18) NOT NULL,
  `instance` ENUM('compass','corporate') NOT NULL,
  `date` DATETIME NOT NULL,
  `probability` DECIMAL(10,7) NOT NULL,
  PRIMARY KEY (`id`));

select date_format(date,'%Y-%m-%d') as 'Date', count(Id) from analytics.opportunity_forecast group by `Date`;

(select 
			o.Id,
			o.CreatedDate as 'Date Created',
			o.LastModifiedDate as 'Date Updated',
			o.Type,
			a.Name as 'Client',
			oo.Name as 'Owner',
			ifnull(o.LeadSource,'') as 'Lead Source',
			ifnull(o.Contract_Term__c,'') as 'Contract Term',
			timestampdiff(day,o.createdDate,utc_timestamp()) as 'Aging Created',
			o.Amount/ct.ConversionRate as 'Amount AUD',
			o.Probability,
			ifnull(o.Region__c,'') as 'Region',
			BillingCountry, 
			BillingState, 
			a.Industry, 
			a.Industry_Vertical__c, 
			a.Industry_Sub_group__c,
			null as 'IsWon'
		from training.opportunity o
		left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
		left join training.user oo on o.OwnerId = oo.Id
		left join training.account a on o.AccountId = a.Id
	where
		o.IsDeleted = 0
		and o.StageName not in ('Closed Won', 'Closed Lost')
		and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
	group by o.Id
	order by o.LastModifiedDate);
