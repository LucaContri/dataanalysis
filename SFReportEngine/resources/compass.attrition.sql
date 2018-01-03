(SELECT 'Compass' AS 'Source',
          'Revenue Lost (Audit)' AS 'Metric',
          analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) AS 'Region',
          analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) AS 'Country',
          dacv.`Business Line`,
          year(dacv.`De-Registered Date`) + if(month(dacv.`De-Registered Date`)<7, 0, 1) AS 'FY',
          DATE_FORMAT(dacv.`De-Registered Date`, '%Y %m') AS 'Period',
          ifnull(dacv.`ACV`/cur.ConversionRate,0) AS 'Value',
          'AUD' AS 'Unit',
          dacv.`ACV` AS 'Original Value',
          dacv.`Currency` AS 'Original Unit',
          dacv.`ACV Calculation`,
          dacv.`ACV - Duration`/8 AS 'ACV - Days',
          dacv.`Client`,
          dacv.`Site Cert Std`,
          dacv.`De-Registered Reason` AS 'Reasons',
          dacv.`Primary Std`,
          if(dacv.`De-Registered Reason` IN ('Application / Certification abandoned', 'Business / site closed down', 'Change to other CB (Cost)', 'Change to other CB (Other)', 'Change to other CB (Service delivery)', 'Company takeover / Liquidation', 'Global certification decision', 'Misuse of Mark', 'No added value / interest', 'No longer manufacturing product', 'Not financially viable - Company may be under Administration/Receivership', 'System failure / Unresolved non conformances', 'Unpaid account'), 1, 0) AS 'Include'
   FROM analytics.deregistration_acv dacv
   LEFT JOIN salesforce.CurrencyType cur ON dacv.Currency = cur.IsoCode
   INNER JOIN salesforce.account client ON dacv.`Client Id` = client.Id
   WHERE dacv.`De-Registered Date`>= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,'-07-01')
     AND dacv.`De-Registered Date`<= concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1),'-06-30')
     AND dacv.`Revenue Ownership` NOT LIKE '%Product%'
     AND dacv.`Business Line` NOT IN ('Product Services',
                                      'Retail')
     AND analytics.getRegionFromReportingBusinessUnit(dacv.`Revenue Ownership`) = 'EMEA' #and analytics.getCountryFromRevenueOwnership(dacv.`Revenue Ownership`) = 'UK'
   GROUP BY dacv.`Site Cert Std Id`,
            `Period`)
UNION ALL
  (SELECT 'Compass' AS 'Source',
          'Confirmed Days',
          analytics.getRegionFromCountry(country.Name),
          country.Name,
          '',
          'PFY',
          '',
          analytics.getFyAuditDays(country.Name,y.Name),
          'Days',
          analytics.getFyAuditDays(country.Name,y.Name),
          'Days',
          '',
          0,
          '',
          '',
          '',
          '',
          1
   FROM
     (SELECT year(concat(if(month(utc_timestamp())<7, year(utc_timestamp()), year(utc_timestamp())+1)-1,'-07-01')) AS 'Name') y,

     (SELECT 'UK' AS 'Name'
      UNION SELECT 'Czech Republic'
      UNION SELECT 'Egypt'
      UNION SELECT 'France'
      UNION SELECT 'Germany'
      UNION SELECT 'Ireland'
      UNION SELECT 'Italy'
      UNION SELECT 'Poland'
      UNION SELECT 'Russia'
      UNION SELECT 'South Africa'
      UNION SELECT 'Spain'
      UNION SELECT 'Sweden'
      UNION SELECT 'Turkey') country);