package com.saiglobal.scrapers.main;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.concurrent.TimeUnit;

import com.google.maps.GeoApiContext;
import com.google.maps.GeocodingApi;
import com.google.maps.errors.OverQueryLimitException;
import com.google.maps.model.AddressComponent;
import com.google.maps.model.AddressComponentType;
import com.google.maps.model.GeocodingResult;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class AccrediaAddressSolver {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final GeoApiContext context = new GeoApiContext()
    												.setApiKey("AIzaSyDtXESgyhXtZazK1KORCivxSxudW6M-adA")
    												.setQueryRateLimit(1,34560)
											        .setConnectTimeout(0, TimeUnit.SECONDS)
											        .setReadTimeout(0, TimeUnit.SECONDS)
											        .setWriteTimeout(0, TimeUnit.SECONDS);
	
	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		List<String> addresses = null;
		while ((addresses = getMissingAddresses()) != null) {
			for (String address : addresses) {
				try {
					address = address.replace("\u0091", "'").replace("\u0092", "'").replace("\u0096", "-");
					GeocodingResult result = getAddress(address);
					saveAddress(address, result);
				} catch (OverQueryLimitException oql) {
					System.out.println("Reached API limit.  Sleeping for an hour");
					Thread.sleep(60*60*1000);
				} catch (Exception e) {
					e.printStackTrace();
					throw e;
				}
			}
		}
	}
	
	private static List<String> getMissingAddresses() throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		List<String> result = new ArrayList<String>();
		
		String queryMissingAddess = "(select "
				+ "aco.address as 'Full Address', "
				+ "substring_index(aco.Address, '-', -1) as 'Fifth Attempt', "
				+ "substring_index(aco.Address, '-', -2) as 'Fourth Attempt', "
				+ "substring_index(aco.Address, '-', -3) as 'Third Attempt', "
				+ "substring_index(aco.Address, '-', -4) as 'Second Attempt', "
				+ "substring_index(aco.Address, '-', -5) as 'First Attempt' "
				+ "from analytics.accredia_certified_organisations aco "
				+ "left join analytics.accredia_addresses aa on aa.Address = aco.Address "
				+ "where aa.Id is null "
				+ "limit 1000);";
				
		ResultSet rs = db.executeSelect(queryMissingAddess, -1);
		while (rs.next()) {
			result.add(rs.getString("Full Address"));
		}
		if (result.size()==0)
			return null;
		
		return result;
	}
	
	private static GeocodingResult getAddress(String address) throws Exception {
		
		if ((address != null) && !address.equals("")) {
			 
			GeocodingResult[] geocoderResponse = GeocodingApi.newRequest(context).address(address).await();

			if ((geocoderResponse != null) && (geocoderResponse.length>0)) {
				return geocoderResponse[0];
			}
			return null;
		}
		return null;
	}
	
	private static void saveAddress(String address, GeocodingResult result) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		String insert = "";
		if (result == null) {
			insert = "insert into analytics.accredia_addresses (Id, Address, Valid) VALUES (null," + clean(address) + ", false)";
		} else {
			double lat = 0, lon = 0;
			try {
				lat = result.geometry.location.lat;
				lon = result.geometry.location.lng;
			} catch (Exception e) {
				// Ignore.  Leave 0;
			}
			insert = "insert into analytics.accredia_addresses VALUES ("
					+ "null,"
					+ clean(address) + ","
					+ clean(result.formattedAddress) + ","
					+ clean(getAddressComponent(result,AddressComponentType.LOCALITY)) + ","
					+ clean(getAddressComponent(result,AddressComponentType.ADMINISTRATIVE_AREA_LEVEL_3)) + ","
					+ clean(getAddressComponent(result,AddressComponentType.ADMINISTRATIVE_AREA_LEVEL_2)) + ","
					+ clean(getAddressComponent(result,AddressComponentType.ADMINISTRATIVE_AREA_LEVEL_1)) + ","
					+ clean(getAddressComponent(result,AddressComponentType.COUNTRY)) + ","
					+ clean(getAddressComponent(result,AddressComponentType.POSTAL_CODE)) + ","
					+ lat + ","
					+ lon + ","
					+ "true"
					+ ");";
			
		}
		System.out.println(insert);
		db.executeInsert(insert);
	}
	
	private static String getAddressComponent(GeocodingResult result, AddressComponentType type) {
		if ((result == null) || (result.addressComponents == null))
			return null;
		
		for (AddressComponent ac : result.addressComponents) {
			for (AddressComponentType aType : ac.types) {
				if (aType.equals(type))
					return ac.longName;
			} 
		}
		return null;
	}
	
	private static String clean(Object i) {
		if (i==null)
			return "null";
		if ((i instanceof Integer) || ((i instanceof Double)) || (i instanceof Float))
			return i.toString();
		if (i instanceof Calendar)
			return "'" + Utility.getMysqldateformat().format(((Calendar)i).getTime()) + "'";
		if(i instanceof String) {
			if (((String)i).equalsIgnoreCase(""))
				return "null";
			else
				return "'" + ((String)i).replace("\\","").replace("'", "\\'").trim() + "'";
		}
		return "'" + i.toString().replace("\\","").replace("'", "\\'") + "'";
	}
}
