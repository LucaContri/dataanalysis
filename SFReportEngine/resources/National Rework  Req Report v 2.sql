USE SSR;

WITH caveats AS ( 

SELECT matter_id, COUNT(*) AS num 
FROM tb_matter m 
INNER JOIN dbo.TB_MATTERSECURITY ms ON m.Matter_Id = ms.matterID 
INNER JOIN dbo.TB_DOCUMENTSECURITY ds ON ms.securityID = ds.securityID 
INNER JOIN dbo.TB_CaveatDocument c ON ds.documentID = c.document_id 
WHERE m.MatterStatus_Id NOT IN ( 9, 10 ) 
GROUP BY matter_id )

SELECT DISTINCT 
m.MatterSSRNumber AS 'SSR#',
s.Site_code AS 'Site', 
a.AccountLong_name AS 'Account', 
m.MatterName AS 'Matter Name', 
la.LoanAccountNumber As 'Loan Account', 
st.MatterStatus_desc AS 'Matter Status', 
CONVERT(VARCHAR,mr.createdDT,103)+' '+ CONVERT(VARCHAR,mr.createdDT,108) AS 'Entered', 
CONVERT(VARCHAR,mr.followUpDT,103)+' '+ CONVERT(VARCHAR,mr.followUpDT,108)  AS 'Due Date', 
DATEDIFF(day,mr.createdDT,GETDATE()) AS 'Requisition Days', 
CASE ISNULL(c.num,0) WHEN 0 THEN 'No' ELSE 'YES' END AS 'Lodged Caveat?', 
tt.TransactionType_Desc AS 'Transaction Type', 
CASE mr.IsClientCausedRework WHEN 0 THEN 'SAIG' ELSE 'Client' END AS 'Matter Marked With', 
'Requisition with ' + CASE mr.IsClientCausedRework WHEN 0 THEN 'SAIG' ELSE 'Client' END + ' (' + CONVERT(VARCHAR,mr.createdDT,103) +' '+ CONVERT(VARCHAR,mr.createdDT,108) +')' AS 'Service Status',
isnull(Stuff((SELECT '|' + LocationDisplay FROM (SELECT  LocationDisplay  FROM TB_RMPacket p  where m.Matter_Id = p.Matter_Id  ) x  For XML PATH ('')),1,1,''),'UNKNOWN') AS 'RM Locations',  
'Rework Queues' AS Queue,
aus.StateShort_desc AS 'State'
  
FROM dbo.TB_MATTER m 
INNER JOIN dbo.TB_WF_INSTANCE wi ON m.Matter_Id = wi.matterID 
INNER JOIN dbo.TB_WF_STATE wfs ON wi.currentStateID = wfs.stateID 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON m.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_MATTERSTATUS st ON m.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON m.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON m.Matter_Id = la.Matter_Id AND la.IsPrimaryAccount = 'Y' 
LEFT JOIN tb_sla sa ON m.Site_Id = sa.Site_Id AND sa.SLAType_Id = 13 
INNER JOIN dbo.TB_MATTERREWORK mr ON m.Matter_Id = mr.matter_id AND mr.CompletedDT IS NULL 
LEFT JOIN caveats c ON c.matter_id = m.matter_id
INNER JOIN dbo.TB_LOCATION lo ON m.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id 

WHERE
mr.CompletedDT IS NULL AND 
NOT (mr.WorkflowInstanceID IS NULL 
AND mr.SecurityID IS NULL) AND 
m.MatterStatus_Id NOT IN (9,10)
AND mr.IsParked = 0


UNION 


SELECT DISTINCT 
t.MatterSSRNumber AS 'SSR#',
s.Site_code AS 'Site', 
a.AccountLong_name AS 'Account', 
t.MatterName AS 'Matter Name', 
la.LoanAccountNumber As 'Loan Account', 
st.MatterStatus_desc AS 'Matter Status', 
CONVERT(VARCHAR,mr.createdDT,103)+' '+ CONVERT(VARCHAR,mr.createdDT,108) AS 'Entered', 
CONVERT(VARCHAR,mr.followUpDT,103)+' '+ CONVERT(VARCHAR,mr.followUpDT,108)  AS 'Due Date', 
DATEDIFF(day,mr.createdDT,GETDATE()) AS 'Requisition Days', 
CASE ISNULL(c.num,0) WHEN 0 THEN 'No' ELSE 'YES' END AS 'Lodged Caveat?', 
tt.TransactionType_Desc AS 'Transaction Type', 
CASE mr.IsClientCausedRework WHEN 0 THEN 'SAIG' ELSE 'Client' END AS 'Matter Marked With', 
'Requisition with ' + CASE mr.IsClientCausedRework WHEN 0 THEN 'SAIG' ELSE 'Client' END + ' (' + CONVERT(VARCHAR,mr.createdDT,103) +' '+ CONVERT(VARCHAR,mr.createdDT,108) +')' AS 'Service Status',
isnull(Stuff((SELECT '|' + LocationDisplay FROM (SELECT  LocationDisplay  FROM TB_RMPacket p  where t.Matter_Id = p.Matter_Id  ) x  For XML PATH ('')),1,1,''),'UNKNOWN') AS 'RM Locations',  
'Rework Queues' AS Queue,
aus.StateShort_desc AS 'State'

from 
dbo.TB_MATTER t 
INNER JOIN dbo.TB_WF_INSTANCE wi ON t.Matter_Id = wi.matterID 
INNER JOIN dbo.TB_WF_STATE wfs ON wi.currentStateID = wfs.stateID 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON t.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_MATTERSTATUS st ON t.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON t.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON t.Matter_Id = la.Matter_Id AND la.IsPrimaryAccount = 'Y' 
INNER JOIN dbo.TB_LOCATION lo ON t.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id
LEFT JOIN tb_sla sa ON t.Site_Id = sa.Site_Id AND sa.SLAType_Id = 13 
LEFT JOIN dbo.TB_MATTERREWORK mr ON t.Matter_Id = mr.matter_id AND mr.CompletedDT IS NULL 
LEFT JOIN caveats c ON c.matter_id = t.matter_id 

inner join (

SELECT DISTINCT 
m.MatterSSRNumber AS 'SSR#',
MAX(mr.createdDT) AS 'Entered'

FROM 
dbo.TB_MATTER m 
INNER JOIN dbo.TB_WF_INSTANCE wi ON m.Matter_Id = wi.matterID 
INNER JOIN dbo.TB_WF_STATE wfs ON wi.currentStateID = wfs.stateID 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON m.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_MATTERSTATUS st ON m.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON m.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON m.Matter_Id = la.Matter_Id AND la.IsPrimaryAccount = 'Y' 
INNER JOIN dbo.TB_LOCATION lo ON m.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id
LEFT JOIN tb_sla sa ON m.Site_Id = sa.Site_Id AND sa.SLAType_Id = 13 
LEFT JOIN dbo.TB_MATTERREWORK mr ON m.Matter_Id = mr.matter_id AND mr.CompletedDT IS NULL 
LEFT JOIN caveats c ON c.matter_id = m.matter_id 

WHERE
mr.CompletedDT IS NULL AND 
NOT (mr.WorkflowInstanceID IS NULL AND 
mr.SecurityID IS NULL) 
AND m.MatterStatus_Id NOT IN (9,10) AND 
mr.IsParked = 1

GROUP BY MatterSSRNumber

) tm on t.MatterSSRNumber = tm.SSR# and mr.createdDT = tm.Entered and mr.CompletedDT IS NULL AND  NOT (mr.WorkflowInstanceID IS NULL AND mr.SecurityID IS NULL) AND t.MatterStatus_Id NOT IN (9,10) AND mr.IsParked = 1


UNION 


SELECT DISTINCT 
m.MatterSSRNumber AS 'SSR#', 
s.Site_code AS 'Site',
a.AccountLong_name AS 'Account', 
m.MatterName AS 'MatterName',
la.LoanAccountNumber AS 'Loan Account', 
st.MatterStatus_desc AS 'Matter Status',  
CONVERT(VARCHAR,ser.Actioned_datetime,103)+' '+ CONVERT(VARCHAR,ser.Actioned_datetime,108) AS 'Entered', 
CONVERT(VARCHAR,req.DueDate,103)+' '+ CONVERT(VARCHAR,req.DueDate,108)AS 'Due Date', 
DATEDIFF(day,ser.Ordered_datetime,GETDATE()) AS 'Requisition Days',
CASE ISNULL(c.num,0) WHEN 0 THEN 'No' ELSE 'YES' END AS 'Lodged Caveat?', 
tt.TransactionType_Desc AS 'Transaction Status',  
CASE req.PartyAtFault WHEN 'Client' THEN 'Client' WHEN 'OtherParty' THEN 'OtherParty' WHEN 'Espreon' THEN 'SAIG' WHEN 'SAIG' THEN 'SAIG' END AS 'Matter Marked With', 
'Requisition with ' + req.PartyAtFault + ' (' + CONVERT(VARCHAR,ser.Actioned_datetime,103)+' '+ CONVERT(VARCHAR,ser.Actioned_datetime,108) +')' AS 'Service Status',
isnull(Stuff((SELECT '|' + LocationDisplay FROM (SELECT  LocationDisplay  FROM TB_RMPacket p  where m.Matter_Id = p.Matter_Id  ) x  For XML PATH ('')),1,1,''),'UNKNOWN') as RMLocations,  
'Requisition Queues' AS Queue,
aus.StateShort_desc AS 'State'

FROM dbo.TB_MATTER m 
INNER JOIN dbo.TB_MATTERSTATUS st ON m.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON m.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON m.Matter_Id = la.Matter_Id 
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_REQUISITION req ON ser.Service_Id = req.Service_Id 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON m.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_LOCATION lo ON m.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id

LEFT JOIN caveats c ON c.matter_id = m.matter_id 

WHERE
la.IsPrimaryAccount = 'Y' AND 
ser.ServiceStatus_Id = 3 AND 
m.MatterStatus_Id NOT IN (9,10) AND 
req.IsParked = 0


UNION


SELECT DISTINCT 
t.MatterSSRNumber AS 'SSR#', 
s.Site_code AS 'Site',
a.AccountLong_name AS 'Account', 
t.MatterName AS 'MatterName',
la.LoanAccountNumber AS 'Loan Account', 
st.MatterStatus_desc AS 'Matter Status',  
CONVERT(VARCHAR,ser.Actioned_datetime,103)+' '+ CONVERT(VARCHAR,ser.Actioned_datetime,108) AS 'Entered', 
CONVERT(VARCHAR,req.DueDate,103)+' '+ CONVERT(VARCHAR,req.DueDate,108) AS 'Due Date', 
DATEDIFF(day,ser.Ordered_datetime,GETDATE()) AS 'Requisition Days',
CASE ISNULL(c.num,0) WHEN 0 THEN 'No' ELSE 'YES' END AS 'Lodged Caveat?', 
tt.TransactionType_Desc AS 'Transaction Status',  
CASE req.PartyAtFault WHEN 'Client' THEN 'Client' WHEN 'OtherParty' THEN 'OtherParty' WHEN 'Espreon' THEN 'SAIG' WHEN 'SAIG' THEN 'SAIG' END AS 'Matter Marked With', 
'Requisition with ' + req.PartyAtFault + ' ('+ CONVERT(VARCHAR,ser.Actioned_datetime,103)+' '+ CONVERT(VARCHAR,ser.Actioned_datetime,108) +')' AS 'Service Status',
isnull(Stuff((SELECT '|' + LocationDisplay FROM (SELECT  LocationDisplay  FROM TB_RMPacket p  where t.Matter_Id = p.Matter_Id  ) x  For XML PATH ('')),1,1,''),'UNKNOWN') as RMLocations,  
'Requisition Queues' AS Queue,
aus.StateShort_desc AS 'State'


FROM dbo.TB_MATTER t 
INNER JOIN dbo.TB_MATTERSTATUS st ON t.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON t.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON t.Matter_Id = la.Matter_Id 
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_REQUISITION req ON ser.Service_Id = req.Service_Id 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON t.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_LOCATION lo ON t.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id
LEFT JOIN caveats c ON c.matter_id = t.matter_id 


inner join (

SELECT DISTINCT 
m.MatterSSRNumber AS 'SSR#',
MAX(ser.Actioned_datetime) AS 'Entered'

  
FROM dbo.TB_MATTER m 
INNER JOIN dbo.TB_MATTERSTATUS st ON m.MatterStatus_Id = st.MatterStatus_Id 
INNER JOIN dbo.TB_ACCOUNT a ON m.Account_Id = a.Account_Id 
INNER JOIN dbo.TB_SITE s ON a.Site_Id = s.Site_Id 
INNER JOIN dbo.TB_LOANACCOUNT la ON m.Matter_Id = la.Matter_Id 
INNER JOIN dbo.TB_SERVICE ser ON la.Matter_Id = ser.Matter_Id 
INNER JOIN dbo.TB_REQUISITION req ON ser.Service_Id = req.Service_Id 
INNER JOIN dbo.TB_TRANSACTIONTYPE tt ON m.TransactionType_Id = tt.TransactionType_Id 
INNER JOIN dbo.TB_LOCATION lo ON m.TransactionState_Id = lo.AustState_Id
INNER JOIN dbo.TB_AUSTSTATE aus ON lo.Location_Id = aus.DefaultLocation_Id
LEFT JOIN caveats c ON c.matter_id = m.matter_id 

WHERE 
la.IsPrimaryAccount = 'Y' AND 
ser.ServiceStatus_Id = 3 AND 
m.MatterStatus_Id NOT IN (9,10) AND 
req.IsParked = 1

GROUP BY MatterSSRNumber

) tm on t.MatterSSRNumber = tm.SSR# and ser.Actioned_datetime = tm.Entered and la.IsPrimaryAccount = 'Y' AND ser.ServiceStatus_Id = 3 AND t.MatterStatus_Id NOT IN (9,10) AND req.IsParked = 1