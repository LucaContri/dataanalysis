drop FUNCTION analytics.getAuditorHourlyRate;

DELIMITER //
CREATE FUNCTION analytics.getAuditorHourlyRate(resourceId VARCHAR(18)) RETURNS DECIMAL (18,10)
BEGIN
		DECLARE hourlyRate DECIMAL(18,10); 
        DECLARE defaultHourlyRate DECIMAL(18,10);
        SET defaultHourlyRate = (SELECT 110);
        SET hourlyRate = 
			(SELECT ifnull(ar.value/ct.ConversionRate, defaultHourlyRate ) 
			from analytics.auditor_rates_2 ar 
            inner join salesforce.currencytype ct on ar.currency_iso_code = ct.IsoCode
            where 
				ar.`Resource Id` = resourceId 
			order by FIELD(ar.`type`, 'ACTUAL', 'AVERAGE'), ar.`period` desc limit 1);
		SET hourlyRate = (select ifnull(hourlyRate, defaultHourlyRate));
        return hourlyRate;		
 END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION analytics.getAuditCostEmpirical(distance DECIMAL(18,10), audit_duration_hours INTEGER, resourceType VARCHAR(64), hourlyRate DECIMAL(18,10)) RETURNS DECIMAL (18,10)
BEGIN
		DECLARE cost DECIMAL(18,10); 
		DECLARE costDailySubsistence DECIMAL(18,10); 
		DECLARE costHotelDay DECIMAL(18,10);
		SET cost = (SELECT 0);
        SET costDailySubsistence = (select 40/0.7);
        SET costHotelDay = (select 100/0.7);
        
		# Resource Cost
        SET cost = 	(select cost + if(resourceType = 'Contractor', audit_duration_hours*hourlyRate,0));
		
        # Travel Cost 
		SET cost = (select cost + 
			   if(distance<=250,
				# Linear
				129 + 0.42022*distance*2,
				
				#Min Log and Linear
				least(129 + 0.42022*distance*2,315*log(distance/100)-94)
			   ));
		
		# Accommodation and Meals
		SET cost = (select cost 
			+ costDailySubsistence*ceil(audit_duration_hours/8));
		SET cost = (select cost
			+ if(distance<200, 0, costHotelDay*ceil(audit_duration_hours/8-1)));
		
        # If distance < 0 - > Error return infinite cost
        SET cost = (select cost + if (distance<0,99999999, 0)); 
		return cost;		
 END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION analytics.getTravelReturnTimeHrs(oneWayDistance DECIMAL(18,10)) RETURNS DECIMAL (18,10)
BEGIN
		DECLARE travelTime DECIMAL(18,10); 
		SET travelTime = (SELECT 
			IF(ifnull(oneWayDistance, 9999999) <0,
                16, # Error assume WCS = 16 hrs
                if(ifnull(oneWayDistance, 9999999)<300,
					oneWayDistance/50, # Assume Driving at average speed 50Km/hr
                    if(ifnull(oneWayDistance, 9999999)<1000,
						oneWayDistance/80, # Assume Driving/Train average speed 80Km/hr
						oneWayDistance/800 + 2 # Assume Flying at average speed 800Km/hr + 1 hrs take-off + 1 hr landing
					)
				)
			) 
			);
		SET travelTime = (SELECT 
				if(travelTime<2,
					0, # Done within audit day
                    if(travelTime<4,
						8, # 1/2 day for travel each way
						16 # WCS 1 day each way
					)
                )
			);
        return travelTime;		
 END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION analytics.getAuditCost(distance DECIMAL(18,10), audit_duration_hours INTEGER, resourceType VARCHAR(64), hourlyRate DECIMAL(18,10)) RETURNS DECIMAL (18,10)
BEGIN
		DECLARE cost DECIMAL(18,10); 
		DECLARE costMilageAUDperKm DECIMAL(18,10);
		DECLARE costAirportTransferReturn DECIMAL(18,10); 
		DECLARE costAirportParkingFirstDay DECIMAL(18,10);
		DECLARE costAirportParkingFollowingDays DECIMAL(18,10); 
		DECLARE costDomesticFlight DECIMAL(18,10); 
		DECLARE costDailySubsistence DECIMAL(18,10); 
		DECLARE costHotelDay DECIMAL(18,10);
		SET cost = (SELECT 0);
        SET costMilageAUDperKm = (select 0.5/0.7);
        SET costAirportTransferReturn = (select 120*costMilageAUDperKm);
        SET costAirportParkingFirstDay = (select 50/0.7);
        SET costAirportParkingFollowingDays = (select 25/0.7);
        SET costDomesticFlight = (select 200/0.7);
        SET costDailySubsistence = (select 40/0.7);
        SET costHotelDay = (select 100/0.7);
        
		# Resource Cost
        SET cost = 	(select cost + if(resourceType = 'Contractor', audit_duration_hours*hourlyRate,0));
		
        # Travel Cost 
		SET cost = (select cost + 
			   if(distance<=150,
				# Assume driving 
				costMilageAUDperKm*distance*2,
				
				#Flight or Train
				costDomesticFlight +
				#Home Train Station/Airport transfer
				costAirportTransferReturn +
				# Client Site Train Station/Airport transfer
				costAirportTransferReturn +
				# Airport Parking
				costAirportParkingFirstDay + costAirportParkingFollowingDays*ceil(audit_duration_hours/8-1)
			   ));
		
		# Accommodation and Meals
		SET cost = (select cost 
			+ costDailySubsistence*ceil(audit_duration_hours/8));
        SET cost = (select cost
			+ if(distance<200, 0, costHotelDay*ceil(audit_duration_hours/8-1)));
		
        # If distance < 0 - > Error return infinite cost
        SET cost = (select cost + if (distance<0,99999999, 0)); 
		return cost;		
 END //
DELIMITER ;


select * from salesforce.allocator_schedule_batch order by Id desc limit 10;

(SELECT wi.Id, wi.Name, s.WorkItemCountry, s.WorkItemState, wi.Location__c as 'WI Location', wi.Service_Delivery_Type__c, s.Duration,
	wi.Status__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Service_target_date__c, s.PrimaryStandard, s.Competencies, 
    ra.Name as 'Actual Scheduled Auditor', ra.Reporting_Business_Units__c, ra.Resource_Type__c, 2*analytics.distance(geo_wi.Latitude,geo_wi.Longitude,geo_r.Latitude,geo_r.Longitude) as 'Actual Distance',
    s.ResourceId, s.ResourceName as 'Allocator Resource', s.Status, s.Type, s.Distance as 'Allocator Distance', s.`Comment`, s.Notes, s.WorkItemGroup, 
ccs.Name as 'Resource Country',
r.Reporting_Business_Units__c, r.Resource_Type__c 
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
left join salesforce.country_code_setup__c ccs2 on site.Business_Country2__c = ccs2.Id
left join salesforce.state_code_setup__c scs2 on site.Business_State__c = scs2.Id
left join salesforce.resource__c ra on wi.Work_Item_Owner__c = ra.Id
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on ra.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on ra.Home_State_Province__c = scs.Id
left join salesforce.saig_geocode_cache geo_r on geo_r.Address = concat(
 ifnull(concat(ra.Home_Address_1__c,' '),''),
 ifnull(concat(ra.Home_Address_2__c,' '),''),
 ifnull(concat(ra.Home_Address_3__c,' '),''),
 ifnull(concat(ra.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(ra.Home_Postcode__c,' '),''))
left join salesforce.saig_geocode_cache geo_wi on geo_wi.Address = concat(
 ifnull(concat(site.Business_Address_1__c,' '),''),
 ifnull(concat(site.Business_Address_2__c,' '),''),
 ifnull(concat(site.Business_Address_3__c,' '),''),
 ifnull(concat(site.Business_City__c,' '),''),
 ifnull(concat(scs2.Name,' '),''),
 ifnull(concat(ccs2.Name,' '),''),
 ifnull(concat(site.Business_Zip_Postal_Code__c,' '),''))
 
where BatchId='Australia Food June 2016' and SubBatchId=30);


#Client Status, Client Number, Client Name, Service Delivery Coordinator, SAI Certificate Number, Expiry Date, SAI Site Certificate Status, Program, Pathway, Preferred Resource, Work Item Comment and Site Certification Comment
(SELECT s.*, wi.Service_Delivery_Type__c, wi.Open_Sub_Status__c, wi.Work_Item_Stage__c, wi.Location__c as 'WI Location',wi.Service_target_date__c,
concat(
 ifnull(concat(r.Home_Address_1__c,' '),''),
 ifnull(concat(r.Home_Address_2__c,' '),''),
 ifnull(concat(r.Home_Address_3__c,' '),''),
 ifnull(concat(r.Home_City__c,' '),''),
 ifnull(concat(scs.Name,' '),''),
 ifnull(concat(ccs.Name,' '),''),
 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
ccs.Name as 'Resource Country',
r.Reporting_Business_Units__c,
client.Status__c as 'Client Status',
client.Client_Number__c as 'Client Number',
client.Name as 'Client Name',
sdc.Name as 'Service Delivery Coordinator',
csp.SAI_Certificate_Number__c as 'SAI Certificate Number',
csp.Expires__c as 'Expiry Date',
scsp.Status__c as 'SAI Site Certificate Status',
p.Name as 'Program',
p.Pathway__c as 'Pathway',
pr.Name as 'Preferred Resource',
wi.Comments__c as 'WI Comments',
sc.Special_Requirements__c as 'Site Cert Comments'
 FROM salesforce.allocator_schedule s
inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
inner join salesforce.standard_program__c sp on scsp.Standard_Program__c = sp.Id
left join salesforce.resource__c pr on sc.Preferred_Resource_1__c = pr.Id
inner join salesforce.program__c p on sp.Program__c = p.Id
inner join salesforce.account site on sc.Primary_client__c = site.Id
inner join salesforce.account client on site.ParentId = client.Id
left join salesforce.user sdc on client.Service_Delivery_Coordinator__c = sdc.Id
inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
left join salesforce.resource__c r on s.ResourceId = r.Id
left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
where BatchId='Australia Food June 2016' and SubBatchId=49);


(select 
	t.*,
	analytics.getAuditCostEmpirical(t.`Distance`, t.`Required_Duration__c`, t.`ResourceType` , analytics.getAuditorHourlyRate(t.`ResourceId`) ) as 'Allocator Resource Calculated Cost',
    analytics.getAuditCostEmpirical(t.`Actual Resource Distance`, t.`Required_Duration__c`, t.`Actual Resource Type` , analytics.getAuditorHourlyRate(t.`Actual Resource Id`) ) as 'Actual Resource Calculated Cost' 
    from 
	(SELECT 
		s.*, 
		wi.Service_Delivery_Type__c, 
		wi.Open_Sub_Status__c, 
		wi.Work_Item_Stage__c, 
		wi.Location__c as 'WI Location', 
		wi.Work_Item_Date__c ,
        wi.Required_Duration__c ,
	concat(
	 ifnull(concat(r.Home_Address_1__c,' '),''),
	 ifnull(concat(r.Home_Address_2__c,' '),''),
	 ifnull(concat(r.Home_Address_3__c,' '),''),
	 ifnull(concat(r.Home_City__c,' '),''),
	 ifnull(concat(scs.Name,' '),''),
	 ifnull(concat(ccs.Name,' '),''),
	 ifnull(concat(r.Home_Postcode__c,' '),'')) as 'Resource Location', 
	ccs.Name as 'Resource Country'    ,
	r.Reporting_Business_Units__c ,
	ar.NAme as 'Actual Resource',
    ar.Id as 'Actual Resource Id',
    ar.Resource_Type__c as 'Actual Resource Type',
	concat(
	 ifnull(concat(ar.Home_Address_1__c,' '),''),
	 ifnull(concat(ar.Home_Address_2__c,' '),''),
	 ifnull(concat(ar.Home_Address_3__c,' '),''),
	 ifnull(concat(ar.Home_City__c,' '),''),
	 ifnull(concat(ascs.Name,' '),''),
	 ifnull(concat(accs.Name,' '),''),
	 ifnull(concat(ar.Home_Postcode__c,' '),'')) as 'Actual Resource Location',
	 analytics.distance(geo.Latitude, geo.Longitude, sgeo.Latitude, sgeo.Longitude)*2 as 'Actual Resource Distance'
	 FROM salesforce.allocator_schedule s
	inner join salesforce.work_item__c wi on left(s.WorkItemId,18) = wi.Id
	left join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
	left join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
	left join salesforce.account site on sc.Primary_client__c = site.Id
	left join salesforce.country_code_setup__c sccs on site.Business_Country2__c = sccs.Id
	left join salesforce.state_code_setup__c sscs on site.Business_State__c = sscs.Id
	left join salesforce.saig_geocode_cache sgeo on concat(
													 ifnull(concat(site.Business_Address_1__c ,' '),''),
													 ifnull(concat(site.Business_Address_2__c,' '),''),
													 ifnull(concat(site.Business_Address_3__c,' '),''),
													 ifnull(concat(site.Business_City__c ,' '),''),
													 ifnull(concat(sscs.Name,' '),''),
													 ifnull(concat(sccs.Name,' '),''),
													 ifnull(concat(site.Business_Zip_Postal_Code__c ,' '),'')) = sgeo.Address
	left join salesforce.work_item_resource__c wir on wir.Work_Item__c = wi.Id and wir.Work_Item_Type__c = 'Audit' and wir.IsDeleted = 0
	left join salesforce.resource__c ar on wir.Resource__c = ar.Id
	left join salesforce.country_code_setup__c accs on ar.Home_Country1__c = accs.Id
	left join salesforce.state_code_setup__c ascs on ar.Home_State_Province__c = ascs.Id
	left join salesforce.saig_geocode_cache geo on concat(
													 ifnull(concat(ar.Home_Address_1__c,' '),''),
													 ifnull(concat(ar.Home_Address_2__c,' '),''),
													 ifnull(concat(ar.Home_Address_3__c,' '),''),
													 ifnull(concat(ar.Home_City__c,' '),''),
													 ifnull(concat(ascs.Name,' '),''),
													 ifnull(concat(accs.Name,' '),''),
													 ifnull(concat(ar.Home_Postcode__c,' '),'')) = geo.Address
	left join salesforce.resource__c r on s.ResourceId = r.Id
	left join salesforce.country_code_setup__c ccs on r.Home_Country1__c = ccs.Id
	left join salesforce.state_code_setup__c scs on r.Home_State_Province__c = scs.Id
	where BatchId='UK Forward Planning' and SubBatchId=3
    and s.`Type` = 'AUDIT'
	group by s.`WorkItemId`, s.`Type`
	) t
);