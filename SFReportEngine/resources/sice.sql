# SiCE replica as 20/06/17

(select * from sice.sice_tables);

(SELECT * 
from sice.sice_tables 
where ToSync=1 
and date_add(LastSyncDate, interval MinSecondsBetweenSyncs second)<utc_timestamp());

(select count(*)
from sice.tbl_persone p
where p.interna = 1
and p.storico = 0 );

# Resources & Users
(select 
	p.pk_persona as 'SICE Id',
    p.username as 'SICE Username',
    p.titolo as 'Title',
    p.nome as 'First Name',
    p.cognome as 'Last Name',
    addr.indirizzo as 'Address', 
    addr.comune as 'City', 
    prov.nome as 'Province',
    prov.regione as 'Country Region',
    country.nome as 'Country',
	addr.cap as 'PostCode',
    p.data_nascita as 'DoB',
    p.titolo_studio as 'Qualification',
    l.nome as 'Language',
    #u.descrizione as 'Office',
    p.note as 'Notes',
    group_concat(distinct ru.descrizione order by ru.descrizione) as 'Roles',
    if(p.interna, 'Employee', 'Contractor') as 'Resource Type',
    not p.storico  as 'Is Active',
    p.ispettore as 'Is Auditor',
	p.Username is not null as 'Is User',
    r.Id is not null as 'Already in Compass',
    r.Id as 'Compass Resource Id'
from sice.tbl_persone p
	left join sice.tbl_lingue l on p.fk_lingua = l.pk_lingua
    left join salesforce.resource__c r on concat(p.nome, ' ', p.cognome) = r.Name
	#left join sice.tbl_tipi_contratti tc on p.fk_tipo_contratto = tc.pk_tipo_contratto
	#left join sice.tbl_aziende a on p.fk_azienda_contratto = a.pk_azienda
	left join sice.tbl_ruoli_persone rp on rp.fk_persona = p.pk_persona
	left join sice.tbl_ruoli ru on rp.fk_ruolo = ru.pk_ruolo
	#left join sice.tbl_persone_aree_geografiche pag on pag.fk_persona = p.pk_persona
	#left join sice.tbl_aree_geografiche ag on pag.fk_area_geografica = ag.pk_area_geografica
    left join sice.tbl_recapiti addr on addr.fk_persona = p.pk_persona
    left join sice.tbl_nazioni country on addr.fk_nazione = country.pk_nazione
    left join sice.tbl_provincie prov on addr.fk_provincia = prov.pk_provincia
    #left join sice.tbl_responsabili resp on p.pk_persona = resp.fk_persona
    #left join sice.tbl_uffici u on resp.fk_ufficio = u.pk_ufficio
where p.interna = 1 or p.ispettore = 1 or (p.username is not null and trim(p.username) != '')
group by p.pk_persona);

# Standards & Codes
select
	'Standard' as 'Record Type',
    '' as 'SubType',
    n.pk_norma as 'SICE Id',
    n.codice as 'Name',
    n.codice_sai as 'Code',
    not n.obsoleta as 'Is Active',
    'TBA' as 'Already in Compass',
    'TBA' as 'Compass Item Id',
    'TBA' as 'Compass Item Name',
    'TBA' as 'Compass Item Description'
from sice.tbl_norme n
union all
select 
	'Code' as 'Record Type',
    'NACE' as 'SubType',
	sn.pk_settore_nace as 'SICE Id',
    sn.descrizione as 'Name',
    sn.codice as 'Code',
    1 as 'Is Active',
    c.Id is not null as 'Already in Compass',
    ifnull(c.Id, 'TBA') as 'Compass Item Id',
    ifnull(c.Name, 'TBA') as 'Compass Item Name',
    ifnull(c.Code_Description__c, 'TBA') as 'Compass Item Description'
from sice.tbl_settori_nace sn
left join salesforce.code__c c on c.Name = concat('NACE: ',trim(sn.codice))
union all
# EA Accredia Codes - http://www.accredia.it/accredia_tablesett.jsp?ID_LINK=284&area=7
(select 
	'Code' as 'Record Type',
    if(sea.codice like '%BRC%', 'BRC', if(sea.codice like '%IFS%', 'IFS', if(sea.codice like '%ETS%', 'ETS', if(sea.codice like '%Unilever%', 'Unilever', 'EA')))) as 'SubType',
	sea.pk_settore_ea as 'SICE Id',
    sea.descrizione as 'Name',
    sea.codice as 'Code',
    1 as 'Is Active',
    c.Id is not null as 'Already in Compass',
    ifnull(c.Id, 'TBA') as 'Compass Item Id',
    ifnull(c.Name, 'TBA') as 'Compass Item Name',
    ifnull(c.Code_Description__c, 'TBA') as 'Compass Item Description'
from sice.tbl_settori_ea sea
left join salesforce.code__c c on (c.Name = concat('BRC: BRC',replace(replace(sea.Codice,'03/BRC 0',''), '03/BRC ', '')) and sea.Codice like '%BRC%')
	or (c.Name = concat('IFS: IFS',replace(sea.Codice,'03/IFS ','')) and sea.Codice like '%IFS%')
);

# Accreditation Bodies
(select 
	e.pk_ente as 'SICE Id',
    e.nome as 'Accreditation Body',
    'TBA' as 'Already in Compass',
    'TBA' as 'Compass Item Id',
    'TBA' as 'Compass Item Name',
    'TBA' as 'Compass Item Description'
from sice.tbl_accreditamenti a
left join sice.tbl_enti e on a.fk_ente = e.pk_ente 
group by e.pk_ente);

# Competencies
(select 
	'Competency Standard' as 'Record Type',
    a.pk_abilitazione as 'SICE Id',
    concat(p.nome, ' ', p.cognome) as 'Resource',
    a.fk_persona as 'SICE Resource Id',
    n.codice as 'Standard',
    a.fk_norma as 'SICE Standard Id',
    '' as 'Code',
    '' as 'Code Scheme',
    '' as 'SICE Code Id',
    la.livello_sai as 'Rank',
    a.note as 'Notes'
from sice.tbl_abilitazioni a
	left join sice.tbl_persone p on a.fk_persona = p.pk_persona
	left join sice.tbl_norme n on a.fk_norma = n.pk_norma
	left join sice.tbl_livelli_abilitazioni la on a.fk_livello_abilitazione = la.pk_livello_abilitazione
group by a.pk_abilitazione)
union all
(select 
	'Competency Code' as 'Record Type',
	asea.pk_abilitazione_settore_ea as 'SICE Id',
    concat(p.nome, ' ', p.cognome) as 'Resource',
    a.fk_persona as 'SICE Resource Id',
    n.codice as 'Standard',
    a.fk_norma as 'SICE Standard Id',
    sea.codice as 'Code',
    if(sea.codice like '%BRC%', 'BRC', if(sea.codice like '%IFS%', 'IFS', if(sea.codice like '%ETS%', 'ETS', if(sea.codice like '%Unilever%', 'Unilever', 'EA')))) as 'Code Scheme',
    sea.pk_settore_ea as 'SICE Code Id',
    la.livello_sai as 'Rank',
    asea.note as 'Notes'
from sice.tbl_abilitazioni_settori_ea asea
	left join sice.tbl_abilitazioni a on asea.fk_abilitazione = a.pk_abilitazione
    left join sice.tbl_persone p on a.fk_persona = p.pk_persona
	left join sice.tbl_norme n on a.fk_norma = n.pk_norma
	left join sice.tbl_livelli_abilitazioni la on a.fk_livello_abilitazione = la.pk_livello_abilitazione
	left join sice.tbl_settori_ea sea on asea.fk_settore_ea = sea.pk_settore_ea
#where asea.non_qualificante = 1
group by asea.pk_abilitazione_settore_ea)
union all
(select 
	'Competency NACE Code' as 'Record Type',
	asn.pk_abilitazione_settore_nace as 'SICE Id',
    concat(p.nome, ' ', p.cognome) as 'Resource',
    a.fk_persona as 'SICE Resource Id',
    n.codice as 'Standard',
    a.fk_norma as 'SICE Standard Id',
    sn.codice as 'Code',
    'NACE' as 'Code Scheme',
    sn.pk_settore_nace as 'SICE Code Id',
    la.livello_sai as 'Rank',
    asn.note as 'Notes'
from sice.tbl_abilitazioni_settori_nace asn
	left join sice.tbl_abilitazioni a on asn.fk_abilitazione = a.pk_abilitazione
    left join sice.tbl_persone p on a.fk_persona = p.pk_persona
	left join sice.tbl_norme n on a.fk_norma = n.pk_norma
	left join sice.tbl_livelli_abilitazioni la on a.fk_livello_abilitazione = la.pk_livello_abilitazione
	left join sice.tbl_settori_nace sn on asn.fk_settore_nace = sn.pk_settore_nace
group by asn.pk_abilitazione_settore_nace);

# Clients & Sites
(select
	ifnull(gr.pk_gruppo_aziendale, '') as 'SICE Corporate Client Id' ,
    ifnull(trim(gr.nome), '') as 'Corporate Client Name',
	a.pk_azienda as 'SICE Client Id', 
    a.ragsoc as 'Client Name', 
    fg.forma as 'Client Company Type',
    a.partita_iva as 'Client Tax Id',
    msa.descrizione as 'Client Industry',
    sa.settore as 'Client Industry sub',
	a.categoria as 'Client Category',
    ta.tipo as 'Client Type',
    a.note as 'Client Notes',
    s.pk_stabilimento as 'SICE Site Id' ,
    ifnull(s.descrizione, '') as 'Site Type',
    ifnull(s.sede_legale, '') as 'Site H/O',
    ifnull(s.sede_amministrativa, '') as 'Site Financial Statement Site',
    ifnull(s.unita_operativa, '') as 'Site Operational Site',
    ifnull(s.dipendenti, '') as 'Site # Employees',
    ifnull(not s.storico, '') as 'Site Is Active',
    ifnull(s.note, '') as 'Site Notes',
    ifnull(max(if(tr.descrizione_en ='Address', trim(r.indirizzo), null)), '')  as 'Site Address',
    ifnull(max(if(tr.descrizione_en ='Address', trim(r.comune), null)), '') as 'Site City' ,
    ifnull(p.nome, '') as 'Site Province',
    ifnull(p.regione, '') as 'Site Region',
    ifnull(n.nome, '') as 'Site Country',
    max(if(tr.descrizione_en ='Address', trim(replace(r.cap, '.','')), null)) as 'Site PostCode',
    group_concat(distinct if(tr.descrizione_en ='E-mail', if(trim(r.indirizzo)='',null,trim(r.indirizzo)), null)) as 'Site Emails',
    ifnull(trim(replace(group_concat(distinct if(tr.descrizione_en ='Phone', if(trim(r.indirizzo)='',null,trim(r.indirizzo)), null)),'.','')),'') as 'Site Telephones',
    ifnull(trim(replace(group_concat(distinct if(tr.descrizione_en ='GSM', if(trim(r.indirizzo)='',null,trim(r.indirizzo)), null)),'.','')),'') as 'Site Mobiles',
    ifnull(trim(group_concat(distinct if(tr.descrizione_en ='Web', if(trim(r.indirizzo)='',null,trim(r.indirizzo)), null))), '') as 'Site Websites',
    ifnull(trim(replace(group_concat(distinct if(tr.descrizione_en ='Fax', if(trim(r.indirizzo)='',null,trim(r.indirizzo)), null)),'.','')),'') as 'Site Faxes'
from sice.tbl_aziende a
	left join sice.tbl_aziende_gruppi agr on agr.fk_azienda = a.pk_azienda
    left join sice.tbl_gruppi_aziendali gr on agr.fk_gruppo_aziendale = gr.pk_gruppo_aziendale
	left join sice.tbl_stabilimenti s on s.fk_azienda = a.pk_azienda
	left join sice.tbl_settori_aziende sa on a.fk_settore_azienda = sa.pk_settore_azienda
	left join sice.tbl_macrosettori msa on a.fk_macrosettore = msa.pk_macrosettore
	left join sice.tbl_tipi_aziende ta on a.fk_tipo_azienda = ta.pk_tipo_azienda
	left join sice.tbl_forme_giuridiche fg on a.fk_forma_giuridica = fg.pk_forma_giuridica
	left join sice.tbl_aree_geografiche ag on a.fk_area_geografica = ag.pk_area_geografica
    left join sice.tbl_recapiti r on r.fk_stabilimento = s.pk_stabilimento
    left join sice.tbl_tipi_recapiti tr on r.fk_tipo_recapito = tr.pk_tipo_recapito 
    left join sice.tbl_nazioni n on r.fk_nazione = n.pk_nazione 
    left join sice.tbl_provincie p on r.fk_provincia = p.pk_provincia 

#where 
#ta.tipo in ('Cliente') # ('Cliente potenziale', 'Cliente formazione', 'Cliente pre-audit') ('Fornitore','Altro') and 
group by a.pk_azienda, s.pk_stabilimento);

# Certifications & Site Certifications
(select 
	c.pk_certificato as 'SICE Certificate Id',
    c.codice as 'Certificate No',
    c.codice_iatf as 'Certificate IATF No', 
    enti.nome as 'Accreditation Body',
    a.ragsoc as 'Client Name',
    a.pk_azienda as 'SICE Client Id',
    n.codice as 'Standard',
    group_concat(distinct if(csea.fk_tipo_settore_ea=1, sea.codice, null)) as 'Primary EA Code',
    group_concat(distinct if(csea.fk_tipo_settore_ea=2, sea.codice, null)) as 'Secondary EA Codes',
    group_concat(distinct if(csn.fk_tipo_settore_nace =1, sn.codice, null)) as 'Primary NACE Code',
    group_concat(distinct if(csn.fk_tipo_settore_nace =2, sn.codice, null)) as 'Secondary NACE Codes',
    c.data_prima_emissione as 'Certificate Originally Registered Date',
    c.data_scadenza as 'Certificate Expiry Date',
    c.data_scadenza_reale as 'Certificate Actual Expiry Date',
    c.data_fine_validita as 'Certificate Valid Until Date',
    mr.descrizione as 'DeRegistration Reason',
    mr.descrizione_accredia as 'DeRegistration Reason Accredia',
    gr.descrizione 'Gravita\' Ritiro', 
    pc.nome_en as 'Certificate Last Event',
    ic.data as 'Certificate Last Event Date',
    concat(p.nome, ' ',p.cognome) as 'Certificate Last Event Done By',
	sc.pk_stabilimento_certificato as 'SICE Site Certificate Id',
    s.pk_stabilimento as 'SICE Site Id',
    s.descrizione as 'Site Description',
    ifnull(sc.linea_prodotto_en, sc.linea_prodotto_it) as 'Scope',
    sc.data_emissione as 'Site Certification Registered Date',
    sc.data_ritiro as 'Site Certification DeRegistered Date',
    sc.ritirato as 'DeRegistered', 
    sc.sospeso as 'Suspended', 
    sc.rischio as 'Risk Level',
    c.importato as 'Imported'
from sice.tbl_certificati c
	left join sice.tbl_accreditamenti acc on acc.fk_certificato = c.pk_certificato
    left join sice.tbl_enti enti on acc.fk_ente = enti.pk_ente
	left join sice.tbl_iter_certificati ic on c.fk_last_iter = ic.pk_iter_certificato 
	left join sice.tbl_passi_certificati pc on ic.fk_passo_certificato = pc.pk_passo_certificato
    left join sice.tbl_persone p on ic.fk_persona = p.pk_persona
	left join sice.tbl_aziende a on c.fk_azienda = a.pk_azienda
    left join sice.tbl_stabilimenti_certificati sc on sc.fk_certificato = c.pk_certificato
    left join sice.tbl_certificati_settori_ea csea on csea.fk_certificato = c.pk_certificato
    left join sice.tbl_settori_ea sea on csea.fk_settore_ea = sea.pk_settore_ea
    left join sice.tbl_certificati_settori_nace csn on csn.fk_certificato = c.pk_certificato
    left join sice.tbl_settori_nace sn on csn.fk_settore_nace = sn.pk_settore_nace
    left join sice.tbl_stabilimenti s on sc.fk_stabilimento = s.pk_stabilimento
    left join sice.tbl_norme n on c.fk_norma = n.pk_norma
    left join sice.tbl_motivi_ritiri mr on c.fk_motivo_ritiro = mr.pk_motivo_ritiro
    left join sice.tbl_gravita_ritiri gr on c.fk_gravita_ritiro = gr.pk_gravita_ritiro
#where c.codice = 'TS 35'
group by c.pk_certificato, sc.pk_stabilimento_certificato
);

SELECT DISTINCT TABLE_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME IN ('fk_stabilimento')
		
        AND TABLE_SCHEMA='sice';
        
describe sice.tbl_tour ;

use sice;
create index index_iter_pratiche_pk on sice.tbl_iter_pratiche(pk_iter_pratica);
create index index_pratiche_fk_last_iter on sice.tbl_pratiche (fk_last_iter);

# Audits
explain
(select 
	p.pk_pratica as 'SICE Audit Id',
    v.pk_visita as 'SICE Visit Id' ,
    p.fk_certificato as 'SICE Certificate Id',
    a.ragsoc as 'Client',
    n.codice as 'Standard',
    tv.descrizione_en as 'WI Type',
    p.follow_up as 'Follow Up',
    pp.nome_en as 'Status',
    v.data_principale as 'Audit Date',
    t.data_effettuazione as 'Visit Date',
    pv.nome_en as 'Visit Status',
    gviv.coordinatore as 'Lead Auditor',
    ri.ruolo as 'Role' ,
    concat(auditor.nome, ' ', auditor.cognome) as 'Auditor',
    gvig.giornate as 'Days'
from sice.tbl_pratiche p 
	left join sice.tbl_visite v on p.fk_visita = v.pk_visita
    left join sice.tbl_tipi_visite tv on p.fk_tipo_visita = tv.pk_tipo_visita
    left join sice.tbl_iter_pratiche ip on p.fk_last_iter = ip.pk_iter_pratica
    left join sice.tbl_passi_pratiche pp on ip.fk_passo_pratica = pp.pk_passo_pratica
    left join sice.tbl_iter_visite iv on v.fk_last_iter = iv.pk_iter_visita
    left join sice.tbl_passi_visite pv on iv.fk_passo_visita = pv.pk_passo_visita
    left join sice.tbl_gvi_visite gviv on gviv.fk_visita = v.pk_visita
    left join sice.tbl_persone auditor on gviv.fk_persona = auditor.pk_persona
    left join sice.tbl_gvi_giorni gvig on gvig.fk_gvi_visita = gviv.pk_gvi_visita
    left join sice.tbl_ruoli_ispettori ri on gvig.fk_ruolo_ispettore = ri.pk_ruolo_ispettore
    left join sice.tbl_norme n on p.fk_norma = n.pk_norma
    left join sice.tbl_certificati cert on cert.pk_certificato = p.fk_certificato
    left join sice.tbl_aziende a on cert.fk_azienda = a.pk_azienda);

select * from sice.tbl_fatture f order by data