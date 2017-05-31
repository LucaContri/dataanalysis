# Addding support for stats on multiple regions
alter table sf_prdsupport.sf_report_history add column Region varchar(63) after Date;
alter table sf_data add column Region varchar(63) after CreateDate;

SET SQL_SAFE_UPDATES = 0;
update sf_data set Region='Australia - MS' where DataType like '%Audit Days%' and DataSubType='MS';
update sf_data set Region='Australia - Food' where DataType like '%Audit Days%' and DataSubType='Food';

insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-06-01', 1454);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-07-01', 1305);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-08-01', 1272);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-09-01', 1354);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-10-01', 1331);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-11-01', 1161);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2014-12-01', 801);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-01-01', 795);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-02-01', 1403);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-03-01', 1436);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-04-01', 1252);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-05-01', 1401);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Budget', 'MS', 'Budget', '2015-06-01', 1155);

insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-06-01', 265);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-07-01', 243);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-08-01', 251);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-09-01', 250);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-10-01', 251);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-11-01', 241);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2014-12-01', 192);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-01-01', 167);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-02-01', 244);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-03-01', 265);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-04-01', 253);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-05-01', 285);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Budget', 'Food', 'Budget', '2015-06-01', 213);


insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-07-01', 1305);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-08-01', 1272);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-09-01', 1354);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-10-01', 1331);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-11-01', 1161);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2014-12-01', 801);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-01-01', 795);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-02-01', 1403);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-03-01', 1436);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-04-01', 1252);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-05-01', 1401);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - MS', 'Audit Days Forecast', 'MS', 'Forecast', '2015-06-01', 1155);

insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-07-01', 243);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-08-01', 251);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-09-01', 250);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-10-01', 251);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-11-01', 241);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2014-12-01', 192);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-01-01', 167);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-02-01', 244);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-03-01', 265);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-04-01', 253);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-05-01', 285);
insert into sf_data (CreateDate, Region, DataType, DataSubType, RefName, RefDate, RefValue) VALUES (now(), 'Australia - Food', 'Audit Days Forecast', 'Food', 'Forecast', '2015-06-01', 213);