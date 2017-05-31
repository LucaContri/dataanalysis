select * from salesforce.allocator_schedule_batch order by Id desc limit 2;

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
where BatchId='PS Open Backlog All' and SubBatchId=67);
