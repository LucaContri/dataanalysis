UPDATE salesforce.sf_tables SET ToSync=1  WHERE TableName IN ('Account', 'Blackout_Period__c', 'Certification_Standard_Family__c', 'Certification_Standard_Program__c', 'Certification__c', 'Client_Code__c', 'Code__c', 'Country_Code_Setup__c', 'Delivery_Strategy__c', 'Event', 'Opportunity', 'Program__c', 'Resource_Competency__c', 'Resource__c', 'Site_Cert_Standard_Program_Code__c', 'Site_Certification_Standard_Family__c', 'Site_Certification_Standard_Program__c', 'Standard_Code__c', 'Standard_Program__c', 'Standard__c', 'State_Code_Setup__c', 'Timesheet_Line_Item__c', 'User', 'Work_Item_Resource_Day__c', 'Work_Item_Resource__c', 'Work_Item__c', 'Work_Package__c');