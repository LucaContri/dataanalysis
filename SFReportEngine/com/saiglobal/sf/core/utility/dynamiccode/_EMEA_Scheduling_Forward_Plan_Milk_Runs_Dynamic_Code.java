package com.saiglobal.sf.core.utility.dynamiccode;

import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCodeInterface;
import com.saiglobal.sf.core.utility.Utility;
import com.saiglobal.sf.core.model.SfResourceType;
import com.saiglobal.sf.core.model.TravelCostCalculationType;
import java.util.HashMap;
import com.google.code.geocoder.Geocoder;
import com.google.code.geocoder.model.LatLng;

public class _EMEA_Scheduling_Forward_Plan_Milk_Runs_Dynamic_Code implements DynamicJavaCodeInterface {

public void execute(HashMap<String, Object> values) throws Exception {
 // Update travel duration and scheduling cost function
 if(values.get("Actual Resource Id") != null) {
 if (values.get("Actual Resource Distance") == null) {
  LatLng resourceCoordinates = Utility.getGeocode((String)values.get("Actual Resource Location"), (String)values.get("Actual Resource Location"), null);
  LatLng siteCoordinates = Utility.getGeocode((String)values.get("Site Location"), (String)values.get("Site Location"), null);
  if (resourceCoordinates != null && siteCoordinates != null) {
   values.put("Actual Resource Distance",
    2*Utility.calculateDistanceKm(resourceCoordinates.getLat().doubleValue(), resourceCoordinates.getLng().doubleValue(), siteCoordinates.getLat().doubleValue(), siteCoordinates.getLng().doubleValue()));
  }
  }
  if (values.get("Actual Resource Distance") != null)
  values.put("Actual Resource Travel Duration", Math.min(Utility.calculateTravelTimeHrs(((double) values.get("Actual Resource Distance"))),8));
 }
 if(values.get("Actual Resource Id") != null && values.get("Actual Resource Distance") != null)
  values.put("Actual Resource Calculated Cost", Utility.calculateAuditCost(
   SfResourceType.getValueForName((String) values.get("Actual Resource Type")),
   (double) values.get("Actual Resource Hourly Rate"),
   (double) values.get("Required Duration"),
   (double) values.get("Actual Resource Distance"),
   TravelCostCalculationType.EMPIRICAL_UK));
 if(values.get("Allocator Resource Id") != null && values.get("Allocator Resource Distance") != null)
  values.put("Allocator Resource Calculated Cost", Utility.calculateAuditCost(
   SfResourceType.getValueForName((String) values.get("Allocator Resource Type")),
   (double) values.get("Allocator Resource Hourly Rate"),
   (double) values.get("Required Duration"),
   (double) values.get("Allocator Resource Distance"),
   TravelCostCalculationType.EMPIRICAL_UK));
 if(values.get("Actual Resource Id") != null) {
  values.put("Resource Id", values.get("Actual Resource Id"));
  values.put("Resource Name", values.get("Actual Resource Name"));
  values.put("Resource Type", values.get("Actual Resource Type"));
  values.put("Resource Travel Duration", values.get("Actual Resource Travel Duration"));
  values.put("Resource Reporting Business Unit", values.get("Actual Resource Reporting Business Unit"));
  values.put("Resource Location", values.get("Actual Resource Location"));
  values.put("Resource Distance", values.get("Actual Resource Distance"));
  values.put("Resource Calculated Cost", values.get("Actual Resource Calculated Cost"));
  values.put("Resource Scheduling Type", "Actual");
 } else {
  values.put("Resource Id", values.get("Allocator Resource Id"));
  values.put("Resource Name", values.get("Allocator Resource Name"));
  values.put("Resource Type", values.get("Allocator Resource Type"));
  values.put("Resource Travel Duration", values.get("Allocator Resource Travel Duration"));
  values.put("Resource Reporting Business Unit", values.get("Allocator Resource Reporting Business Unit"));
  values.put("Resource Location", values.get("Allocator Resource Location"));
  values.put("Resource Distance", values.get("Allocator Resource Distance"));
  values.put("Resource Calculated Cost", values.get("Allocator Resource Calculated Cost"));
  values.put("Resource Scheduling Type", (((String)values.get("Allocator Status")).equalsIgnoreCase("ALLOCATED"))?"Allocator - Allocated":(((String)values.get("Allocator Status")).equalsIgnoreCase("OUT OF SCOPE"))?"Allocator - Out Of Scope":"Allocator - Not Allocated");
 }
}
}
