package com.saiglobal.sf.core.model;

import org.apache.log4j.Logger;

public enum SfSaigOffice {
	Australia_Adelaide("Australia | Adelaide - Pirie St"),
	Australia_Brisbane("Australia | Brisbane - Little Edward St"),
	Australia_Melbourne("Australia | Melbourne - Wadhurst Dr"),
	Australia_Port_Melbourne("Australia | Port Melbourne - Lorimer St"),
	Australia_Perth("Australia | Perth - Adelaide Terrace"),
	Australia_Sydney("Australia | Sydney - Sussex St"),
	Australia_WestMelbourne("Australia | West Melbourne – Spencer St"),
	Bangladesh_Dhaka("Bangladesh | Dhaka"),
	Canada_Montreal("Canada | Montreal"),
	Canada_Toronto("Canada | Toronto"),
	China_Beijing("China | Beijing"),
	China_Guangzhou("China | Guangzhou"),
	China_Shanghai("China | Shanghai"),
	CzechRepublic_Prague("Czech Republic | Prague"),
	France_Vannes("France | Vannes"),
	Germany_Munich("Germany | Munchen"),
	India_Delhi("India | Delhi"),
	India_Mumbai("India | Mumbai"),
	India_Nasik("India | Nasik"),
	Indonesia_Jakarta("Indonesia | Jakarta"),
	Italy_Torino("Italy | Torino"),
	Italy_Turin("Italy | Turin"),
	Japan_Fukuoka("Japan | Fukuoka"),
	Japan_Tokyo("Japan | Tokyo"),
	Korea_Seoul("Korea | Seoul"),
	Lebanon_Beirut("Lebanon | Beirut"),
	NewZealand_Auckland("New Zealand | Auckland"),
	Poland_Gyndia("Poland | Gyndia"),
	Remote("Remote"),
	Russia_StPetersburg("Russia | St. Petersburg"),
	Spain_Madrid("Spain | Madrid"),
	Sweden_Stockholm("Sweden | Stockholm"),
	Thailand_Bangkok("Thailand | Bangkok"),
	UnitedKingdom_MiltonKeynes("United Kingdom | Milton Keynes"),
	UnitedStates_Cleveland("United States | Cleveland"),
	Turkey_Istanbul("Turkey | Istanbul"),
	Ireland_Dundalk("Ireland | Dundalk"),
	SouthAfrica_Johannessburg("South Africa | Johannessburg"),
	NewZealand_Christchurch("New Zealand | Christchurch"),
	Unknown("Unknown");
	
	private String name;
	
	SfSaigOffice(String aName) {
		name = aName;
	}
	
	public String getName() {
		return name;
	}
	
	public Location getLocation() {
		switch (this) {
		case Australia_Adelaide:
			Location adelaideOffice = new Location(this.toString(), "50 Pirie St", null, null, "Adelaide", "Australia", "SA", "5000", -34.9256609, 138.6017570);
			adelaideOffice.setMetropolitanRadius(40);
			return adelaideOffice;
		case Australia_Brisbane:
			Location brisbaneOffice = new Location(this.toString(), "55 Little Edward St", null, null, "Spring Hill", "Australia", "QLD", "4000", -27.4615678, 153.0243378);
			brisbaneOffice.setMetropolitanRadius(40);
			return brisbaneOffice;
		case Australia_Sydney:  
			Location sydneyOffice = new Location(this.toString(), "286 Sussex St", null, null, "Sydeny", "Australia", "NSW", "2000", -33.8738754, 151.2042149);
			sydneyOffice.setMetropolitanRadius(60);
			return sydneyOffice;
		case Australia_Perth:
			Location perthOffice = new Location(this.toString(), "165 Adelaide Tce", null, null, "East Perth", "Australia", "WA", "6892", -31.9596062, 115.8709830);
			perthOffice.setMetropolitanRadius(60);
			return perthOffice;
		case Australia_WestMelbourne:
			Location melbourneOffice1 = new Location(this.toString(), "355 Spencer St", null, null, "West Melbourne", "Australia", "VIC", "3000", -37.8165136, 144.9530850);
			melbourneOffice1.setMetropolitanRadius(60);
			return melbourneOffice1;
		case Australia_Melbourne:  
			Location melbourneOffice2 = new Location(this.toString(), "13-15 Wadhurst Dr", null, null, "Boronia", "Australia", "VIC", "3155", -37.8662596, 145.2545567);
			melbourneOffice2.setMetropolitanRadius(60);
			return melbourneOffice2;
		case Indonesia_Jakarta:  
			return new Location(this.toString(), null, null, null, "Jakarta", "Indonesia", "", "", 0, 0);
		case NewZealand_Christchurch:  
			return new Location(this.toString(), null, null, null, "Christchurch", "New Zealand", "", "", 0, 0);
		case Russia_StPetersburg:  
			return new Location(this.toString(), null, null, null, "St.Petersburg", "Russia", "", "", 0, 0);
		case Italy_Turin:  
			return new Location(this.toString(), null, null, null, "Turin", "Italy", "", "", 0, 0);
		case Korea_Seoul:  
			return new Location(this.toString(), null, null, null, "Seoul", "Korea", "", "", 0, 0);
		case Spain_Madrid:  
			return new Location(this.toString(), null, null, null, "Madrid", "Spain", "", "", 0, 0);
		case UnitedKingdom_MiltonKeynes:  
			return new Location(this.toString(), null, null, null, "MiltonKeynes", "UnitedKingdom", "", "", 0, 0);
		case Thailand_Bangkok:  
			return new Location(this.toString(), null, null, null, "Bangkok", "Thailand", "", "", 0, 0);
		case India_Mumbai:  
			return new Location(this.toString(), null, null, null, "Mumbai", "India", "", "", 0, 0);
		case Canada_Toronto:  
			return new Location(this.toString(), null, null, null, "Toronto", "Canada", "", "", 0, 0);
		case Bangladesh_Dhaka:  
			return new Location(this.toString(), null, null, null, "Dhaka", "Bangladesh", "", "", 0, 0);
		case China_Beijing:  
			return new Location(this.toString(), null, null, null, "Beijing", "China", "", "", 0, 0);
		case China_Shanghai:  
			return new Location(this.toString(), null, null, null, "Shanghai", "China", "", "", 0, 0);
		case Poland_Gyndia:  
			return new Location(this.toString(), null, null, null, "Gyndia", "Poland", "", "", 0, 0);
		case Lebanon_Beirut:  
			return new Location(this.toString(), null, null, null, "Beirut", "Lebanon", "", "", 0, 0);
		case China_Guangzhou:  
			return new Location(this.toString(), null, null, null, "Guangzhou", "China", "", "", 0, 0);
		case UnitedStates_Cleveland:  
			return new Location(this.toString(), null, null, null, "Cleveland", "UnitedStates", "", "", 0, 0);
		case Japan_Tokyo:  
			return new Location(this.toString(), null, null, null, "Tokyo", "Japan", "", "", 0, 0);
		case NewZealand_Auckland:  
			return new Location(this.toString(), null, null, null, "Auckland", "NewZealand", "", "", 0, 0);
		case CzechRepublic_Prague:  
			return new Location(this.toString(), null, null, null, "Prague", "CzechRepublic", "", "", 0, 0);
		case Germany_Munich:  
			return new Location(this.toString(), null, null, null, "Munich", "Germany", "", "", 0, 0);
		case Japan_Fukuoka:  
			return new Location(this.toString(), null, null, null, "Fukuoka", "Japan", "", "", 0, 0);
		case Italy_Torino:  
			return new Location(this.toString(), null, null, null, "Torino", "Italy", "", "", 0, 0);
		case India_Delhi:  
			return new Location(this.toString(), null, null, null, "Delhi", "India", "", "", 0, 0);
		case India_Nasik:  
			return new Location(this.toString(), null, null, null, "Nasik", "India", "", "", 0, 0);
		case Canada_Montreal:  
			return new Location(this.toString(), null, null, null, "Montreal", "Canada", "", "", 0, 0);

		default:
			return null;
		}
	}
	
	public static SfSaigOffice getValueForName(String typeString) {
		if ((typeString != null) && !typeString.equals("")) {
			String typeString2 = "";
			try {
				String[] typearray = typeString.split("-|–");
				typeString2 = typearray[0].replace(" | ", "_").replaceAll(" ", "").replaceAll("\\.", "").replaceAll("Munchen", "Munich").trim();
				if (typeString2.startsWith("Australia_WestMelbourne"))
					typeString2 = "Australia_WestMelbourne";
				return valueOf(typeString2);
			} catch (Exception e) {
				Logger.getLogger(SfSaigOffice.class).error("Error in getValueForName(" + typeString2 + ") Original String:" + typeString, e);
			}
		}
		return SfSaigOffice.Unknown;
	}
}
