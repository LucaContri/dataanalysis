package com.saiglobal.sf.core.schedule;



import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfSaigOffice;
import com.saiglobal.sf.core.model.TravelType;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_TravelCostFromOffice extends AbstractBusinessRule {

	private static final double metroAreaRadius = 60;
	private static final double loss_revenue_hourly_rate = 100;
	private static final double driving_average_speed = 50;
	private static final Logger logger = Logger.getLogger(BusinessRule_TravelCostFromOffice.class);
	public BusinessRule_TravelCostFromOffice(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		logger.debug("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input");
		Utility.startTimeCounter("BusinessRule_TravelCostFromOffice");
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		
		List<String> whereClauseList = new ArrayList<String>();
		List<String> whereClauseList_2 = new ArrayList<String>();
		if (!emptyInput) {
			String resourceIdInClause = "r.Id IN (";
			boolean first = true;
			for (String resourceId : resourceIdWithScore.keySet()) {
				if (first) {
					resourceIdInClause += "'" + resourceId + "'";
					first = false;
				} else {
					resourceIdInClause += ", '" + resourceId + "'";
				}
			}
			resourceIdInClause += ")";
			whereClauseList.add(resourceIdInClause);
			whereClauseList_2.add(resourceIdInClause);
		}
		whereClauseList_2.add("c.Latitude is null");
		whereClauseList_2.add("c.Longitude is null");
		
		if ((workItem.getClientSite()==null) ) {
			logger.error("Missing client site.  Cannot calculate distance.  Returning input list unchanged");
			return resourceIdWithScore;
		}
		
		if ((workItem.getClientSite().getLatitude() == 0) || (workItem.getClientSite().getLongitude() == 0)) {
			logger.error("Missing coordinates for ClientSite.  Cannot calculate distance.  Returning input list unchanged");
			return resourceIdWithScore;
		}
		
		// First we need to check we have resource coordinate on cache;
		String query = "SELECT " +
				"r.Id, " +
				"r.FLocation_Home__c " +
				"FROM resource__c r " +
				"LEFT JOIN saig_geocode_cache c on c.Address = r.FLocation_Home__c " +
				db.getWhereClause(whereClauseList_2);
		
		ResultSet rs = db.executeSelect(query, -1);
		while (rs.next()) {
			// This will look up geocode up and store it in cache for next query
			Utility.getGeocode(rs.getString("r.FLocation_Home__c"), rs.getString("r.FLocation_Home__c"), db);
		}
		
		query = "SELECT " +
				"r.Id, " +
				"r.Managing_Office__c, " +
				"DISTANCE(" + workItem.getClientSite().getLatitude() + ", " + workItem.getClientSite().getLongitude() + ", co.Latitude, co.Longitude) as 'distance_office', " +
				"DISTANCE(" + workItem.getClientSite().getLatitude() + ", " + workItem.getClientSite().getLongitude() + ", cr.Latitude, cr.Longitude) as 'distance_home' " +
				"FROM resource__c r " +
				"LEFT JOIN saig_geocode_cache co on co.Address = concat('SAIG Office | ', r.Managing_Office__c) " +
				"LEFT JOIN saig_geocode_cache cr on cr.Address = r.FLocation_Home__c " +
				db.getWhereClause(whereClauseList);
		
		rs = db.executeSelect(query, -1);
		if (emptyInput) {
			while (rs.next()) {
				Resource resource = new Resource();
				resource.setId(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getDouble("distance_home"), rs.getDouble("distance_office"), SfSaigOffice.getValueForName(rs.getString("r.Managing_Office__c")));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		} else {
			while (rs.next()) {
				Resource resource = resourceIdWithScore.get(rs.getString("r.Id"));
				updateScore(resource, workItem, rs.getDouble("distance_home"), rs.getDouble("distance_office"), SfSaigOffice.getValueForName(rs.getString("r.Managing_Office__c")));
				filteredResources.put(rs.getString("r.Id"), resource);
			}
		}	
		
		Utility.stopTimeCounter("BusinessRule_TravelCostFromOffice");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}

	private void updateScore(Resource resource, WorkItem workItem, double distance_home, double distance_office, SfSaigOffice office) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		
		if (resource.getScore() == null)
			resource.setScore(new Double(0));
		
		if (office.equals(SfSaigOffice.Unknown)) {
			logger.error("Office Unknown.  Cannot calculate travel cost");
			return;
		}
		// Travel cost = loss revenue cost for the duration of the travel
		double carTravelTime = Utility.addDrivingFatiguePolicyBreaks(distance_office/driving_average_speed);
		if (distance_office-metroAreaRadius<=workItem.getDistanceToClosestAirport(db)){
			// Driving
			resource.setTravelType(TravelType.DRIVE);
			resource.setTravelTime(carTravelTime);
			resource.setTravelCost(carTravelTime*loss_revenue_hourly_rate);
			resource.setScore(new Double(resource.getScore() + resource.getTravelCost()));
		} else {
			// Possible Flying
			double flyTravelTime = workItem.getFlyingTimeFrom(office, db);
			if (flyTravelTime<0) {
				// Cannot resolve airport.  Assume driving.
				resource.setTravelType(TravelType.FLY_ERROR);
				resource.setTravelTime(carTravelTime);
				resource.setTravelCost(carTravelTime*loss_revenue_hourly_rate);
				resource.setScore(new Double(resource.getScore() + carTravelTime*loss_revenue_hourly_rate) + calculateAccomodationCost(carTravelTime, workItem.getRequiredDuration()));
			} else {
				if (flyTravelTime > carTravelTime) {
					// Just drive there
					resource.setTravelType(TravelType.DRIVE);
					resource.setTravelTime(carTravelTime);
					resource.setTravelCost(carTravelTime*loss_revenue_hourly_rate);
					resource.setScore(new Double(resource.getScore() + carTravelTime*loss_revenue_hourly_rate) + calculateAccomodationCost(carTravelTime, workItem.getRequiredDuration()));
				} else {
					// Fly
					resource.setTravelType(TravelType.FLY);
					resource.setTravelTime(flyTravelTime);
					resource.setTravelCost(flyTravelTime*loss_revenue_hourly_rate);
					resource.setScore(new Double(resource.getScore() + flyTravelTime*loss_revenue_hourly_rate + calculateFlightCost(distance_office)) + calculateAccomodationCost(flyTravelTime, workItem.getRequiredDuration()));
				}
			}
		}
		resource.setDistanceFromClient(distance_office);
		resource.setHomeDistanceFromClient(distance_home);
	}
	
	private double calculateFlightCost(double distance) {
		// Heuristic
		double rateKm = 0.60;
		double minCost = 600; //Flight cost between capital cities (ex Perth)
		double maxCost = 1000; //Flight ex Perth
		return Math.min(Math.max(distance*rateKm, minCost),maxCost);
	}
	
	private double calculateAccomodationCost(double travelTime, double workItemDuration) {
		// Heuristic
		double rateDay = 250;
		double maxHrsDay = 12;
		return Math.ceil((travelTime + workItemDuration)/maxHrsDay)*rateDay;		
	}
}
