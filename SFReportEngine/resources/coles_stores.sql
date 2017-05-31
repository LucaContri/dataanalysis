(SELECT * FROM analytics.coles_stores where Latitude is null);

#(select concat('[\'',t.Latitude, ' ', t.Longitude, '\', \'', replace(replace(concat(t.Name, ' ', t.Address),'\'', ' '),'\n',' '),'\', \'', if(t.`Closest SAIG Office` like 'Adelaide%', 'in_blue', if(t.`Closest SAIG Office` like 'Brisbane%', 'in_green', if(t.`Closest SAIG Office` like 'Perth%', 'in_pink', if(t.`Closest SAIG Office` like 'Sydney%', 'out_blue', 'out_pink')))), '\'],') as 'js_office'
#from
(select s.*,
if(s.`Category` like 'Distribution Centre', 'small_green', if(s.`Category` like 'Retail Liquor', 'small_red', if(s.`Category` like 'Spirit Hotels', 'small_yellow', if(s.`Category` like 'Supermarket', 'measle_turquoise', 'small_purple')))) as 'category_market',
if(s.`Closest SAIG Office` like 'Adelaide%', 'small_green', if(s.`Closest SAIG Office` like 'Brisbane%', 'small_red', if(s.`Closest SAIG Office` like 'Perth%', 'small_yellow', if(s.`Closest SAIG Office` like 'Sydney%', 'measle_turquoise', 'small_purple')))) as 'office_market'
from (
select coles.*,
	saig_office.Name as 'Closest SAIG Office',
    saig_office.latitude as 'SAIG office Lat',
    saig_office.longitude as 'SAIG office Lng',
	salesforce.distance(saig_office.latitude, saig_office.longitude, coles.Latitude, coles.Longitude) as 'Distance'
from (
	select cs.Store_No,cs.Category, cs.Brand as 'Name', cs.Address, cs.Suburb, cs.State, cs.Postcode, 
	if (cs.latitude is null, pg.latitude, cs.latitude) as 'Latitude', 
	if (cs.longitude is null, pg.longitude, cs.longitude) as 'Longitude', 
	if (cs.latitude is null or cs.longitude is null, 'PostCode', 'Exact') as 'GeoLocation Type'
	from analytics.coles_stores cs
	left join analytics.postcodes_geo pg on cs.postcode = pg.postcode COLLATE utf8_unicode_ci
    #where cs.Store_No=704
    group by cs.Store_No
    ) coles, 
	(select substring_index(address,' | ',-1) as 'Name', Latitude,Longitude from salesforce.saig_geocode_cache where Address like 'SAIG Office | Australia %') saig_office
order by coles.Store_No, `Distance`) s
group by s.Store_No) ;
#t);




insert into salesforce.saig_geocode_cache (Address, Latitude, Longitude) VALUES ('SAIG Office | Australia | Adelaide - Pirie St', -34.9256609, 138.6017570);
insert into salesforce.saig_geocode_cache (Address, Latitude, Longitude) VALUES ('SAIG Office | Australia | Brisbane - Little Edward St', -27.4615678, 153.0243378);
insert into salesforce.saig_geocode_cache (Address, Latitude, Longitude) VALUES ('SAIG Office | Australia | Perth - Adelaide Terrace', -31.9596062, 115.8709830);
insert into salesforce.saig_geocode_cache (Address, Latitude, Longitude) VALUES ('SAIG Office | Australia | Sydney - George St', -33.877216, 151.206819);
insert into salesforce.saig_geocode_cache (Address, Latitude, Longitude) VALUES ('SAIG Office | Australia | West Melbourne - Spencer St', -37.8165136, 144.9530850);

