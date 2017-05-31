// Work Item standards/family
SELECT wi.Id, wi.Name, wi.LastModifiedDate, wi.Status__c, wi.Service_target_date__c, wi.Work_Item_Date__c, wp.Id, c.Id FROM salesforce.Work_Item__c  wi LEFT JOIN salesforce.work_package__c wp on wi.Work_Package__c=wp.Id LEFT JOIN salesforce.certification__c c on wp.Site_Certification__c=c.Id where wi.Name='AU-250819';

SELECT scsp.Id, scsp.Standard_Program__c, sp.Standard__c, sp.Standard_Service_Type_Name__c from salesforce.site_certification_standard_program__c scsp left join salesforce.standard_program__c sp on scsp.Standard_Program__c=sp.Id where scsp.Site_Certification__c='a1kd00000009HutAAE';

SELECT scsf.Id, sp.Standard__c, sp.Standard_Service_Type_Name__c from salesforce.site_certification_standard_family__c scsf left join salesforce.standard_program__c sp on scsf.Standard_Program__c= sp.Id where scsf.Site_Certification_Standard__c='a30d00000004OFYAA2';

// Work Item codes
