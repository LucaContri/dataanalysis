package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class JASANZListingScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final String search_page = "http://www.jas-anz.com.au/our-directory/certified-organisations";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final Logger logger = Logger.getLogger(JASANZListingScraper.class);

	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		
		String lockName = JASANZListingScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}
		
		int page = 1;
		try {	
			String[] tobeUpdated = null;
			while ((tobeUpdated = getCertifiedOrganisations(page++)) != null) {
				String newJASANZSitesQuery = "select t.* from (select '";
				newJASANZSitesQuery += StringUtils.join(tobeUpdated, "' as 'Id' union select '");
				newJASANZSitesQuery += "') t "
						+ "left join analytics.jasanz_certified_organisations jasanzco on t.Id = jasanzco.Id "
						+ "where jasanzco.Id is null;";
				ResultSet rs = db.executeSelect(newJASANZSitesQuery, -1);
				while (rs.next()) {
					logger.info("Found new JASANZ Site: " + rs.getString("Id") + ". Getting details");
					JASANZDetailsScraper.updateJASANZDetails(rs.getString("Id"));
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

	private static Document getPage(String address) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				System.out.println("Fetching page: " + address + ". Try no. " + tryNo);
				retValue = Jsoup.connect(address).timeout(read_timeout).get();
				retry = false;
			} catch (IOException ioe) {
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
		URL address = new URL(search_page + "?accredited_body=All&page=" + page);
		Document doc = null;
		doc = getPage(address.toString());

		if (doc != null) {
			Elements table = doc.getElementsByClass("cols-5");
			if (table != null && table.size()==1) {
				Elements rows = table.first().getElementsByTag("tr");
				if (rows != null && rows.size()>1) {
					boolean header = true;
					for (Element row : rows) {
						if (header) {
							header = false;
							continue;
						}
						Elements cells = row.getElementsByTag("td");
						if (cells != null && cells.size()==5) {
							Elements detailsLink = cells.get(1).getElementsByTag("a");
							if (detailsLink != null && detailsLink.size()==1) {
								String[] aux = detailsLink.get(0).attr("href").split("/");
								retValue.add(aux[aux.length-1]);
							}
						}
					}
				}
			}
		}
		if (retValue.size()>0)
			return retValue.toArray(new String[retValue.size()]);
		else
			return null;
	}
}