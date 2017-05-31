package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Calendar;






import org.apache.log4j.Logger;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.select.Elements;

import com.saiglobal.scrapers.model.CertifiedOrganisation;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class JASANZDetailsScraper {

	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final String search_page = "http://www.jas-anz.com.au/our-directory/certified-organisations";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final int minAgingDays = 5;
	private static final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	private static final SimpleDateFormat mysqlFormat = new SimpleDateFormat("yyyy-MM-dd");
	private static final Logger logger = Logger.getLogger(JASANZDetailsScraper.class);
	private static String[] trackHistoryFields = new String[] {"CertificationBody"};
	
	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {	
		String lockName = JASANZDetailsScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}
		try {
			while (true) {
				String nextSiteToBeUpdate = null;
				while ((nextSiteToBeUpdate = getNextToBeUpdated()) != null) {
					try {
						updateJASANZDetails(nextSiteToBeUpdate);
						logger.info("Updated JASANZ site " + nextSiteToBeUpdate);
					} catch (Exception e) {
						Utility.handleError(p, e);
					}
					int sleep = (int) (sleepMin + Math.random()*sleepVar);
					Thread.sleep(sleep);
				}
				// No more to update.  Sleep until there will be.
				int sleep2 = db.executeScalarInt("select " + minAgingDays + "*24*3600 - timestampdiff(second, min(lastUpdated),utc_timestamp()) from analytics.jasanz_certified_organisations;");
				logger.info("No more sites to update for now. Sleeping for " + sleep2 + " seconds");
				Thread.sleep(sleep2*1000);
			}
							
		} catch (Throwable t) {
			Utility.handleError(p, t);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}			
	}
	
	private static String getNextToBeUpdated() {
		ResultSet rs;
		try {
			rs = db.executeSelectThreadSafe("select Id from jasanz_certified_organisations where lastUpdated<date_add(utc_timestamp(), interval -" + minAgingDays + " day) order by lastUpdated asc", 1);
			if (rs.next()) {
				return rs.getString("Id");
			}
		} catch (Exception e) {
			// Ignore for now
		}
		return null;
	}
	
	public static void updateJASANZDetails(String Id) throws Exception {
		CertifiedOrganisation co = getCertifiedOrganisationDetails(Id);
		
		if (co != null) {
			// Track history fields
			for (String fieldName : trackHistoryFields) {
				if (db.executeScalarInt("select " + fieldName + "=" + clean(co.getField(fieldName)) + " from jasanz_certified_organisations where Id=" + clean(Id))<=0) {
					db.executeStatement(
							"INSERT INTO jasanz_certified_organisations_history values ("
							+ clean(Id)
							+ "," + clean(fieldName)
							+ ",utc_timestamp()"
							+ ", (SELECT " + fieldName + " FROM jasanz_certified_organisations where Id=" + clean(Id) + ")"
							+ ",'" + co.getField(fieldName) + "')"
							);
				}
			}
			String update = null;
			if (co.isDeleted()) {
				update = "UPDATE jasanz_certified_organisations set IsDeleted=1, LastUpdated=utc_timestamp() where Id=" + clean(co.getId());
			} else {
				update = "insert into jasanz_certified_organisations values ("
						+ clean(co.getId()) 
						+ ", " + clean(co.getName())
					+ ", " + clean(co.getStatus())
					+ ", " + clean(co.getTypeOfCertification()) 
					+ ", " + clean(co.getCountry()) 
					+ ", " + clean(co.getCity()) 
					+ ", " + clean(co.getScope()) 
					+ ", " + clean(co.getCertificationStandards())
					+ ", " + clean(co.getCertificationCodes()) 
					+ ", " + clean(co.getCertificationBody())
					+ ", " + clean(co.getDateCertified())
					+ ", utc_timestamp()"
					+ ", utc_timestamp()"
					+ "," + co.isDeleted() + ") "
					+ " on duplicate key update "
					+ "`Name`=values(`Name`) "
					+ ", `Status`=values(`Status`) "
					+ ", `TypeOfCertification`=values(`TypeOfCertification`) "
					+ ", `Country`=values(`Country`) "
					+ ", `City`=values(`City`) "
					+ ", `Scope`=values(`Scope`) "
					+ ", `CertificationStandards`=values(`CertificationStandards`) "
					+ ", `CertificationCodes`=values(`CertificationCodes`) "
					+ ", `CertificationBody`=values(`CertificationBody`) "
					+ ", `DateCertified`=values(`DateCertified`) "
					+ ", `LastUpdated`=values(`LastUpdated`) "
					+ ", `isDeleted`=values(`isDeleted`) ";;
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
	
	private static CertifiedOrganisation getCertifiedOrganisationDetails(String id) throws Exception {
		CertifiedOrganisation co = new CertifiedOrganisation();
		URL address = new URL(search_page + "/" + id);
		Document doc = null;
		try {
			doc = getPage(address.toString());
		} catch (IOException ioe) {
			System.out.println("Error reading page: " + address.toString());
			ioe.printStackTrace();
			System.out.println("Skipping page: " + address.toString());
		}
		if (doc != null) {
			co.setId(id);
			Elements title = doc.getElementsByClass("description");
			if (title != null && title.size()==1 && title.get(0).text() != null) { 
				co.setName(title.get(0).text().trim());
			} else {
				co.setDeleted(true);
			}
			Elements typeOfCert = doc.getElementsByClass("views-field-type");
			if (typeOfCert!= null && typeOfCert.size()==1 && typeOfCert.get(0).childNodeSize()==2) { 
				co.setTypeOfCertification(typeOfCert.get(0).childNode(1).toString().trim());
			}
			Elements status = doc.getElementsByClass("views-field-status");
			if (status!= null && status.size()==1 && status.get(0).childNodeSize()==2) { 
				co.setStatus(status.get(0).childNode(1).toString().trim());
			} 
			Elements city = doc.getElementsByClass("views-field-location");
			if (city!= null && city.size()==1 && city.get(0).childNodeSize()==2) { 
				co.setCity(city.get(0).childNode(1).toString().trim());
			}
			Elements country = doc.getElementsByClass("views-field-country");
			if (country!= null && country.size()==1 && country.get(0).childNodeSize()==2) { 
				co.setCountry(country.get(0).childNode(1).toString().trim());
			}
			Elements scope = doc.getElementsByClass("views-field-scope");
			if (scope!= null && scope.size()==1 && scope.get(0).childNodeSize()==2) { 
				co.setScope(scope.get(0).childNode(1).toString().trim());
			}
			Elements standard = doc.getElementsByClass("views-field-standard");
			if (standard!= null && standard.size()==1 && standard.get(0).childNodeSize()==2) { 
				co.setCertificationStandards(standard.get(0).childNode(1).toString().trim());
			}
			Elements codes = doc.getElementsByClass("views-field-code");
			if (codes!= null && codes.size()==1 && codes.get(0).childNodeSize()==2) { 
				co.setCertificationCodes(codes.get(0).childNode(1).toString().trim());
			}
			Elements date = doc.getElementsByClass("views-field-date");
			if (date!= null && date.size()==1 && date.get(0).childNodeSize()==2) {
				String dateString = date.get(0).childNode(1).toString().trim();
				Calendar dateCert = Calendar.getInstance();
				try {
					dateCert.setTime(dateFormat.parse(dateString));
				} catch (Exception e) {
					// Ignore
					dateCert = null;
				}
				co.setDateCertified(dateCert);
			} else {
			}
			Elements cb = doc.getElementsByClass("views-field-accredited-body");
			if (cb!= null && cb.size()==1 && cb.get(0).childNodeSize()==2) { 
				co.setCertificationBody(cb.get(0).childNode(1).toString().trim());
			}
		}

		return co;
	}
	
}
