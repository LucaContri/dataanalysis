drop function `analytics`.`getMcDonaldsAuditTypeFromStandard`;

DELIMITER $$
CREATE FUNCTION `analytics`.`getMcDonaldsAuditTypeFromStandard`(standard varchar(256)) RETURNS VARCHAR(64)
BEGIN
	DECLARE audit_type VARCHAR(64) DEFAULT null;
    SET audit_type = 
			(SELECT 
				if (standard like '%10 Core%', '10 CORE',
				if (standard like '%Distributor Quality Management Process%' or standard like '%DQMP%', 'DQMP',
				if (standard like '%Bolt On%' , 'GFSI+A or GFSI+A (BRC) or GFSI+A (FSSC) orGFSI+A(IFS)',
				if (standard like '%SQMS%', 'SQMS or FSQMS',
				if (standard like '%Good Agricultral Practice%' , 'GAP',
				if (standard like '%Egg Laying Farms%' , 'HEN HOUSE',
                if (standard like '%Cattle Slaughter & Deboning%' or standard like '%Pig Slaughter & Deboning%' or standard like '%Chicken Slaughter & Deboning%' , 'PROTEIN Sl & Db',
				if (standard like '%Cattle Slaughter%' or standard like '%Pig Slaughter%' or standard like '%Chicken Slaughter%' , 'PROTEIN (Sl)',
				if (standard like '%Cattle Deboning%' or standard like '%Pig Deboning%' or standard like '%Chicken Deboning%' , 'PROTEIN (Db)',
				if (standard like '%Supplier Workplace Accountability%' or standard like '%SWA%', 'SWA',
				'?'
            )))))))))));
    RETURN audit_type ;
 END$$
DELIMITER ;

select mcds.Id, mcds.Name, getMcDonaldsAuditTypeFromStandard(mcds.Name) as 'Audit Type' from salesforce.McDonalds_Standards mcds;

select 
	client.Name as 'Client',
    site.Name as 'Site',
    ccs.Name as 'Site Country', 
    site.Time_Zone__c as 'Site Timezone',
    scsp.Id as 'Site Cert Std Id',
	scsp.Name as 'Site Cert Std',
    wi.Id as 'Work Item Id',
	wi.Name as 'Work Item',
    sc.Revenue_Ownership__c as 'Revenue Ownership',
    date_format(wi.Service_target_date__c, '%Y') as 'Audit Due Year',
    date_format(wi.Service_target_date__c, '%b') as 'Audit Due Month',
    wi.Service_target_date__c as 'Audit Due Date (Target)',
    wi.Earliest_Service_Start_DateTime__c as 'Audit Start Date',
    wi.End_Service_Date__c as 'Audit End Date',
    timestampdiff(day, wi.Service_target_date__c, wi.Work_Item_Date__c) as 'Target to Scheduled (Days)',
    wi.Status__c  as 'Work Item Status',
    wi.Work_Item_Submission_Date__c as 'Compass Upload Date (UTC)',
    analytics.getBusinessDays(wi.End_Service_Date__c, wi.Work_Item_Submission_Date__c, site.Time_Zone__c) as 'TAT Audit Finish to Upload to Compass',
    arg.Name as 'ARG', 
    arg.Audit_Report_Status__c as 'ARG Status',
    arg.CA_Approved__c as 'ARG Approval Date (UTC)-(UPLOAD TO STETON / APMEA DATABASE?)',
    analytics.getBusinessDays(wi.End_Service_Date__c, arg.CA_Approved__c, site.Time_Zone__c) 'TAT Upload to Database / Review',
	arg.Admin_Closed__c as 'ARG completed (Issue of Cert/report to Client?)',
    analytics.getBusinessDays(wi.End_Service_Date__c, arg.Admin_Closed__c, site.Time_Zone__c) 'TAT Issue of Cert to Client',
    wi.Comments__c as 'Work Items Comments',
    '?' as 'Audit Type',
    s.Name as 'Primary Standard',
    ifnull(group_concat(fs.Name), '') as 'Family of Standards',
    wi.Work_Item_Stage__c as 'Work Item Type',
    wio.Name as 'Work Item Owner (Auditor?)',
    ifnull(group_concat(cod.Name),'') as 'Category',
    ifnull(group_concat(cod.Code_Description__c),'') as 'Code Desc',
    ifnull(group_concat(cod.External_Id__c),'') as 'Code Ext Id',
    csp.Re_Audit_Due_Date__c as 'Re-Audit Due Date'
    
from salesforce.work_item__c wi
	left join salesforce.user wio on wi.OwnerId = wio.Id
	left join salesforce.arg_work_item__c argwi on wi.Id = argwi.RWork_Item__c and argwi.IsDeleted = 0
    left join salesforce.audit_report_group__c arg on argwi.RAudit_Report_Group__c = arg.Id
	inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
    inner join salesforce.certification_standard_program__c csp on scsp.Certification_Standard__c = csp.Id
    inner join salesforce.certification__c sc on scsp.Site_Certification__c = sc.Id
    inner join salesforce.account site on sc.Primary_client__c = site.Id
    inner join salesforce.account client on site.ParentId = client.Id
    left join salesforce.country_code_setup__c ccs on site.Business_Country2__c = ccs.Id
	inner join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
	inner join salesforce.standard__c s on sp.Standard__c = s.Id
	left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id and scsf.IsDeleted = 0
	left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
	left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
    left join salesforce.site_cert_standard_program_code__c scspc on scspc.Site_Certification_Standard_Program__c = scsp.Id and scspc.IsDeleted = 0
	left join salesforce.code__c cod on scspc.Code__c = cod.Id
where
	wi.IsDeleted = 0
    and wi.Status__c not in ('Cancelled')
    and (s.Id in (select Id from salesforce.McDonalds_Standards) or
		fs.Id in (select Id from salesforce.McDonalds_Standards))
group by wi.Id;
        
(select * from salesforce.McDonalds_Standards);

#explain
(select wi.Id, wi.Name, mcdat.`auditType`, s.NAme as 'Primary Standard', group_concat(fs.Name) as 'FoS' 
from salesforce.work_item__c wi
inner join analytics.mcd_audit_types mcdat on wi.Name = mcdat.wi
inner join salesforce.site_certification_standard_program__c scsp on wi.Site_Certification_Standard__c = scsp.Id
inner join salesforce.standard_program__c sp on sp.Id = scsp.Standard_Program__c
inner join salesforce.standard__c s on sp.Standard__c = s.Id
left join salesforce.site_certification_standard_family__c scsf on scsf.Site_Certification_Standard__c = scsp.Id and scsf.IsDeleted = 0
left join salesforce.standard_program__c fsp on scsf.Standard_Program__c = fsp.Id
left join salesforce.standard__c fs on fsp.Standard__c = fs.Id
group by wi.Id);

select * from salesforce.McDonalds_Standards ;
drop table mcd_audit_types;
create table mcd_audit_types (
`wi` varchar(18) not null,
`auditType` varchar(64) not null
);
select count(*) from mcd_audit_types;
create index mcd_audit_type_wi on mcd_audit_types(wi);
INSERT INTO mcd_audit_types VALUES('WI-758715','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-726411','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-819045','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-790130','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-822560','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-749374','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-822529','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-780899','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-751309','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-822580','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-792355','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-818546','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-788090','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-726362','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758776','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758803','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757587','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-726624','SWA');
INSERT INTO mcd_audit_types VALUES('WI-758773','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-826514','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757633','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-782042','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-726379','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-752605','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-726197','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-832788','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-822424','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-821859','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-749222','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-757606','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758778','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-749194','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758094','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-752270','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758693','GFSI+A (IFS)');
INSERT INTO mcd_audit_types VALUES('WI-751264','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-749230','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-795353','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758786','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-845027','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757658','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-838639','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-731063','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-839133','GAP');
INSERT INTO mcd_audit_types VALUES('WI-839120','GAP');
INSERT INTO mcd_audit_types VALUES('WI-752512','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-839432','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-821663','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-843546','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-835268','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-822806','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757591','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-822422','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757608','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-730578','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-832584','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-745067','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-758276','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-726349','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-782350','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757597','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-829584','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-830876','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-729853','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-729849','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-781101','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-729841','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757610','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-830864','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-781106','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-844792','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-744465','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-797964','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-749339','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758797','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-845616','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-731838','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-848903','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-843782','GFSI+A (BRC)');
INSERT INTO mcd_audit_types VALUES('WI-753886','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-838827','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-775036','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-848376','GFSI+A (FSSC)');
INSERT INTO mcd_audit_types VALUES('WI-749354','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-811207','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-781103','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758739','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758741','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757604','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758712','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-781107','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-795518','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-729649','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-774642','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757562','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-840017','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-844807','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-840009','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-751669','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-809010','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-791859','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-752520','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-781359','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-822729','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-749232','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-850858','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-849478','GFSI+A (FSSC)');
INSERT INTO mcd_audit_types VALUES('WI-749179','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-757595','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-838803','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-752327','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-757578','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-749371','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758508','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-849487','GFSI+A (FSSC)');
INSERT INTO mcd_audit_types VALUES('WI-749177','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-774774','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757586','GFSI+A (BRC)');
INSERT INTO mcd_audit_types VALUES('WI-816929','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-818790','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-838804','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-852323','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-831563','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-822826','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-749185','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-818781','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-751641','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-840033','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-759820','GFSI+A (BRC)');
INSERT INTO mcd_audit_types VALUES('WI-764607','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757599','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-817778','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757576','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-756211','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-750357','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-777369','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-751030','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-756164','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-775188','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-757674','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-758795','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-819046','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-857100','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-728873','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-752288','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-757546','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-759825','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-792552','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-851365','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-860812','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-763716','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-764610','10 Core');
INSERT INTO mcd_audit_types VALUES('WI-787411','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758791','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-851366','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-758079','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757543','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-752505','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-856683','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-859265','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-854901','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-788419','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-856435','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752309','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-752342','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-781757','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-780739','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-757817','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-860701','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-780746','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-860079','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-780744','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-821627','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-791320','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-869377','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-832949','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-850859','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-819526','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-752643','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-758744','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-726356','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-788419','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-780734','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-801495','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752535','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-749206','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757552','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-775362','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-808307','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-780229','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-752595','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752340','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-752542','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-777431','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-780320','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-818108','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-758805','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-843937','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-832195','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-791858','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-845571','GAP');
INSERT INTO mcd_audit_types VALUES('WI-793259','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-818323','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-850965','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-816593','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-777439','10 CORE');
INSERT INTO mcd_audit_types VALUES('WI-733953','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-817776','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758767','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-763397','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758764','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-752599','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-756310','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-786440','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-728995','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-842525','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-842524','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-752337','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-791317','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752544','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-746732','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-777441','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757565','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-731114','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-840032','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-845138','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-843780','GFSI+A');
INSERT INTO mcd_audit_types VALUES('WI-795900','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-838930','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-752517','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-752503','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757540','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-751047','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-745103','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-842528','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752294','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-755747','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-750597','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-791267','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752315','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752624','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-845164','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-818800','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-859870','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-849206','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-856541','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752629','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-854105','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-843651','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-843650','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-843657','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-749633','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-764623','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-838684','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757555','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-793251','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-792135','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-764617','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752574','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-728890','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-823351','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-817372','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-749234','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-749197','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-795797','GFSI+A');
INSERT INTO mcd_audit_types VALUES('WI-816926','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-792547','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-822099','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-749373','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757549','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-819480','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-757665','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-818538','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-821730','GFSI+A');
INSERT INTO mcd_audit_types VALUES('WI-752523','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-752648','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-793443','SWA');
INSERT INTO mcd_audit_types VALUES('WI-752324','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-728916','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-818305','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-752312','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-840036','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-759413','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-821419','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-850151','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-749183','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-792363','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-818556','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-781376','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-781372','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-768629','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-768631','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-768627','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-822413','SQMS');
INSERT INTO mcd_audit_types VALUES('WI-758732','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-758735','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-758737','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-822274','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-819446','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-758758','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-818532','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-758783','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-781374','HEN HOUSE');
INSERT INTO mcd_audit_types VALUES('WI-819473','PROTEIN (Db)');
INSERT INTO mcd_audit_types VALUES('WI-818800','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-818313','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-757570','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757571','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-752335','PROTEIN Sl');
INSERT INTO mcd_audit_types VALUES('WI-850964','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-816597','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-829783','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-821420','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-758801','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-818313','FSQMS');
INSERT INTO mcd_audit_types VALUES('WI-860674','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-757557','DQMP');
INSERT INTO mcd_audit_types VALUES('WI-821642','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-822433','PROTEIN Sl & Db');
INSERT INTO mcd_audit_types VALUES('WI-777382','GFSI+A');
