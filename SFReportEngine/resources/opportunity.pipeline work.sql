create index oppSites_Opportunity_index on oppSites(Opportunity__c);
create index oppSites_Client_Site_index on oppSites(Client_Site(128));
create index oppSites_Standard_index on oppSites(Standard__c);
create index account_name_index on salesforce.account(Name(128));

drop procedure AnalyticsUpdateOpportunitySites;
DELIMITER //
CREATE PROCEDURE AnalyticsUpdateOpportunitySites()
 BEGIN
truncate analytics.oppSites;
insert into analytics.oppSites 
(select osc.Opportunity__c, site.Id as 'Client Site Id', site.Name as 'Client_Site', site.Location__c as 'Client_Site_Location', s.Parent_Standard__c, s.Id as 'Standard__c', s.Name as 'Standard_Name',  group_concat(oscsc.Code__c) as 'codes'
	from salesforce.opportunity_site_certification__c osc 
	left join salesforce.Account site on osc.Client_Site__c = site.Id
	left join salesforce.oppty_site_cert_standard_program__c oscsp on oscsp.Opportunity_Site_Certification__c = osc.Id
	left join salesforce.standard_program__c sp on oscsp.Standard_Program__c = sp.Id
    left join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.Opportunity_Site_Certification_Code__c oscsc on oscsc.Oppty_Site_Cert_Standard_Program__c = oscsp.Id
	group by osc.Id);
 END //
DELIMITER ;
call AnalyticsUpdateOpportunitySites();

select * from analytics.oppSites where Opportunity__c='006d000000RMUyOAAX' and Client_Site_Location='285 Kildonan Road, Goondiwindi, QLD, 4390, Australia';#and Standard__c = 'a36900000004EwlAAE';

#explain
select opp4.*, oppSite.codes as 'codeIds', oppSite.Standard__c as 'Standard Id',  oppSite.Standard_Name as 'Standard Name',
	site.Id as 'Client Site Id', site.Name as 'Client Site Name', site.Business_Address_1__c as 'Client Site Address1', site.Business_Address_2__c as 'Client Site Address2', site.Business_Address_3__c as 'Client Site Address3', site.Business_City__c as 'Client Site City', site.Business_Zip_Postal_Code__c as 'Client Site Postcode', ccs.Name as 'Client Site Country', scs.Name as 'Client Site State', scs.State_Code_c__c as 'Client State State Description',
    geocache.Latitude as 'Client Site Cached Latitude', geocache.Longitude as 'Client Site Cached Longitude', site.Latitude__c as 'Client Site Latitude', site.Longitude__c as 'Client Site Longitude',
    sp.Program_Business_Line__c
    from (
	select opp3.*, group_concat(opp3.Product_Type__c)  from (
	select 
		opp2.*
	from
		(select opp.*, 
			oli.Client_Site__c, oli.Site_Location__c, p.Standard__c as 'Parent Standard Id', oli.Standard_Service_Type__c as 'Parent Standard Name', p.Service_Type__c, p.Product_Type__c, sum(if(p.UOM__c='DAY',oli.Quantity*8, if(p.UOM__c='HFD', oli.Quantity*4, oli.Quantity))) as 'Required Duration'
		from 
			(select 
				a.Client_Ownership__c, a.Name as 'Client Name', a.Id as 'Client Id',
				o.Id as 'Opportunity Id', o.Name as 'Opportunity Name', o.Quote_Ref__c, o.CreatedDate, ow.Name as 'Owner', o.StageName, o.Probability, o.Proposed_Delivery_Date__c, o.Proposed_Sent_Date__c, timestampdiff(day, o.CreatedDate, utc_timestamp()) as 'Aging'
			from salesforce.opportunity o
			inner join salesforce.account a on o.AccountId = a.Id
			inner join salesforce.user ow on o.Opportunity_Owner__c = left(ow.Id,15)
			where
				a.Client_Ownership__c = 'Australia'
				and o.IsDeleted = 0
				and o.StageName not in ('Closed Won', 'Closed Lost', 'Budget')
				and o.Proposed_Delivery_Date__c is not null
				and o.Proposed_Delivery_Date__c > now()
				#and timestampdiff(day, o.CreatedDate, utc_timestamp())<180
				and ow.IsActive=1) opp
			inner join salesforce.opportunitylineitem oli on opp.`Opportunity Id` = oli.OpportunityId and oli.IsDeleted=0 and oli.Days__c>0
			inner join salesforce.product2 p on oli.Product2Id = p.Id
		group by opp.`Opportunity Id`, oli.Client_Site__c, p.Standard__c, p.Product_Type__c) opp2
		order by opp2.`Opportunity Id`, opp2.Client_Site__c, opp2.`Parent Standard Id`, field(opp2.Product_Type__c,'Gap','Stage 1','Stage 2','Initial Verification', 'Initial Inspection', 'Verification', 'Inspection', 'Assessment', 'Customised', 'Unannounced Certification','Unannounced Re-Certification','Unannounced Special','Unannounced Surveillance','Unannounced Verification', 'Surveillance','Certification', 'Re-Certification', 'Application','Technical Review','Client Management')) opp3
	group by opp3.`Opportunity Id`, opp3.Client_Site__c, opp3.`Parent Standard Id`) opp4
    left join analytics.oppSites oppSite on opp4.`Opportunity Id`= oppSite.Opportunity__c and opp4.Client_Site__c = oppSite.Client_Site and opp4.Site_Location__c = oppSite.Client_Site_Location and opp4.`Parent Standard Id` = oppSite.Parent_Standard__c
    left join salesforce.account site on oppSite.Client_Site_Id = site.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
    left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id
    left join salesforce.saig_geocode_cache geocache on geocache.Address = concat(
					ifnull(concat(site.Business_Address_1__c,' '),''),
					ifnull(concat(site.Business_Address_2__c,' '),''),
					ifnull(concat(site.Business_Address_3__c,' '),''),
					ifnull(concat(site.Business_City__c,' '),''),
					ifnull(concat(scs.Name,' '),''),
					ifnull(concat(ccs.Name,' '),''),
					ifnull(concat(site.Business_Zip_Postal_Code__c,' '),''))
	left join salesforce.standard_program__c sp on oppSite.`Standard__c` = sp.Standard__c;
    
select opp4.*, oppSite.codes as 'codeIds', oppSite.Standard__c as 'Standard Id',  oppSite.Standard_Name as 'Standard Name', site.Id as 'Client Site Id', site.Name as 'Client Site Name', site.Business_Address_1__c as 'Client Site Address1', site.Business_Address_2__c as 'Client Site Address2', site.Business_Address_3__c as 'Client Site Address3', site.Business_City__c as 'Client Site City', site.Business_Zip_Postal_Code__c as 'Client Site Postcode', ccs.Name as 'Client Site Country', scs.Name as 'Client Site State', scs.State_Code_c__c as 'Client State State Description',     geocache.Latitude as 'Client Site Cached Latitude', geocache.Longitude as 'Client Site Cached Longitude', site.Latitude__c as 'Client Site Latitude', site.Longitude__c as 'Client Site Longitude'     from ( select opp3.*, group_concat(opp3.Product_Type__c)  from ( select  opp2.* from (select opp.*,  oli.Client_Site__c, p.Standard__c as 'Parent Standard Id', oli.Standard_Service_Type__c as 'Parent Standard Name', p.Service_Type__c, p.Product_Type__c, sum(if(p.UOM__c='DAY',oli.Quantity*8, if(p.UOM__c='HFD', oli.Quantity*4, oli.Quantity))) as 'Required Duration' from  (select  a.Client_Ownership__c, a.Name as 'Client Name', a.Id as 'Client Id', o.Id as 'Opportunity Id', o.Name as 'Opportunity Name', o.Quote_Ref__c, o.CreatedDate, ow.Name as 'Owner', o.StageName, o.Probability, o.Proposed_Delivery_Date__c, o.Proposed_Sent_Date__c, timestampdiff(day, o.CreatedDate, utc_timestamp()) as 'Aging' from salesforce.opportunity o inner join salesforce.account a on o.AccountId = a.Id inner join salesforce.user ow on o.Opportunity_Owner__c = left(ow.Id,15) where a.Client_Ownership__c = 'Australia' and o.IsDeleted = 0 and o.StageName not in ('Closed Won', 'Closed Lost', 'Budget') and o.Proposed_Delivery_Date__c is not null and o.Proposed_Delivery_Date__c > now() and o.Proposed_Delivery_Date__c between '2016-06-01 00:00:00' and '2016-08-31 23:59:59' and ow.IsActive=1) opp inner join salesforce.opportunitylineitem oli on opp.`Opportunity Id` = oli.OpportunityId and oli.IsDeleted=0 and oli.Days__c>0 inner join salesforce.product2 p on oli.Product2Id = p.Id group by opp.`Opportunity Id`, oli.Client_Site__c, p.Standard__c, p.Product_Type__c) opp2 order by opp2.`Opportunity Id`, opp2.Client_Site__c, opp2.`Parent Standard Id`, field(opp2.Product_Type__c,'Gap','Stage 1','Stage 2','Initial Verification', 'Initial Inspection', 'Verification', 'Inspection', 'Assessment', 'Customised', 'Unannounced Certification','Unannounced Re-Certification','Unannounced Special','Unannounced Surveillance','Unannounced Verification', 'Surveillance','Certification', 'Re-Certification', 'Application','Technical Review','Client Management')) opp3 group by opp3.`Opportunity Id`, opp3.Client_Site__c, opp3.`Parent Standard Id`) opp4     left join analytics.oppSites oppSite on opp4.`Opportunity Id`= oppSite.Opportunity__c and opp4.Client_Site__c = oppSite.Client_Site and opp4.`Parent Standard Id` = oppSite.Parent_Standard__c     left join salesforce.account site on oppSite.Client_Site_Id = site.Id     left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id     left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id     left join salesforce.saig_geocode_cache geocache on geocache.Address = concat( ifnull(concat(site.Business_Address_1__c,' '),''), ifnull(concat(site.Business_Address_2__c,' '),''), ifnull(concat(site.Business_Address_3__c,' '),''), ifnull(concat(site.Business_City__c,' '),''), ifnull(concat(scs.Name,' '),''), ifnull(concat(ccs.Name,' '),''), ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) left join salesforce.standard_program__c sp on oppSite.`Standard__c` = sp.Standard__c where sp.Program_Business_Line__c='Agri-Food';