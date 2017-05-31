
--400 Tasks Completed by User (by Date Range)

USE oscar

DECLARE @FromDate DATETIME
DECLARE @ToDate DATETIME

-- should be the day prior
SET @FromDate = '05/05/2015 00:00:00'
-- should be the execution day
SET @ToDate = '05/06/2015 00:00:00'

SELECT        

(u.GivenName + ' ' + u.surname)as 'Name',          
tt.DisplayName as TaskType,          
count(t.TaskID) as Number                        

FROM          

OscarUsers u with(nolock),          
Tasks t with(nolock),          
TaskTypes tt with(nolock),          
AuditTrails at with(nolock)                        

WHERE         

U.UserID = at.UserID 
and t.TaskTypeID = tt.TaskTypeID 
and t.TaskID = at.EntityID 
and at.EntityTypeID = 8 
and at.EventTime between @FromDate and @ToDate
and at.UserID is not null 
and at.EventID = 2 

GROUP BY  u.givenname, u.surname, tt.DisplayName  

UNION      

SELECT      

(u.GivenName + ' ' + u.surname)as 'Name',
'Manual Task Completed',          
COUNT(*) As Number                        

FROM          

AuditTrails at WITH(NOLOCK)                       
JOIN Tasks t WITH(NOLOCK) ON t.TaskID = at.EntityID AND t.TaskTypeID in (23,24,25,26) -- Manual Queue Tasks                                                        
AND t.EntityTypeID =  1 -- Orders                                        
JOIN (SELECT DISTINCT
O.OrderID                                                                        

FROM Orders o WITH(NOLOCK) 
JOIN CertificateOrders co WITH(NOLOCK) ON co.OrderID = o.OrderID
JOIN AuthorityCertificateTypes act WITH(NOLOCK) ON co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID 
AND act.TransmissionHandlerID = 33) O ON o.OrderID = t.EntityID
JOIN Users u WITH(NOLOCK) ON u.UserID = at.UserID 

WHERE at.AuditTrailEventTypeID = 1 -- Status change event type                                                                        
AND at.EventID = 2 -- Status ID of Task Completed                                                                        
AND U.UserID IS NOT NULL                                                                        
AND at.EventTime BETWEEN @FromDate and @ToDate                                                    
and at.EventID = 2                                                        

GROUP BY                  
u.givenname,                  
u.surname                                                           

UNION              

SELECT                       
(u.GivenName + ' ' + u.surname)as 'Name',                  
'Uploaded Bundle',                  
COUNT(*) As Uploaded                                                        

FROM AuditTrails at WITH(NOLOCK)                                                        
JOIN CertificateOrderBundles cob WITH(NOLOCK) ON cob.BundleID = at.EntityID                                                        
JOIN Users u WITH(NOLOCK) ON u.UserID = at.UserID                                                        

WHERE at.AuditTrailEventTypeID = 2   -- User Action event type                                                                        
AND at.EventID = 1 -- UserAction ID of Bundle Uploaded                                                                        
AND at.EventTime BETWEEN @FromDate and dateadd(d, 1, @ToDate)                                                                            

GROUP BY                  
u.givenname,                  
u.surname                                                         

UNION              

SELECT                      
(u.GivenName + ' ' + u.surname)as 'Name',                  
'Associated Bundle',                  
count(at.entityid) as Total                                                        

FROM                
AuditTrails at with(nolock), Users u with(nolock)                                                        

WHERE
at.eventid = 43 -- All images collected, bundle ready for association                                                                        
and at.userid is not null                                                                        
and u.userid = at.userid                                                                        
and at.EventTime >= @FromDate                                                                       
and at.EventTime < dateadd(d, 1, @ToDate)                                                                     

GROUP BY                 
u.givenname,                  
u.surname