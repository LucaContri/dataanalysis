(select * from sice.sice_tables);

(SELECT * 
from sice.sice_tables 
where ToSync=1 
and date_add(LastSyncDate, interval MinSecondsBetweenSyncs second)<utc_timestamp());

