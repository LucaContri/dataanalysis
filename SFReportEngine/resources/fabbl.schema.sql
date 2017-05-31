drop schema `fabbl`;
CREATE SCHEMA IF NOT EXISTS `fabbl`;
USE `fabbl`;

drop table `test`;
CREATE TABLE `test` (
  `Id` int(11) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `fabbl_tables` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `TableName` varchar(100) DEFAULT NULL,
  `LastSyncDate` datetime DEFAULT NULL,
  `ToSync` tinyint(1) NOT NULL DEFAULT '1',
  `MinSecondsBetweenSyncs` int(10) unsigned NOT NULL DEFAULT '60',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table fabbl.inspectors;
CREATE TABLE IF NOT EXISTS fabbl.`Inspectors` (
  `ID` INT NOT NULL , 
  `Initials` VARCHAR(6), 
  `Name` VARCHAR(40), 
  `Region` VARCHAR(4), 
  `Region_Code` VARCHAR(6), 
  `Address1` VARCHAR(50), 
  `Address2` VARCHAR(50), 
  `Town` VARCHAR(50), 
  `County` VARCHAR(50), 
  `Postcode` VARCHAR(12), 
  `current` BOOLEAN, 
  `Latest_count` INT, 
  `Release_ID` INT, 
  `Canc_ID` INT, 
  `Resno` INT, 
  `NotifyAllocationsByPost` BOOLEAN, 
  `Email` VARCHAR(200), 
  `NotifyAllocationsByEmail` BOOLEAN, 
  `TelephoneNumber` VARCHAR(20), 
  `Extension` VARCHAR(6), 
  `MobileNumber` VARCHAR(15), 
  `NotifyAllocationsBySMS` BOOLEAN, 
  `FaxNumber` VARCHAR(20), 
  `OFG` BOOLEAN, 
  `FABBL_TeamLeader` BOOLEAN, 
  `FABBL_Led_By_TeamLeader` INT, 
  `FABBL_TeamLeader_Region` VARCHAR(50), 
  `UsingAM2` BOOLEAN,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'Inspectors');
--
-- Table structure for table 'tblBanking5'
--

CREATE TABLE IF NOT EXISTS `tblBanking5` (
    `Banking_ID` INT,
    `DateReceived` DATETIME,
    `BankingTotal` DECIMAL(18 , 10 ),
    `ChequeTotal` DECIMAL(18 , 10 ),
    `DateProcessed` DATETIME,
    `Banked` BOOLEAN,
    `Marked` BOOLEAN,
    `DateBanked` DATETIME,
    `FF_Report` BOOLEAN,
    `ABP_Report` BOOLEAN,
    `OFG` BOOLEAN,
    `PaymentTotal` DECIMAL(18 , 10 ),
    `NettTotal` DECIMAL(18 , 10 ),
    `Do_Not_Roll` BOOLEAN,
    `posted_date` DATETIME,
    `Staff` INT,
    PRIMARY KEY (`Banking_ID`)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8;
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'tblBanking5');

--
-- Table structure for table 'tblCheque5'
--


CREATE TABLE IF NOT EXISTS `tblCheque5` (
  `Request_ID` INT , 
  `Cheque_ID` INT, 
  `PaymentValue` DECIMAL(18,10), 
  `PaymentNett` DECIMAL(18,10), 
  `PaymentVAT` DECIMAL(18,10), 
  `PaymentError` DECIMAL(18,10), 
  `ChequeName` VARCHAR(50), 
  `Voucher_Value` DECIMAL(18,10), 
  `Banking_ID` INT, 
  `Payments` SMALLINT, 
  `Payment_sum` DECIMAL(18,10), 
  `Deferred_cleared` DATETIME, 
  `Ready_to_Defer` BOOLEAN,
  PRIMARY KEY (`Request_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'tblCheque5');
--
-- Table structure for table 'tblInspect5'
--

CREATE TABLE IF NOT EXISTS `tblInspect5` (
  `Request_ID` INT, 
  `Insp_Type` INT, 
  `Member_ID` INT, 
  `VisitType` VARCHAR(1), 
  `InspectionDate` DATETIME, 
  `Insp_Code` VARCHAR(12), 
  `InspectionBatch` INT, 
  `Out1` VARCHAR(1), 
  `Out2` VARCHAR(1), 
  `Rec_Req_Present` BOOLEAN, 
  `Inspection_Due` DATETIME, 
  `Inspection_Seq` SMALLINT, 
  `Letter_ID` INT, 
  `RegionAllocated` VARCHAR(4), 
  `RegionDate` DATETIME, 
  `Transfer_ID` INT, 
  `FIS_ID` INT, 
  `DatetoFABBL` DATETIME, 
  `FISNotes` TEXT, 
  `Inspection_Type` SMALLINT, 
  `Date_to_FIS` DATETIME, 
  `Banking_ID` INT, 
  `No_Beef` BOOLEAN, 
  `No_Sheep` BOOLEAN, 
  `Delay_Letter_Sent` DATETIME, 
  `Delay_Letter_Final` DATETIME, 
  `Delay_Ignore` BOOLEAN, 
  `Crop_Fail_Reverse` DATETIME, 
  `Inspector` INT, 
  `Return_Batch_ID` INT, 
  `Crop_Type` INT, 
  `Out_Area` BOOLEAN, 
  `ABP_Year` INT, 
  `Time_Taken` INT, 
  `ReverseBatch` INT, 
  `Time_from` INT, 
  `Time_to` INT
);
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'tblInspect5');
--
-- Table structure for table 'tblMember5'
--

CREATE TABLE IF NOT EXISTS `tblMember5` (
  `autoid` INT , 
  `Member_ID` INT NOT NULL, 
  `Surname` VARCHAR(35), 
  `Contact` VARCHAR(50), 
  `Address1` VARCHAR(50), 
  `Address2` VARCHAR(40), 
  `Town` VARCHAR(35), 
  `County` VARCHAR(35), 
  `Postcode` VARCHAR(20), 
  `Telephone` VARCHAR(30), 
  `Salutation` VARCHAR(35), 
  `Mobile` VARCHAR(50), 
  `FAX` VARCHAR(50), 
  `FISNote` TEXT, 
  `PrintSticker` BOOLEAN, 
  `Closed` BOOLEAN, 
  `Member_Note` TEXT, 
  `Holding` VARCHAR(12), 
  `Main_Contact` VARCHAR(50), 
  `Dog_Sign` DATETIME, 
  `Med_Book` DATETIME, 
  `Deceased` BOOLEAN, 
  `Crop_Book` DATETIME, 
  `Latest_Amend` DATETIME, 
  `Email` VARCHAR(50), 
  `M_Region` VARCHAR(1), 
  `B_Insp` INT, 
  `B_Date` DATETIME, 
  `B_Type` INT, 
  `Company` VARCHAR(50), 
  `B_cleared` DATETIME, 
  `Late_Cancel` BOOLEAN, 
  `M_Beef_Sheep` BOOLEAN, 
  `M_Pigs` BOOLEAN, 
  `M_Crops` BOOLEAN, 
  `M_Assured_Produce` BOOLEAN, 
  `M_Dairy` BOOLEAN, 
  `M_OFG` BOOLEAN, 
  `Scotland` BOOLEAN, 
  `Farm_Size` INT, 
  `Other_BL` BOOLEAN, 
  `Other_P` BOOLEAN, 
  `Other_D` BOOLEAN, 
  `Other_T` BOOLEAN, 
  `Other_Ch` BOOLEAN, 
  `Other_C` BOOLEAN, 
  `Other_AP` BOOLEAN, 
  `Other_OFG` BOOLEAN, 
  `No_Locations` BOOLEAN, 
  `Auction_ID` INT, 
  `Staff_ID` INT, 
  `Latest_Access` DATETIME, 
  `Closure_ID` INT, 
  `Closure date` DATETIME, 
  `M_Tran` BOOLEAN, 
  `Other_Tran` BOOLEAN, 
  `BS_Doc_Evi` BOOLEAN, 
  `AngliaFarmers` BOOLEAN, 
  `AngliaFarmerCode` VARCHAR(20),
  PRIMARY KEY (`autoid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'tblMember5');
--
-- Table structure for table 'tblPayment5'
--

CREATE TABLE IF NOT EXISTS `tblPayment5` (
  `Banking_ID` INT, 
  `Request_ID` INT NOT NULL, 
  `Member_ID` INT, 
  `Insp_type` INT NOT NULL, 
  `VisitType` VARCHAR(1), 
  `Inspection_Seq` SMALLINT, 
  `Payment_Nett` DECIMAL(18,10), 
  `Payment_Fee` DECIMAL(18,10), 
  `Payment_Royalty` DECIMAL(18,10), 
  `Royalty_Band` VARCHAR(255), 
  `Crop_Type` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `fabbl_tables` (`Id`, `TableName`) VALUES(null,'tblPayment5');

#select TableName from fabbl_tables where ToSync = 1 and (LastSyncDate is null or date_add(LastSyncDate, interval MinSecondsBetweenSyncs second)<utc_timestamp());