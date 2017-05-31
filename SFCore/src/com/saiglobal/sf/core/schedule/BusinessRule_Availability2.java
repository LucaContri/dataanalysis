package com.saiglobal.sf.core.schedule;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_Availability2 extends AbstractBusinessRule {

	private static final Logger logger = Logger.getLogger(BusinessRule_Availability2.class);
	private int monthsBeforeTarget;
	private int monthsAfterTarget;
	
	public BusinessRule_Availability2(DbHelper db, int monthsBeforeTarget, int monthsAfterTarget) {
		super(db);
		this.monthsBeforeTarget = monthsBeforeTarget;
		this.monthsAfterTarget = monthsAfterTarget;
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) {
		logger.debug(("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input"));
		Utility.startTimeCounter("BusinessRule_Availability");
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		Calendar pointer = new GregorianCalendar();
		pointer.setTime(workItem.getSearchResourceStartDate());
		pointer.add(Calendar.MONTH, -monthsBeforeTarget);
		Date startDate = pointer.getTime();
		pointer.add(Calendar.MONTH, monthsBeforeTarget+monthsAfterTarget);
		Date endDate = pointer.getTime();
		
		//List<String> whereClauseList1 = new ArrayList<String>();
		//List<String> whereClauseList2 = new ArrayList<String>();
		//if (!emptyInput) {
			String resourceIdInClause = " (";
			boolean first = true;
			for (String resourceId : resourceIdWithScore.keySet()) {
				if (first) {
					resourceIdInClause += "'" + resourceId + "'";
					first = false;
				} else {
					resourceIdInClause += ", '" + resourceId + "'";
				}
			}
			resourceIdInClause += ")";
			//whereClauseList1.add(resourceIdInClause);
			//whereClauseList2.add(resourceIdInClause);
		//}
		//whereClauseList1.add("wd.date>='" + Utility.getActivitydateformatter().format(startDate) + "'");
		//whereClauseList1.add("wd.date<='" + Utility.getActivitydateformatter().format(endDate) + "'");
		//whereClauseList2.add("e.ActivityDate>='" + Utility.getActivitydateformatter().format(startDate) + "'");
		//whereClauseList2.add("e.ActivityDate<='" + Utility.getActivitydateformatter().format(endDate) + "'");
		
		String query = "SELECT  "
				+ "i.Id, count(i.date) "
				+ "FROM "
				+ "(SELECT wd.date, r.Id "
				+ "FROM `sf_working_days` wd, resource__c r "
				+ "WHERE "
				+ "r.Id IN ? "
				+ "AND wd.date >= ? "
				+ "AND wd.date <= ?) i "
				+ "LEFT JOIN "
				+ "(SELECT r.Id, e.ActivityDate "
				+ "FROM `event` e "
				+ "INNER JOIN `resource__c` r ON r.User__c = e.OwnerId "
				+ "WHERE "
				+ "r.Id IN ? "
				+ "AND e.ActivityDate >= ? "
				+ "AND e.ActivityDate <= ?) t ON t.ActivityDate = i.date AND t.id = i.Id "
				+ "WHERE "
				+ "t.Id is NULL "
				+ "GROUP BY i.Id";
		logger.info(query);
		
		
		try {
			Utility.startTimeCounter("BusinessRule_Availability_Query");
			Connection conn = db.getConnection();
			PreparedStatement st = conn.prepareStatement(query);
			st.setString(1, resourceIdInClause);
			st.setString(2, Utility.getActivitydateformatter().format(startDate));
			st.setString(3, Utility.getActivitydateformatter().format(endDate));
			st.setString(4, resourceIdInClause);
			st.setString(5, Utility.getActivitydateformatter().format(startDate));
			st.setString(6, Utility.getActivitydateformatter().format(endDate));
			ResultSet rs = st.executeQuery();
			Utility.stopTimeCounter("BusinessRule_Availability_Query");
			if (emptyInput) {
				while (rs.next()) {
					if (rs.getInt("count(i.date)")>Math.ceil(workItem.getRequiredDuration()/8)) {
						Resource resource = new Resource();
						resource.setId(rs.getString("i.Id"));
						resource.setScore(new Double(0));
						filteredResources.put(rs.getString("i.Id"), resource);
					}
				}
			} else {
				while (rs.next()) {
					if (rs.getInt("count(i.date)")>Math.ceil(workItem.getRequiredDuration()/8)) {
						filteredResources.put(rs.getString("i.Id"), resourceIdWithScore.get(rs.getString("i.Id")));
					}
				}
			}
		} catch (Exception e) {
			logger.error("", e);
		}
		Utility.stopTimeCounter("BusinessRule_Availability");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}
}
