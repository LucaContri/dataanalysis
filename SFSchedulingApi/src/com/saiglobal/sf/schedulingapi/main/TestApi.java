package com.saiglobal.sf.schedulingapi.main;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import org.apache.log4j.Logger;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.schedulingapi.data.DbHelper;
import com.saiglobal.sf.schedulingapi.utility.Utility;

public class TestApi {

	private static Logger logger = Logger.getLogger(TestApi.class);
	private static DbHelper db;
	private static final GlobalProperties gp;
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		try {
			db = new DbHelper(gp);
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
	}
	
	
	public static void main(String[] args) throws ClassNotFoundException, IllegalAccessException, InstantiationException, SQLException, IOException {
		
		List<WorkItem> matches = db.searchWorkItem("NSW",10);
		int maxConcurrent = 3;
		
		Utility.startTimeCounter("TestApi-Overall");
		for (int i=0; i<matches.size()-1; i++) {
			WorkItem workItem = matches.get(i);
			while (Thread.activeCount()>maxConcurrent) {
				try {
					Thread.sleep(100);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			Runnable action = new TestApiAction(workItem.getName());
			Thread thread = new Thread(action);
			thread.setDaemon(true);
			thread.setName("Action-" + workItem.getName());
			thread.start();
	        Utility.incEventCounter("TestApi-Overall");
		} 
		Runnable lastAction = new TestApiAction(matches.get(matches.size()-1).getName());
		Thread lastThread = new Thread(lastAction);
		lastThread.setDaemon(true);
		lastThread.setName("Action-" + matches.get(matches.size()-1).getName());
		lastThread.start();
        Utility.incEventCounter("TestApi-Overall");
        
		try {
			lastThread.join();
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		Utility.stopTimeCounter("TestApi-Overall");
		Utility.logAllProcessingTime();
		Utility.logAllEventCounter();
	}

}
