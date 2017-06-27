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

# Competencies
select * from sice.tbl_norme;
select * from salesforce.standard__c where Name like '%9001%';

select * from sice.tbl_tipi_norme;
select * from sice.tbl_tipi_settori_ea ;
select * from sice.tbl_tipi_settori_nace ;
select * from sice.tbl_settori_nace ;

select * from sice.tbl_ruoli_ispettori ;
select * from sice.tbl_abilitazioni_settori_ea;

SELECT DISTINCT TABLE_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME IN ('pk_utente')
        AND TABLE_SCHEMA='sice';
        
select * from sice.tbl_recapiti;
select * from sice.tbl_responsabili;
select * from sice.tbl_sto_persone;
select * from sice.tbl_uffici