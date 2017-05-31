package com.saiglobal.sf.core.utility;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.lang.management.ManagementFactory;
import java.net.InetAddress;
import java.nio.file.Files;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.text.StringCharacterIterator;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;
import java.util.TimeZone;
import java.util.stream.Stream;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
import javax.mail.Authenticator;
import javax.mail.BodyPart;
import javax.mail.Flags;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Part;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Transport;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.search.AndTerm;
import javax.mail.search.SearchTerm;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import com.google.code.geocoder.Geocoder;
import com.google.code.geocoder.GeocoderRequestBuilder;
import com.google.code.geocoder.model.GeocodeResponse;
import com.google.code.geocoder.model.GeocoderRequest;
import com.google.code.geocoder.model.GeocoderResult;
import com.google.code.geocoder.model.GeocoderStatus;
import com.google.code.geocoder.model.LatLng;
import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.SfSaigOffice;
import com.saiglobal.sf.core.model.TravelCostCalculationType;
import com.saiglobal.sf.core.model.WorkItem;

public class Utility {
	private static final String defaultLockDir = "C:\\SAI\\Properties\\";
	private static final Logger logger = Logger.getLogger(Utility.class);
	private static final Geocoder geocoder = new Geocoder();
	private static HashMap<String, Long> eventCounter= new HashMap<String, Long>();
	private static HashMap<String, Long> processingTime = new HashMap<String, Long>();
	private static HashMap<String, Long> startTime = new HashMap<String, Long>();
	private static String defaultpropertyLinkFile = "C:\\SAI\\Properties\\defaultProperties.properties";
	private static String defaultPropertyFile = "C:\\SAI\\Properties\\global.config.properties";
	private static final SimpleDateFormat mysqlDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	private static final SimpleDateFormat mysqlUtcDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	private static final SimpleDateFormat soqlDateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'.000Z'");
	private static final SimpleDateFormat shortDateDisplayFormat = new SimpleDateFormat("dd MMM yy");
	private static final SimpleDateFormat shortDateTimeDisplayFormat = new SimpleDateFormat("dd MMM yy '-' HH:mm");
	private static final SimpleDateFormat fileDateTimeDisplayFormat = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss");
	private static final SimpleDateFormat activityDateFormatter = new SimpleDateFormat("yyyy-MM-dd");
	private static final SimpleDateFormat periodFormatter = new SimpleDateFormat("yyyy-MM");
	private static final Calendar origin = new GregorianCalendar();
	
	static {
		mysqlUtcDateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
		origin.set(1970, 1, 1);
	}
	
	public static boolean getLock(String lockName) {
		try {
			File lFile = new File(defaultLockDir + lockName);
			if (lFile.exists()) {
				// Check PID in file is actually running on this machine.
				List<String> lines = Files.readAllLines(lFile.toPath());
				if (lines.size()>0) {
					String pid = lines.get(0);
					Process p = Runtime.getRuntime().exec("tasklist /fi \"PID eq " + pid + "\" /fi \"imagename eq javaw.exe\"");
					try (BufferedReader buffer = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
						//String res1 = buffer.readLine();
						//String res2 = buffer.readLine();
						//String res3 = buffer.readLine();
						//String res4 = buffer.readLine();
						if(!buffer.readLine().contains("No tasks are running")) {
							return false;
						}
					}
				}
				lFile.delete();
			}
			FileOutputStream fos = new FileOutputStream(lFile);
			String pid_name = ManagementFactory.getRuntimeMXBean().getName();
			if (pid_name != null && pid_name.split("@").length>1) {
				fos.write(pid_name.split("@")[0].getBytes());
			}
			fos.close();
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
		return true;
	}
	
	public static void releaseLock(String lockName) {
		try {
			File lFile = new File(defaultLockDir + lockName);
			if (lFile.exists()) {
				List<String> lines = Files.readAllLines(lFile.toPath());
				String pid_name = ManagementFactory.getRuntimeMXBean().getName();
				if (lines.size()>0 && pid_name != null && pid_name.split("@").length>1 && pid_name.split("@")[0].equalsIgnoreCase(lines.get(0))) {
					lFile.delete();
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			// Ignore
		}
	}
	
	public static Calendar getNow() {
		Date now = new Date();
		Calendar nowCal = new GregorianCalendar();
		nowCal.setTime(now);
		return nowCal;
	}
	
	public static Date getUtcNow() {
		try {
			return mysqlDateFormat.parse(mysqlUtcDateFormat.format(new Date()));
		} catch (ParseException pe) {
			logger.error(pe);
		}
		return null;
	}
	
	private static String getLogKey() {
		Thread thread = Thread.currentThread();
		StackTraceElement[] trace = thread.getStackTrace();
		StackTraceElement first = trace[trace.length-1];
		String key = first.getClassName() + "." + first.getMethodName();
		//String key = Thread.currentThread().getStackTrace()[0].getClassName()+"." + Thread.currentThread().getStackTrace()[0].getMethodName();
		return key;
	}
	
	public static void resetEventCounter() {
		eventCounter.put(getLogKey(), new Long(0));
	}
	
	public static void incEventCounter() {
		if (eventCounter.get(getLogKey()) == null)
			eventCounter.put(getLogKey(), new Long(1));
		else
			eventCounter.put(getLogKey(), new Long(eventCounter.get(getLogKey()).longValue()+1));
	}
	
	public static void incEventCounter(String key) {
		if (eventCounter.get(key) == null)
			eventCounter.put(key, new Long(1));
		else
			eventCounter.put(key, new Long(eventCounter.get(key).longValue()+1));
	}
	
	public static void resetTimeCounter() {
		processingTime.put(getLogKey(), new Long(0));
	}
	
	public static void resetAllTimeCounter() {
		for (String key : processingTime.keySet()) {
			resetTimeCounter(key);
		}
	}
	
	public static void resetTimeCounter(String key) {
		processingTime.put(key, new Long(0));
	}
	
	public static void removeTimeCounter(String key) {
		processingTime.remove(key);
	}
	
	public static void startTimeCounter() {
		startTime.put(getLogKey(), new Long(System.currentTimeMillis()));
	}
	
	public static void startTimeCounter(String key) {
		startTime.put(key, new Long(System.currentTimeMillis()));
	}
	
	public static long getTimeCounterS() {
		return getTimeCounterMS()/1000;
	}
	public static long getTimeCounterMS(String key) {
		if (processingTime.get(key) == null)
			return 0;
		return processingTime.get(key).longValue();
	}
	public static long getTimeCounterMS() {
		if (processingTime.get(getLogKey()) == null)
			return 0;
		return processingTime.get(getLogKey()).longValue();
	}
	
	public static void logProcessingTime(String key) {
		if (processingTime.get(key) != null)
			logger.info("Processing time(s) for " + key + ": " + processingTime.get(key).longValue()/1000.0 + " s. ");
	}
	
	public static void logProcessingTime() {
		if (processingTime.get(getLogKey()) != null)
			logger.info("Processing time(s) for " + getLogKey() + ": " + processingTime.get(getLogKey()).longValue()/1000.0 + " s. " );
	}
	
	public static void logAllProcessingTime() {
		for (String key : processingTime.keySet()) {
			logProcessingTime(key);
		}
	}
	public static void logEventCounter(String key) {
		if (eventCounter.get(key) != null)
			logger.info("Number of " + key + " events: " + eventCounter.get(key).longValue());
	}
	
	public static void logAllEventCounter() {
		for (String key : eventCounter.keySet()) {
			logEventCounter(key);
		}
	}
	public static void stopTimeCounter() {
		long endTime = System.currentTimeMillis();
		String key = getLogKey();
		if (startTime.get(key) != null)
			if (processingTime.get(key) != null)
				processingTime.put(key, new Long(processingTime.get(key).longValue() + (endTime-startTime.get(key).longValue())));
			else
				processingTime.put(key, new Long(endTime-startTime.get(key).longValue()));
	}

	public static void stopTimeCounter(String key) {
		long endTime = System.currentTimeMillis();
		if (startTime.get(key) != null)
			if (processingTime.get(key) != null)
				processingTime.put(key, new Long(processingTime.get(key).longValue() + (endTime-startTime.get(key).longValue())));
			else
				processingTime.put(key, new Long(endTime-startTime.get(key).longValue()));
	}
	
	public static boolean isWeekend(Calendar day){
		return (day.get(Calendar.DAY_OF_WEEK)==Calendar.SUNDAY) || (day.get(Calendar.DAY_OF_WEEK)==Calendar.SATURDAY);
	}
	
	public static double calculateWeekendDays(Date fromDateUTC, Date toDateUTC, TimeZone timeZone){
		if (timeZone==null) {
			logger.info("Using default timezone");
			timeZone = TimeZone.getDefault();
		}
		Calendar c1 = Calendar.getInstance(timeZone);  
		c1.setTimeInMillis(toDateUTC.getTime() + timeZone.getOffset(toDateUTC.getTime()));
        
        Calendar c2 = Calendar.getInstance(timeZone);  
        c2.setTimeInMillis(fromDateUTC.getTime() + timeZone.getOffset(fromDateUTC.getTime()));
        double weekendDays = 0;  
   
        while(c1.after(c2)) {  
            if((c2.get(Calendar.DAY_OF_WEEK)==Calendar.SUNDAY) || (c2.get(Calendar.DAY_OF_WEEK)==Calendar.SATURDAY)) 
            	weekendDays++;  
            c2.add(Calendar.DATE,1);  
        }
        return weekendDays;
	}
	
	public static double calculateWorkingDaysInPeriod(Date fromDate, Date toDate, TimeZone timeZone){
		double hoursInPeriod = (double) (toDate.getTime() - fromDate.getTime())/(1000*60*60);
		double fullDays = Math.floor(hoursInPeriod/24);
		//double remainder = hoursInPeriod/24 - fullDays;
		//double remainderHrs = remainder*24;
		//double remainderDays = remainderHrs/8;
		// The one below is not correct as CalculateWeekendDays should convert to user timezone before figuring out if it is a weekend day
        return fullDays - calculateWeekendDays(fromDate, toDate, timeZone);
		// ASSUMPTION: No BOP set for weekends -> (fullDays + remainderDays - CalculateWeekendDays(fromDate, toDate)) = fullDays + remainderDays;
		//return (fullDays + remainderDays);
	}
	
	public static double calculateWorkingDaysInPeriodV2(Date fromDateUTC, Date toDateUTC, TimeZone timeZone){
		double hoursInPeriod = (double) (toDateUTC.getTime() - fromDateUTC.getTime())/(1000*60*60);
		double fullDays = hoursInPeriod/24;
		if (timeZone==null) {
			logger.info("Using default timezone");
			timeZone = TimeZone.getDefault();
		}
            
		return fullDays - calculateWeekendDays(fromDateUTC, toDateUTC, timeZone);
	}
	
	public static boolean isBlackout(String eventDescription) {
		return (eventDescription.contains("Blackout") || 
				eventDescription.contains("Office Time") ||
				eventDescription.contains("Leave Annual") ||
				eventDescription.contains("Public Holiday"));
	}
	
	public static String addSlashes( String text ){    	
        final StringBuffer sb = new StringBuffer( text.length() * 2 );
        final StringCharacterIterator iterator = new StringCharacterIterator( text );
        
  	  	char character = iterator.current();
        
        while( character != StringCharacterIterator.DONE ){
            if( character == '"' ) sb.append( "\\\"" );
            else if( character == '\'' ) sb.append( "\\\'" );
            else if( character == '\\' ) sb.append( "\\\\" );
            else if( character == '\\' ) sb.append( "\\\\" );
            else if( character == '\n' ) sb.append( "\\n" );
            else if( character == '{'  ) sb.append( "\\{" );
            else if( character == '}'  ) sb.append( "\\}" );
            else sb.append( character );
            
            character = iterator.next();
        }
        
        return sb.toString();
    }
	
	public static LatLng getGeocode(String address, String hash, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		if (db == null) {
			// Use default
			db = new DbHelper(Utility.getProperties());
		}
		// First check if we cached this address in database
		if (db != null) {
			LatLng coordinates = db.getGeocodeCached(address);
			if (coordinates != null) {
				//Utility.stopTimeCounter();
				return coordinates;
			}
		}
		if ((address != null) && !address.equals("")) {
			Utility.startTimeCounter("Utility.getGeoCodeGoogle");
			Utility.incEventCounter("Utility.getGeoCodeGoogle");
			logger.debug("Geocoding " + address);
			GeocoderRequest geocoderRequest = new GeocoderRequestBuilder().setAddress(address).setLanguage("en").getGeocoderRequest();
			GeocodeResponse geocoderResponse = geocoder.geocode(geocoderRequest);
			Utility.stopTimeCounter("Utility.getGeoCodeGoogle");
			if ((geocoderResponse != null) && (geocoderResponse.getStatus().equals(GeocoderStatus.OK)) && (geocoderResponse.getResults().size()>0)) {
				if (db != null) {
					db.storeGeocodeCached(hash, geocoderResponse.getResults().get(0).getGeometry().getLocation());
				}
				return geocoderResponse.getResults().get(0).getGeometry().getLocation();
			} else {
				if (geocoderResponse == null) {
					logger.error("Google Geocode API no response with request string: " + address);
					throw new GeoCodeApiException(address, null);
				} else {
					logger.error("Google Geocode API response: " + geocoderResponse.getStatus().name() + " with request string: " + address);
					throw new GeoCodeApiException(address, geocoderResponse.getStatus());
				}
			}
		}
		return null;
	}
	
	public static LatLng getGeocode(Location location, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		
		if (location == null) {
			return null;
		}
		String address = location.getFullAddress();
		try {
			return getGeocode(address, address, db);
		} catch (GeoCodeApiException e1) {
			if (e1.getResponseStatus() != null && e1.getResponseStatus().equals(GeocoderStatus.ZERO_RESULTS)) {
				// Let's try with City, State, Country and PostCode only
				try {
					StringBuilder addressBuilder = new StringBuilder("");
					if (location.getCity()!=null) addressBuilder.append(location.getCity()+ " ");
					if (location.getStateDescription()!=null) addressBuilder.append(location.getStateDescription()+ " ");
					if (location.getCountry()!=null) addressBuilder.append(location.getCountry()+ " ");
					if (location.getPostCode()!=null) addressBuilder.append(location.getPostCode()+ " ");
					return getGeocode(addressBuilder.toString(), address, db);
					
				} catch (GeoCodeApiException e2) {
					if (e2.getResponseStatus().equals(GeocoderStatus.ZERO_RESULTS)) {
						// Let's try with City, State and Country only
						StringBuilder addressBuilder = new StringBuilder("");
						if (location.getCity()!=null) addressBuilder.append(location.getCity()+ " ");
						if (location.getStateDescription()!=null) addressBuilder.append(location.getStateDescription()+ " ");
						if (location.getCountry()!=null) addressBuilder.append(location.getCountry()+ " ");
						return getGeocode(addressBuilder.toString(), address, db);
					}
				}
			}
		}
		return null;
		
	}
	
	public static GeocoderResult getFullGeocode(String address, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException {
		
		if ((address != null) && !address.equals("")) {
			Utility.startTimeCounter("Utility.getGeoCodeGoogle");
			Utility.incEventCounter("Utility.getGeoCodeGoogle");
			GeocoderRequest geocoderRequest = new GeocoderRequestBuilder().setAddress(address).setLanguage("en").getGeocoderRequest();
			GeocodeResponse geocoderResponse = geocoder.geocode(geocoderRequest);
			Utility.stopTimeCounter("Utility.getGeoCodeGoogle");
			if ((geocoderResponse != null) && (geocoderResponse.getStatus().equals(GeocoderStatus.OK)) && (geocoderResponse.getResults().size()>0)) {
				if (db != null) {
					db.storeGeocodeCached(address, geocoderResponse.getResults().get(0).getGeometry().getLocation());
				}
				//Utility.stopTimeCounter("Utility.getGeoCode");
				return geocoderResponse.getResults().get(0);
			}
		}
		return null;
	}
	
	public static double calculateDistanceKm(Location a, Location b, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		// Check input parameters.  If something is wrong fallback to Google Geocode API
		//Utility.startTimeCounter("Utility.calculateDistanceKm"); 
		if ((a == null) || (b == null)) {
			return -1;
		}
		if ((a.getLatitude()==0) && (a.getLongitude()==0.0)) {
			try {
				LatLng coordinates = Utility.getGeocode(a, db);
				if (coordinates != null) {
					a.setLatitude(coordinates.getLat().doubleValue());
					a.setLongitude(coordinates.getLng().doubleValue());
				} else {
					// If Google fails as well return -1
					//Utility.stopTimeCounter();
					return -1;
				}
			} catch (GeoCodeApiException e) {
				return -1;
			}
		} 
		
		if ((b.getLatitude()==0) && (b.getLongitude()==0.0)) {
			try {
				LatLng coordinates = Utility.getGeocode(b, db);
			
				if (coordinates != null) {
					b.setLatitude(coordinates.getLat().doubleValue());
					b.setLongitude(coordinates.getLng().doubleValue());
				} else {
					// If Google fails as well return -1
					//Utility.stopTimeCounter("Utility.calculateDistanceKm");
					return -1;
				}
			} catch (GeoCodeApiException e) {
				return -1;
			}
		}
	    return calculateDistanceKm(a.getLatitude(), a.getLongitude(), b.getLatitude(), b.getLongitude());
	}
	
	public static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
		
		double d2r = Math.PI / 180;
	    double dlong = (lon2 - lon1) * d2r;
	    double dlat = (lat2 - lat1) * d2r;
	    double haversine =
	        Math.pow(Math.sin(dlat / 2.0), 2)
	            + Math.cos(lat1 * d2r)
	            * Math.cos(lat2 * d2r)
	            * Math.pow(Math.sin(dlong / 2.0), 2);
	    double distance = 6367 * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
	   
	    return distance;
	}
	
	public static double calculateReturnDistance(Resource resource, WorkItem workItem) {
		double distance = 2*Utility.calculateDistanceKm(
				workItem.getClientSite().getLatitude(), 
				workItem.getClientSite().getLongitude(), 
				resource.getHome().getLatitude(), 
				resource.getHome().getLongitude());
		if (distance<0) {
			Utility.getLogger().error("Error in calculating distance between: " + workItem.getClientSite().getFullAddress() + " and " + resource.getHome().getFullAddress());
			Utility.getLogger().error("Assuming cost infinity");
			return Double.MAX_VALUE;
		}
		return distance;
	}
	
	public static double calculateTravelCost(double distance, double durationHours, TravelCostCalculationType type) {
		double costMilageAUDperKm = 0.5/0.7;
		double costAirportTransferReturn = 120*costMilageAUDperKm;
		double costAirportParkingFirstDay = 50/0.7;
		double costAirportParkingFollowingDays = 25/0.7;
		double costDomesticFlight = 200/0.7;
		double cost = 0;

		switch (type) {
		case SIMPLE:
			// Travel Cost 
			if(distance<=300) {
				// Assume driving 
				cost += costMilageAUDperKm*distance;
			} else {
				// Flight or Train
				cost += costDomesticFlight;
				// Home Train Station/Airport transfer
				cost += costAirportTransferReturn;
				// Client Site Train Station/Airport transfer
				cost += costAirportTransferReturn;
				// Airport Parking
				cost += costAirportParkingFirstDay + costAirportParkingFollowingDays*Math.ceil((durationHours/8-1));
			}
			break;
		case EMPIRICAL_UK:
			// Based on analysis on H1 fy17 actual travel costs in EMEA
			if (distance<=500) {
				cost = 129 + 0.42022*distance;
			} else {
				cost = Math.min(129 + 0.42022*distance,315*Math.log(distance/100)-94);
			}
			break;
		case EMPIRICAL_AUSTRALIA:
		default:
			// Based on analysis on H1 fy17 actual travel costs in Australia
			cost = 155*Math.log(distance/100)+90;
			break;
		}
		
		return cost;
	}
	
	public static double calculateAuditCost(SfResourceType resourceType, double resourceHourlyRate, double requiredDuration, double oneWayDistance, TravelCostCalculationType type, boolean isMilkRun, boolean isFirstInMilkRun, boolean isPrimary) {
		// Costs in AUD
		double cost = 0;
		double costDailySubsistence = 40/0.7;
		double costHotelDay = 100/0.7;
		double maxReturnHomeDistance = 200;
		
		// Resource Cost
		if (resourceType.equals(SfResourceType.Contractor)) {
			// Contractor
			if (resourceHourlyRate > 0) {
				cost += requiredDuration*resourceHourlyRate;
			}
		}
		if (isPrimary) {
			// Travel cost 
			if(isMilkRun)
				cost += calculateTravelCost(oneWayDistance, requiredDuration, type);
			else
				cost += 2*calculateTravelCost(oneWayDistance, requiredDuration, type);
			
			// Accommodation and Meals
			cost += costDailySubsistence*Math.ceil((requiredDuration/8));
			if (oneWayDistance>=maxReturnHomeDistance || isMilkRun)
				cost += costHotelDay*Math.ceil((requiredDuration/8-1));
			
			if(isMilkRun && !isFirstInMilkRun) {
				// The auditor is not coming from home, therefore add additional Accommodation for previous night
				// TODO: if it is a weekend we need to add additional accommodations and meals???
				cost += costHotelDay;
			}
		}
		
		return cost;
	}
	
	public static double calculateAuditCost(Resource resource, WorkItem workItem, WorkItem precedingWorkItem, TravelCostCalculationType type, DbHelper db, boolean isMilkRun, boolean isFirstAuditInRun) throws Exception {
		double distance = Double.MAX_VALUE;
		if(workItem.isPrimary())
			if(precedingWorkItem != null && workItem != null && !workItem.getName().equalsIgnoreCase(precedingWorkItem.getName())) 
				distance = calculateDistanceKm(resource.getHome(), workItem.getClientSite(), db);
			else
				distance = calculateDistanceKm(precedingWorkItem.getClientSite(), workItem.getClientSite(), db);
		else
			distance = 0;
		return calculateAuditCost(resource.getType(), resource.getHourlyRate(), workItem.getRequiredDuration() + workItem.getLinkedWorkItems().stream().mapToInt(wi -> (int) Math.ceil(wi.getRequiredDuration())).sum(), distance, type, isMilkRun, isFirstAuditInRun, workItem.isPrimary());
	}
	/*
	public static double calculateOneWayAuditCost(Resource resource, WorkItem workItem, WorkItem precedingWorkItem, TravelCostCalculationType type, DbHelper db) throws Exception {
		double distance = Double.MAX_VALUE;
		if(precedingWorkItem != null && workItem != null && workItem.getId().equalsIgnoreCase(precedingWorkItem.getId())) 
			distance = calculateDistanceKm(resource.getHome(), workItem.getClientSite(), db);
		else
			distance = calculateDistanceKm(precedingWorkItem.getClientSite(), workItem.getClientSite(), db);
			
		return calculateAuditCost(resource.getType(), resource.getHourlyRate(), workItem.getRequiredDuration() + workItem.getLinkedWorkItems().stream().mapToInt(wi -> (int) Math.ceil(wi.getRequiredDuration())).sum(), distance, type);
	}
	*/
	public static Location getClosestAirport(Location location, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		Location closestAirport = null;
		double minDistance = Long.MAX_VALUE;
		for (Location airport : db.getAirports()) {
			double distance = Utility.calculateDistanceKm(airport, location, db);
			if (distance<0) {
				// Ignore
				continue;
			}
			if (distance<minDistance) {
				minDistance = distance;
				closestAirport = airport;
			}
		}
		return closestAirport;
	}
	
	public static double addDrivingFatiguePolicyBreaks(double drivingTimeMin) {
		double noBreaks = Math.floor(drivingTimeMin/120);
		return drivingTimeMin + noBreaks*20;
	}
	
	public static double getGMapTravelTimeMin(Location a, Location b, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		// TODO:  To be implemented
		/*
		 * Example http://maps.googleapis.com/maps/api/directions/xml?origin=-33.8674649+151.2070860&destination=-32.9266888+151.7789194&sensor=false
		 * Given Google Maps API limit of 2,500 requests/day, for now just using heuristic formula to calculate travel time
		 * Assuming avg of 50 km/h over straight line distance
		 */
		double distance = Utility.calculateDistanceKm(a, b, db);
		if (distance<0)
			return 0;
		return distance/50*60;
	}
	
	public static double calculateTravellingTimeHr(SfSaigOffice office, Location clientSite, DbHelper db) throws SQLException, ClassNotFoundException, IllegalAccessException, InstantiationException, GeoCodeApiException {
		double travelTime  = 0;
		// Check input parameters
		if (office.getLocation() == null) {
			logger.info("Office location is null for: " + office.getName());
			return -1;
		}
		if (clientSite == null) {
			logger.info("Client site location is null");
			return -1;
		}
		// 1) Check if it is metro area
		Location officeLocation = office.getLocation();
		double distance = Utility.calculateDistanceKm(officeLocation, clientSite, db);
		if (distance <= officeLocation.getMetropolitanRadius()) {
			// No travelling to be accounted for
			return travelTime;
		}
		
		// 2) Get closest airport to clientSite
		Location airport = Utility.getClosestAirport(clientSite, db);
		
		// 3) Calculate distance to closest airport
		double distanceToAirport = Utility.calculateDistanceKm(clientSite, airport, db);
		
		if (distance < distanceToAirport) {
			// Just drive there
			// Use Google Maps API to calculate travelling time + rest time as per driving fatigue policy
			double drivingTimeMin = Utility.getGMapTravelTimeMin(officeLocation, clientSite, db);
			travelTime += Utility.addDrivingFatiguePolicyBreaks(drivingTimeMin);
		} else {
			// Fly and drive
			// Get flying time + driving to airport + check in + baggage collection as per travel guidelines
			if (office.equals(SfSaigOffice.Australia_WestMelbourne))
				office = SfSaigOffice.Australia_Melbourne;
			double flyingTime = db.getFlyingTimeMin(airport.getName(), office);
			if (flyingTime<0) {
				// Could not match airport with office ... Something wrong here
				logger.error("To investigate this... table saig_travel_airports is missing some records. Airport:" + airport.getName() + ". Office: " + office.toString());
				// Fall back to heuristic distance/700
				logger.info("Using heuristic. Time(min) = distance(km)/700(km/h)*60");
				flyingTime = calculateDistanceKm(airport, office.getLocation(), db)/700*60;
			}
			flyingTime += (30 +45 + 30)*2;
			// Get travel time from airport to client site using Google Map API
			double drivingTimeMin = Utility.getGMapTravelTimeMin(airport, clientSite, db);
			
			// Sum the two above
			travelTime = flyingTime + Utility.addDrivingFatiguePolicyBreaks(drivingTimeMin);
		}
		
		// 4) Round to closest 15 min and convert to Hrs
		return Math.round(travelTime/15)*15/60;
	}

	public static Logger getLogger() {
		return logger;
	}
	
	public static void writeSforceObject(String query, com.saiglobal.sf.core.utility.GlobalProperties cmd) throws IOException {
		write(query, cmd.getSqlPath(),cmd.getSqlTablefile());
	}

	public static void writeSforceRelation(String query, com.saiglobal.sf.core.utility.GlobalProperties cmd) throws IOException {
		write(query, cmd.getSqlPath(),cmd.getSqlRelationfile());
	}

	private static void write(String query,String path, String fileName) throws IOException {
		FileWriter fw;
		BufferedWriter bw = null;
		try {
			File f= new File(path+"\\"+fileName);
			if (!f.exists()) {
				File p = new File(path);
				if (!p.exists()) {
					p.mkdirs();
				}
				f.createNewFile();
				logger.debug("New file created [" + fileName + "]");
			}
			fw = new FileWriter(f);
			bw = new BufferedWriter(fw);
			bw.write(query);
		} finally {
			try {
				bw.close();
			} catch (Exception e) {

			}
		}
	}

	protected static String readFileAsString(String filePath) throws java.io.IOException {
		byte[] buffer = new byte[(int) new File(filePath).length()];
		BufferedInputStream f = null;
		try {
			f = new BufferedInputStream(new FileInputStream(filePath));
			f.read(buffer);
		} finally {
			if (f != null)
				try {
					f.close();
				} catch (IOException ignored) {
				}
		}
		return new String(buffer);
	}

	public static String removeLastChar(String text) {
		if (text.length()>0)
			return text.substring(0, text.length() - 1);
		else
			return text;
	}
	
	public static StringBuilder removeLastChar(StringBuilder text) {
		if (text.length()>0)
			return text.deleteCharAt(text.length()-1);
		else
			return text;
	}
	
	public static boolean inArray(String[] haystack, String needle) {
	    for(int i=0;i<haystack.length;i++) {
	        if(haystack[i].toLowerCase().equals(needle.toLowerCase())) {
	            return true;
	        }
	    }
	    return false;
	}
	
	public static GlobalProperties getProperties() {
		File f = new File(defaultpropertyLinkFile);
		if(f.exists() && !f.isDirectory()) {
			Properties propertiesLink = new Properties();			
	    	try {
	    		propertiesLink.load(new FileInputStream(defaultpropertyLinkFile));
	    		return getProperties(propertiesLink.getProperty("defaultPrpertyFile", defaultPropertyFile));
	    	} catch (IOException ioe) {
	    		logger.error("Error in loading property link file ", ioe);
	        }
		}
		return getProperties(defaultPropertyFile);
	}
	
	public static GlobalProperties getProperties(String aPropertyFile) {
		Properties properties = new Properties();
		GlobalProperties retValue = new GlobalProperties();
    	try {
    		properties.load(new FileInputStream(aPropertyFile));
    
    	} catch (IOException ioe) {
    		logger.error("Error in loading property file ", ioe);
        }
    	retValue.setFileName(aPropertyFile);
    	retValue.setEnableProxy(properties.getProperty("EnableProxy", "false"));
    	retValue.setProxyAuthRequired(properties.getProperty("IsProxyAuthRequired", "false"));
    	retValue.setProxyHost(properties.getProperty("ProxyHost", null));
        retValue.setProxyPort(properties.getProperty("ProxyPort"));
        retValue.setProxyUser(properties.getProperty("ProxyUser"));
        retValue.setProxyPassword(properties.getProperty("ProxyPassword"));
        
        retValue.setSfUser(properties.getProperty("SalesforceUser"));
        retValue.setSfPassword(properties.getProperty("SalesforcePassword"));
        retValue.setSfToken(properties.getProperty("SalesforceToken"));
        retValue.setSfEndpoint(properties.getProperty("SalesforceEndpoint"));
        retValue.setSfConnectionTimeout(properties.getProperty("SalesforceConnectionTimeout","90000"));
        retValue.setSfReadTimeOut(properties.getProperty("SalesforceReadTimeout","90000"));
        
        retValue.setSqlPath(properties.getProperty("SqlPath", "c:\\temp\\salesforce\\sqls"));
        retValue.setSqlTablefile(properties.getProperty("SqlTablefile", "sf_objects_create.sql"));
        retValue.setSqlRelationfile(properties.getProperty("SqlRelationfile", "sf_relations_create.sql"));
        
        retValue.setCreateLocalSqlfiles(properties.getProperty("CreateLocalSqlfiles", "false"));
        retValue.setCreateLocalTables(properties.getProperty("CreateLocalTables", "true"));
        retValue.setDropIfTableExists(properties.getProperty("DropIfTableExists", "false"));
        retValue.setPopulateDb(properties.getProperty("PopulateDb", "true"));
        
        // Data Sources Properties - Used by Report Engine
        for(String key : properties.stringPropertyNames()) {
		  if (key.startsWith("datasource.")) {
			  String dataSourceName = "";
			  String propertyName = "";
			  String[] keyComponenets = key.split("\\.");
			  if ((keyComponenets != null) && (keyComponenets.length>2)) {
				  dataSourceName =keyComponenets[1];
				  propertyName = key.substring(key.indexOf(dataSourceName )+dataSourceName.length()+1);
				  if (dataSourceName.equalsIgnoreCase("default") && propertyName.equalsIgnoreCase("name"))
					  retValue.setCurrentDataSource(properties.getProperty(key));
				  if (propertyName.equalsIgnoreCase("DbConnectionURL")) {
					  retValue.setDbConnectionURL(dataSourceName, properties.getProperty(key,"jdbc:mysql://<DbHost>/<DbSchema>?jdbcCompliantTruncation=true"));
				  }
				  if (propertyName.equalsIgnoreCase("DbDriver")) {
					  retValue.setDbDriver(dataSourceName, properties.getProperty(key,"com.mysql.jdbc.Driver"));
				  }
				  if (propertyName.equalsIgnoreCase("DbUser")) {
					  retValue.setDbUser(dataSourceName, properties.getProperty(key));
				  }
				  if (propertyName.equalsIgnoreCase("DbPassword")) {
					  retValue.setDbPassword(dataSourceName, properties.getProperty(key));
				  }
				  if (propertyName.equalsIgnoreCase("DbHost")) {
					  retValue.setDbHost(dataSourceName, properties.getProperty(key));
				  }
				  if (propertyName.equalsIgnoreCase("DbSchema")) {
					  retValue.setDbSchema(dataSourceName, properties.getProperty(key));
				  }
				  if (propertyName.equalsIgnoreCase("DbPrefix")) {
					  retValue.setDbPrefix(dataSourceName, properties.getProperty(key,""));
				  }
				  if (propertyName.equalsIgnoreCase("DbLogError")) {
					  retValue.setDblogError(dataSourceName, properties.getProperty(key,"true"));
				  }
				  if (propertyName.equalsIgnoreCase("JdbcName")) {
					  retValue.setJdbcName(dataSourceName, properties.getProperty(key,"jdbc/compass"));
				  }
			  }
		  }
        }
        
        // Used only by SfReportEngine
        retValue.setReportBuilderClass(properties.getProperty("ReportBuilderClass"));
        retValue.setReportEmails(properties.getProperty("ReportEmails"));
        retValue.setReportFormat(properties.getProperty("ReportFormat"));
        retValue.setReportFolder(properties.getProperty("ReportFolder"));
        
        // Used only by Allocator
        retValue.setAllocatorImplementationClass(properties.getProperty("allocatorImplementationClass"));
        retValue.setIncludePipeline(properties.getProperty("includePipeline"));
        retValue.setScoreAvailabilityDayReward(properties.getProperty("scoreAvailabilityDayReward"));
        retValue.setScoreCapabilityAuditPenalty(properties.getProperty("scoreCapabilityAuditPenalty"));
        retValue.setScoreContractorPenalties(properties.getProperty("scoreContractorPenalties"));
        retValue.setScoreDistanceKmPenalty(properties.getProperty("scoreDistanceKmPenalty"));
        
        // Email properties
        retValue.setMail_smtp_auth(properties.getProperty("mail.smtp.auth"));
        retValue.setMail_smtp_host(properties.getProperty("mail.smtp.host"));
        retValue.setMail_smtp_password(properties.getProperty("mail.smtp.password"));
        retValue.setMail_smtp_port(properties.getProperty("mail.smtp.port"));
        retValue.setMail_smtp_starttls_enable(properties.getProperty("mail.smtp.starttls.enable"));
        retValue.setMail_smtp_user(properties.getProperty("mail.smtp.user"));
        retValue.setMail_smtp_from(properties.getProperty("mail.smtp.from"));
        retValue.setMail_transport_protocol(properties.getProperty("mail.transport.protocol"));
        retValue.setMail_smtp_log_error_to(properties.getProperty("mail.smtp.log.error.to"));
        
        retValue.setMail_imaps_auth(properties.getProperty("mail.imaps.auth"));
        retValue.setMail_imaps_host(properties.getProperty("mail.imaps.host"));
        retValue.setMail_imaps_password(properties.getProperty("mail.imaps.password"));
        retValue.setMail_imaps_port(properties.getProperty("mail.imaps.port"));
        retValue.setMail_imaps_starttls_enable(properties.getProperty("mail.imaps.starttls.enable"));
        retValue.setMail_imaps_user(properties.getProperty("mail.imaps.user"));

        // Scheduling API properties
        retValue.setSchedulingApiPort(80); //Default
        if (properties.getProperty("scheduling.api.port")!=null) {
        	retValue.setSchedulingApiPort(Integer.parseInt(properties.getProperty("scheduling.api.port").trim()));
        }    
        
        // FABBL Downloader properties
        retValue.setFABBLsourceFile(properties.getProperty("fabbl.source.file"));
        retValue.setFABBLdestinationFile(properties.getProperty("fabbl.destination.file"));
        
        // Task Specific Properties
        for(String key : properties.stringPropertyNames()) {
		  if (key.startsWith("task.")) {
			  String taskName = "";
			  String propertyName = "";
			  String[] keyComponenets = key.split("\\.");
			  if ((keyComponenets != null) && (keyComponenets.length>2)) {
				  taskName =keyComponenets[1];
				  propertyName = key.substring(key.indexOf(taskName )+taskName.length()+1);
				  TaskProperties task = retValue.getTasksProperties().get(taskName);
				  if (task == null) {
					  task = new TaskProperties();
					  task.setName(taskName);
				  }
				  if (propertyName.equalsIgnoreCase("logLevel")) {
					  task.setLogLevel(Level.toLevel(properties.getProperty(key), Level.INFO));
				  }
				  if (propertyName.equalsIgnoreCase("enable")) {
					  task.setEnabled(Boolean.parseBoolean(properties.getProperty(key)));
				  }
				  if (propertyName.equalsIgnoreCase("error.disable")) {
					  task.setDisableIfError(Boolean.parseBoolean(properties.getProperty(key)));
				  }
				  if (propertyName.equalsIgnoreCase("error.email")) {
					  task.setEmailError(Boolean.parseBoolean(properties.getProperty(key)));
				  }
				  retValue.setTaskProperty(task);
			  }
		  }
        }
        
        return retValue;
	}
	
	public static void logReport(GlobalProperties gp, String className, String reportName, String emailedTo, String sftpedTo, long processingTime) {
		String currentDataSource = gp.getCurrentDataSource();
		DbHelperDataSource db = new DbHelperDataSource(gp, "analytics");
		try {
			db.executeStatement("INSERT INTO log_report_engine VALUES (" 
						+ "null,"
						+ "'" + InetAddress.getLocalHost().getHostName() + "',"
						+ "utc_timestamp(),"
						+ "'" + className + "',"
						+ "'" + reportName + "',"
						+ ((emailedTo==null)?null:"'" + emailedTo + "'") + ","
						+ ((sftpedTo==null)?null:"'" + sftpedTo + "'") + ","
						+ processingTime +")"
						);
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			gp.setCurrentDataSource(currentDataSource);
		}
	}
	
	public static void email(GlobalProperties gp, String[] to, String subject, String body, String[] attachments) {
		// Schedule email to be set
		if (((to == null) || (to.length==0)))
			to = gp.getReportEmails();
		
		String currentDataSource = gp.getCurrentDataSource();
		DbHelperDataSource db = new DbHelperDataSource(gp, "analytics");
		try {
			for (String aReceipient: to) {
				// Add email to queue in db
				db.executeStatement("INSERT INTO email_queue VALUES (" 
						+ "null,"
						+ "'" + InetAddress.getLocalHost().getHostName() + "',"
						+ "utc_timestamp(),"
						+ "'n/a',"
						+ "'" + aReceipient + "',"
						+ ((subject==null)?"null":("'" + subject.replace("\\", "\\\\") + "'")) + "," 
						+ ((body==null)?"null":("'" + body.replace("\\", "\\\\") + "'")) + ","
						+ (((attachments == null) || (attachments.length==0))?"null":("'" + StringUtils.join(attachments , ",") + "'")).replace("\\", "\\\\") + ","
						+ "null,"
						+ "null,"
						+ "0,0)"
						);
			}
		} catch (Exception e) {
			//handleError(gp, e);
			e.printStackTrace();
		} finally {
			gp.setCurrentDataSource(currentDataSource);
		}
	}
	
	public static void email(GlobalProperties gp, String subject, String body, String[] attachments) {
		email(gp, gp.getReportEmails(), subject, body, attachments);
	}
	
	public static void sendEmail(GlobalProperties gp, String to, String subject, String body, String[] attachments) throws AddressException, MessagingException, UnsupportedEncodingException, InterruptedException {
		
		if ((attachments != null) && (attachments.length>0)) {
			String attachementString = attachments[0];
			for (int i=1; i<attachments.length; i++) {
				attachementString += ", " + attachementString;
			}
			logger.info("Emailing '" + subject + "' to: " + to + " with attachments: " + attachementString);
		} else {
			logger.info("Emailing '" + subject + "' to: " + to);
		}
		
		
		Properties properties = new Properties();
		properties.put("mail.transport.protocol", gp.getMail_transport_protocol());
		properties.put("mail.smtp.host", gp.getMail_smtp_host());
		properties.put("mail.smtp.port", gp.getMail_smtp_port());
		properties.put("mail.smtp.auth", gp.getMail_smtp_auth());

		final String user = gp.getMail_smtp_user().split("@")[0];
		final String password = gp.getMail_smtp_password();
		
		 Authenticator authenticator = new Authenticator() {
		    protected PasswordAuthentication getPasswordAuthentication() {
		        return new PasswordAuthentication(user, password);
		    }
		};
		
		Transport transport = null;

		try {
		    Session session = Session.getDefaultInstance(properties, authenticator);
			
			// Create a default MimeMessage object.
			MimeMessage message = new MimeMessage(session);
			
			// Set From: header field of the header.
			message.setFrom(new InternetAddress(gp.getMail_smtp_user(), gp.getMail_smtp_user()));
			
			// Set Subject: header field
			message.setSubject(subject);
			
			// Create the message part 
			BodyPart messageBodyPart = new MimeBodyPart();

			// Fill the message
			//messageBodyPart.setText(body);
			messageBodyPart.setContent(body, "text/html; charset=utf-8");
	        
			// Create a multi part message
			Multipart multipart = new MimeMultipart();

			// Set text message part
			multipart.addBodyPart(messageBodyPart);

			// Part two is attachment
			if ((attachments != null) && (attachments.length>0)) {
				for (String attachement : attachments) {
					messageBodyPart = new MimeBodyPart();
					DataSource source = new FileDataSource(attachement);
					messageBodyPart.setDataHandler(new DataHandler(source));
					messageBodyPart.setFileName(attachement.substring(attachement.lastIndexOf("\\")+1));
					multipart.addBodyPart(messageBodyPart);				
				}
			}

			// Send the complete message parts
			message.setContent(multipart);

		    transport = session.getTransport();
		    //transport.connect(user, password);
		    transport.connect();
		    
		    message.setRecipients(Message.RecipientType.TO, to);
		    transport.sendMessage(message, message.getAllRecipients());
		    logger.info("Sent '" + subject + "' to: " + to);
			
		} finally {
		    if (transport != null) 
		    	try { 
		    		transport.close(); 
		    	} catch (MessagingException me) {
		    		logger.error("", me);
		    	}
		}
	}
	
public static void sftp(String server, int port, String userName, String password, String source, String destination) throws Exception {
		
		// Sanity check
		if ((source == null) || (destination == null) ) {
			throw new Exception("Sources and Destination must be non-null, non-empty String");
		}
		JSch jsch = new JSch();
        com.jcraft.jsch.Session session = null;
		try {
        	
            session = jsch.getSession(userName, server, port);
            session.setConfig("StrictHostKeyChecking", "no");
            session.setPassword(password);
            session.connect(30000);

            Channel channel = session.openChannel("sftp");
            channel.connect(30000);
            ChannelSftp sftpChannel = (ChannelSftp) channel;
            
            logger.info("SFTP " + source + " to " +  server + " as " + userName);
            InputStream fis = new FileInputStream(source);
            sftpChannel.put(fis, destination);
            fis.close();
			sftpChannel.exit();
            session.disconnect();
            logger.info("Finished SFTP");
        } catch (Exception e) {
        	logger.error(e);
            throw e;
        } 
		
	}
	
	public static void handleError(GlobalProperties gp, Throwable e) {
		handleError(gp, e, null);
	}
	public static void handleError(GlobalProperties gp, Throwable e, String message) {
		if (message == null || message == "") {
			message  = "Error in " + e.getStackTrace()[e.getStackTrace().length-1].getClassName();
		}
		
		logger.error(message, e);
		if (gp.getTaskProperties().emailError()) {
			gp.setReportEmails(gp.getMail_smtp_log_error_to());
			String body = "Error in " + e.getStackTrace()[e.getStackTrace().length-1].getClassName() + "." + e.getStackTrace()[e.getStackTrace().length-1].getMethodName() + "\n\n";
			StringWriter sw = new StringWriter();
			PrintWriter pw = new PrintWriter(sw);
			e.printStackTrace(pw);
			body += sw.toString();
			
			email(gp, message, body, null);
			
		}
		if (gp.getTaskProperties().disableIfError()) {
			Properties properties = new Properties();
			SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH.mm.ss");
	    	try {
	    		properties.load(new FileInputStream(gp.getFileName()));
	    		properties.setProperty("task." + gp.getCurrentTask() + ".enable", "false");
	    		properties.store(new FileOutputStream(gp.getFileName()), "Updated by com.saiglobal.sf.core.utitlity.Utility on " + df.format(new Date()));
	    	} catch (IOException ioe) {
	    		logger.error("Error in accessing property file ", ioe);
	        }
		}
	}

	public static List<String> downloadAttachmentsFromEmail(GlobalProperties gp, SearchTerm[] searchTerms, boolean deleteAfterDownload, String downloadFolder) throws Exception {
		if (searchTerms == null || searchTerms.length==0)
			return null;
		
		if (downloadFolder == null)
			downloadFolder = "download";
		
		Properties properties = new Properties();
		properties.put("mail.store.protocol", "imap");
		properties.put("mail.imap.host", gp.getMail_imaps_host());
		properties.put("mail.imap.auth.plain.disable", "true");
		properties.put("mail.imap.auth", gp.getMail_imaps_auth());
		properties.put("mail.imap.ssl.enable", true);
		properties.put("mail.imap.ssl.checkserveridentity", "false");
		properties.put("mail.imap.ssl.trust", "*");
		
		final String user = gp.getMail_imaps_user().split("@")[0];
		final String password = gp.getMail_imaps_password();
	
	    Session session = Session.getInstance(properties);
	    session.setDebug(true);
	    
	    Store store = session.getStore();
	    store.connect(user, password);
	    logger.info("IMAP Connected to " + gp.getMail_imaps_host() + " as " + gp.getMail_imaps_user());
	    
	    Folder inbox = store.getFolder("Inbox");
	    inbox.open(Folder.READ_WRITE);
	    
	    // creates a search criterion
	    SearchTerm st = new AndTerm(searchTerms);

	    Message[] messages = inbox.search(st);
	    List<String> attachments = new ArrayList<String>();
	    for (Message message : messages) {
	    	if (message.getContent() instanceof Multipart) {
		    	Multipart multipart = (Multipart) message.getContent();
		    	
		        for (int i = 0; i < multipart.getCount(); i++) {
			        BodyPart bodyPart = multipart.getBodyPart(i);
			        if(!Part.ATTACHMENT.equalsIgnoreCase(bodyPart.getDisposition()) ) {
			          continue; // dealing with attachments only
			        }
			        InputStream is = bodyPart.getInputStream();
			        File f = new File(downloadFolder + "\\" + bodyPart.getFileName());
			        FileOutputStream fos = new FileOutputStream(f);
			        byte[] buf = new byte[4096];
			        int bytesRead;
			        while((bytesRead = is.read(buf))!=-1) {
			            fos.write(buf, 0, bytesRead);
			        }
			        fos.close();
			        is.close();
			        attachments.add(f.getAbsolutePath());
			        logger.info("IMAP Downoaded: " + downloadFolder + "/" + bodyPart.getFileName());
			        
			        if (deleteAfterDownload) {
			        	message.setFlag(Flags.Flag.DELETED, true);
			        	logger.info("IMAP Deleted email message: " + message.getSubject() + " of " + message.getSentDate());
			        }
		        }
	    	}
		}
	    inbox.close(true);
	    return attachments;
	}
	
	public static SimpleDateFormat getMysqldateformat() {
		return mysqlDateFormat;
	}

	public static SimpleDateFormat getMysqlutcdateformat() {
		return mysqlUtcDateFormat;
	}

	public static SimpleDateFormat getSoqldateformat() {
		return soqlDateFormat;
	}

	public static SimpleDateFormat getShortdatedisplayformat() {
		return shortDateDisplayFormat;
	}

	public static SimpleDateFormat getShortdatetimedisplayformat() {
		return shortDateTimeDisplayFormat;
	}

	public static Calendar getOrigin() {
		return origin;
	}

	public static SimpleDateFormat getFiledatetimedisplayformat() {
		return fileDateTimeDisplayFormat;
	}

	public static SimpleDateFormat getActivitydateformatter() {
		return activityDateFormatter;
	}

	public static SimpleDateFormat getPeriodformatter() {
		return periodFormatter;
	}
	
	public static String resultSetToCsv(ResultSet rs) throws SQLException {
		String csv = "";
		// Write details header
		ResultSetMetaData rsmd = rs.getMetaData();
		boolean first = true;
		for (int i = 1; i < rsmd.getColumnCount() + 1; i++ ) {
			if (first) {
				csv += rsmd.getColumnName(i);
				first=false;
			} else {
				csv += ("," + rsmd.getColumnName(i));	
			}
		}		
		csv += "\r\n";
		
		// Write details
		while (rs.next()) {
			first = true;
			for (int i = 1; i < rsmd.getColumnCount() + 1; i++ ) {
				if (first) {
					csv += rs.getString(i);
					first=false;
				} else {
					if (rs.getObject(i)==null) {
						csv += ",\\N";
					} else {
						if(rsmd.getColumnType(i)==Types.BOOLEAN)
							csv += (",\""+(rs.getString(i)=="false"?0:1)+"\"");
						else
							csv += (",\""+rs.getString(i).replace("\"","")+"\"");
					}
				}
			}
			csv += "\r\n";
		}
		return csv;
	}
	
	public static Stream<String> resultSetToStringStream(ResultSet rs) throws SQLException {
		List<String> rows = new ArrayList<String>();
		
		// Write details header
		ResultSetMetaData rsmd = rs.getMetaData();
		boolean first = true;
		String header = "";
		for (int i = 1; i < rsmd.getColumnCount() + 1; i++ ) {
			if (first) {
				header += rsmd.getColumnName(i);
				first=false;
			} else {
				header += ("," + rsmd.getColumnName(i));	
			}
		}
		rows.add(header);
		
		 
		// Write details
		while (rs.next()) {
			String row =  "";
			first = true;
			for (int i = 1; i < rsmd.getColumnCount() + 1; i++ ) {
				if (first) {
					row += rs.getString(i);
					first=false;
				} else {
					if (rs.getObject(i)==null) {
						row += ",\\N";
					} else {
						if(rsmd.getColumnType(i)==Types.BOOLEAN)
							row += (",\""+(rs.getString(i)=="false"?0:1)+"\"");
						else
							row += (",\""+rs.getString(i).replace("\"","")+"\"");
					}
				}
			}
			rows.add(row);
		}
		return rows.stream();
	}
	
	public static Object[][] resultSetToObjectArray(ResultSet rs, boolean addHeader) throws SQLException {
		List<Object[]> records=new ArrayList<Object[]>();
		ResultSetMetaData rsmd = rs.getMetaData();
		int cols = rsmd.getColumnCount();
		if (addHeader) {
			Object[] header = new Object[cols];
			for (int i = 0; i < cols; i++ ) {
				header[i] = rsmd.getColumnLabel(i+1);	
			}
			records.add(header);
		}
		while(rs.next()){
		    Object[] arr = new Object[cols];
		    for(int i=0; i<cols; i++){
		      arr[i] = rs.getObject(i+1);
		    }
		    records.add(arr);
		}
		
		return records.toArray(new Object[records.size()][cols]);
	}
	
	public static String csvToHtmlTable(String csvData) {
		StringBuffer htmlTable = new StringBuffer();
		htmlTable.append("<table>");
		for (String line : csvData.split("\n")) {
			htmlTable.append("<tr>");
			for (String element : line.split(",")) {
				htmlTable.append("<td>" + element + "</td>");
			}
			htmlTable.append("</tr>");
		}
		htmlTable.append("</table>");
		return htmlTable.toString();
	}
	
	public static double calculateTravelReturnTimeHrs(double lat1, double lon1, double lat2, double lon2) {
		return calculateTravelTimeHrs(2*calculateDistanceKm(lat1, lon1, lat2, lon2), true);
	}
	
	public static double calculateTravelTimeHrs(double distanceKm, boolean returnDistance) {
		if (!returnDistance)
			distanceKm = distanceKm*2;
		double travelTime;
		double totalEquivalentTravelReturnHrs;
		if (distanceKm<0) {
			logger.info("Error in calculating travel time.  Assuming WCS 1 day");
			travelTime = 16;
		} else {
			if(distanceKm<400) {
				// Assume Driving at average speed 50Km/hr
				travelTime = distanceKm/60.0;
			} else if(distanceKm<1000) {
				// Assume Driving/Train average speed 80Km/hr
				travelTime = distanceKm/80.0;
			} else {
				// Assume Flying at average speed 800Km/hr + 1 hrs take-off
				travelTime = distanceKm/800.0 + 2;
			}
		}
		
		if (travelTime <= 4) {
			// Done within audit day
			totalEquivalentTravelReturnHrs = 0;
		} else if(travelTime <=12) {
			// 1/2 day for travel each way
			totalEquivalentTravelReturnHrs = 8;
		} else {
			// WCS 1 day each way
			totalEquivalentTravelReturnHrs = 16;
		}
		
		return returnDistance?totalEquivalentTravelReturnHrs:totalEquivalentTravelReturnHrs/2;
	}
}
