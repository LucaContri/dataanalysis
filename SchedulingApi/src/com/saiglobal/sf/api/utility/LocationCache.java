package com.saiglobal.sf.api.utility;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.concurrent.Semaphore;

import com.saiglobal.sf.api.data.DbHelper;
import com.saiglobal.sf.api.model.SimpleParameter;

public class LocationCache {
	private static LocationCache reference= null;
	private static final int refreshIntervalHrs = 24*365;
	private DbHelper db = null;
	private Calendar lastUpdateLocations;
	private Semaphore update = new Semaphore(1);
	private List<Location> locations = new ArrayList<Location>();
	
	private LocationCache(DbHelper db) {
		this.db = db;
	}

	public static LocationCache getInstance(DbHelper db) {
		if( reference == null) {
			synchronized (  ResourceCache.class) {
			  	if( reference  == null)
			  		reference  = new LocationCache(db);
			}
		}
		return  reference;
	}

	public List<Location> getLocations() throws Exception {
		Calendar intervalBefore = Calendar.getInstance();
		intervalBefore.add(Calendar.HOUR, -refreshIntervalHrs);
		
		update.acquire();
		if(lastUpdateLocations == null || lastUpdateLocations.before(intervalBefore)) {
			
			String query = "select * from analytics.postcodes_geo";
			try {
				ResultSet rs = db.executeSelect(query, -1);
				locations = new ArrayList<Location>();
				while (rs.next()) {
					Location location = new Location(
							rs.getString("id"),
							rs.getString("suburb"),
							rs.getString("state"),
							rs.getString("postcode"),
							rs.getDouble("latitude"),
							rs.getDouble("longitude"));
					locations.add(location);
				}
			} catch (Exception e) {
				throw e;
			}
			lastUpdateLocations = Calendar.getInstance();  
		}
		update.release();
	  return locations;
	}
	
	public List<SimpleParameter> getLocationsParameters(String search) throws Exception {
		if ((search == null) || (search == ""))
			return null;
		search = search.toLowerCase();
		List<SimpleParameter> result = new ArrayList<SimpleParameter>();
		for (Location location : getLocations()) {
			if (location.getName().toLowerCase().contains(search) )
				result.add(new SimpleParameter(location.getName(), location.getId()));
		}
		return result;
	}
	
	public List<Location> getLocationByName(String search) throws Exception {
		if ((search == null) || (search == ""))
			return null;
		search = search.toLowerCase();
		List<Location> result = new ArrayList<Location>();
		for (Location location : getLocations()) {
			if (location.getName().toLowerCase().contains(search))
				result.add(location);
		}
		return result;
	}
		
	public Location getLocationById(String id) throws Exception {
		if ((id == null) || (id== ""))
			return null;
		for (Location location : getLocations()) {
			if (location.getId().equals(id))
				return location;
		}
		return null;
	}
	
	
}

class Location {
	private String suburb;
	private String state;
	private String postcode;
	private double latitute, longitude;
	private String id;
	
	public Location(String id, String suburb, String state, String postcode, double latitute, double longitude) {
		super();
		this.id = id;
		this.suburb = suburb;
		this.state = state;
		this.postcode = postcode;
		this.latitute = latitute;
		this.longitude = longitude;
	}

	public String getName() {
		return suburb + "," + state + "," + postcode;
	}
	public String getSuburb() {
		return suburb;
	}

	public void setSuburb(String suburb) {
		this.suburb = suburb;
	}

	public String getState() {
		return state;
	}

	public void setState(String state) {
		this.state = state;
	}

	public String getPostcode() {
		return postcode;
	}

	public void setPostcode(String postcode) {
		this.postcode = postcode;
	}

	public double getLatitute() {
		return latitute;
	}

	public void setLatitute(double latitute) {
		this.latitute = latitute;
	}

	public double getLongitude() {
		return longitude;
	}

	public void setLongitude(double longitude) {
		this.longitude = longitude;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}
}