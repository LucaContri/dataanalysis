package com.saiglobal.sf.allocator.rules;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.model.WorkItem;

public class ProcessorRule_Country_PS implements ProcessorRule {
	private String comment;
	private String name = "ProcessorRule_Country_PS";
	private static HashMap<String, List<String>> country_resources = new HashMap<String, List<String>>();
	
	static {
		country_resources.put("Australia", Arrays.asList(new String[] {"Edward Waloch", "Ismael Parra", "Gerry Pisani", "Mike Ryan", "David Kershaw","Raymond Ng", "Tony Liu","Gautam Yadav", "Barak Mizrachi", "Bill Iskander", "Cher Seong Phang", "David Barnes", "Graham Blucher", "John Webster", "Kin Shing Chan", "Mark Hazeldine", "Minnie Rong", "Osvaldo Marques", "Ranganathan Raghavan", "Rebecca Searcy", "Richard Donarski", "Simon Fraser", "Sylvia Butcher", "Thomas Guan", "William Wang", "Scott Trevitt", "Colin Marchant", "Wendy Lim", "Norman Thomas", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Austria", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Belgium", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Canada", Arrays.asList(new String[] {"Qiaoli Meng","Jeffery Judd", "Christian Halford", "Jason Friedrich", "Julia Arbanas", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("China", Arrays.asList(new String[] {"Jessica Zhong","William Wang","Sigit Yulianto", "David (Dawei) Lu", "Davy Wei", "George Liu", "Jenny Tang", "Jim Li", "David Tseng", "Matthew Slater", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Cyprus", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Czech Republic", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Denmark", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("France", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Germany", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Greece", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("India", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Nambi Narasimhan Manohar", "Arun Kumar Sinha", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Indonesia", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Setyo Sutadiono", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Israel", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Italy", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Japan", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Lithuania", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Luxembourg", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Korea, South", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sechul Kim", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Malaysia", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Monaco", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("New Zealand", Arrays.asList(new String[] {"Anthony Alberts", "Roger Marriott", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Norway", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Netherlands", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Pakistan", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Poland", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Portugal", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Romania", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Russian Federation", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Singapore", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Slovakia", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Slovenia", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("South Africa", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Sweden", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Spain", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Sri Lanka", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Switzerland", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Taiwan", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Thailand", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Turkey", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("United Kingdom", Arrays.asList(new String[] {"Gordon Walton","Diego Piazzano", "Geoff White", "Giuliano Franzosi", "Christian Halford", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("United States", Arrays.asList(new String[] {"Qiaoli Meng","Jeffery Judd", "Christian Halford", "Jason Friedrich", "Julia Arbanas", "Janet Hoh", "Richard Bickle"}));
		country_resources.put("Viet Nam", Arrays.asList(new String[] {"Jenny Tang", "Jim Li", "Sigit Yulianto", "Matthew Slater", "David Tseng", "Janet Hoh", "Richard Bickle"}));
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
