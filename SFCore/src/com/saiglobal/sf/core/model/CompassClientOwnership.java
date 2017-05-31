package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

public enum CompassClientOwnership {
	Americas("Americas"),
	AsiaChina("Asia - China"),
	AsiaIndia("Asia - India"),
	AsiaIndonesia("Asia - Indonesia"),
	AsiaJapan("Asia - Japan"),
	AsiaKorea("Asia - Korea"),
	AsiaRegionalDesk("Asia - Regional Desk"),
	AsiaThailand("Asia - Thailand"),
	Corporate("Corporate"),
	ITSupport("IT Support"),
	TestingServices("Testing Services"),
	Australia("Australia"),
	ProductServices("Product Services"),
	Unknown("Unknown"),
	EMEAUK("EMEA - UK"),
	EMEAIreland("EMEA - Ireland"),
	EMEAItaly("EMEA - Italy"),
	EMEACzechRepublic("EMEA - Czech Republic"),
	EMEAFrance("EMEA - France"),
	EMEAGermany("EMEA - Germany"),
	EMEAPoland("EMEA - Poland"),
	EMEARussia("EMEA - Russia"),
	EMEASouthAfrica("EMEA - South Africa"),
	EMEASpain("EMEA - Spain"),
	EMEATurkey("EMEA - Turkey"),
	EMEAEgypt("EMEA - Egypt"),
	EMEASweden("EMEA - Sweden");

	String name; 
	CompassClientOwnership(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static CompassClientOwnership getValueForName( String typeString) {
		try {
			return valueOf(typeString.replace(" ", "").replace("-", "").replace("/", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfBusiness.getValueForName(" + typeString + ")", e);
		}
		return CompassClientOwnership.Unknown;
	}
	@Override
	public String toString() {
		return getName();
	}
	
	public static List<CompassClientOwnership> getBusinessForRegion(String region, String exclude) {
		List<CompassClientOwnership> result = new ArrayList<CompassClientOwnership>();
		for (CompassClientOwnership business : CompassClientOwnership.values()) {
			if (business.getName().contains(region) && !business.getName().contains(exclude))
				result.add(business);
		}
		return result;
	}
}
