# Calculate distance in km given geo coordinates given as signed decimal degrees without compass direction, where negative indicates west/south (e.g. 40.7486, -73.9864)
create function DISTANCE (lat1 double(18,10), lon1 double(18,10), lat2 double(18,10), lon2 double(18,10))
RETURNS double(18,10)
return 6367 * acos( cos( radians(lat1) ) 
              * cos( radians( lat2) ) 
              * cos( radians( lon2 ) - radians(lon1) ) 
              + sin( radians(lat1) ) 
              * sin( radians( lat2 ) ) );