
--600 P&R: Certificate Proofing/Completion by Date Range

USE oscar

DECLARE @FromDate DATETIME
DECLARE @ToDate DATETIME

-- should be the day prior
SET @FromDate = '05/05/2015 00:00:00'
-- should be the execution day
SET @ToDate = '05/06/2015 00:00:00'

SELECT          

u.GivenName + ' ' + u.Surname + ' (' + u.Username + ')' as Name,          
'Certificates Reviewed',          
count(at.AuditTrailID) as Number              

FROM          

Users u with(nolock),          
AuditTrails at with(nolock)            

WHERE          

u.UserID = at.UserID 
and at.EntityTypeID = 14
and at.EventID = 77
and at.EventTime between @FromDate and @ToDate  
            
GROUP BY          

at.UserID,          
u.GivenName,          
u.Surname,          
u.Username              

UNION     

SELECT        

u.GivenName + ' ' + u.Surname + ' (' + u.Username + ')' as Name,          
'Certificates Proofed',          
count(at.AuditTrailID) as Number              

FROM

Users u with(nolock),          
AuditTrails at with(nolock)            

WHERE          

u.UserID = at.UserID                      
and at.EntityTypeID = 14                      
and at.EventID = 78                     
and at.EventTime between @FromDate and @ToDate           
and at.UserID is not null      

GROUP BY          

at.UserID,          
u.GivenName,          
u.Surname,          
u.Username              

ORDER BY 1
