USE oscar

DECLARE @FromDate DATETIME
DECLARE @ToDate DATETIME

-- @ToDo: Should be the day prior
SET @FromDate = '04/29/2015 00:00:00'
-- @ToDo: Should be the execution day
SET @ToDate = '04/30/2015 00:00:00'

SELECT    
'NonConformingItem' AS 'QualityCategoryRoot',            
oe.Created AS 'CreatedDateTime',  
'N/A' AS 'Site',        
oe.OrderID AS 'Account',   
oe.ReporterUserName AS 'CreatedBy',
'N/A' AS 'AusState',  
co.CertificateOrderID AS 'SSRNumber',
'N/A' AS 'LoanNumber',
'N/A' AS 'MatterName' ,    
'N' AS 'IsMatterWithClient',
'Espreon' AS 'WhosAtFault',
'N' AS 'IsSLAMissed',
'N' AS 'IsWorkflowPaused',
'Y' AS 'IsAvoidable',      
oe.ErrorUserName AS 'CausedBy',          
'Process Error' AS 'L2Description',
oe.Error AS 'L3Description',
act.ProductName AS 'L4Description',
'Re-Training / Issue Highlighted' AS 'L5Description',
'Low' AS 'RiskSeverity',
'Near Miss' AS 'Impact',
'0' AS 'ImpactValue',
' | ' + oe.Error + + oe.AdditonalComments AS 'Comments',  
'' AS 'ID'

FROM          
OperatorErrors oe with(nolock)      
inner join  CertificateOrders co with(nolock) ON oe.CertificateOrderID = co.CertificateOrderID      
inner join  AuthorityCertificateTypes act with(nolock) on co.AuthorityCertificateTypeID = act.AuthorityCertificateTypeID
left outer join CertificateBills cb with(nolock) on co.CertificateOrderID = cb.CertificateOrderID 

WHERE 
oe.Created BETWEEN @FromDate AND @ToDate      

ORDER BY oe.OrderID