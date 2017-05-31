package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;

public class ProcessorRule_Country_Tesco implements ProcessorRule {
	private String comment;
	private String name = "ProcessorRule_Country_Tesco";
	private static HashMap<String, List<String>> country_resources = new HashMap<String, List<String>>();
	
	static {
		country_resources.put("Italy", Arrays.asList(new String[] {"Giulio Milan","Enrico Girotto","Stefano Stefanucci","Giulia Bughi Peruglia"}));
		country_resources.put("France", Arrays.asList(new String[] {"Audrey Barbier","Bruce Maurice","Daniela Da Silva","Taghrid Paresys"}));
		country_resources.put("Germany", Arrays.asList(new String[] {"Franz Gropp","Beata Biezunska","Tatiana Wiktorowicz","Renata Chramostova","Joanna Rylko","Wojciech Kowalczyk"}));
		country_resources.put("Spain", Arrays.asList(new String[] {"Elise","Christel Kaberghs","Yobana Bermudez","Esther","Maribel"}));
		country_resources.put("Denmark", Arrays.asList(new String[] {"Franz Gropp","Beata Biezunska","Tatiana Wiktorowicz","Renata Chramostova","Joanna Rylko","Wojciech Kowalczyk"}));
		country_resources.put("Greece", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Portugal", Arrays.asList(new String[] {"Elise","Christel Kaberghs","Yobana Bermudez","Esther","Maribel"}));
		country_resources.put("Turkey", Arrays.asList(new String[] {"Mine Certug","Derya Kasan Ozdemir","Esra Downs","Evren Efe","Tulay Eren"}));
		country_resources.put("Switzerland", Arrays.asList(new String[] {"Giulio Milan","Enrico Girotto","Stefano Stefanucci","Giulia Bughi Peruglia","Audrey Barbier","Bruce Maurice","Daniela Da Silva","Taghrid Paresys","Franz Gropp","Beata Biezunska","Tatiana Wiktorowicz","Renata Chramostova","Joanna Rylko","Wojciech Kowalczyk"}));
		country_resources.put("Norway", Arrays.asList(new String[] {"Franz Gropp","Beata Biezunska","Tatiana Wiktorowicz","Renata Chramostova","Joanna Rylko","Wojciech Kowalczyk"}));
		country_resources.put("Austria", Arrays.asList(new String[] {"Giulio Milan","Enrico Girotto","Stefano Stefanucci","Giulia Bughi Peruglia","Audrey Barbier","Bruce Maurice","Daniela Da Silva","Taghrid Paresys","Franz Gropp","Beata Biezunska","Tatiana Wiktorowicz","Renata Chramostova","Joanna Rylko","Wojciech Kowalczyk"}));		
	}
	
	@Override
	public List<Resource> filter(WorkItem workItem, List<Resource> resources, DbHelper db, ScheduleParameters parameters) throws Exception {
		
		List<Resource> filteredResources = new ArrayList<Resource>();
		List<String> resourcesForCountry = country_resources.get(workItem.getClientSite().getCountry());
		if(resourcesForCountry == null)
			return resources;
		
		for (Resource resource : resources) {
			if(resourcesForCountry.contains(resource.getName())) {
				filteredResources.add(resource);
			}
		}
		return filteredResources;
	}

	@Override
	public String getComment() {
		return comment;
	}
	
	@Override
	public String getName() {
		return name;
	}
}
