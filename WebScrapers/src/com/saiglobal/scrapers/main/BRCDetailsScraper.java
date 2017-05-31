package com.saiglobal.scrapers.main;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.log4j.Logger;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import com.saiglobal.scrapers.model.BRCCertifiedOrganisation;
import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class BRCDetailsScraper {
	private static final GlobalProperties p = Utility.getProperties();
	private static final DbHelperDataSource db = new DbHelperDataSource(p);
	private static final String detail_page = "https://www.brcdirectory.com/InternalSite//Site.aspx";
	private static final int read_timeout = 30000;
	private static final int maxTries = 3;
	private static final int sleepMin = 5000;
	private static final int sleepVar= 5000;
	private static final int minAgingDays = 5;
	private static final SimpleDateFormat mysqlFormat = new SimpleDateFormat("yyyy-MM-dd");
	private static final Logger logger = Logger.getLogger(BRCDetailsScraper.class);
	private static String[] trackHistoryFields = new String[] {"certificationBody"};
	
	static {
		// Init
		db.use("analytics");
		p.setCurrentTask("webscraper");
	}
	
	public static void main(String[] args) throws Exception {
		
		String lockName = BRCDetailsScraper.class.getCanonicalName();
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
						updateBRCDetails(nextSiteToBeUpdate);
						logger.info("Updated BRC site " + nextSiteToBeUpdate);
					} catch (Exception e) {
						Utility.handleError(p, e);
					}
					int sleep = (int) (sleepMin + Math.random()*sleepVar);
					Thread.sleep(sleep);
				}
				// No more to update.  Sleep until there will be.
				int sleep2 = Math.max(sleepMin, db.executeScalarInt("select " + minAgingDays + "*24*3600 - timestampdiff(second, min(lastUpdated),utc_timestamp()) from analytics.brc_certified_organisations;"));
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
			rs = db.executeSelectThreadSafe("select BRCSiteCode from brc_certified_organisations where lastUpdated<date_add(utc_timestamp(), interval -" + minAgingDays + " day) order by lastUpdated asc", 1);
			if (rs.next()) {
				return rs.getString("BRCSiteCode");
			}
		} catch (Exception e) {
			// Ignore for now
		}
		return null;
	}
	
	public static void updateBRCDetails(String siteId) throws Exception {
		BRCCertifiedOrganisation co = getCertifiedOrganisationDetails(siteId);
		if (co != null) {
			// Track history fields
			for (String fieldName : trackHistoryFields) {
				if (db.executeScalarInt("select " + fieldName + "=" + clean(co.getField(fieldName)) + " from brc_certified_organisations where BRCSiteCode=" + clean(siteId))<=0) {
					db.executeStatement(
							"INSERT INTO brc_certified_organisations_history values ("
							+ clean(siteId)
							+ "," + clean(fieldName)
							+ ",utc_timestamp()"
							+ ", (SELECT " + fieldName + " FROM brc_certified_organisations where BRCSiteCode=" + clean(siteId) + ")"
							+ "," + clean(co.getField(fieldName)) + ")"
							);
				}
			}
			String update = null;
			if (co.isDeleted()) {
				update = "UPDATE brc_certified_organisations set IsDeleted=1, lastUpdated=utc_timestamp() where BRCSiteCode=" + clean(siteId);
			} else {
				update = "INSERT INTO brc_certified_organisations values ("
					+ clean(siteId)
					+ "," + clean(co.getCompanyName())
					+ "," + clean(co.getContact())
					+ "," + clean(co.getContactEMail())
					+ "," + clean(co.getContactPhone())
					+ "," + clean(co.getContactFax())
					+ "," + clean(co.getCommercialContact())
					+ "," + clean(co.getCommercialContactEmail())
					+ "," + clean(co.getCommercialContactPhone())
					+ "," + clean(co.getAddress())
					+ "," + clean(co.getCity())
					+ "," + clean(co.getPostCode())
					+ "," + clean(co.getRegionState())
					+ "," + clean(co.getLatitude())
					+ "," + clean(co.getLongitude())
					+ "," + clean(co.getCountry())
					+ "," + clean(co.getPhone())
					+ "," + clean(co.getFax())
					+ "," + clean(co.getEmail())
					+ "," + clean(co.getWebsite())
					+ "," + clean(co.getGrade())
					+ "," + clean(co.getScope())
					+ "," + clean(co.getExclusion())
					+ "," + clean(co.getCertificationBody())
					+ "," + clean(co.getAuditCategory())
					+ "," + clean(co.getStandard())
					+ "," + clean(co.getCodes())
					+ "," + clean(co.getIssueDate())
					+ "," + clean(co.getExpiryDate())
					+ ",utc_timestamp() "
					+ ",utc_timestamp() "
					+ "," + co.isDeleted() + ") "
					+ "on duplicate key update "
					+ "`companyName`=values(`companyName`) "
					+ ", `contact`=values(`contact`) "
					+ ", `contactEMail`=values(`contactEMail`) "
					+ ", `contactPhone`=values(`contactPhone`) "
					+ ", `contactFax`=values(`contactFax`) "
					+ ", `commercialContact`=values(`commercialContact`) "
					+ ", `commercialContactEMail`=values(`commercialContactEMail`) "
					+ ", `commercialContactPhone`=values(`commercialContactPhone`) "
					+ ", `address`=values(`address`) "
					+ ", `city`=values(`city`) "
					+ ", `postCode`=values(`postCode`) "
					+ ", `regionState`=values(`regionState`) "
					+ ", `latitude`=values(`latitude`) "
					+ ", `longitude`=values(`longitude`) "
					+ ", `country`=values(`country`) "
					+ ", `phone`=values(`phone`) "
					+ ", `fax`=values(`fax`) "
					+ ", `email`=values(`email`) "
					+ ", `website`=values(`website`) "
					+ ", `grade`=values(`grade`) "
					+ ", `scope`=values(`scope`) "
					+ ", `exclusion`=values(`exclusion`) "
					+ ", `certificationBody`=values(`certificationBody`) "
					+ ", `auditCategory`=values(`auditCategory`) "
					+ ", `standard`=values(`standard`) "
					+ ", `codes`=values(`codes`) "
					+ ", `issueDate`=values(`issueDate`) "
					+ ", `expiryDate`=values(`expiryDate`) "
					+ ", `lastUpdated`=values(`lastUpdated`) "
					+ ", `isDeleted`=values(`isDeleted`) ";
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
			} catch (IOException ioe) {
				ioe.printStackTrace();
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
	
	private static BRCCertifiedOrganisation getCertifiedOrganisationDetails(String id) throws Exception {
		URL address = new URL(detail_page + "?BrcSiteCode=" + id);
		Document doc = null;
		doc = getPage(address.toString());
		
		if (doc != null) {
			BRCCertifiedOrganisation co = new BRCCertifiedOrganisation();
			co.setBRCSiteCode(id);
			co.setCompanyName((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_SiteName")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_SiteName").text());
			co.setContact((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Contact")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Contact").text());
			co.setContactEMail((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Email")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Email").text());
			co.setContactFax((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Fax")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Fax").text());
			co.setContactPhone((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Telephone")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_con_Telephone").text());
			co.setCommercialContact((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_CommercialRepres")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_CommercialRepres").text());
			co.setCommercialContactEmail((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_CommercialRepresMail")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_CommercialRepresMail").text());
			co.setCommercialContactPhone((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_FacilityTelephone")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView2_ctl02_lb_FacilityTelephone").text());
			co.setAddress((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Address")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Address").text());
			co.setCity((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_City")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_City").text());
			co.setPostCode((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_ZipCode")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_ZipCode").text());
			co.setRegionState((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_RegionState")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_RegionState").text());
			co.setCountry((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Country")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Country").text());
			co.setLatitude((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_GPS")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_GPS").text());
			co.setLongitude((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_GPS")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_GPS").text());
			co.setPhone((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Telephone")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Telephone").text());
			co.setFax((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Fax")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Fax").text());
			co.setEmail((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Email")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_Email").text());
			co.setWebsite((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_hl_WebSite")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_hl_WebSite").text());
			co.setStandard((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Standard")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Standard").text());
			co.setCodes((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_gv_Extensions")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_gv_Extensions").text());
			co.setCertificationBody((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_CertificationBody")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_CertificationBody").text());
			co.setGrade((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Grade")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Grade").text());
			co.setScope((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Scope")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Scope").text());
			co.setExclusion((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Exclusions")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_Exclusions").text());
			co.setIssueDate((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_IssueDate")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_IssueDate").text());
			co.setExpiryDate((doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_ExpiryDate")==null)?null:doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_GridView1_ctl02_lb_ExpiryDate").text());
			if(doc.getElementById("ctl00_ContentPlaceHolder1_FormView1_lb_SiteName")==null)
				co.setDeleted(true);
			else
				co.setDeleted(false);
			return co;
		}
		return null;
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