package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.saiglobal.scrapers.model.CertifiedOrganisation;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class FSSC22kListingScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static String search_page = "https://viasyst.net/fssc?page=0";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final Logger logger = Logger.getLogger(FSSC22kListingScraper.class);

	
	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		String lockName = FSSC22kListingScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}

		try {
			List<String> notNoBeDeletedId = new ArrayList<String>();
			List<CertifiedOrganisation> scraped = null;
			while ((scraped = scrapeCertifiedOrganisations()) != null) {
				for (CertifiedOrganisation co : scraped) {
					// Update database
					updateDb(co);
					// Remove not to be deleted
					notNoBeDeletedId.add(co.getId());
				}
				int sleep = (int) (sleepMin + Math.random()*sleepVar);
				Thread.sleep(sleep);
			}
			// Mark not updated as deleted
			db.executeStatement("update fssc22000_certified_organisations set IsDeleted=1 where Id not in ('" + StringUtils.join(notNoBeDeletedId.toArray(new String[notNoBeDeletedId.size()]), "','") + "')");
		} catch (Exception e) {
			Utility.handleError(p, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
	private static void updateDb(CertifiedOrganisation co) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException {
		String update = "insert into fssc22000_certified_organisations values ("
				+ clean(co.getId()) 
				+ ", " + clean(co.getName())
				+ ", " + clean(co.getAddress())
				+ ", " + clean(co.getCity()) 
				+ ", " + clean(co.getState()) 
				+ ", " + clean(co.getCountry()) 
				+ ", " + clean(co.getScope()) 
				+ ", " + clean(co.getAuditScope()) 
				+ ", " + clean(co.getCertificationStandards())
				+ ", " + clean(co.getAccredited())
				+ ", " + clean(co.getStatus())
				+ ", " + clean(co.getDateCertified())
				+ ", " + clean(co.getDateExpiry())
				+ ", utc_timestamp()"
				+ "," + co.isDeleted() + ") "
			+ " on duplicate key update "
				+ "`companyName`=values(`companyName`) "
				+ ", `address`=values(`address`) "
				+ ", `state`=values(`city`) "
				+ ", `state`=values(`state`) "
				+ ", `Country`=values(`Country`) "
				+ ", `scope`=values(`scope`) "
				+ ", `auditScope`=values(`auditScope`) "
				+ ", `standard`=values(`standard`) "
				+ ", `accredited`=values(`accredited`) "
				+ ", `status`=values(`status`) "
				+ ", `TypeOfCertification`=values(`TypeOfCertification`) "
				+ ", `issueDate`=values(`issueDate`) "
				+ ", `expiryDate`=values(`expiryDate`) "
				+ ", `isDeleted`=values(`isDeleted`) ";;
	
			db.executeStatement(update);
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
	
	private static Document getPage(String address) throws IOException, InterruptedException {
		boolean retry = true;
		int tryNo = 1;
		Document retValue = null;
		while (retry) {
			try {
				logger.info("Fetching page: " + address + ". Try no. " + tryNo);
				Connection conn = Jsoup.connect(address).timeout(read_timeout);
				retValue = conn.get();
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
	
	private static List<CertifiedOrganisation> scrapeCertifiedOrganisations() throws Exception {
		if(search_page==null)
			return null;
		List<CertifiedOrganisation> retValue = new ArrayList<CertifiedOrganisation>();
		URL address = new URL(search_page);
		Document doc = null;
		doc = getPage(address.toString());

		if (doc != null) {
			// Parse response to update address for next request
			Elements nextPageElement = doc.getElementsByAttributeStarting("Go to next page");
			if(nextPageElement != null && nextPageElement.size()>0)
				search_page = nextPageElement.get(0).attr("href");
			else
				search_page = null;
			Elements tables = doc.getElementsByClass("views-table cols-12");
			if(tables!=null && tables.size()>0) {
				Elements rows = tables.get(0).getElementsByTag("tr");
				if(rows != null && rows.size()>0) {
					Iterator<Element> rowsIterator = rows.iterator();
					while (rowsIterator.hasNext()) {
						Elements fields = rowsIterator.next().getElementsByTag("td");
						if (fields != null && fields.size()==12) {
							CertifiedOrganisation co = new CertifiedOrganisation();
							co.setName(fields.get(0).text());
							co.setAddress(fields.get(1).text());
							co.setCity(fields.get(2).text());
							co.setState(fields.get(3).text());
							co.setCountry(fields.get(4).text());
							co.setScope(fields.get(5).text());
							co.setAuditScope(fields.get(6).text());
							co.setCertificationStandards(fields.get(7).text());
							co.setAccredited(fields.get(8).text());
							co.setCertificationStatus(fields.get(9).text());
							String dateCertifiedText = fields.get(10).text();
							String dateExpiryText = fields.get(11).text();
							try {
								Date dateCertified = Utility.getActivitydateformatter().parse(dateCertifiedText);
								Date dateExpiry = Utility.getActivitydateformatter().parse(dateExpiryText);
								Calendar calCertified = Calendar.getInstance();
								Calendar calExpiry  = Calendar.getInstance();
								calCertified.setTime(dateCertified);
								calExpiry.setTime(dateExpiry);
								co.setDateCertified(calCertified);
								co.setDateExpiry(calExpiry);
							} catch (ParseException e) {
								// Ignore
							}
							co.setDeleted(false);
							co.setIdFromHash();
							retValue.add(co);
						}
					}
				}
			}
		}
		if (retValue.size()==0) 
			logger.info(doc.toString());
		
		return retValue;
	}
}