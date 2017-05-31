package com.saiglobal.sf.core.utility;

import com.saiglobal.sf.core.utility.Utility;
import com.google.code.geocoder.Geocoder;
import com.google.code.geocoder.model.LatLng;

public class DynamicJavaCodeImplementation implements com.saiglobal.sf.core.utility.DynamicJavaCodeInterface {

 public void execute(Object[] values) throws Exception {
error
   if(values[3] == null || values[4] == null || ((double)values[3]==0 && (double)values[4]==0)) {
   // Need to geocode
   System.out.println("Geocoding home location for " + values[1] + " - " + values[2]);
   LatLng coordinates = Utility.getGeocode((String)values[2], (String)values[2], null);
   if (coordinates != null) {
    values[3] = coordinates.getLat().doubleValue();
    values[4] = coordinates.getLng().doubleValue();
   }
  }
 }
}
