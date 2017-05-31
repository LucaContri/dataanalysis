package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

public enum CompassRevenueOwnership {
	AUSDirect("AUS-Direct"),
	AUSFood("AUS-Food"),	
	AUSGlobal("AUS-Global"),
	AUSManaged("AUS-Managed"),
	AUSGlobalNSWACT("AUS-Global-NSW/ACT"),
	AUSGlobalVICTAS("AUS-Global-VIC/TAS"),
	AUSGlobalQLD("AUS-Global-QLD"),
	AUSGlobalSANT("AUS-Global-SA/NT"),
	AUSGlobalWA("AUS-Global-WA"),
	AUSGlobalROW("AUS-Global-ROW"),
	AUSManagedPlusNSWACT("AUS-Managed Plus-NSW/ACT"),
	AUSManagedPlusVICTAS("AUS-Managed Plus-VIC/TAS"),
	AUSManagedPlusQLD("AUS-Managed Plus-QLD"),
	AUSManagedPlusSANT("AUS-Managed Plus-SA/NT"),
	AUSManagedPlusWA("AUS-Managed Plus-WA"),
	AUSManagedPlusROW("AUS-Managed Plus-ROW"),
	AUSManagedNSWACT("AUS-Managed-NSW/ACT"),
	AUSManagedVICTAS("AUS-Managed-VIC/TAS"),
	AUSManagedQLD("AUS-Managed-QLD"),
	AUSManagedSANT("AUS-Managed-SA/NT"),
	AUSManagedWA("AUS-Managed-WA"),
	AUSManagedROW("AUS-Managed-ROW"),
	AUSDirectNSWACT("AUS-Direct-NSW/ACT"),
	AUSDirectVICTAS("AUS-Direct-VIC/TAS"),
	AUSDirectQLD("AUS-Direct-QLD"),
	AUSDirectSANT("AUS-Direct-SA/NT"),
	AUSDirectWA("AUS-Direct-WA"),
	AUSDirectROW("AUS-Direct-ROW"),
	AUSFoodNSWACT("AUS-Food-NSW/ACT"),
	AUSFoodVICTAS("AUS-Food-VIC/TAS"),
	AUSFoodQLD("AUS-Food-QLD"),
	AUSFoodSANT("AUS-Food-SA/NT"),
	AUSFoodWA("AUS-Food-WA"),
	AUSFoodROW("AUS-Food-ROW"),
	AUSProductServicesNSWACT("AUS-Product Services-NSW/ACT"),
	AUSProductServicesVICTAS("AUS-Product Services-VIC/TAS"),
	AUSProductServicesQLD("AUS-Product Services-QLD"),
	AUSProductServicesSANT("AUS-Product Services-SA/NT"),
	AUSProductServicesWA("AUS-Product Services-WA"),
	AUSProductServicesROW("AUS-Product Services-ROW"),
	AUSProductServices("AUS-Product Services"),
	ASSCORP("ASS-CORP"),
	AUSCSCNot("AUS-CSCNot"),
	AUSMGTNot("AUS-MGTNot"),
	AUSOPS("AUS-OPS"),
	Unknown("Unknown"),
	EMEAUK("EMEA-UK"),
	EMEAIreland("EMEA-Ireland"),
	EMEAItaly("EMEA-Italy"),
	EMEACzechRepublic("EMEA-Czech Republic"),
	EMEAFrance("EMEA-France"),
	EMEAGermany("EMEA-Germany"),
	EMEAPoland("EMEA-Poland"),
	EMEARussia("EMEA-Russia"),
	EMEASouthAfrica("EMEA-South Africa"),
	EMEASpain("EMEA-Spain"),
	EMEATurkey("EMEA-Turkey"),
	EMEASweden("EMEA-Sweden"),
	EMEAEgypt("EMEA-Egypt"),
	// Reporting Business Units for EMEA.  They have different names than Revenue Ownerships???
	RBUEMEAMS("EMEA-MS"),
	RBUMSEMEA("MS-EMEA"),
	RBUMSTURKEY("MS-TURKEY"),
	RBUTURKEYMS("TURKEY-MS"),
	RBUMSRUSSIA("MS-RUSSIA"),
	RBURUSSIAMS("RUSSIA-MS"),
	RBUMSSOUTHAFRICA("MS-SOUTH AFRICA"),
	AsiaChinaFood("Asia-China-Food"),	
	AsiaChinaMS("Asia-China-MS"),	
	AsiaIndiaFood("Asia-India-Food"),	
	AsiaIndiaMS("Asia-India-MS"),	
	AsiaIndonesiaFood("Asia-Indonesia-Food"),
	AsiaIndonesiaMS("Asia-Indonesia-MS"),	
	AsiaJapanFood("Asia-Japan-Food"),
	AsiaJapanMS("Asia-Japan-MS"),
	AsiaKoreaFood("Asia-Korea-Food"),	
	AsiaKoreaMS("Asia-Korea-MS"),
	AsiaThailandFood("Asia-Thailand-Food"),
	AsiaThailandMS("Asia-Thailand-MS"),
	AsiaRegionalDesk("Asia-Regional Desk");

	String name; 
	CompassRevenueOwnership(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public static CompassRevenueOwnership getValueForName( String typeString) {
		try {
			return valueOf(typeString.replace(" ", "").replace("-", "").replace("/", ""));
		} catch (Exception e) {
			Logger.getLogger(SfSaigOffice.class).error("Error in SfBusinessUnit.getValueForName(" + typeString + ")", e);
		}
		return CompassRevenueOwnership.Unknown;
	}
	@Override
	public String toString() {
		return getName();
	}
	
	public static List<CompassRevenueOwnership> getBusinessUnitsForRegion(String region, String exclude) {
		List<CompassRevenueOwnership> result = new ArrayList<CompassRevenueOwnership>();
		for (CompassRevenueOwnership businessUnit : CompassRevenueOwnership.values()) {
			if (businessUnit.getName().contains(region) && !businessUnit.getName().contains(exclude))
				result.add(businessUnit);
		}
		return result;
	}
}
