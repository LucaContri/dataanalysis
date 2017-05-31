package com.saiglobal.sf.allocator.processor;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;

import com.google.code.geocoder.model.LatLng;
import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Availability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Capability;
import com.saiglobal.sf.allocator.rules.ProcessorRule_Distance;
import com.saiglobal.sf.allocator.rules.ProcessorRule_OpenSubStatus;
import com.saiglobal.sf.allocator.rules.ProcessorRule_ResourceType;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Client;
import com.saiglobal.sf.core.model.ClientSite;
import com.saiglobal.sf.core.model.Competency;
import com.saiglobal.sf.core.model.CompetencyType;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SFWorkItemType;
import com.saiglobal.sf.core.model.Schedule;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.ScheduleType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.model.WorkItemSource;
import com.saiglobal.sf.core.model.WorkItemStatus;
import com.saiglobal.sf.core.utility.Utility;

public class ProcessorAustraliaFood extends AbstractProcessor {
	private static List<ProcessorRule> rules = new ArrayList<ProcessorRule>(); 
	
	public ProcessorAustraliaFood(DbHelper db, ScheduleParameters parameters) throws Exception {
		super(db, parameters);
		rules.add(new ProcessorRule_OpenSubStatus());
		rules.add(new ProcessorRule_Capability());
		rules.add(new ProcessorRule_Availability());
		rules.add(new ProcessorRule_Distance(db));
		rules.add(new ProcessorRule_ResourceType());
	}
	
	@Override
	public int getBatchSize() {
		return 100000;
	}

	@Override
	protected List<Resource> sortResources(List<Resource> resourceList) {
		Comparator<Resource> byScore = (r1, r2) -> Double.compare(
	            r1.getScore(), r2.getScore());
		resourceList = resourceList.stream().sorted(byScore.reversed()).collect(Collectors.toList());
		for (Resource resource : resourceList) {
			logger.debug("Resource: " + resource.getName() + ". Score: " + resource.getScore());
		}
		return resourceList;
	};
	
	@Override
	protected List<WorkItem> sortWorkItems(List<WorkItem> workItemList) {
		Utility.startTimeCounter("BasicProcessor.sortWorkItems");
		ProcessorRule_Capability p = new ProcessorRule_Capability();
		for (WorkItem aWorkItem : workItemList) {
			//aWorkItem.setFrequencyOfCapabilities(uniqueCompetencyMap.get(aWorkItem.getRequiredCompetenciesString()));
			try {
				aWorkItem.setFrequencyOfCapabilities(p.filter(aWorkItem, resources, db, parameters).size());
			} catch (Exception e) {
				// ignore
				aWorkItem.setFrequencyOfCapabilities(1);
				e.printStackTrace();
			}
		}
		
		@SuppressWarnings("unused")
		Comparator<WorkItem> byCustomStandard = (wi1, wi2) -> Long.compare(
	            wi1.getPrimaryStandard().getCompetencyName().startsWith("CODEX HACCP - 2003")?0:1, 
	            wi2.getPrimaryStandard().getCompetencyName().startsWith("CODEX HACCP - 2003")?0:1);
		Comparator<WorkItem> byDate = (wi1, wi2) -> Long.compare(
	            wi1.getTargetDate().getTime(), wi2.getTargetDate().getTime());
		Comparator<WorkItem> byComplexity = (wi1, wi2) -> Long.compare(
	            wi1.getFrequencyOfCapabilities(), wi2.getFrequencyOfCapabilities());
		//workItemList = workItemList.stream().sorted(byCustomStandard.thenComparing(byDate.thenComparing(byComplexity))).collect(Collectors.toList());
		workItemList = workItemList.stream().sorted(byDate.thenComparing(byComplexity)).collect(Collectors.toList());
		
		Utility.stopTimeCounter("BasicProcessor.sortWorkItems");
		return workItemList;
	}

	@Override
	protected List<WorkItem> getPipelineWorkItems() {
		ArrayList<WorkItem> pipelineWI = new ArrayList<WorkItem>();
		
		String select = "select opp4.*, oppSite.codes as 'codeIds', oppSite.Standard__c as 'Standard Id',  oppSite.Standard_Name as 'Standard Name', "
				+ "site.Id as 'Client Site Id', site.Name as 'Client Site Name', site.Business_Address_1__c as 'Client Site Address1', site.Business_Address_2__c as 'Client Site Address2', site.Business_Address_3__c as 'Client Site Address3', site.Business_City__c as 'Client Site City', site.Business_Zip_Postal_Code__c as 'Client Site Postcode', ccs.Name as 'Client Site Country', scs.Name as 'Client Site State', scs.State_Code_c__c as 'Client State State Description', "
				+ "    geocache.Latitude as 'Client Site Cached Latitude', geocache.Longitude as 'Client Site Cached Longitude', site.Latitude__c as 'Client Site Latitude', site.Longitude__c as 'Client Site Longitude' "
				+ "    from ( "
				+ "select opp3.*, group_concat(opp3.Product_Type__c)  from ( "
				+ "select  "
				+ "opp2.* "
				+ "from "
				+ "(select opp.*,  "
				+ "oli.Client_Site__c, p.Standard__c as 'Parent Standard Id', oli.Standard_Service_Type__c as 'Parent Standard Name', p.Service_Type__c, p.Product_Type__c, sum(if(p.UOM__c='DAY',oli.Quantity*8, if(p.UOM__c='HFD', oli.Quantity*4, oli.Quantity))) as 'Required Duration' "
				+ "from  "
				+ "(select  "
				+ "a.Client_Ownership__c, a.Name as 'Client Name', a.Id as 'Client Id', "
				+ "o.Id as 'Opportunity Id', o.Name as 'Opportunity Name', o.Quote_Ref__c, o.CreatedDate, ow.Name as 'Owner', o.StageName, o.Probability, o.Proposed_Delivery_Date__c, o.Proposed_Sent_Date__c, timestampdiff(day, o.CreatedDate, utc_timestamp()) as 'Aging' "
				+ "from salesforce.opportunity o "
				+ "inner join salesforce.account a on o.AccountId = a.Id "
				+ "inner join salesforce.user ow on o.Opportunity_Owner__c = left(ow.Id,15) "
				+ "where "
				+ "a.Client_Ownership__c = 'Australia' "
				+ "and o.IsDeleted = 0 "
				+ "and o.StageName not in ('Closed Won', 'Closed Lost', 'Budget') "
				+ "and o.Proposed_Delivery_Date__c is not null "
				+ "and o.Proposed_Delivery_Date__c > now() "
				+ "and o.Proposed_Delivery_Date__c between '" + Utility.getMysqldateformat().format(parameters.getStartDate().getTime()) + "' and '" + Utility.getMysqldateformat().format(parameters.getEndDate().getTime()) + "' "
				+ "and ow.IsActive=1) opp "
				+ "inner join salesforce.opportunitylineitem oli on opp.`Opportunity Id` = oli.OpportunityId and oli.IsDeleted=0 and oli.Days__c>0 "
				+ "inner join salesforce.product2 p on oli.Product2Id = p.Id "
				+ "group by opp.`Opportunity Id`, oli.Client_Site__c, p.Standard__c, p.Product_Type__c) opp2 "
				+ "order by opp2.`Opportunity Id`, opp2.Client_Site__c, opp2.`Parent Standard Id`, field(opp2.Product_Type__c,'Gap','Stage 1','Stage 2','Initial Verification', 'Initial Inspection', 'Verification', 'Inspection', 'Assessment', 'Customised', 'Unannounced Certification','Unannounced Re-Certification','Unannounced Special','Unannounced Surveillance','Unannounced Verification', 'Surveillance','Certification', 'Re-Certification', 'Application','Technical Review','Client Management')) opp3 "
				+ "group by opp3.`Opportunity Id`, opp3.Client_Site__c, opp3.`Parent Standard Id`) opp4 "
				+ "    left join analytics.oppSites oppSite on opp4.`Opportunity Id`= oppSite.Opportunity__c and opp4.Client_Site__c = oppSite.Client_Site and opp4.`Parent Standard Id` = oppSite.Parent_Standard__c "
				+ "    left join salesforce.account site on oppSite.Client_Site_Id = site.Id "
				+ "    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id "
				+ "    left join salesforce.state_code_setup__c scs on site.Business_State__c = scs.Id "
				+ "    left join salesforce.saig_geocode_cache geocache on geocache.Address = concat( "
				+ "ifnull(concat(site.Business_Address_1__c,' '),''), "
				+ "ifnull(concat(site.Business_Address_2__c,' '),''), "
				+ "ifnull(concat(site.Business_Address_3__c,' '),''), "
				+ "ifnull(concat(site.Business_City__c,' '),''), "
				+ "ifnull(concat(scs.Name,' '),''), "
				+ "ifnull(concat(ccs.Name,' '),''), "
				+ "ifnull(concat(site.Business_Zip_Postal_Code__c,' '),'')) "
				+ "left join salesforce.standard_program__c sp on oppSite.`Standard__c` = sp.Standard__c "
				+ "where sp.Program_Business_Line__c='Agri-Food';";
		try {
			// Init
			db.executeStatement("call analytics.AnalyticsUpdateOpportunitySites();");
			
			ResultSet rs = db.executeSelectThreadSafe(select, -1);
			while (rs.next()) {
				WorkItem wi = new WorkItem();
				wi.setId(rs.getString("Opportunity Id") + '-' + rs.getString("Client Site Id") + '-' + rs.getString("Standard Id"));
				wi.setName(rs.getString("Opportunity Name") + '-' + rs.getString("Client Site Name") + '-' + rs.getString("Standard Name"));
				wi.setWorkItemSource(WorkItemSource.COMPASS_PIPELINE);
				wi.setStartDate(rs.getDate("Proposed_Delivery_Date__c"));
				wi.setTargetDate(rs.getDate("Proposed_Delivery_Date__c"));
				wi.setLocalStatus(WorkItemStatus.OPEN);
				//wi.setSfStatus(SfWorkItemStatus.Open);
				wi.setAllocatedResources(new ArrayList<Resource>());
				wi.setRequiredDuration(rs.getDouble("Required Duration"));
				wi.setServiceDeliveryType("On Site");
				
				// Client
				Client client = new Client();
				client.setName(rs.getString("Client Name"));
				client.setId(rs.getString("Client Id"));
				
				// Client Site
				ClientSite clientSite = new ClientSite();
				clientSite.setName(rs.getString("Client Site Name"));
				clientSite.setId(rs.getString("Client Site Id"));
					Location clientSiteLocation = new Location();
					clientSiteLocation.setAddress_1(rs.getString("Client Site Address1"));
					clientSiteLocation.setAddress_2(rs.getString("Client Site Address2"));
					clientSiteLocation.setAddress_3(rs.getString("Client Site Address3"));
					clientSiteLocation.setCity(rs.getString("Client Site City"));
					clientSiteLocation.setState(rs.getString("Client Site State"));
					clientSiteLocation.setStateDescription(rs.getString("Client State State Description"));
					clientSiteLocation.setCountry(rs.getString("Client Site Country"));
					clientSiteLocation.setPostCode(rs.getString("Client Site Postcode"));
					clientSiteLocation.setLatitude(rs.getDouble("Client Site Cached Latitude"));
					clientSiteLocation.setLongitude(rs.getDouble("Client Site Cached Longitude"));
					if(rs.getDouble("Client Site Cached Latitude")==0 || rs.getDouble("Client Site Cached Longitude")==0) {
						clientSiteLocation.setLatitude(rs.getDouble("Client Site Latitude"));
						clientSiteLocation.setLongitude(rs.getDouble("Client Site Longitude"));
						// Latitude and Longitude from Compass are not reliable.  Using Geocoding API with local cache
						LatLng coordinates = null;
						try {
							coordinates = Utility.getGeocode(clientSiteLocation, db);
							if (coordinates != null) {
								clientSiteLocation.setLatitude(coordinates.getLat().doubleValue());
								clientSiteLocation.setLongitude(coordinates.getLng().doubleValue());
							}
						} catch (GeoCodeApiException gcae) {
							// Ignore and Carry on.  Can't stop the world because we can't get geocodes :)
						}
					}
					
				clientSite.setLocation(clientSiteLocation);
				List<ClientSite> clientSites = new ArrayList<ClientSite>();
				clientSites.add(clientSite);
				client.setClientSites(clientSites);
				
				wi.setClientSite(clientSiteLocation);
				wi.setClient(client);
				
				wi.setType(SFWorkItemType.getValueForName(rs.getString("Product_Type__c")));
				
				// Set Competencies
				List<Competency> requiredCompetencies = new ArrayList<Competency>();
				requiredCompetencies.add(new Competency(rs.getString("Standard Id"), rs.getString("Standard Name"), CompetencyType.PRIMARYSTANDARD, null));

				if (rs.getString("codeIds")!=null) {
					String[] codesIds = rs.getString("codeIds").split(",");
					for (String codeId : codesIds) {
						requiredCompetencies.add(new Competency(codeId, codeId, CompetencyType.CODE, null));
					}
				}
				wi.setRequiredCompetencies(requiredCompetencies);
				pipelineWI.add(wi);
			}
		} catch (ClassNotFoundException | IllegalAccessException | InstantiationException | SQLException e) {
			logger.error(e.getMessage());
		}
		
		return pipelineWI;
	};
	
	@Override
	protected Logger initLogger() {
		return Logger.getLogger(ProcessorAustraliaFood.class.toString()); 
	}
	
	@Override
	public List<ProcessorRule> getRules() {
		return rules;
	};
	
	@Override
	public void init() throws Exception {
		super.init();

		// Group WI by location target date
		//Map<String, WorkItem> wiMap = workItemList.stream()
		//.collect(
		//		Collectors.groupingBy(WorkItem::getClientLocationAndTargetDate, 
		//		Collector.of( WorkItem::new, WorkItem::add, WorkItem::combine)));
		//
		//workItemList = new ArrayList<WorkItem>(wiMap.values());
	
	}
	
	@Override
	protected void postProcessTravel(List<Schedule> schedules, Schedule travel) throws Exception {
		// Heuristic Milk run
		// If travel distance is > 2000 and resource have audits already scheduled closer than their home location, then group them together
		if(travel.getDistanceKm()>2000) {
			Comparator<Schedule> byDistance = (s1, s2) -> Double.compare(
					Utility.calculateDistanceKm(s1.getLatitude(), s1.getLongitude(), travel.getLatitude(), travel.getLongitude()),
					Utility.calculateDistanceKm(s2.getLatitude(), s2.getLongitude(), travel.getLatitude(), travel.getLongitude()));
			
			Optional<Schedule> closer = schedules
				.stream()
				.filter(s -> s.getType().equals(ScheduleType.TRAVEL) && 
						s.getResourceId().equalsIgnoreCase(travel.getResourceId()) 
						&& s.getWorkItemCountry().equalsIgnoreCase(travel.getWorkItemCountry()) 
						//&& s.getStartPeriod().equalsIgnoreCase(travel.getStartPeriod())
						)
				.sorted(byDistance)
				.findFirst();
			if (closer.isPresent() && Utility.calculateDistanceKm(closer.get().getLatitude(), closer.get().getLongitude(), travel.getLatitude(), travel.getLongitude())<travel.getDistanceKm()) {
				travel.setWorkItemGroup(closer.get().getWorkItemGroup());
				travel.setDistanceKm(Utility.calculateDistanceKm(closer.get().getLatitude(), closer.get().getLongitude(), travel.getLatitude(), travel.getLongitude()));
				travel.setComment("Travel from " + closer.get().getWorkItemName() + " to " + travel.getWorkItemName());
				//travel.setDuration(0);
			}
		}
	}

	@Override
	protected void postProcessWorkItemList() {
		// TODO Auto-generated method stub
		
	}
}
