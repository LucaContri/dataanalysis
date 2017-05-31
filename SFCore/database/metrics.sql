-- MySQL dump 10.13  Distrib 5.6.22, for Win64 (x86_64)
--
-- Host: localhost    Database: analytics
-- ------------------------------------------------------
-- Server version	5.6.22-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `metrics`
--

DROP TABLE IF EXISTS `metrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metrics` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Function` enum('Operations','Finance','Commercial','HR','EPMO','Technology') NOT NULL DEFAULT 'Operations',
  `Product Portfolio` enum('Assurance','Learning','Knowledge','Risk') NOT NULL,
  `Metric Group` enum('Utilisation','Quality','Timeliness','Retention') NOT NULL,
  `Metric` varchar(128) NOT NULL,
  `Volume Definition` text NOT NULL,
  `Volume Unit` varchar(64) NOT NULL,
  `Value Definition` text NOT NULL,
  `Value Target` double(18,10) NOT NULL,
  `Value Target Min/Max` enum('MIN','MAX','EQ') NOT NULL,
  `Value Unit` varchar(64) NOT NULL,
  `Currency` varchar(3) DEFAULT NULL,
  `SLA Definition` text NOT NULL,
  `Weight` double(18,10) DEFAULT NULL,
  `Reporting Period` enum('Year','Quarter','Month','Week','Day') NOT NULL DEFAULT 'Month',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metrics`
--

LOCK TABLES `metrics` WRITE;
/*!40000 ALTER TABLE `metrics` DISABLE KEYS */;
INSERT INTO `metrics` VALUES 
(1,'Operations','Knowledge','Utilisation','Staff Productivity from Enlighten','No. of Staff','Count','(Core Time / Time at Work)*Efficiency',0.72,'MIN','%','n/a','No. of staff within productivity target (72%) / Total no. of staff',1,'Month'),
(2,'Operations','Assurance','Utilisation','Staff Productivity from Enlighten','No. of Staff','Count','(Core Time / Time at Work)*Efficiency',0.72,'MIN','%','n/a','No. of staff within productivity target (72%) / Total no. of staff',1,'Month'),
(3,'Operations','Learning','Utilisation','Trainers Utilisation','No of Trainers','Count','(Training Days) / ((Days Available - Leave)',0.7000000000,'MIN','%','n/a','No of Trainers within utilisation target (70%) / Total no. of trainers',1,'Month'),
(4,'Operations','Assurance','Timeliness','ARG process time','Distinct ARG Completed','ARG','Average ARG Processing time',15.0000000000,'MAX','Days','n/a','(No. of ARG processed within 15 days target) / (No. of ARG processed)',1,'Month'),
(6,'Operations','Assurance','Quality','ARG Rejection','Distinct ARG Submitted','ARG','ARG Rejected / Distinct ARG Submitted',0.1000000000,'MAX','%','n/a','1 minus ARG Rejected / Distinct ARG Submitted',1,'Month'),
(9,'Operations','Risk','Utilisation','Chargeability','Total no of staff','resources','(Billable Hours / (Total Timesheet Hours – (Non-chargeable Timesheet Hours - Annual Leave – Sick Leave – Support (Helpdesk))) x 100',0.7000000000,'MIN','%','n/a','(Billable Hours / (Total Timesheet Hours – (Non-chargeable Timesheet Hours - Annual Leave – Sick Leave – Support (Helpdesk))) x 100',1,'Month'),
(13,'Operations','Knowledge','Quality','Accurate Orders','No of orders processed','orders','Refunds / Total orders',0.0100000000,'MAX','%','n/a','1 minus Refunds / Total orders',1,'Month'),
(14,'Operations','Knowledge','Quality','InfoStore pricing errors','products made live','products','Pricing Errors / Total products made live',1.0000000000,'MAX','products','n/a','1 minus Pricing Errors / Total products made live',1,'Month'),
(15,'Operations','Knowledge','Quality','Royalty reporting errors','products made live','products','Royalty Errors / Total products made live',1.0000000000,'MAX','products','n/a','1 minus Royalty Errors / Total products made live',1,'Month'),
(16,'Operations','Assurance','Utilisation','Chargeability','Number of Auditors','auditors','(Total Audit Days + Travel) / (Days Available - Leaves)',0.8000000000,'MIN','%','n/a','(Total Audit Days + Travel) / (Days Available - Leaves)',1,'Month'),
(23,'Operations','Risk','Utilisation','Chargeability','Total no of staff','resources','(Billable Hours / (Total Timesheet Hours – (Non-chargeable Timesheet Hours - Annual Leave – Sick Leave – Support (Helpdesk))) x 100',0.4000000000,'MIN','%','n/a','(Billable Hours / (Total Timesheet Hours – (Non-chargeable Timesheet Hours - Annual Leave – Sick Leave – Support (Helpdesk))) x 100',1,'Month'),
(24,'Operations','Knowledge','Quality','Email Relevant and Accurate','Email Sent','email','Internal Survey Score',0.8000000000,'MIN','%','n/a','Internal Survey Score',1,'Month'),
(25,'Operations','Knowledge','Timeliness','Email Response Time','Emailed responded to','emails','Average Response Time',2.0000000000,'MAX','Days','n/a','Percentage emails responded within 2 day target',1,'Month'),
(26,'Operations','Knowledge','Timeliness','Email Resolution Time','Cases Resolved','emails','Created to Resolved Average Time',3.0000000000,'MAX','Days','n/a','Percentage emails resolved within 3 day target',1,'Month'),
(27,'Operations','Knowledge','Timeliness','Phone Waiting Time','No of calls received','calls','Average Response Time',20.0000000000,'MAX','Sec','n/a','Percentage calls answered within 20 sec target',1,'Month'),
(28,'Operations','Learning','Timeliness','Online Registration Processing Time','No. of Online Registrations','Count','Average Registration Processing time',2.0000000000,'MAX','Days','n/a','(No. Of Registration processed within 2 day target) / (No. of Registration)',1,'Month'),
(32,'Operations','Risk','Timeliness','Support Tickets Resolution Time','Tickets Resolved','Count','Average Titcket Processing Time',1.0000000000,'MAX','Days','n/a','No of tickets resolved within 1 day target',1,'Month'),
(33,'Operations','Knowledge','Quality','Phone Quality Survey','No of calls received','calls','Internal Survey Score',0.8000000000,'MIN','%','n/a','Internal Survey Score',1.0000000000,'Month'),
(34,'Operations','Knowledge','Quality','Lawlex Error Rate','No of stories','stories','No of Errors / Total no of stories',0.0002000000,'MAX','%','n/a','1 minus (No of Errors / Total no of stories)',1.0000000000,'Month'),
(35,'Operations','Knowledge','Timeliness','Newsfeeds published','Newsfeeds published','newsfeeds','Newsfeeds published',64.0000000000,'MIN','Count','n/a','Newsfeeds published / 64 (target)',1,'Month'),
(36,'Operations','Knowledge','Timeliness','Law Bulleting published','Law Bulleting published','bulletins','Law bulletins published',1.0000000000,'MIN','Count','n/a','Law Bulleting published / 1 (target)',1,'Month'),
(37,'Operations','Knowledge','Timeliness','SHE Monitor Published','SHE Monitor Published','bulletins','SHE Monitor Published',4.0000000000,'MIN','Count','n/a','SHE Monitor Published / 4 (target)',1,'Month'),
/*(38,'Operations','Assurance','Quality','Enlighten Process Lost Time','Core Hours','Core Hours','Process Lost Time / Core Hours',0.05,'MAX','%','n/a','1 minus (Process Lost Time / Core Hours)',1,'Month'); */
(39,'Operations','Learning','Quality','Rework English','No of Tickets','tickets','Rework outside of production',1.0000000000,'MAX','Count','n/a','1 minus (Number of rework courses/number of total courses)',1,'Month'),
(40,'Operations','Learning','Quality','Rework Translations','No of Tickets','tickets','Rework outside of production',1.0000000000,'MAX','Count','n/a','1 minus (Number of rework courses/number of total courses)',1,'Month'),
(41,'Operations','Learning','Timeliness','On-Time English','No of Tickets','tickets','Courses delivered on due date',1.0000000000,'MIN','Count','n/a','Number of on time deliveries/number of total deliveries',1,'Month'),
(42,'Operations','Learning','Timeliness','On-Time Translations','No of Tickets','tickets','Courses delivered on due date',1.0000000000,'MIN','Count','n/a','Number of on time deliveries/number of total deliveries',1,'Month'),
(43,'Operations','Assurance','Utilisation','Chargeability','Hours Available','Hours','Billable Hours / Hours Available',0.8000000000,'MIN','%','n/a','Billable Hours / Hours Available',1,'Month');

/*!40000 ALTER TABLE `metrics` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

--
-- Table structure for table `metrics_data`
--

DROP TABLE IF EXISTS `metrics_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metrics_data` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Metric Id` int(11) NOT NULL,
  `Target Id` int(11) NOT NULL DEFAULT '1',
  `Region` enum('APAC','EMEA','AMERICAs') NOT NULL DEFAULT 'APAC',
  `SubRegion` varchar(128) NOT NULL,
  `Team` varchar(128) NOT NULL,
  `Business Owner` varchar(128) DEFAULT NULL,
  `Period` date NOT NULL,
  `Prepared By` varchar(128) NOT NULL,
  `Prepared Date/Time` datetime NOT NULL,
  `Volume` double(18,10) NOT NULL,
  `Value` double(18,10) DEFAULT NULL,
  `SLA` double(18,10) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Metric Id` (`Metric Id`,`SubRegion`,`Period`,`Team`,`Region`,`Target Id`)
) ENGINE=InnoDB AUTO_INCREMENT=1107 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

-- Dump completed on 2015-08-18 21:29:41
