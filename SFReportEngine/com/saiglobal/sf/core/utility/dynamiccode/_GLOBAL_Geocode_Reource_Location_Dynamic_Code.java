package com.saiglobal.sf.core.utility.dynamiccode;

import java.util.HashMap;
import com.saiglobal.sf.core.utility.dynamiccode.DynamicJavaCodeInterface;
import com.saiglobal.sf.core.utility.Utility;
import com.google.code.geocoder.Geocoder;
import com.google.code.geocoder.model.LatLng;

public class _GLOBAL_Geocode_Reource_Location_Dynamic_Code implements DynamicJavaCodeInterface {

 public void execute(HashMap<String, Object> values) throws Exception {
   if(values.get("Latitude") == null || values.get("Longitude") == null ) {
   // Need to geocode
   try {
    Utility.getLogger().info("Geocoding home location for " + values.get("Resource Name") + " - " + values.get("Resource Location"));
    LatLng coordinates = Utility.getGeocode((String)values.get("Resource Location"), (String)values.get("Resource Location"), null);
    if (coordinates != null) {
  values.put("Latitude", coordinates.getLat().doubleValue());
  values.put("Longitude", coordinates.getLng().doubleValue());
    }
   } catch (Exception e) {
     // Ignore
     e.printStackTrace();
   }
  }
 }
}
