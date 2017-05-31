package com.saiglobal.sf.core.schedule;

import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelper;
import com.saiglobal.sf.core.model.Resource;
import com.saiglobal.sf.core.model.CompassRevenueOwnership;
import com.saiglobal.sf.core.model.WorkItem;
import com.saiglobal.sf.core.utility.Utility;

public class BusinessRule_BusinessUnit extends AbstractBusinessRule {

	private static final Logger logger = Logger.getLogger(BusinessRule_BusinessUnit.class);
	private static final String businessUnitWhereClause = "r.Reporting_Business_Units__c in ('" + 
			CompassRevenueOwnership.AUSDirectNSWACT.getName() + "', '" +
			CompassRevenueOwnership.AUSDirectQLD.getName() + "', '" +
			CompassRevenueOwnership.AUSDirectROW.getName() + "', '" +
			CompassRevenueOwnership.AUSDirectSANT.getName() + "', '" +
			CompassRevenueOwnership.AUSDirectVICTAS.getName() + "', '" +
			CompassRevenueOwnership.AUSDirectWA.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodNSWACT.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodQLD.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodROW.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodSANT.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodVICTAS.getName() + "', '" +
			CompassRevenueOwnership.AUSFoodWA.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalNSWACT.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalQLD.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalROW.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalSANT.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalVICTAS.getName() + "', '" +
			CompassRevenueOwnership.AUSGlobalWA.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedNSWACT.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedQLD.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedROW.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedSANT.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedVICTAS.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedWA.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusNSWACT.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusQLD.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusROW.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusSANT.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusVICTAS.getName() + "', '" +
			CompassRevenueOwnership.ASSCORP.getName() + "', '" +
			CompassRevenueOwnership.AUSManagedPlusWA.getName() + "')";
	
	
	public BusinessRule_BusinessUnit(DbHelper db) {
		super(db);
	}
	
	@Override
	public HashMap<String, Resource> filter(WorkItem workItem, HashMap<String, Resource> resourceIdWithScore) {
		logger.debug(("Received " + ((resourceIdWithScore==null)?0:resourceIdWithScore.size()) + " resources as input"));
		Utility.startTimeCounter("BusinessRule_BusinessUnit");
		boolean emptyInput = (resourceIdWithScore == null) || (resourceIdWithScore.size()==0);
		HashMap<String, Resource> filteredResources = new HashMap<String, Resource>();
		
		List<String> whereClauseList = new ArrayList<String>();
		if (!emptyInput) {
			String resourceIdInClause = "r.Id IN (";
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
			whereClauseList.add(resourceIdInClause);
		}
		
		if (workItem.getRevenueOwnership()!=null) {
			switch (workItem.getRevenueOwnership()) {
			case AUSDirectNSWACT:
			case AUSDirectQLD:
			case AUSDirectROW:
			case AUSDirectSANT:
			case AUSDirectVICTAS:
			case AUSDirectWA:
			case AUSFoodNSWACT:
			case AUSFoodQLD:
			case AUSFoodROW:
			case AUSFoodSANT:
			case AUSFoodVICTAS:
			case AUSFoodWA:
			case AUSGlobalNSWACT:
			case AUSGlobalQLD:
			case AUSGlobalROW:
			case AUSGlobalSANT:
			case AUSGlobalVICTAS:
			case AUSGlobalWA:
			case AUSManagedNSWACT:
			case AUSManagedQLD:
			case AUSManagedROW:
			case AUSManagedSANT:
			case AUSManagedVICTAS:
			case AUSManagedWA:
			case AUSManagedPlusNSWACT:
			case AUSManagedPlusQLD:
			case AUSManagedPlusROW:
			case AUSManagedPlusSANT:
			case AUSManagedPlusVICTAS:
			case AUSManagedPlusWA:
			case ASSCORP:
				whereClauseList.add(businessUnitWhereClause);
				break;
	
			default:
				break;
			}
		}
		String query = "SELECT r.Id " +
				"FROM resource__c r " + 
				db.getWhereClause(whereClauseList);
		try {
			ResultSet rs = db.executeSelect(query, -1);
			if (emptyInput) {
				while (rs.next()) {
					Resource resource = new Resource();
					resource.setId(rs.getString("r.Id"));
					resource.setScore(new Double(0));
					filteredResources.put(rs.getString("r.Id"), resource);
				}
			} else {
				while (rs.next()) {	
					filteredResources.put(rs.getString("r.Id"), resourceIdWithScore.get(rs.getString("r.Id")));
				}
			}
		} catch (Exception e) {
			logger.error("", e);
		}
		Utility.stopTimeCounter("BusinessRule_BusinessUnit");
		logger.debug("Returned " + filteredResources.size() + " resources as output");
		return filteredResources;
	}
}
