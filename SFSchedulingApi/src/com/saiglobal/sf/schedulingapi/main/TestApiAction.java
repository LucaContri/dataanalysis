package com.saiglobal.sf.schedulingapi.main;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;

import com.saiglobal.sf.schedulingapi.utility.Utility;

public class TestApiAction implements Runnable {

	private String workItemName;
	
	public TestApiAction(String wiName) {
		this.workItemName = wiName;
	}
	
	@Override
	public void run() {
		URL server;
		try {
			Utility.startTimeCounter("TestApi-" + workItemName);
			server = new URL("http://ausydhq-cotap06:8080/SchedulingApi/wi?name=" + workItemName);
		
	        URLConnection yc = server.openConnection();
	        BufferedReader in = new BufferedReader(new InputStreamReader(
	                                    yc.getInputStream()));
	        String inputLine;
	        while ((inputLine = in.readLine()) != null) { 
	            System.out.println(inputLine);
	        }
	        in.close();
	        Utility.stopTimeCounter("TestApi-" + workItemName);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
