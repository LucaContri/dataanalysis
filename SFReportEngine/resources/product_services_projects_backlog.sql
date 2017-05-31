DELIMITER $$
CREATE FUNCTION `getPSActivityDurationMin`(Activity VARCHAR(128)) RETURNS double(18,10)
BEGIN
	DECLARE duration DOUBLE(18,10) DEFAULT null;
    SET duration = (SELECT 
		if(Activity = 'Advise AQIS of Changes to certification type/status. - Type 1',15,
		if(Activity = 'Advise AQIS of Changes to certification type/status. - Type 3',30,
		if(Activity = 'Advise AQIS of Changes to certification type/status. - Type 5',30,
		if(Activity = 'Approvals - ARG',15,
		if(Activity = 'Approve Evaluation Plan and Methodology - Unrestricted Building Certifier (UBC).',30,
		if(Activity = 'Approve the Evaluation Report and Certificate - Unrestricted Building Certifier (UBC).',15,
		if(Activity = 'ARG Submitted',30,
		if(Activity = 'Arrange Type Testing at a Recognised Laboratory, where applicable.',30,
		if(Activity = 'Assess against AWPCS revision. - Type 1',30,
		if(Activity = 'Assess against AWPCS revision. - Type 3',30,
		if(Activity = 'Assess against AWPCS revision. - Type 5',30,
		if(Activity = 'Complete and sign the PCF175 checklist.',15,
		if(Activity = 'Confirm relationship with prior certification / testing, confirm description matrix.',15,
		if(Activity = 'Define the certified product range, establish model description matrix. - Type 1',30,
		if(Activity = 'Define the certified product range, establish model description matrix. - Type 3',15,
		if(Activity = 'Define the certified product range, establish model description matrix. - Type 5',15,
		if(Activity = 'Develop Evaluation Plan and Methodology.',30,
		if(Activity = 'Establish / Review Product Evaluation Report, where applicable.',30,
		if(Activity = 'Establish Product Listing / Certificate Information and submit via Product Database when r',15,
		if(Activity = 'Establish/Review Test Program and Sample Selection, where applicable.',30,
		if(Activity = 'Identification of Test Station Type - Verify documentation on the Test Station Type.',20,
		if(Activity = 'Identification of the Cylinder Type - Verify documentation on the Cylinder Type.',30,
		if(Activity = 'Identify the Relevant Clauses of the respective Building Code(s) applicable to the product',30,
		if(Activity = 'Identify/verify the process that fits in the AWPCS types (one or multiple)',15,
		if(Activity = 'Inspect the Product/s and verify compliance.',15,
		if(Activity = 'New Signatory Assessment - Verify documentation for staff competency with the Standard and',30,
		if(Activity = 'Prepare Certificate - Scope and Limitations.',15,
		if(Activity = 'Request to AQIS for certification number.',30,
		if(Activity = 'Review and Confirm that the pricing / audit information is correct.',15,
		if(Activity = 'Review Marking and verify compliance with the Standard and/or relevant Compliance Program.',30,
		if(Activity = 'Review Marking and verify compliance with the Standard.',30,
		if(Activity = 'Review Quality Documentation.',30,
		if(Activity = 'Review Test Report and verify compliance. - Type 1',15,
		if(Activity = 'Review Test Report and verify compliance. - Type 3',30,
		if(Activity = 'Review Test Report and verify compliance. - Type 5',15,
		if(Activity = 'Review Test Report for correct TRF, country deviations and compliance. - Type 1',30,
		if(Activity = 'Review Test Report for correct TRF, country deviations and compliance. - Type 3',30,
		if(Activity = 'Review Test Report for correct TRF, country deviations and compliance. - Type 5',30,
		if(Activity = 'Review Test Report, verify validity, adequacy and ompliance. - Type 1',15,
		if(Activity = 'Review Test Report, verify validity, adequacy and ompliance. - Type 3',30,
		if(Activity = 'Review Test Report, verify validity, adequacy and ompliance. - Type 5',15,
		if(Activity = 'Review the Audit Report, where applicable, and confirm compliance.',15,
		if(Activity = 'Review the construction site audit report compliance with the Evaluation Plan, where appli',15,
		if(Activity = 'Send the Certificate to JAS-ANZ.',30,
		if(Activity = 'Verify applied standard with JASANZ accreditation scope for decalred articles.',30,
		if(Activity = 'Verify applied standard with JASANZ accreditation scope for non decalred articles.',15,
		if(Activity = 'Verify that construction site audit is completed, where applicable.',15,
		if(Activity = 'Verify that the information supplied, i.e. product specifications, drawings, test reports, - Type 1',15,
		if(Activity = 'Verify that the information supplied, i.e. product specifications, drawings, test reports, - Type 3',15,
		if(Activity = 'Verify that the information supplied, i.e. product specifications, drawings, test reports, - Type 5',30,
		if(Activity = 'Verify that the Product Specifications, Materials and Design, where applicable, comply wit - Type 1',30,
		if(Activity = 'Verify that the Product Specifications, Materials and Design, where applicable, comply wit - Type 3',15,
		if(Activity = 'Verify that the Product Specifications, Materials and Design, where applicable, comply wit - Type 5',30,
		if(Activity = 'Verify that the product/s fits the standard/code, i.e. are in the scope of standard/code.',15,
		if(Activity = 'Verify that the relevant audit/inspection(s) has been completed, where applicable.',30,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals co - Type 1',30,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals co - Type 3',30,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals co - Type 5',15,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals, w - Type 1',15,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals, w - Type 3',30,
		if(Activity = 'Verify that the the Product Specifications, critical components/Materials and approvals, w - Type 5',15,
		if(Activity = 'Verify that User Manual/Instructions, where applicable, comply with the Standard.',30,
		if(Activity = 'Verifying issuing laboratory & test scope. - Type 1',15,
		if(Activity = 'Verifying issuing laboratory & test scope. - Type 3',30,
		if(Activity = 'Verifying issuing laboratory & test scope. - Type 5',15,
		if(Activity = 'Verifying test standard within lab and our CB scope.',30,
        if(Activity = 'Witness Type Testing, where applicable.', 0,null)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
	);
    RETURN duration;
 END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION `getPSProjectDurationMin`(Pathway VARCHAR(128), ProjectType enum('Initial Project','Product Update')) RETURNS integer
BEGIN
	DECLARE duration DOUBLE(18,10) DEFAULT null;
    SET duration = 
		(SELECT 
			IF(ProjectType='Initial Project', 
				IF(Pathway='Appliances', 248,
				IF(Pathway='Building & Infrastructure', 251,
                IF(Pathway='Laboratories', 251, # Don't know historical duration for Laboratories as they don't use Criteria.  Using max of other pathways
				IF(Pathway='Health & Safety', 175,
				IF(Pathway='Plumbing & Water', 227,null))))),
				IF(ProjectType='Product Update', 
					IF(Pathway='Appliances', 224,
					IF(Pathway='Building & Infrastructure', 106,
                    IF(Pathway='Laboratories', 224, # Don't know historical duration for Laboratories as they don't use Criteria.  Using max of other pathways
					IF(Pathway='Health & Safety', 100,
					IF(Pathway='Plumbing & Water', 112,null))))),
					null
				)
			)
		);
    RETURN duration;
 END$$
DELIMITER ;

(select 
	wi.Id, 
    wi.Name, 
    wi.Primary_Standard__c, 
    p.Business_Line__c, 
    p.Pathway__c, 
    wi.Status__c, 
    wi.createdDate, 
    wi.Project_Start_Date__c, 
    wi.Project_Projected_End_Date__c, 
    wi.Project_End_Date__c, 
    r.Name as 'Project Manager',
    m.Name as 'Manager',
    wi.Work_Item_Stage__c,
    analytics.getPSProjectDurationMin(p.Pathway__c,wi.Work_Item_Stage__c) as 'Project Historical Duration (min)',
	count(if(c.IsDeleted or c.Status__c='Cancelled', null, c.Id)) as '# Criteria',
	count(if(c.IsDeleted=0 and c.Applicability__c='Mandatory' and c.Status__c not in ('Cancelled'),c.Id,null)) as '# Mandatory Criteria',
    count(if(c.IsDeleted=0 and c.Applicability__c='Mandatory' and c.Status__c='Completed', c.Id, null)) as '# Mandatory Criteria Completed',
    count(if(c.IsDeleted=0 and c.Applicability__c='Optional' and c.Status__c='Completed', c.Id, null)) as '# Optional Criteria Completed',
    ifnull(sum(if(c.IsDeleted=0 and c.Applicability__c='Mandatory' and c.Status__c='Completed', 
		analytics.getPSActivityDurationMin(salesforce.getCriteriaWithType(left(substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1),90),s.Conformity_Type__c)), 
        null)),0) as '# Mandatory Criteria Completed (min)',
    ifnull(sum(if(c.IsDeleted=0 and c.Applicability__c='Optional' and c.Status__c='Completed', 
		analytics.getPSActivityDurationMin(salesforce.getCriteriaWithType(left(substring_index(c.Name__c , '**Client Output Language Not Found For This Criteria** ',-1),90),s.Conformity_Type__c)), 
        null)),0) as '# Optional Criteria Completed (min)',
	ifnull(group_concat(distinct if(c.IsDeleted=0 and (c.Applicability__c='Mandatory' or c.Status__c='Completed') and c.Status__c not in ('Cancelled'), c.Criteria_Owner_Name__c, null)),r.Name) as 'Criteria Owners'
from salesforce.work_item__c wi
left join salesforce.criteria__c c on c.Work_Item__c = wi.Id
left join salesforce.standard__c s on wi.Primary_Standard__c = s.Name
left join salesforce.program__c p on s.Program__c = p.Id
inner join salesforce.work_package__c wp on wi.Work_Package__c = wp.Id
inner join salesforce.certification__c sc on wp.Site_Certification__c = sc.Id
inner join salesforce.certification__c cert on sc.Primary_Certification__c = cert.Id
inner join salesforce.resource__c r on cert.Project_Manager_2__c = r.Id
inner join salesforce.user u on r.User__c = u.Id
inner join salesforce.user m on u.ManagerId = m.Id
where 
wi.Work_Item_Stage__c in ('Initial Project','Product Update')
and wi.Status__c in ('Open','In Progress')
group by wi.Id);