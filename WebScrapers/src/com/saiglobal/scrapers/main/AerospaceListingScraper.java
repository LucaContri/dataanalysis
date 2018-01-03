package com.saiglobal.scrapers.main;

import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import org.apache.log4j.Logger;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.saiglobal.scrapers.model.AccrediaCertifiedOrganisation;
import com.saiglobal.scrapers.model.CertifiedOrganisationOld;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class AerospaceListingScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static String fileName = "/Users/conluc0/Downloads/aerospace_certified_organisations.html";
	private static final Logger logger = Logger.getLogger(AerospaceListingScraper.class);
	
	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] commandLineArguments) throws Exception {
		// Parse Arguments
		
		String lockName = AerospaceListingScraper.class.getCanonicalName();
		boolean gotLock = Utility.getLock(lockName);
		
		if (!gotLock) {
			logger.info("Cannot get lock.  Process already running.  Exiting");
			return;
		}

		try {
			List<AccrediaCertifiedOrganisation> scraped = scrapeCertifiedOrganisations(fileName);
			
			String update = "insert into aerospace_certified_organisations values ";
			for (int i=0; i<scraped.size(); i++) {
				AccrediaCertifiedOrganisation co = scraped.get(i);
				update += " (" + clean(co.getId()) 
						+ ", " + clean(co.getCertificateId()) 
						+ ", " + clean(co.getCompanyName())
						+ ", " + clean(co.getStatus())
						+ ", " + clean(co.getAddress())
						+ ", " + clean(co.getStructureType()) 
						+ ", " + clean(co.getStandards())
						+ ", " + clean(co.getCertificationBody())
						+ ", " + clean(co.getCentralOffice())
						+ ", utc_timestamp()"
						+ ", utc_timestamp()"
						+ "," + co.isDeleted() + "),";
				if(i%1000==0) {
					update = Utility.removeLastChar(update);
					db.executeStatement(update);
					update = "insert into aerospace_certified_organisations values ";
				}
			}
			update = Utility.removeLastChar(update);
			db.executeStatement(update);
			
		} catch (Exception e) {
			Utility.handleError(p, e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
		}
	}
	private static void updateDb(AccrediaCertifiedOrganisation co) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, NoSuchAlgorithmException, UnsupportedEncodingException {
		String update = "insert into aerospace_certified_organisations values ("
				+ clean(co.getId()) 
				+ ", " + clean(co.getCertificateId()) 
				+ ", " + clean(co.getCompanyName())
				+ ", " + clean(co.getStatus())
				+ ", " + clean(co.getAddress())
				+ ", " + clean(co.getStructureType()) 
				+ ", " + clean(co.getStandards())
				+ ", " + clean(co.getCertificationBody())
				+ ", " + clean(co.getCentralOffice())
				+ ", utc_timestamp()"
				+ ", utc_timestamp()"
				+ "," + co.isDeleted() + ") ";
	
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
				File input = new File(address);
				retValue = Jsoup.parse(input, "UTF-8", "http://example.com/");
				retry = false;
			} catch (IOException ioe) {
				throw ioe;
			}
		}
		return retValue;
	}
	
	private static List<AccrediaCertifiedOrganisation> scrapeCertifiedOrganisations(String address) throws Exception {
		if(fileName==null)
			return null;
		List<AccrediaCertifiedOrganisation> retValue = new ArrayList<AccrediaCertifiedOrganisation>();
		Document doc = null;
		doc = getPage(address);

		if (doc != null) {
			Elements trs = doc.getElementsByTag("tr");
			int i = 0;
			for (Element tr: trs) {
				if (i++==0)
					continue;
				
				try {
					Element company = tr.select("td").get(0).select("a").first();
					String href = company.attr("href");
					String OIN = href.split("'")[1];
					AccrediaCertifiedOrganisation co = new AccrediaCertifiedOrganisation();
				
					co.setComapnyName(company.text().trim());
					co.setId(OIN);
					try { co.setAddress(tr.select("td").get(1).text().trim()); } catch (Exception e) {e.printStackTrace();}
					try { co.setCertificateId(tr.select("td").get(2).text().trim()); } catch (Exception e) {e.printStackTrace();}
					try { co.setStandards(tr.select("td").get(3).text().trim()); } catch (Exception e) {e.printStackTrace();}
					try { co.setCertificationBody(tr.select("td").get(4).text().trim()); } catch (Exception e) {e.printStackTrace();}	
					try { co.setStatus(tr.select("td").get(5).text().trim()); } catch (Exception e) {e.printStackTrace();}
					try { co.setStructureType(tr.select("td").get(6).text().trim()); } catch (Exception e) {e.printStackTrace();}
					try { co.setCentralOffice(tr.select("td").get(7).text().trim()); } catch (Exception e) {e.printStackTrace();}
					retValue.add(co);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		if (retValue.size()==0) 
			logger.info(doc.toString());
		
		return retValue;
	}
}