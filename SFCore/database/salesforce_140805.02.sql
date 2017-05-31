use salesforce;
alter table sf_data add column current TINYINT(1) not null default 1;
alter table sf_data modify column DataType varchar(50);