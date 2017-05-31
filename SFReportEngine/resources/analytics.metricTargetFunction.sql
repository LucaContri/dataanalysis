drop FUNCTION analytics.getTarget;
DELIMITER //
CREATE FUNCTION analytics.getTarget(Metric VARCHAR(64), Region VARCHAR(64), Standard VARCHAR(256)) RETURNS INTEGER
BEGIN
	DECLARE target INTEGER DEFAULT null;
    SET target = (SELECT 
		IF(Metric = 'arg_submission_first',5,
		IF(Metric = 'arg_submission_resubmission',2,
        IF(Metric = 'arg_revision_first', 5,
		IF(Metric = 'arg_revision_resubmission',2,
		IF(Metric = 'arg_completion',5,
        IF(Metric = 'arg_process_other',15,
		IF(Metric = 'arg_process_brc', 30, 
        IF(Metric = 'scheduling_lifecycle_sla',7,
		IF(Metric = 'scheduling_scheduled_sla',14,
		IF(Metric = 'scheduling_scheduled_offered_sla',35,
		IF(Metric = 'scheduling_confirmed_sla',-28,
		IF(Metric = 'scheduling_open_substatus_sla',365,null)))))))))))));
        
    RETURN target;
 END //
DELIMITER ;

DROP FUNCTION analytics.getBusinessDays;
DELIMITER //
CREATE FUNCTION `getBusinessDays`(utc_from_date datetime, utc_to_date datetime, timezone varchar(64)) RETURNS INTEGER
BEGIN
	# Used to calculate business days between dates.
    # Accept UTC from and to timestamps and timezone
    # Returns number of business days between from_date and to_date.  Partial business days are counted as 1
    # Assumptions:
	#	1) Business days Mon - Fri regardless of timezone
    #	2) No public holidays
    #	3) Business hours 9.00 to 17:00 regardless of timezone
    #	4) if timezone is null we assume 'UTC'.
    DECLARE business_days INTEGER;
    DECLARE local_from_date DATETIME;
    DECLARE local_to_date DATETIME;
    SET business_days = (SELECT 0);
    SET local_to_date = (SELECT convert_tz(utc_to_date,'UTC', timezone));
    SET local_from_date = (SELECT date_format(date_add(convert_tz(utc_from_date,'UTC', timezone), interval if (date_format(convert_tz(utc_from_date,'UTC', timezone), '%H%m')<'1700',0,1) day), '%Y-%m-%d 09:00:00'));
    WHILE local_from_date < local_to_date DO
		SET business_days = (SELECT business_days + IF(date_format(local_from_date, '%W') in ('Saturday','Sunday'),0,1));
        SET local_from_date = date_add(local_from_date, interval 1 day);
	END WHILE;
    RETURN business_days;
 END //
DELIMITER ;

# Test Business Days Function
SET @from_date = '2015-09-22 8:00:00';
SET @to_date = '2015-09-29 9:01:00';
select utc_timestamp(), date_add(utc_timestamp(), interval 3 day), getBusinessDays(utc_timestamp(),date_add(utc_timestamp(), interval 3 day), 'Australia/Sydney');