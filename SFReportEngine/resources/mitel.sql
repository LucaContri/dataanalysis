create database mitel;

use mitel;
drop table employee_queue_data;
CREATE TABLE `employee_queue_data` (
  `fromDate` datetime NOT NULL,
  `toDate` datetime NOT NULL,
  `Span` varchar(5) NOT NULL DEFAULT 'DAY', # DAY, MONTH, YEAR
  `EmployeeId` varchar(18) NOT NULL,
  `EmployeeName` varchar(128) NOT NULL,
  `QueueId` varchar(18) NOT NULL,
  `Count` integer NULL default 0,
  `DurationSec` integer NULL default 0,
  `Requeued` integer NULL default 0,
  PRIMARY KEY (`fromDate`,`toDate`,`EmployeeId`, `QueueId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `queue` (
  `QueueId` varchar(18) NOT NULL,
  `QueueName` varchar(128) NOT NULL,
  PRIMARY KEY (`QueueId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `queue` VALUES ('OUTBOUND','Outbound');
INSERT INTO `queue` VALUES ('NOACD','Non ACD CAll');
INSERT INTO `queue` VALUES ('TRANSTO','Transferred to Agent');
INSERT INTO `queue` VALUES ('TRANSFROM','Transferred from Agent');
INSERT INTO `queue` VALUES ('CONF','Conference Call');

INSERT INTO `queue` VALUES ('12840','Canberra_Day');
INSERT INTO `queue` VALUES ('12861','Scheduling_Craig');
INSERT INTO `queue` VALUES ('12862','Scheduling_Eleanor');
INSERT INTO `queue` VALUES ('12863','Scheduling_Bianca');
INSERT INTO `queue` VALUES ('12864','Scheduling_Amanda');
INSERT INTO `queue` VALUES ('2*0993','Queue 2*0993');
INSERT INTO `queue` VALUES ('20707','ReworksRequisitions');
INSERT INTO `queue` VALUES ('20725','GeorgeStWestpac');
INSERT INTO `queue` VALUES ('20962','ANZ_Banking_Finance');
INSERT INTO `queue` VALUES ('20971','ANZ_Settlements');
INSERT INTO `queue` VALUES ('20989','Post_Settlement_B_OB');
INSERT INTO `queue` VALUES ('20990','ChequeDirectionsTeam');
INSERT INTO `queue` VALUES ('20991','Post_Settlements_B');
INSERT INTO `queue` VALUES ('20992','DMT');
INSERT INTO `queue` VALUES ('20993','Post_Settlements_A');
INSERT INTO `queue` VALUES ('20994','Professional_Service');
INSERT INTO `queue` VALUES ('20995','Settlements_Team');
INSERT INTO `queue` VALUES ('20996','Stamping_Team');
INSERT INTO `queue` VALUES ('26051','Compass_Ring_Group');
INSERT INTO `queue` VALUES ('26061','AccountsPayableSusSt');
INSERT INTO `queue` VALUES ('26080','CreditControl');
INSERT INTO `queue` VALUES ('26162','InfoSvcAcctsRec');
INSERT INTO `queue` VALUES ('26800','AssuranceAcctsRec');
INSERT INTO `queue` VALUES ('31144','Cust_Svc_SouthBank');
INSERT INTO `queue` VALUES ('P200','Reception AH');
INSERT INTO `queue` VALUES ('P201','ITT Svc Desk');
INSERT INTO `queue` VALUES ('P204','Sales Enq Property');
INSERT INTO `queue` VALUES ('P205','Assurance');
INSERT INTO `queue` VALUES ('P206','MS Sales');
INSERT INTO `queue` VALUES ('P211','Customer Service');
INSERT INTO `queue` VALUES ('P212','Reseller Services');
INSERT INTO `queue` VALUES ('P213','Research Services');
INSERT INTO `queue` VALUES ('P220','Reg Historical');
INSERT INTO `queue` VALUES ('P221','Enq Historical');
INSERT INTO `queue` VALUES ('P222','Online Learning');
INSERT INTO `queue` VALUES ('P223','Assessments');
INSERT INTO `queue` VALUES ('P224','Recognition');
INSERT INTO `queue` VALUES ('P225','Learn Historical');
INSERT INTO `queue` VALUES ('P226','Cert Historical');
INSERT INTO `queue` VALUES ('P227','BusEx Historical');
INSERT INTO `queue` VALUES ('P228','ProMapp Historical');
INSERT INTO `queue` VALUES ('P229','Other Enquiries');
INSERT INTO `queue` VALUES ('P230','TIS Callback 1 EDC');
INSERT INTO `queue` VALUES ('P231','TIS Callback 2 EDC');
INSERT INTO `queue` VALUES ('P232','InHouse');
INSERT INTO `queue` VALUES ('P233','Public Training');
INSERT INTO `queue` VALUES ('P234','Precourse Enq.');
INSERT INTO `queue` VALUES ('P235','Online Course TA');
INSERT INTO `queue` VALUES ('P236','Invoice Enq.');
INSERT INTO `queue` VALUES ('P237','Cancellation');
INSERT INTO `queue` VALUES ('P238','TIS Callback 3 EDC');
INSERT INTO `queue` VALUES ('P239','TIS Callback 4 EDC');
INSERT INTO `queue` VALUES ('P298','Transfer UK');
INSERT INTO `queue` VALUES ('P299','Essist Test');
INSERT INTO `queue` VALUES ('44771','Settlements_Team');
INSERT INTO `queue` VALUES ('44772','Pre_settlements_Team');
INSERT INTO `queue` VALUES ('44773','Professional Service');
INSERT INTO `queue` VALUES ('44774','CBA');
INSERT INTO `queue` VALUES ('44775','WESTPAC_And_STG');
INSERT INTO `queue` VALUES ('44776','Cooper Grace Ward');
INSERT INTO `queue` VALUES ('44780','FirstmacSettlements');
INSERT INTO `queue` VALUES ('44882','PostSettlements_Team');
INSERT INTO `queue` VALUES ('44884','CBA Post');
INSERT INTO `queue` VALUES ('44891','RecordsManagementRG');
INSERT INTO `queue` VALUES ('44892','ANZ_Pre');
INSERT INTO `queue` VALUES ('44893','ANZ_Post');
INSERT INTO `queue` VALUES ('P501','CBA Booking Line');
INSERT INTO `queue` VALUES ('P502','SUN Booking Line');
INSERT INTO `queue` VALUES ('P503','BW Booking Line');
INSERT INTO `queue` VALUES ('P513','BW Priority');
INSERT INTO `queue` VALUES ('13804','CBA_Stamp_Lodge');
INSERT INTO `queue` VALUES ('13810','Boronia Ring Group');
INSERT INTO `queue` VALUES ('13843','Key_Accts_P2_Q');
INSERT INTO `queue` VALUES ('13844','Key_Accts_P3_Q');
INSERT INTO `queue` VALUES ('13845','Key_Accts_P4_Q');
INSERT INTO `queue` VALUES ('13850','Professional_Srvc_RG');
INSERT INTO `queue` VALUES ('31133','Legislation_Hotline');

INSERT INTO `queue` VALUES ('31160','Finance_SouthBank');
INSERT INTO `queue` VALUES ('31166','API_Roads');
INSERT INTO `queue` VALUES ('31502','ANSTAT_App_Support');
INSERT INTO `queue` VALUES ('31529','GRC_Helpdesk');
INSERT INTO `queue` VALUES ('34021','EDRMS');
INSERT INTO `queue` VALUES ('34022','ANZ_Stamps_LOD');
INSERT INTO `queue` VALUES ('34039','Rework_Final');
INSERT INTO `queue` VALUES ('34090','Hobart_Property');
INSERT INTO `queue` VALUES ('34355','BAU_Stamp_Rego');
INSERT INTO `queue` VALUES ('34365','Settlements_Bourke');
INSERT INTO `queue` VALUES ('34390','Key_Accounts_Bourke');
INSERT INTO `queue` VALUES ('P301','Certificates/Search');
INSERT INTO `queue` VALUES ('P302','SSR/Stamp/Rego');
INSERT INTO `queue` VALUES ('P303','Conveyancing Mgr');
INSERT INTO `queue` VALUES ('P304','Accounts/CSM');
INSERT INTO `queue` VALUES ('P305','Invoice/Payment');
INSERT INTO `queue` VALUES ('P306','Other Enquires');
INSERT INTO `queue` VALUES ('P307','Call Back Property');
INSERT INTO `queue` VALUES ('P308','Encompass');
INSERT INTO `queue` VALUES ('P309','Cert/Search AH');
INSERT INTO `queue` VALUES ('P311','CBA Booking Line');
INSERT INTO `queue` VALUES ('P312','BW Booking Line');
INSERT INTO `queue` VALUES ('P313','HSBC Booking Line');
INSERT INTO `queue` VALUES ('P314','CUA Booking Line');
INSERT INTO `queue` VALUES ('P315','New Registration');
INSERT INTO `queue` VALUES ('P666','Settlements Oflow');
INSERT INTO `queue` VALUES ('#62896','Osbourne Pk Overflow');
INSERT INTO `queue` VALUES ('66019','SoftwareSupportDesk');
INSERT INTO `queue` VALUES ('66033','Post_Settlements');
INSERT INTO `queue` VALUES ('66040','Pre_Settlements');
INSERT INTO `queue` VALUES ('66091','Records_Mgmt_Team');
INSERT INTO `queue` VALUES ('66092','Records_M_OF');
INSERT INTO `queue` VALUES ('P611','BW Booking Line');
INSERT INTO `queue` VALUES ('P201','ITT Svc Desk');
INSERT INTO `queue` VALUES ('P204','Sales Enq Property');
INSERT INTO `queue` VALUES ('P205','Assurance');
INSERT INTO `queue` VALUES ('P206','MS Sales');
INSERT INTO `queue` VALUES ('P211','Customer Service');
INSERT INTO `queue` VALUES ('P212','Research Services');
INSERT INTO `queue` VALUES ('P213','Reseller Services');
INSERT INTO `queue` VALUES ('P220','Reg Historical');
INSERT INTO `queue` VALUES ('P221','Enq Historical');
INSERT INTO `queue` VALUES ('P222','Online Learning');
INSERT INTO `queue` VALUES ('P223','Assessments');
INSERT INTO `queue` VALUES ('P224','Recognition');
INSERT INTO `queue` VALUES ('P225','Learn Historical');
INSERT INTO `queue` VALUES ('P226','Cert Historical');
INSERT INTO `queue` VALUES ('P227','BusEx Historical');
INSERT INTO `queue` VALUES ('P228','ProMapp Historical');
INSERT INTO `queue` VALUES ('P229','Other Enquiries');
INSERT INTO `queue` VALUES ('P230','TIS Callback 1 GDC');
INSERT INTO `queue` VALUES ('P231','TIS Callback 1 GDC');
INSERT INTO `queue` VALUES ('P232','InHouse');
INSERT INTO `queue` VALUES ('P233','Public Training');
INSERT INTO `queue` VALUES ('P234','Precourse Enq.');
INSERT INTO `queue` VALUES ('P235','Online Course TA');
INSERT INTO `queue` VALUES ('P236','Invoice Enq.');
INSERT INTO `queue` VALUES ('P237','Cancellation');
INSERT INTO `queue` VALUES ('P238','TIS Callback 3 GDC');
INSERT INTO `queue` VALUES ('P239','TIS Callback 4 GDC');
INSERT INTO `queue` VALUES ('P501','Queue 59201');
INSERT INTO `queue` VALUES ('P502','Queue 59202');
INSERT INTO `queue` VALUES ('P503','Queue 59203');
INSERT INTO `queue` VALUES ('P513','Queue 59213');
INSERT INTO `queue` VALUES ('P301','Certificates/Search');
INSERT INTO `queue` VALUES ('P302','SSR/Stamp/Rego');
INSERT INTO `queue` VALUES ('P303','Conveyancing Mgr');
INSERT INTO `queue` VALUES ('P304','Accounts/CSM');
INSERT INTO `queue` VALUES ('P305','Invoice/Payment');
INSERT INTO `queue` VALUES ('P306','Other Enquires');
INSERT INTO `queue` VALUES ('P307','CB Property GDC');
INSERT INTO `queue` VALUES ('P308','Encompass');
INSERT INTO `queue` VALUES ('P309','Cert/Search AH');
INSERT INTO `queue` VALUES ('P311','CBA Booking Line');
INSERT INTO `queue` VALUES ('P312','BW Booking Line');
INSERT INTO `queue` VALUES ('P313','HSBC Booking Line');
INSERT INTO `queue` VALUES ('P314','CUA Booking Line');
INSERT INTO `queue` VALUES ('P315','New Registration');
INSERT INTO `queue` VALUES ('P621','BW Booking Line');


(select date_format(fromDate, '%d/%m/%Y') as 'Date', eqd.QueueId, q.QueueName as 'Queue', eqd.EmployeeId, eqd.EmployeeName, Count, DurationSec as 'Duration (Sec)' 
from employee_queue_data eqd
left join queue q on eqd.queueId = q.queueId
where eqd.span='DAY');
#Sales 
(select * from employee_queue_data);