package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class BRCListingScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final String search_page = "https://www.brcdirectory.com/InternalSite//Siteresults.aspx";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static String __EVENTTARGET = "ctl00$ContentPlaceHolder1$gv_Results";
	private static String __EVENTARGUMENT = null;
	private static String __VIEWSTATE = null;
	private static String __EVENTVALIDATION = null;
	private static final Logger logger = Logger.getLogger(BRCListingScraper.class);

	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		String lockName = BRCListingScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}
		
		int page = 1;
		try {	
			String[] tobeUpdated = null;
			while ((tobeUpdated = getCertifiedOrganisations(page++)) != null) {
				String newBRCSitesQuery = "select t.* from (select ";
				newBRCSitesQuery += StringUtils.join(tobeUpdated, " as 'Id' union select ");
				newBRCSitesQuery += ") t "
						+ "left join analytics.brc_certified_organisations bco on t.Id = bco.BRCSiteCode "
						+ "where bco.BRCSiteCode is null;";
				ResultSet rs = db.executeSelect(newBRCSitesQuery, -1);
				while (rs.next()) {
					logger.info("Found new BRC Site: " + rs.getString("Id") + ". Getting details");
					BRCDetailsScraper.updateBRCDetails(rs.getString("Id"));
					int sleep = (int) (sleepMin + Math.random()*sleepVar);
					Thread.sleep(sleep);
				}
				int sleep = (int) (sleepMin + Math.random()*sleepVar);
				Thread.sleep(sleep);
			}
		} catch (Exception e) {
			Utility.handleError(p, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
	private static Document getPage(String address, int page) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				Connection conn = Jsoup.connect(address).timeout(read_timeout);
				logger.info("Fetching page: " + address + ". Page: " + page + ". Try no. " + tryNo);
				if(page>1) {
					__EVENTARGUMENT = "Page$" + page;
					conn.header("Content-Type", "application/x-www-form-urlencoded");
					if(__EVENTTARGET != null) conn.data("__EVENTTARGET", __EVENTTARGET);
					if(__EVENTARGUMENT != null) conn.data("__EVENTARGUMENT", __EVENTARGUMENT);
					if(__VIEWSTATE != null) conn.data("__VIEWSTATE", __VIEWSTATE);
					if(__EVENTVALIDATION != null) conn.data("__EVENTVALIDATION", __EVENTVALIDATION);
					retValue = conn.post();
				} else {
					retValue = conn.get();
				}
				retry = false;
			} catch (IOException ioe) {
				logger.error("Error in fetching page: " + address);
				if (tryNo<maxTries) {
					tryNo++;
					Thread.sleep(sleepMin);
				} else {
					throw ioe;
				}
			}
		}
		return retValue;
	}
	private static String[] getCertifiedOrganisations(int page) throws Exception {
		List<String> retValue = new ArrayList<String>();
		URL address = new URL(search_page + "?StandardId=00000000-0000-0000-0000-000000000000");
		Document doc = null;
		doc = getPage(address.toString(), page);

		if (doc != null) {
			// Parse response to update hidden parameters for next request
			__VIEWSTATE = doc.getElementById("__VIEWSTATE").attr("value");
			__EVENTVALIDATION = doc.getElementById("__EVENTVALIDATION").attr("value");
			String[] lables = new String[] {"2","3","4","5","6"};
			for (String label : lables) {
				try {
					retValue.add(doc.getElementById("ctl00_ContentPlaceHolder1_gv_Results_ctl0"+label+"_hl_Site").attr("href").split("=")[1]);
				} catch (Exception e) {
					logger.error("Error in parsing page: " + page + ", label: " + label, e);
					// Continue with next one
				}
			}
		}
		if (retValue.size()>0) {
			return retValue.toArray(new String[retValue.size()]);
		} else {
			logger.info(doc.toString());
			return null;
		}
	}
}