USE SSR

declare @FromDate datetime
declare @ToDate datetime

set @FromDate = GETDATE()
set @ToDate = DATEADD(MONTH,6,GETDATE())


--Checking to make sure I dropped the temporary table(s) from the last session. If the table does exists, it is dropped

IF OBJECT_ID(N'tempdb.dbo.#FooQLDIpswitch', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLDIpswitch;END;
IF OBJECT_ID(N'tempdb.dbo.#FooQLD', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLD;END;
IF OBJECT_ID(N'tempdb.dbo.#FooQLDBrisSuburbs', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLDBrisSuburbs;END;
IF OBJECT_ID(N'tempdb.dbo.#FooQLDGoldCoast', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLDGoldCoast;END;
IF OBJECT_ID(N'tempdb.dbo.#FooVICMelbMetro', 'U') IS NOT NULL BEGIN DROP TABLE #FooVICMelbMetro;END;
IF OBJECT_ID(N'tempdb.dbo.#FooNTAll', 'U') IS NOT NULL BEGIN DROP TABLE #FooNTAll;END;
IF OBJECT_ID(N'tempdb.dbo.#FooNSWRegional', 'U') IS NOT NULL BEGIN DROP TABLE #FooNSWRegional;END;
IF OBJECT_ID(N'tempdb.dbo.#FooVICRegional', 'U') IS NOT NULL BEGIN DROP TABLE #FooVICRegional;END;
IF OBJECT_ID(N'tempdb.dbo.#FooSAAll', 'U') IS NOT NULL BEGIN DROP TABLE #FooSAAll;END;
IF OBJECT_ID(N'tempdb.dbo.#FooQLDSunshine', 'U') IS NOT NULL BEGIN DROP TABLE #FooQLDSunshine;END;
IF OBJECT_ID(N'tempdb.dbo.#FooTASAll', 'U') IS NOT NULL BEGIN DROP TABLE #FooTASAll;END;
IF OBJECT_ID(N'tempdb.dbo.#FooWABunbury', 'U') IS NOT NULL BEGIN DROP TABLE #FooWABunbury;END;
IF OBJECT_ID(N'tempdb.dbo.#FooWAPerthMetro', 'U') IS NOT NULL BEGIN DROP TABLE #FooWAPerthMetro;END;
IF OBJECT_ID(N'tempdb.dbo.#FooWAAllOther', 'U') IS NOT NULL BEGIN DROP TABLE #FooWAAllOther;END;


--Creating temporary table(s) to hold the results of the stored procedures - using multiple because the procedure has a defect where the state is not retrieved and this is an easy way to dofferenciate

CREATE TABLE #FooQLDIpswitch (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooQLD (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooQLDBrisSuburbs (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooQLDGoldCoast (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooVICMelbMetro (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooNTAll (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooNSWRegional (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooVICRegional (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooQLDSunshine (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooTASAll (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooWABunbury (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooWAPerthMetro (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)
CREATE TABLE #FooWAAllOther (venue_Desc varchar(255), settle_venue_desc varchar(255), settlement_datetime DateTime, service_id Int, agentConfirmed_datetime DateTime, UserName varchar(50), site_desc varchar(200), MatterSSRNumber varchar(50), MatterName varchar(255), agent_confirmed varchar(5), transactionType_desc varchar(255), agent_Id varchar(255), defaultVenueAgentId varchar(255), loanAccountNumber varchar(255), account_code varchar(255), site_code varchar(50), postcode varchar(50), agent_contacted varchar(5), agentcontacted_datetime DateTime, ContactedBy varchar(50), Matter_Id int)

--Inserting stored procedure results into temporary tables  

INSERT #FooQLDIpswitch 
		EXEC    p_LoadSettlement -1, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL

INSERT #FooQLD 
		EXEC	p_LoadSettlement 2, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL

INSERT #FooQLDBrisSuburbs
		EXEC	p_LoadSettlement 4, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooQLDGoldCoast
		EXEC	p_LoadSettlement 6, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooVICMelbMetro
		EXEC	p_LoadSettlement 8, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooNTAll
		EXEC	p_LoadSettlement 11, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooNSWRegional
		EXEC	p_LoadSettlement 12, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooVICRegional
		EXEC	p_LoadSettlement 14, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooQLDSunshine
		EXEC	p_LoadSettlement 17, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooTASAll 
		EXEC	p_LoadSettlement 21, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooWABunbury
		EXEC	p_LoadSettlement 25, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		
INSERT #FooWAAllOther
		EXEC	p_LoadSettlement 28, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL

INSERT #FooWAPerthMetro
		EXEC	p_LoadSettlement 29, -1, -2, NULL, @FromDate ,@ToDate, 1, 4, 0 , NULL
		

--Returning all results

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDIpswitch a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDIpswitch a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLD a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account',
a.transactionType_desc AS 'TranType',  
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLD a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDBrisSuburbs a
	JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
	site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDBrisSuburbs a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDGoldCoast a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM #FooQLDGoldCoast a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'VIC' AS 'State'

FROM #FooVICMelbMetro a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 
	
UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'VIC' AS 'State'

FROM #FooVICMelbMetro a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'NT' AS 'State'

FROM #FooNTAll a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'NT' AS 'State'

FROM #FooNTAll a

WHERE 
site_desc <> 'ANZ' 

UNION

SELECT
MatterSSRNumber AS 'SSR', 
MatterName AS 'Matter', 
loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
agent_contacted AS 'Contacted?', 
ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
site_desc AS 'Site', 
account_code AS 'Account', 
transactionType_desc AS 'TranType', 
service_id AS 'ServiceId', 
defaultVenueAgentId AS 'AgentID', 
Matter_Id AS 'MatterID',
'NSW' AS 'State'

FROM  #FooNSWRegional a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'NSW' AS 'State'

FROM  #FooNSWRegional a

WHERE 
site_desc <> 'ANZ' 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'VIC' AS 'State'

FROM  #FooVICRegional a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'VIC' AS 'State'

FROM  #FooVICRegional a

WHERE 
site_desc <> 'ANZ' 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM   #FooQLDSunshine a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'QLD' AS 'State'

FROM   #FooQLDSunshine a

WHERE 
site_desc <> 'ANZ' 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'TAS' AS 'State'

FROM   #FooTASAll a
	JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'TAS' AS 'State'

FROM   #FooTASAll a

WHERE 
site_desc <> 'ANZ' 
	
UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWABunbury a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time',  
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWABunbury a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWAPerthMetro a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWAPerthMetro a

WHERE 
site_desc <> 'ANZ'

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date', 
a.venue_desc AS 'Venue',
p.clientRegion AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWAAllOther a
JOIN TB_POSTCODECLIENTREGION p ON a.postcode=p.postcode

WHERE 
site_desc = 'ANZ'

GROUP BY
a.MatterSSRNumber, 
a.MatterName, 
a.loanAccountNumber,  
a.settlement_datetime, 
a.agent_contacted, 
a.ContactedBy, 
a.agentcontacted_datetime, 
a.agent_confirmed, 
a.agentConfirmed_datetime, 
a.UserName,  
a.venue_desc,
p.clientRegion,
a.site_desc, 
a.account_code, 
a.transactionType_desc,
a.service_id, 
a.defaultVenueAgentId, 
a.Matter_Id 

UNION

SELECT
a.MatterSSRNumber AS 'SSR', 
a.MatterName AS 'Matter', 
a.loanAccountNumber AS 'Loan#',  
CAST(CONVERT(varchar(10),a.settlement_datetime,101 ) as Date) AS 'Date/Time', 
a.agent_contacted AS 'Contacted?', 
a.ContactedBy AS 'Contacted By', 
CAST(CONVERT(varchar(10),a.agentcontacted_datetime,101 ) as Date) AS 'Contacted Date', 
a.agent_confirmed AS 'Confirmed?', 
a.UserName AS 'Confirmed By',  
CAST(CONVERT(varchar(10),a.agentConfirmed_datetime,101 ) as Date) AS 'Confirmed Date',  
a.venue_desc AS 'Venue',
'' AS 'ClientRegion',
a.site_desc AS 'Site', 
a.account_code AS 'Account', 
a.transactionType_desc AS 'TranType', 
a.service_id AS 'ServiceId', 
a.defaultVenueAgentId AS 'AgentID', 
a.Matter_Id AS 'MatterID',
'WA' AS 'State'

FROM   #FooWAAllOther a

WHERE 
site_desc <> 'ANZ'

----Dropping Temporary table

DROP TABLE #FooQLDIpswitch
DROP TABLE #FooQLD
DROP TABLE #FooQLDBrisSuburbs
DROP TABLE #FooQLDGoldCoast
DROP TABLE #FooVICMelbMetro
DROP TABLE #FooNTAll
DROP TABLE #FooNSWRegional
DROP TABLE #FooVICRegional
DROP TABLE #FooQLDSunshine
DROP TABLE #FooTASAll
DROP TABLE #FooWABunbury
DROP TABLE #FooWAPerthMetro
DROP TABLE #FooWAAllOther