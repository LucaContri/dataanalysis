---100 Overdure Cerficates - Form 3




select          

o.OrderID,          
co.certificateorderid as certID,          
au.ProductName,          
ABS(DATEDIFF(day, atr.transtime, getdate())) - ABS(DATEDIFF(WEEK, atr.transtime, getdate())*2) - au.overduedays as overdue,          
atr.transtime as 'TransDate{date}',          
o.orderid as 'address{propertyaddress}',          
au.contactphone as 'BCM Phone'      

from          

certificatetransrecords ct WITH(NOLOCK),          
authoritytransrecords atr WITH(NOLOCK),          
authoritycertificatetypes au WITH(NOLOCK),          
certificateorders co WITH(NOLOCK),          
orders o WITH(NOLOCK)             

where          

co.orderid = o.orderid and co.authoritycertificatetypeid = au.authoritycertificatetypeid and convert(datetime,convert(varchar,getdate(),112)) > DATEADD(DAY, au.overduedays + ROUND(au.overduedays/5.0,0)*2, convert(datetime,convert(varchar,atr.transtime,112))) and co.StatusID in (31,32,33,34,35,36) and au.CertificateTypeID = 108 and ct.certificateorderid = co.certificateorderid and atr.authoritytransrecordid = ct.authoritytransrecordid and o.datesubmitted > '2011/07/01'             

order by          
au.productname,          
co.certificateorderid desc