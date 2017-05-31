LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 5.6/Uploads/export (6).csv'
INTO TABLE analytics.brc_sample_data
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select * from analytics.brc_sample_data;

(select 
	analytics.getRegionFromCountry(brc.Country) as 'Region', 
    brc.Country, 
    if(month(brc.Audit_Date)>6, 1,0)+year(brc.Audit_Date) as 'FY', 
    brc.Standard, 
    count(distinct brc.Site_Code) as '# Sites', 
    count(brc.Audit_Date) as '# Audit',
    max(brc.Audit_Date) as 'Last Audit Date'
from analytics.brc_sample_data brc
group by `Region`, `Country`, `FY`, brc.Standard);