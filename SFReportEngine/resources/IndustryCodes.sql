drop function salesforce.getIndustryFromNace;


DELIMITER //
CREATE FUNCTION salesforce.getIndustryFromNace(NaceSector varchar(2)) RETURNS VARCHAR(64)
BEGIN
	DECLARE IndustryName VARCHAR(64) DEFAULT "";
    SET IndustryName = (SELECT 
		IF (NaceSector is null, null,
		IF (NaceSector <= '03', '01 - Agriculture, forestry and fishing',
        IF (NaceSector <= '09', '02 - Mining and Quarrying',
        IF (NaceSector <= '11', '03 - Manufacturing - Food & Beverages',
        IF (NaceSector <= '33', '03 - Manufacturing',
        IF (NaceSector <= '39', '04 - Utilities',
        IF (NaceSector <= '43', '05 - Construction',
        IF (NaceSector <= '47', '06 - Wholesale and Retail Trade',
        IF (NaceSector <= '53', '07 - Transport and Storage',
        IF (NaceSector <= '56', '08 - Accommodation and Food Service',
        IF (NaceSector <= '63', '09 - Information and Communication',
        IF (NaceSector <= '82', '10 - Business Services',
        IF (NaceSector <= '84', '11 - Public Administration, Defence and Social Security ',
        IF (NaceSector <= '85', '12 - Education',
        IF (NaceSector <= '88', '13 - Human Health and Social Work',
        IF (NaceSector <= '96', '14 - Arts, Entertainment, Recreational and Cultural Services',
        '99 - To Be Confirmed'
		)))))))))))))))));
		
	RETURN IndustryName ;
 END //
DELIMITER ;

select Industry_Sector__c from industry__c group by Industry_Sector__c;

select * from salesforce.code__c where Name like 'SAI%' and Name like '%01%'
