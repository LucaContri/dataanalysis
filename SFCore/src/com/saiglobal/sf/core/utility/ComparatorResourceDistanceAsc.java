package com.saiglobal.sf.core.utility;

import java.sql.SQLException;
import java.util.Comparator;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.exceptions.GeoCodeApiException;
import com.saiglobal.sf.core.model.Location;
import com.saiglobal.sf.core.model.Resource;

/* Note: this comparator imposes orderings that are inconsistent with equals. */
public class ComparatorResourceDistanceAsc implements Comparator<Resource> {
	
	private Location clientSite;
	private DbHelper db;
	private static final Logger logger = Logger.getLogger(ComparatorResourceDistanceAsc.class);
	
	public ComparatorResourceDistanceAsc(Location clientSite, DbHelper db) {
		this.clientSite = clientSite;
		this.db = db;
	}
	
	@Override
	public int compare(Resource resource1, Resource resource2) {
		//Utility.startTimeCounter(); 
		double d1 = 0;
		double d2 = 0;
		try {
			d1 = Utility.calculateDistanceKm(clientSite, resource1.getHome(), db);
			d2 = Utility.calculateDistanceKm(clientSite, resource2.getHome(), db);
		} catch (SQLException e) {
			logger.error("", e);
		} catch (ClassNotFoundException e) {
			logger.error("", e);
		} catch (IllegalAccessException e) {
			logger.error("", e);
		} catch (InstantiationException e) {
			logger.error("", e);
		} catch (GeoCodeApiException e) {
			logger.error("", e);
		}
		//Utility.stopTimeCounter(); 
		if (d1<d2)
			return -1;
		if (d1>d2)
			return +1;
		return 0;
	}

}
