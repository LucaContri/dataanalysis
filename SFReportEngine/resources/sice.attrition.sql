/* Revenue Lost from De-Registered licences
	The ACV of a licence is assumed to be the no. of audit days delivered during last completed audit. 
	Assumptions: 
		- If last copleted audit does not exits, assuming ACV = 0 days
		- If site country = null assuming Italy */
(SELECT 
	CAST('SICE' AS VARCHAR) AS "Source",
	CAST('Revenue Lost (Audit)' AS VARCHAR) AS "Metric",
	CAST('EMEA' AS VARCHAR) AS "Region",
	COALESCE(country.nome,'Italy') AS "Country",
	CAST('Management Systems' AS VARCHAR) AS "Business Line",
	CAST(CASE WHEN EXTRACT(MONTH FROM ic.data)<7 
		THEN EXTRACT(YEAR FROM ic.data)
		ELSE EXTRACT(YEAR FROM ic.data)+1
	END AS VARCHAR) AS "FY",
	TO_CHAR(ic.data, 'YYYY MM') AS "Period",
	0.0 AS "Value",
	CAST('N/A' AS VARCHAR) AS "Unit",
	0.0 AS "Original Value",
	CAST('N/A' AS VARCHAR) AS "Original Unit",
	CAST('N/A' AS VARCHAR) AS "ACV Calculation",
	SUM(ca.giornate)AS "ACV - Days",
	CAST(a.ragsoc AS VARCHAR) AS "Name",
	CAST(c.pk_certificato AS VARCHAR)AS "Id",
	CAST(mr.descrizione_accredia AS VARCHAR) AS "Notes",
	n.codice AS "Primary Standard",
	1 AS "Include"
FROM tbl_iter_certificati ic 
	INNER JOIN tbl_certificati c ON ic.fk_certificato = c.pk_certificato
	LEFT JOIN tbl_motivi_ritiri mr ON c.fk_motivo_ritiro = mr.pk_motivo_ritiro
	INNER JOIN tbl_norme n ON c.fk_norma = n.pk_norma 
	INNER JOIN tbl_aziende a ON c.fk_azienda = a.pk_azienda 
	LEFT JOIN (SELECT (array_agg(t.pk_pratica))[1] AS "pk_pratica", t.fk_certificato, (array_agg(t.data))[1] AS "data" FROM
				(SELECT p.pk_pratica, p.fk_certificato, p.data
				FROM tbl_pratiche p 
				INNER JOIN tbl_iter_pratiche ip ON ip.pk_iter_pratica = p.fk_lASt_iter  
				WHERE  
				ip.fk_pASso_pratica = 16
				AND p.follow_up = false
				ORDER BY p.data desc) t
				GROUP BY t.fk_certificato
			) tbl_pratiche_completate ON tbl_pratiche_completate.fk_certificato  =c.pk_certificato
	LEFT JOIN tbl_campionamenti ca ON ca.fk_pratica = tbl_pratiche_completate.pk_pratica 
	LEFT JOIN tbl_stabilimenti site ON ca.fk_stabilimento = site.pk_stabilimento
	LEFT JOIN tbl_recapiti address ON site.pk_stabilimento = address.fk_stabilimento AND address.fk_tipo_recapito = 1
	LEFT JOIN tbl_nazioni country ON address.fk_nazione = country.pk_nazione
WHERE
	ic.fk_pASso_certificato = 10
	AND ic.data 
	BETWEEN CAST(CASE WHEN EXTRACT(MONTH FROM now())<7 THEN CAST(EXTRACT(YEAR FROM now())-1 AS VARCHAR) ELSE CAST(EXTRACT(YEAR FROM now()) AS VARCHAR) END || '-07-01' AS timestamp)
	AND CAST(CASE WHEN EXTRACT(MONTH FROM now())<7 THEN CAST(EXTRACT(YEAR FROM now()) AS VARCHAR) ELSE CAST(EXTRACT(YEAR FROM now())+1 AS VARCHAR) END || '-06-30' AS timestamp)
GROUP BY "Metric", "Region","Country", "FY","Period","Name","Id","Notes", "Primary Standard", "Include", c.pk_certificato)
UNION ALL
(SELECT 
	CAST('SICE' AS VARCHAR) AS "Source",
	CAST('Confirmed Days' AS VARCHAR) AS "Metric",
	CAST('EMEA' AS VARCHAR) AS "Region",
	COALESCE(country.nome,'Italy') AS "Country",
	CAST('Management Systems' AS VARCHAR) AS "Business Line",
	CAST('PFY' AS VARCHAR) AS "FY",
	CAST('' AS VARCHAR) AS "Period",
	CAST(SUM(ca.giornate)AS NUMERIC)  AS "Value",
	CAST('Days' AS VARCHAR) AS "Unit",
	CAST(SUM(ca.giornate)AS NUMERIC) AS "Original Value",
	CAST('Days' AS VARCHAR) AS "Original Unit",
	CAST('N/A' AS VARCHAR) AS "ACV Calculation",
	SUM(ca.giornate)  AS "ACV - Days",
	CAST('N/A' AS VARCHAR) AS "Name",
	CAST('N/A' AS VARCHAR) AS "Id",
	CAST('N/A' AS VARCHAR) AS "Notes",
	CAST('N/A' AS VARCHAR) AS "Primary Standard",
	1 AS "Include"
FROM tbl_pratiche p
	INNER JOIN tbl_iter_pratiche ip ON ip.pk_iter_pratica = p.fk_lASt_iter  
	LEFT JOIN tbl_campionamenti ca ON ca.fk_pratica = p.pk_pratica 
	LEFT JOIN tbl_stabilimenti site ON ca.fk_stabilimento = site.pk_stabilimento
	LEFT JOIN tbl_recapiti address ON site.pk_stabilimento = address.fk_stabilimento AND address.fk_tipo_recapito = 1
	LEFT JOIN tbl_nazioni country ON address.fk_nazione = country.pk_nazione
WHERE  
	ip.fk_pASso_pratica = 16
	AND p.data 
		BETWEEN CAST(CASE WHEN EXTRACT(MONTH FROM now())<7 THEN CAST(EXTRACT(YEAR FROM now())-2 AS VARCHAR) ELSE CAST(EXTRACT(YEAR FROM now())-1 AS VARCHAR) END || '-07-01' AS timestamp)
		AND CAST(CASE WHEN EXTRACT(MONTH FROM now())<7 THEN CAST(EXTRACT(YEAR FROM now())-1 AS VARCHAR) ELSE CAST(EXTRACT(YEAR FROM now()) AS VARCHAR) END || '-06-30' AS timestamp)
GROUP BY "Metric", "Region", "Country", "Business Line", "FY", "Period");