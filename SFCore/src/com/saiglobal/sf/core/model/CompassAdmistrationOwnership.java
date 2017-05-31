package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

public enum CompassAdmistrationOwnership {
	AsiaChina("ASIA-China"),
	AsiaThailand("ASIA-Thailand"),
	AsiaJapan("ASIA-Japan"),
	AsiaIndonesia("ASIA-Indonesia"),
	AsiaIndia("ASIA-India"),
	AsiaKorea("ASIA-Korea"),
	EmeaPoland("EMEA-Poland"),
	EmeaCzechRepublic("EMEA-Czech Republic"),
	EmeaIreland("EMEA-Ireland"),
	EmeaEgypt("EMEA-Egypt"),
	EmeaFrance("EMEA-France"),
	EmeaSouthAfrica("EMEA-South Africa"),
	EmeaGermany("EMEA-Germany"),
	EmeaSpain("EMEA-Spain"),
	EmeaUk("EMEA-UK"),
	EmeaRussia("EMEA-Russia"),
	EmeaTurkey("EMEA-Turkey"),
	AusFood("AUS-Food"),
	AmericasRegionalDesk("AMERICAS-Regional Desk"),
	AusManagementSystems("AUS-Management Systems"),
	AsiaRegionalDesk("ASIA-Regional Desk"),
	EmeaRegionalDesk("EMEA-Regional Desk"),
	AusRegionalDesk("AUS-Regional Desk"),
	AusProductServices("AUS-Product Services"),
	EmeaItaly("EMEA-Italy"),
	EmeaSweden("EMEA-Sweden"),
	Unknown("UNKNOWN");

	String name; 
	CompassAdmistrationOwnership(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static CompassAdmistrationOwnership getValueForName( String typeString) {
		try {
			return valueOf(typeString.replace(" ", "").replace("-", "").replace("/", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in CompassAdmistrationOwnership.getValueForName(" + typeString + ")", e);
		}
		return CompassAdmistrationOwnership.Unknown;
	}
	@Override
	public String toString() {
		return getName();
	}
	
	public static List<CompassAdmistrationOwnership> getBusinessForRegion(String region, String exclude) {
		List<CompassAdmistrationOwnership> result = new ArrayList<CompassAdmistrationOwnership>();
		for (CompassAdmistrationOwnership business : CompassAdmistrationOwnership.values()) {
			if (business.getName().contains(region) && !business.getName().contains(exclude))
				result.add(business);
		}
		return result;
	}
}
