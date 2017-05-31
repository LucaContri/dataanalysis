package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

public enum CompassSchedulingOwnership {
	AmericasRegionalDesk("AMERICAS-Regional Desk"),
	AsiaChina("ASIA-China"),
	AsiaIndia("ASIA-India"),
	AsiaIndonesia("ASIA-Indonesia"),
	AsiaJapan("ASIA-Japan"),
	AsiaKorea("ASIA-Korea"),
	AsiaRegionalDesk("ASIA-Regional Desk"),
	AsiaThailand("ASIA-Thailand"),
	AusFood("AUS-Food"),
	AusManagementSystems("AUS-Management Systems"),
	AusProductServices("AUS-Product Services"),
	AusRegionalDesk("AUS-Regional Desk"),
	EmeaCzechRepublic("EMEA-Czech Republic"),
	EmeaEgypt("EMEA-Egypt"),
	EmeaFrance("EMEA-France"),
	EmeaGermany("EMEA-Germany"),
	EmeaIreland("EMEA-Ireland"),
	EmeaItaly("EMEA-Italy"),
	EmeaPoland("EMEA-Poland"),
	EmeaRegionalDesk("EMEA-Regional Desk"),
	EmeaRussia("EMEA-Russia"),
	EmeaSouthAfrica("EMEA-South Africa"),
	EmeaSpain("EMEA-Spain"),
	EmeaSweden("EMEA-Sweden"),
	EmeaTurkey("EMEA-Turkey"),
	EmeaUk("EMEA-UK"),
	Unknown("UNKNOWN");

	String name; 
	CompassSchedulingOwnership(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static CompassSchedulingOwnership getValueForName( String typeString) {
		try {
			return valueOf(typeString.replace(" ", "").replace("-", "").replace("/", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfBusiness.getValueForName(" + typeString + ")", e);
		}
		return CompassSchedulingOwnership.Unknown;
	}
	@Override
	public String toString() {
		return getName();
	}
	
	public static List<CompassSchedulingOwnership> getBusinessForRegion(String region, String exclude) {
		List<CompassSchedulingOwnership> result = new ArrayList<CompassSchedulingOwnership>();
		for (CompassSchedulingOwnership business : CompassSchedulingOwnership.values()) {
			if (business.getName().contains(region) && !business.getName().contains(exclude))
				result.add(business);
		}
		return result;
	}
}
