package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.HashMap;

import org.apache.log4j.Logger;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class ReedDetailsScraper {
	private static final GlobalProperties p = Utility.getProperties("/mnt/disk/SAI/properties/pi.config.properties");
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final String detail_page = "http://www.reed.co.uk";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final int minAgingDays = 5;
	private static final SimpleDateFormat mysqlFormat = new SimpleDateFormat("yyyy-MM-dd");
	private static final Logger logger = Logger.getLogger(ReedDetailsScraper.class);
	
	static {
		// Init
		db.use("jobs");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		
		try {
			while (true) {
				String nextListingToBeUpdate = null;
				while ((nextListingToBeUpdate = getNextToBeUpdated()) != null) {
					try {
						updateListingDetails(nextListingToBeUpdate);
						logger.info("Updated Listing " + nextListingToBeUpdate);
					} catch (Exception e) {
						Utility.handleError(p, e);
					}
					int sleep = (int) (sleepMin + Math.random()*sleepVar);
					Thread.sleep(sleep);
				}
				// No more to update.  Sleep until there will be.
				int sleep2 = Math.max(sleepMin, db.executeScalarInt("select " + minAgingDays + "*24*3600 - timestampdiff(second, min(lastUpdated),utc_timestamp()) from listing_reed;"));
				logger.info("No more sites to update for now. Sleeping for " + sleep2 + " seconds");
				Thread.sleep(sleep2*1000);
			}
		} catch (Throwable t) {
			t.printStackTrace();
		}
	}
	
	private static String getNextToBeUpdated() {
		
		ResultSet rs;
		try {
			rs = db.executeSelectThreadSafe("select link from listing_reed where lastUpdated<date_add(utc_timestamp(), interval -" + minAgingDays + " day) order by lastUpdated asc", 1);
			if (rs.next()) {
				return rs.getString("link");
			}
		} catch (Exception e) {
			// Ignore for now
		}
		return null;
		
	}
	
	public static void updateListingDetails(String link) throws Exception {
		HashMap<String,Object> listing = getListingDetails(link);
		if (listing != null) {
			String update = null;
			if (listing.containsKey("delete")) {
				update = "UPDATE listing_reed set IsDeleted=1, lastUpdated=utc_timestamp() where id=" + clean(listing.get("Id"));
			} else {
				update = "UPDATE listing_reed set "
						+ "lastUpdated=utc_timestamp() "
						+ ", `desc` = " + clean(listing.get("desc")) 
						+ ", applications = " + clean(listing.get("applications")) 
						+ ", skills = " + clean(listing.get("skills")) 
						+ " where id=" + clean(listing.get("id"));
			}
			
			db.executeStatement(update);
		}
	}
	private static Document getPage(String address) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				Connection conn = Jsoup.connect(address).timeout(read_timeout);
				retValue = conn.get();
				retry = false;
			} catch (Exception ioe) {
				ioe.printStackTrace();
			}
		}
		return retValue;
	}
	
	public static HashMap<String, Object> getListingDetails(String link) throws Exception {
		HashMap<String, Object> listing = new HashMap<String, Object>();
		listing.put("id", link.split("/")[3]);
		URL address = new URL(detail_page + link);
		Document doc = null;
		doc = getPage(address.toString());
		
		if (doc != null) {
				try {
				listing.put("desc", doc.getElementsByClass("description").first().text());
				String skills = "";
				for (Element skill: doc.getElementsByClass("skill-name")) {
					skills+=skill.text()+",";
				}
				listing.put("skills", skills);
				listing.put("applications", Integer.parseInt(doc.getElementsByClass("applications").first().text().replace("applications", "").replace("application", "").trim()));
			} catch (Exception e) {
				listing.put("isdeleted", "true");
			}
		} else {
			listing.put("isdeleted", "true");
		}
		return listing;
	}
		
	private static String clean(Object i) {
		if (i==null)
			return "null";
		if ((i instanceof Integer) || ((i instanceof Double)) || (i instanceof Float))
			return i.toString();
		if (i instanceof Calendar)
			return "'" + mysqlFormat.format(((Calendar)i).getTime()) + "'";
		if(i instanceof String) {
			if (((String)i).equalsIgnoreCase(""))
				return "null";
			else
				return "'" + ((String)i).replace("\\","").replace("'", "\\'").trim() + "'";
		}
		return "'" + i.toString().replace("\\","").replace("'", "\\'") + "'";
	}	
}