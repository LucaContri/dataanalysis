---100 Overdure Cerficates - NSW (non-Espreon products)


select          

distinct o.orderid,         
co.certificateorderid as certID,          
au.ProductName,          
ABS(DATEDIFF(day, atr.transtime, getdate())) - ABS(DATEDIFF(WEEK, atr.transtime, getdate())*2) - au.overduedays as overdue,
atr.transtime as 'TransDate{date}',          
tm.DisplayName as TransMethod,          
pm.DisplayName as PaymentMethod,          
o.orderid as 'address{propertyaddress}',         
p.value as LotPlan              

from          

certificatetransrecords ct WITH(NOLOCK),          
authoritytransrecords atr WITH(NOLOCK),          
authoritycertificatetypes au WITH(NOLOCK),          
certificatetypes cf WITH(NOLOCK),          
certificateorders co WITH(NOLOCK),          
dbo.PaymentMethods pm WITH(NOLOCK),          
dbo.TransMethods tm WITH(NOLOCK),          
dbo.Authorities ath WITH(NOLOCK),          
orders o WITH(NOLOCK)             
left outer join  orderpropertyfields p WITH(NOLOCK) on o.orderid = p.orderid and p.inputfieldid = 1811 where co.orderid = o.orderid and co.authoritycertificatetypeid = au.authoritycertificatetypeid and convert(datetime,convert(varchar,getdate(),112)) > DATEADD(DAY, au.overduedays + ROUND(au.overduedays/5.0,0)*2, convert(datetime,convert(varchar,atr.transtime,112))) and co.StatusID in (31,32,33,34,36) and ct.certificateorderid = co.certificateorderid and atr.authoritytransrecordid = ct.authoritytransrecordid and au.authorityid = ath.AuthorityID and au.authorityid != 140 and au.PaymentMethodID = pm.PaymentMethodID and au.TransMethodID = tm.TransMethodID and au.ProductState = 'NSW' and au.AuthorityCertificateTypeID not in (SELECT AuthorityCertificateTypeID FROM AuthorityCertificateTypes with(NOLOCK) WHERE AuthorityCertificateTypeID in (2608, 4064)) -- Office of State Revenue - Valuation Certificate                     
order by          
au.ProductName,          
co.certificateorderid desc