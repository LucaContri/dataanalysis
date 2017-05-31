package com.saiglobal.reporting.servlets;

import java.sql.ResultSet;
import java.util.ArrayList;

import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;

import com.google.visualization.datasource.DataSourceServlet;
import com.google.visualization.datasource.datatable.ColumnDescription;
import com.google.visualization.datasource.datatable.DataTable;
import com.google.visualization.datasource.datatable.value.ValueType;
import com.google.visualization.datasource.query.Query;
import com.saiglobal.sf.core.data.DbHelperConnPool;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;


@SuppressWarnings("serial")
public class ResourcesServlet extends DataSourceServlet {
	private static Logger logger = Logger.getLogger(ResourcesServlet.class);
	private static DbHelperConnPool db;
	private static final GlobalProperties gp;
	
	static {
	// Initialise
		gp = GlobalProperties.getDefaultInstance();
		
		try {
			logger.info("static init");
			db = new DbHelperConnPool(gp, "jdbc/compass");
		} catch (Exception e) {
			logger.error(e);
			Utility.handleError(gp, e);
		}
		
	}
	  @Override
	  public DataTable generateDataTable(Query query, HttpServletRequest request) {
	    // Create a data table.
	    DataTable data = new DataTable();
	    ArrayList<ColumnDescription> cd = new ArrayList<ColumnDescription>();
	    cd.add(new ColumnDescription("Latitude", ValueType.NUMBER, "Latitude"));
	    cd.add(new ColumnDescription("Longitude", ValueType.NUMBER, "Longitude"));
	    cd.add(new ColumnDescription("Region", ValueType.TEXT, "Region"));
	    cd.add(new ColumnDescription("FTEs", ValueType.NUMBER, "FTEs"));
	    cd.add(new ColumnDescription("Contractors", ValueType.NUMBER, "Contractors"));

	    data.addColumns(cd);

	    // Fill the data table.
	    String sqlquery = "select t.State, t.SLAName, t.Latitude, t.Longitude, sum(t.FTEs) as 'ftes', sum(t.Contractors) as 'contractors' from ("
	    		+ "select "
	    		+ "r.Resource_Type__c, scs.Name as 'State', sla.SLAName, sla.Latitude, sla.Longitude,"
	    		+ "if (r.Resource_Type__c='Employee', Count(r.Id),0) as 'FTEs',"
	    		+ "if (r.Resource_Type__c='Contractor', Count(r.Id),0) as 'Contractors' "
	    		+ "from "
	    		+ "resource__c r inner join "
	    		+ "resource_competency__c rc ON rc.Resource__c = r.Id left join "
	    		+ "state_code_setup__c scs ON scs.Id = r.Home_State_Province__c left join "
	    		+ "saig_postcodes_to_sla4 sla ON r.Home_Postcode__c = sla.Postcode "
	    		+ "where "
	    		+ "r.Reporting_Business_Units__c like 'AUS%' "
	    		+ "and r.Active_User__c = 'Yes' "
	    		+ "and rc.standard_or_Code__c='9001:2008 | Certification' "
	    		+ "group by r.Resource_Type__c, `State`, sla.SLAName, sla.Latitude, sla.Longitude) t "
	    		+ "group by  t.State, t.SLAName, t.Latitude, t.Longitude";
	    
	    try {
	    	ResultSet rs = db.executeSelect(sqlquery, -1);
	   
		    while (rs.next()) {
		      data.addRowFromValues(
		    		  rs.getDouble("t.Latitude") 
		    		  ,rs.getDouble("t.Longitude") 
		    		  ,rs.getString("t.State")+"-" + rs.getString("t.SLAName")
		    		  ,rs.getInt("ftes")
		    		  ,rs.getInt("contractors")
		    		 );
		      
		    }
		} catch (Exception e) {
			Utility.handleError(gp, e);
	    } finally {
	    	db.closeConnection();
			Utility.logAllProcessingTime();
			Utility.resetAllTimeCounter();
	    }
	    return data;
	  }

	  /**
	   * NOTE: By default, this function returns true, which means that cross
	   * domain requests are rejected.
	   * This check is disabled here so examples can be used directly from the
	   * address bar of the browser. Bear in mind that this exposes your
	   * data source to xsrf attacks.
	   * If the only use of the data source url is from your application,
	   * that runs on the same domain, it is better to remain in restricted mode.
	   */
	  @Override
	  protected boolean isRestrictedAccessMode() {
	    return false;
	  }
	}
