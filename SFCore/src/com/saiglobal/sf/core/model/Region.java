package com.saiglobal.sf.core.model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public enum Region {
	AUSTRALIA_MANAGED_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedNSWACT}, new String[] {"AUS-MANAGED-NSWACT"}, "Australia - Managed - NSW ACT"),
	AUSTRALIA_MANAGED_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedVICTAS}, new String[] {"AUS-MANAGED-VICTAS"}, "Australia - Managed - VIC TAS"),
	AUSTRALIA_MANAGED_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedQLD}, new String[] {"AUS-MANAGED-QLD"}, "Australia - Managed - QLD"),
	AUSTRALIA_MANAGED_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedSANT}, new String[] {"AUS-MANAGED-SANT"}, "Australia - Managed - SA NT"),
	AUSTRALIA_MANAGED_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedWA}, new String[] {"AUS-MANAGED-WA"}, "Australia - Managed - WA"),
	AUSTRALIA_MANAGED_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedROW}, new String[] {"AUS-MANAGED-ROW"}, "Australia - Managed - ROW"),
	
	AUSTRALIA_MANAGED_PLUS_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusNSWACT}, new String[] {"AUS-MANAGED-PLUS-NSWACT"}, "Australia - Managed Plus - NSW ACT"),
	AUSTRALIA_MANAGED_PLUS_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusVICTAS}, new String[] {"AUS-MANAGED-PLUS-VICTAS"}, "Australia - Managed Plus - VIC TAS"),
	AUSTRALIA_MANAGED_PLUS_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusQLD}, new String[] {"AUS-MANAGED-PLUS-QLD"}, "Australia - Managed Plus - QLD"),
	AUSTRALIA_MANAGED_PLUS_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusSANT}, new String[] {"AUS-MANAGED-PLUS-SANT"}, "Australia - Managed Plus - SA NT"),
	AUSTRALIA_MANAGED_PLUS_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusWA}, new String[] {"AUS-MANAGED-PLUS-WA"}, "Australia - Managed Plus - WA"),
	AUSTRALIA_MANAGED_PLUS_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSManagedPlusROW}, new String[] {"AUS-MANAGED-PLUS-ROW"}, "Australia - Managed Plus - ROW"),
	
	AUSTRALIA_DIRECT_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectNSWACT}, new String[] {"AUS-DIRECT-NSWACT"}, "Australia - Direct - NSW ACT"),
	AUSTRALIA_DIRECT_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectVICTAS}, new String[] {"AUS-DIRECT-VICTAS"}, "Australia - Direct - VIC TAS"),
	AUSTRALIA_DIRECT_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectQLD}, new String[] {"AUS-DIRECT-QLD"}, "Australia - Direct - QLD"),
	AUSTRALIA_DIRECT_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectSANT}, new String[] {"AUS-DIRECT-SANT"}, "Australia - Direct - SA NT"),
	AUSTRALIA_DIRECT_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectWA}, new String[] {"AUS-DIRECT-WA"}, "Australia - Direct - WA"),
	AUSTRALIA_DIRECT_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSDirectROW}, new String[] {"AUS-DIRECT-ROW"}, "Australia - Direct - ROW"),

	AUSTRALIA_GLOBAL_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalNSWACT}, new String[] {"AUS-GLOBAL-NSWACT"}, "Australia - Global - NSW ACT"),
	AUSTRALIA_GLOBAL_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalVICTAS}, new String[] {"AUS-GLOBAL-VICTAS"}, "Australia - Global - VIC TAS"),
	AUSTRALIA_GLOBAL_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalQLD}, new String[] {"AUS-GLOBAL-QLD"}, "Australia - Global - QLD"),
	AUSTRALIA_GLOBAL_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalSANT}, new String[] {"AUS-GLOBAL-SANT"}, "Australia - Global - SA NT"),
	AUSTRALIA_GLOBAL_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalWA}, new String[] {"AUS-GLOBAL-WA"}, "Australia - Global - WA"),
	AUSTRALIA_GLOBAL_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSGlobalROW}, new String[] {"AUS-GLOBAL-ROW"}, "Australia - Global - ROW"),
	
	AUSTRALIA_FOOD_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodNSWACT}, new String[] {"AUS-FOOD-NSWACT"}, "Australia - Food - NSW ACT"),
	AUSTRALIA_FOOD_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodVICTAS}, new String[] {"AUS-FOOD-VICTAS"}, "Australia - Food - VIC TAS"),
	AUSTRALIA_FOOD_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodQLD}, new String[] {"AUS-FOOD-QLD"}, "Australia - Food - QLD"),
	AUSTRALIA_FOOD_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodSANT}, new String[] {"AUS-FOOD-SANT"}, "Australia - Food - SA NT"),
	AUSTRALIA_FOOD_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodWA}, new String[] {"AUS-FOOD-WA"}, "Australia - Food - WA"),
	AUSTRALIA_FOOD_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[]{CompassClientOwnership.Australia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSFoodROW}, new String[] {"AUS-FOOD-ROW"}, "Australia - Food - ROW"),

	AUSTRALIA_PRODUCT_SERVICES_NSWACT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesNSWACT}, new String[] {"AUS-PRODUCTS-SERVICES-NSWACT"}, "Australia - Products Services - NSW ACT"),
	AUSTRALIA_PRODUCT_SERVICES_VICTAS(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesVICTAS}, new String[] {"AUS-PRODUCTS-SERVICES-VICTAS"}, "Australia - Products Services - VIC TAS"),
	AUSTRALIA_PRODUCT_SERVICES_QLD(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesQLD}, new String[] {"AUS-PRODUCTS-SERVICES-QLD"}, "Australia - Products Services - QLD"),
	AUSTRALIA_PRODUCT_SERVICES_SANT(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesSANT}, new String[] {"AUS-PRODUCTS-SERVICES-SANT"}, "Australia - Products Services - SA NT"),
	AUSTRALIA_PRODUCT_SERVICES_WA(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesWA}, new String[] {"AUS-PRODUCTS-SERVICES-WA"}, "Australia - Products Services - WA"),
	AUSTRALIA_PRODUCT_SERVICES_ROW(true, false, true, true, new String[] {"AUD"}, new CompassClientOwnership[] {CompassClientOwnership.ProductServices}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AUSProductServicesROW}, new String[] {"AUS-PRODUCTS-SERVICES-ROW"}, "Australia - Products Services - ROW"),
	
	AUSTRALIA_NSWACT(false, true, "New South Wales & ACT", new Region[] {AUSTRALIA_DIRECT_NSWACT, AUSTRALIA_FOOD_NSWACT, AUSTRALIA_GLOBAL_NSWACT, AUSTRALIA_MANAGED_NSWACT, AUSTRALIA_MANAGED_PLUS_NSWACT}),
	AUSTRALIA_VICTAS(false, true, "Victoria & Tasmania", new Region[] {AUSTRALIA_DIRECT_VICTAS, AUSTRALIA_FOOD_VICTAS, AUSTRALIA_GLOBAL_VICTAS, AUSTRALIA_MANAGED_VICTAS, AUSTRALIA_MANAGED_PLUS_VICTAS}),
	AUSTRALIA_QLD(false, true, "Queensland", new Region[] {AUSTRALIA_DIRECT_QLD, AUSTRALIA_FOOD_QLD, AUSTRALIA_GLOBAL_QLD, AUSTRALIA_MANAGED_QLD, AUSTRALIA_MANAGED_PLUS_QLD}),
	AUSTRALIA_ROW(false, true, "ROW", new Region[] {AUSTRALIA_DIRECT_ROW, AUSTRALIA_FOOD_ROW, AUSTRALIA_GLOBAL_ROW, AUSTRALIA_MANAGED_ROW, AUSTRALIA_MANAGED_PLUS_ROW}),
	AUSTRALIA_SANT(false, true, "South Australia & Northern Territory", new Region[] {AUSTRALIA_DIRECT_SANT, AUSTRALIA_FOOD_SANT, AUSTRALIA_GLOBAL_SANT, AUSTRALIA_MANAGED_SANT, AUSTRALIA_MANAGED_PLUS_SANT}),
	AUSTRALIA_WA(false, true, "Western Australia", new Region[] {AUSTRALIA_DIRECT_WA, AUSTRALIA_FOOD_WA, AUSTRALIA_GLOBAL_WA, AUSTRALIA_MANAGED_WA, AUSTRALIA_MANAGED_PLUS_WA}),
	
	AUSTRALIA_MANAGED(false, false, "Australia - Managed", new Region[] {AUSTRALIA_MANAGED_NSWACT, AUSTRALIA_MANAGED_QLD, AUSTRALIA_MANAGED_ROW, AUSTRALIA_MANAGED_SANT, AUSTRALIA_MANAGED_VICTAS,AUSTRALIA_MANAGED_WA}),
	AUSTRALIA_MANAGED_PLUS(false, false, "Australia - Managed Plus", new Region[] {AUSTRALIA_MANAGED_PLUS_NSWACT, AUSTRALIA_MANAGED_PLUS_QLD, AUSTRALIA_MANAGED_PLUS_ROW, AUSTRALIA_MANAGED_PLUS_SANT, AUSTRALIA_MANAGED_PLUS_VICTAS,AUSTRALIA_MANAGED_PLUS_WA}),
	AUSTRALIA_DIRECT(false, false, "Australia - Direct", new Region[] {AUSTRALIA_DIRECT_NSWACT, AUSTRALIA_DIRECT_QLD, AUSTRALIA_DIRECT_ROW, AUSTRALIA_DIRECT_SANT, AUSTRALIA_DIRECT_VICTAS,AUSTRALIA_DIRECT_WA}),
	AUSTRALIA_FOOD(false, false, "Australia - Food", new Region[] {AUSTRALIA_FOOD_NSWACT, AUSTRALIA_FOOD_QLD, AUSTRALIA_FOOD_ROW, AUSTRALIA_FOOD_SANT, AUSTRALIA_FOOD_VICTAS,AUSTRALIA_FOOD_WA}),
	AUSTRALIA_GLOBAL(false, false, "Australia - Global", new Region[] {AUSTRALIA_GLOBAL_NSWACT, AUSTRALIA_GLOBAL_QLD, AUSTRALIA_GLOBAL_ROW, AUSTRALIA_GLOBAL_SANT, AUSTRALIA_GLOBAL_VICTAS,AUSTRALIA_GLOBAL_WA}),
	AUSTRALIA_PRODUCT_SERVICE(false, true, "Australia - Product Services", new Region[] {AUSTRALIA_PRODUCT_SERVICES_NSWACT, AUSTRALIA_PRODUCT_SERVICES_QLD, AUSTRALIA_PRODUCT_SERVICES_ROW, AUSTRALIA_PRODUCT_SERVICES_SANT, AUSTRALIA_PRODUCT_SERVICES_VICTAS,AUSTRALIA_PRODUCT_SERVICES_WA}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusProductServices}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusProductServices}, false),
	
	AUSTRALIA_MS(false, false, "Australia - MS", new Region[] {AUSTRALIA_DIRECT, AUSTRALIA_GLOBAL, AUSTRALIA_MANAGED, AUSTRALIA_MANAGED_PLUS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusManagementSystems}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusManagementSystems}, false),
	AUSTRALIA_MS_AND_FOOD(false, false, "Australia - MS & Food", new Region[] {AUSTRALIA_MS, AUSTRALIA_FOOD}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusFood}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusFood}, false),
	AUSTRALIA(false, true, "Australia (inc PS)", new Region[] {AUSTRALIA_MS_AND_FOOD, AUSTRALIA_PRODUCT_SERVICE, AUSTRALIA_NSWACT, AUSTRALIA_QLD, AUSTRALIA_ROW, AUSTRALIA_VICTAS, AUSTRALIA_SANT, AUSTRALIA_WA}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusManagementSystems, CompassAdmistrationOwnership.AusFood}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusManagementSystems, CompassSchedulingOwnership.AusFood}, false),
	AUSTRALIA_2(false, true, "Australia (ex PS)", new Region[] {AUSTRALIA_NSWACT, AUSTRALIA_QLD, AUSTRALIA_ROW, AUSTRALIA_VICTAS, AUSTRALIA_SANT, AUSTRALIA_WA}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusManagementSystems, CompassAdmistrationOwnership.AusFood}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusManagementSystems, CompassSchedulingOwnership.AusFood}, true),
	AUSTRALIA_DAILY_STATS(false, true, "Australia (inc PS)", new Region[] {AUSTRALIA_MS_AND_FOOD, AUSTRALIA_NSWACT, AUSTRALIA_QLD, AUSTRALIA_ROW, AUSTRALIA_VICTAS, AUSTRALIA_SANT, AUSTRALIA_WA}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AusManagementSystems, CompassAdmistrationOwnership.AusFood}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AusManagementSystems, CompassSchedulingOwnership.AusFood}, false),
	
	
	CHINA(true, true, false, false, new String[] {"CNY"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaChina}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AsiaChinaFood, CompassRevenueOwnership.AsiaChinaMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaChina}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaChina}, new String[] {"China"}, "China", true),
	INDIA(true, true, false, false, new String[] {"INR"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaIndia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AsiaIndiaFood, CompassRevenueOwnership.AsiaIndiaMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaIndia}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaIndia}, new String[] {"India"}, "India", true),
	INDONESIA(true, true, false, false, new String[] {"IDR"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaIndonesia}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AsiaIndonesiaFood, CompassRevenueOwnership.AsiaIndonesiaMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaIndonesia}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaIndonesia}, new String[] {"Indonesia"}, "Indonesia", true),
	JAPAN(true, true, false, false, new String[] {"JPY"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaJapan}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AsiaJapanFood, CompassRevenueOwnership.AsiaJapanMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaJapan}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaJapan}, new String[] {"Japan"}, "Japan", true),
	KOREA(true, true, false, false, new String[] {"KRW"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaKorea}, new CompassRevenueOwnership[] {CompassRevenueOwnership.AsiaKoreaFood, CompassRevenueOwnership.AsiaKoreaMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaKorea}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaKorea}, new String[] {"Korea"}, "Korea", true),
	THAILAND(true, true, false, false, new String[] {"THB"}, new CompassClientOwnership[]{CompassClientOwnership.AsiaThailand}, new CompassRevenueOwnership[]{CompassRevenueOwnership.AsiaThailandFood, CompassRevenueOwnership.AsiaThailandMS}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaThailand}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaThailand}, new String[] {"Thailand"}, "Thailand", true),
	ASIA_REGIONAL_DESK(true, true, false, false, new String[] {"AUD"}, null, new CompassRevenueOwnership[] {CompassRevenueOwnership.AsiaRegionalDesk}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.AsiaRegionalDesk}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.AsiaRegionalDesk}, new String[] {"AsiaRegionalDesk"}, "Asia Regional Desk", false),
	
	CZECH_REPUBLIC(true, true, false, false, new String[] {"CZK"}, new CompassClientOwnership[]{CompassClientOwnership.EMEACzechRepublic}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEACzechRepublic}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaCzechRepublic}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaCzechRepublic}, new String[] {"CzechRepublic"}, "Czech Republic", true),
	FRANCE(true, true, false, false, new String[] {"EUR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAFrance}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAFrance}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaFrance}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaFrance}, new String[] {"France"}, "France", true),
	GERMANY(true, true, false, false, new String[] {"EUR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAGermany}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAGermany}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaGermany}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaGermany}, new String[] {"Germany"}, "Germany", true),
	IRELAND(true, true, false, false, new String[] {"EUR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAIreland}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAIreland}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaIreland}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaIreland}, new String[] {"Ireland"}, "Ireland", true),
	ITALY(true, true, false, false, new String[] {"EUR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAItaly}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAItaly}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaItaly}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaItaly}, new String[] {"Italy"}, "Italy", true),
	POLAND(true, true, false, false, new String[] {"PLN"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAPoland}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAPoland}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaPoland}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaPoland}, new String[] {"Poland"}, "Poland", true),
	RUSSIA(true, true, false, false, new String[] {"RUB"}, new CompassClientOwnership[]{CompassClientOwnership.EMEARussia}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEARussia}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaRussia}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaRussia}, new String[] {"Russia"}, "Russia", true),
	SOUTH_AFRICA(true, true, false, false, new String[] {"ZAR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEASouthAfrica}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEASouthAfrica}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaSouthAfrica}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaSouthAfrica}, new String[] {"SouthAfrica"}, "South Africa", true),
	SPAIN(true, true, false, false, new String[] {"EUR"}, new CompassClientOwnership[]{CompassClientOwnership.EMEASpain}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEASpain}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaSpain}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaSpain}, new String[] {"Spain"}, "Spain", true),
	TURKEY(true, true, false, false, new String[] {"TRY"}, new CompassClientOwnership[]{CompassClientOwnership.EMEATurkey}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEATurkey}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaTurkey}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaTurkey}, new String[] {"Turkey"}, "Turkey", true),
	UK(true, true, false, false, new String[] {"GBP"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAUK}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAUK}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaUk}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaUk}, new String[] {"UK"}, "United Kingdom", true),
	EGYPT(true, true, false, false, new String[] {"EGP"}, new CompassClientOwnership[]{CompassClientOwnership.EMEAEgypt}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEAEgypt}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaSweden}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaEgypt}, new String[] {"Egypt"}, "Egypt", true),
	SWEDEN(true, true, false, false, new String[] {"SEK"}, new CompassClientOwnership[]{CompassClientOwnership.EMEASweden}, new CompassRevenueOwnership[] {CompassRevenueOwnership.EMEASweden}, new CompassAdmistrationOwnership[] {CompassAdmistrationOwnership.EmeaSweden}, new CompassSchedulingOwnership[] {CompassSchedulingOwnership.EmeaSweden}, new String[] {"Sweden"}, "Sweden", true),
	
	EUROPE(false, false, "Europe", new Region[] {CZECH_REPUBLIC, FRANCE, GERMANY, IRELAND, ITALY, POLAND, SPAIN, TURKEY, UK, SWEDEN}),
	EMEA_UK(false, true, "Emea UK", new Region[] {IRELAND, UK}),
	EMEA_EUROPE(false, true, "Emea Europe", new Region[] {CZECH_REPUBLIC, FRANCE, GERMANY, ITALY, POLAND, SPAIN, TURKEY, RUSSIA, SOUTH_AFRICA, EGYPT, SWEDEN}),
	EMEA(false, true, "Emea", new Region[] {EMEA_UK, EMEA_EUROPE}),
	EMEA_ALL(false, true, "Emea", new Region[] {CZECH_REPUBLIC,FRANCE,GERMANY,IRELAND,ITALY,POLAND,RUSSIA,SOUTH_AFRICA,SPAIN,TURKEY,SWEDEN,TURKEY,UK, EGYPT}),
	APAC_ALL(false, true, "Apac", new Region[] {ASIA_REGIONAL_DESK, AUSTRALIA_2, CHINA, INDIA, INDONESIA, JAPAN, KOREA, THAILAND}),
	ASIA(false, true, "Asia", new Region[] {CHINA, INDIA, INDONESIA, JAPAN, KOREA, THAILAND, ASIA_REGIONAL_DESK}),
	
	AMERICAs(false, false, false, false, new String[] {"USD"}, new CompassClientOwnership[]{}, new CompassRevenueOwnership[]{}, new String[] {}, "Americas"),
	
	GLOBAL(false, true, "Global", new Region[] {APAC_ALL,EMEA_ALL});
	
	public static final String defaultCurrency = "AUD";
	public boolean enabled;
	public boolean reportOpportunities = true;
	public boolean reportTis = true;
	public boolean saveInHistory;
	public boolean isCountry = false;
	public CompassRevenueOwnership[] revenueOwnerships;
	public CompassClientOwnership[] clientOwnerships;
	public CompassAdmistrationOwnership[] administrationOwnerships;
	public CompassSchedulingOwnership[] schedulingOwnerships;
	public String[] identifiers;
	public String name;
	public String[] names;
	public String[] currencies;
	public List<Region> subRegions;

	Region(boolean saveInHistory, boolean enabled, boolean reportOpportunities, boolean reportTis, String[] currencies, CompassClientOwnership[] clientOwnerships, CompassRevenueOwnership[] revenueOwnerships, String[] identifiers, String name) {
		this.saveInHistory =saveInHistory;
		this.enabled = enabled;
		this.reportOpportunities = reportOpportunities;
		this.reportTis = reportTis;
		this.currencies = currencies;
		this.clientOwnerships = clientOwnerships;
		this.revenueOwnerships = revenueOwnerships;
		
		this.identifiers = identifiers;
		this.name = name;
		this.names = new String[] {this.name};
	}

	Region(boolean saveInHistory, boolean enabled, boolean reportOpportunities, boolean reportTis, String[] currencies, CompassClientOwnership[] clientOwnerships, CompassRevenueOwnership[] revenueOwnerships, CompassAdmistrationOwnership[] adminOwnerships, CompassSchedulingOwnership[] schedulingOwnerships, String[] identifiers, String name, boolean isCountry) {
		this(saveInHistory,enabled,reportOpportunities,reportTis,currencies,clientOwnerships,revenueOwnerships,identifiers, name);
		this.administrationOwnerships = adminOwnerships;
		this.schedulingOwnerships = schedulingOwnerships;
		this.isCountry = isCountry; 
	}
	
	Region(boolean saveInHistory, boolean enabled, String name, Region[] regions) {
		this.saveInHistory =saveInHistory;
		this.enabled = enabled;
		this.name = name;
		this.subRegions = Arrays.asList(regions);
		Set<CompassRevenueOwnership> revenueOwnershipSet = new HashSet<CompassRevenueOwnership>();
		Set<CompassClientOwnership> clientOwnershipSet = new HashSet<CompassClientOwnership>();
		Set<CompassAdmistrationOwnership> adminOwnershipSet = new HashSet<CompassAdmistrationOwnership>();
		Set<CompassSchedulingOwnership> schedulingOwnershipSet = new HashSet<CompassSchedulingOwnership>();
		
		Set<String> identifiersList = new HashSet<String>();
		Set<String> currenciesList = new HashSet<String>();
		Set<String> namesList = new HashSet<String>();
		namesList.add(this.name);
		for (Region region : regions) {
			if (region.revenueOwnerships != null)
				revenueOwnershipSet.addAll(Arrays.asList(region.revenueOwnerships));
			if (region.clientOwnerships != null)
				clientOwnershipSet.addAll(Arrays.asList(region.clientOwnerships));
			if (region.administrationOwnerships != null)
				adminOwnershipSet.addAll(Arrays.asList(region.administrationOwnerships));
			if (region.schedulingOwnerships != null)
				schedulingOwnershipSet.addAll(Arrays.asList(region.schedulingOwnerships));
			this.reportOpportunities &= region.reportOpportunities;
			this.reportTis &= region.reportTis;
			identifiersList.addAll(Arrays.asList(region.identifiers));
			currenciesList.addAll(Arrays.asList(region.currencies));
			namesList.addAll(Arrays.asList(region.names));
		}
		this.clientOwnerships = clientOwnershipSet.toArray(new CompassClientOwnership[clientOwnershipSet.size()]);
		this.revenueOwnerships = revenueOwnershipSet.toArray(new CompassRevenueOwnership[revenueOwnershipSet.size()]);
		this.administrationOwnerships = adminOwnershipSet.toArray(new CompassAdmistrationOwnership[adminOwnershipSet.size()]);
		this.schedulingOwnerships = schedulingOwnershipSet.toArray(new CompassSchedulingOwnership[schedulingOwnershipSet.size()]);
		
		this.identifiers = identifiersList.toArray(new String[identifiersList.size()]);
		this.currencies = currenciesList.toArray(new String[currenciesList.size()]);
		this.names = namesList.toArray(new String[namesList.size()]);
	}
	
	Region(boolean saveInHistory, boolean enabled, String name, Region[] regions, CompassAdmistrationOwnership[] adminOwnerships, CompassSchedulingOwnership[] schedulingOwnerships, boolean isCountry) {
		this(saveInHistory, enabled, name, regions);
		this.isCountry = isCountry;
		Set<CompassAdmistrationOwnership> adminOwnershipSet = new HashSet<CompassAdmistrationOwnership>();
		Set<CompassSchedulingOwnership> schedulingOwnershipSet = new HashSet<CompassSchedulingOwnership>();
		if(this.administrationOwnerships != null)
			adminOwnershipSet.addAll(Arrays.asList(this.administrationOwnerships));
		if(adminOwnerships != null)
			adminOwnershipSet.addAll(Arrays.asList(adminOwnerships));
		if(this.schedulingOwnerships != null)
			schedulingOwnershipSet.addAll(Arrays.asList(this.schedulingOwnerships));
		if(schedulingOwnerships != null)
			schedulingOwnershipSet.addAll(Arrays.asList(schedulingOwnerships));
		this.administrationOwnerships = adminOwnershipSet.toArray(new CompassAdmistrationOwnership[adminOwnershipSet.size()]);
		this.schedulingOwnerships = schedulingOwnershipSet.toArray(new CompassSchedulingOwnership[schedulingOwnershipSet.size()]);
	}
	
	/*
	Region(boolean saveInHistory, boolean enabled, SfBusiness[] businesses, String name, Region[] regions, String pricebook) {
		this.saveInHistory =saveInHistory;
		this.enabled = enabled;
		this.name = name;
		this.subRegions = Arrays.asList(regions);
		Set<SfBusinessUnit> businessUnitsList = new HashSet<SfBusinessUnit>();
		Set<String> identifiersList = new HashSet<String>();
		Set<String> currenciesList = new HashSet<String>();
		Set<String> namesList = new HashSet<String>();
		namesList.add(this.name);
		for (Region region : regions) {
			businessUnitsList.addAll(Arrays.asList(region.businessUnits));
			identifiersList.addAll(Arrays.asList(region.identifiers));
			currenciesList.addAll(Arrays.asList(region.currencies));
			namesList.addAll(Arrays.asList(region.names));
		}
		this.businesses = businesses;
		this.businessUnits = businessUnitsList.toArray(new SfBusinessUnit[businessUnitsList.size()]);
		this.identifiers = identifiersList.toArray(new String[identifiersList.size()]);
		this.currencies = currenciesList.toArray(new String[currenciesList.size()]);
		this.names = namesList.toArray(new String[namesList.size()]);
	}
	*/
	public CompassClientOwnership[] getClientOwnerships() {
		return clientOwnerships;
	}
	
	public CompassRevenueOwnership[] getRevenueOwnerships() {
		return revenueOwnerships;
	}
	
	public String[] getIdentifiers() {
		return identifiers;
	}

	public String getName() {
		return name;
	}
	
	public void setName(String name) {
		this.name= name;
	}
	
	public String[] getNames() {
		return names;
	}
	
	public boolean isBaseRegion() {
		return identifiers.length==1;
	}
	
	public String getIdentifier() {
		return identifiers[0];
	}
	
	public boolean isEnabled() {
		return enabled;
	}
	
	public boolean reportAuditDays() {
		return (enabled && (revenueOwnerships != null) && (revenueOwnerships.length>0) );
	}
	
	public boolean reportOpportunities() {
		return (enabled && (clientOwnerships != null) && (clientOwnerships.length>0) && this.reportOpportunities);
	}
	
	public boolean reportTraining() {
		// TODO: Implement this once you know how to distinguish TIS records by region (RecordType???)
		return ((this.name.equals(Region.AUSTRALIA.name) || this.name.equals(Region.AUSTRALIA_2.name) || this.name.equals(Region.AUSTRALIA_DAILY_STATS.name)) && this.reportTis);
	}
	
	public boolean isMultiCurrency() {
		return (this.currencies != null) && (this.currencies.length>1);
	}
	
	public static Region[] saveInHistoryValues() {
		List<Region> regionsToSaveInHistory = new ArrayList<Region>();
		for (Region region : Region.values()) {
			if (region.saveInHistory)
				regionsToSaveInHistory.add(region);
		}
		return regionsToSaveInHistory.toArray(new Region[regionsToSaveInHistory.size()]);
	}
	
	public static List<Region> getRegionsTree() {
		List<Region> topRegions = new ArrayList<Region>();
		List<Region> subRegions = new ArrayList<Region>();
		for (Region region : Region.values()) {
			if (region.subRegions!=null) { 
				subRegions.addAll(region.subRegions);
			}
		}
		for (Region region : Region.values()) {
			if ((region.enabled) && (!subRegions.contains(region))) { 
				topRegions.add(region);
			}
		}
		
		return topRegions;
	}
	
	public static List<Region> getCountryRegions(Region region) {
		List<Region> countryRegions = new ArrayList<Region>();
		if (region.isCountry)
			countryRegions.add(region);
		if ((region.subRegions != null) && (region.subRegions.size()>0)) {
			for (Region subRegion : region.subRegions) {
				countryRegions.addAll(getCountryRegions(subRegion));
			}
		}
		return countryRegions;
	}
	
	public static List<Region> getCountryRegions() {
		List<Region> countryRegions = new ArrayList<Region>();
		for (Region region : Region.values()) {
			if (region.isCountry) { 
				countryRegions.add(region);
			}
		}
		return countryRegions;
	}
	
	public String getCurrency() {
		if (this.isMultiCurrency() || currencies == null || currencies.length==0) 
			return null;
		return currencies[0];
	}

	public CompassAdmistrationOwnership[] getAdministrationOwnerships() {
		return administrationOwnerships;
	}

	public CompassSchedulingOwnership[] getSchedulingOwnerships() {
		return schedulingOwnerships;
	}
	
	public static Region getRegionByName(String regionName) {
		if (regionName == null)
			return null;
		for (Region region : Region.values()) {
			if (region.getName().equalsIgnoreCase(regionName))
				return region;
		}
		return null;
	}
}
