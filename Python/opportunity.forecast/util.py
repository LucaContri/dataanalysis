from dateutil.parser import parse
import pandas as pd
import logging
import logging.config
import inspect
import os
import pymysql as db
from pyjavaproperties import Properties
from collections import defaultdict
import numpy as np
from sklearn.ensemble import RandomForestClassifier

logging.config.fileConfig('/SAI/properties/python.log.conf')
name = inspect.getfile(inspect.currentframe())
logging = logging.getLogger(name)

def get_properties(file_name = None):
	if file_name is None:
		file_name = 'C:/SAI/properties/global.config.properties'
	p = Properties()
	p.load(open(file_name))
	return p

def get_paths():
	p = get_properties()
	reportfolder = p['ReportFolder']
	data_path = os.path.join(reportfolder, "Opportunities")
	submission_path = os.path.join(reportfolder, "Opportunities/forecast")
	return data_path, submission_path

def get_connection(datasource):
	p = get_properties()
	filtered = [(t[0].split('.')[2], t[1]) for t in p.items() if ''+datasource+'' in t[0]]
	if len(filtered)<=0:
		return null
	else:
		user = [t[1] for t in filtered if t[0] == 'DbUser'][0]
		password = [t[1] for t in filtered if t[0] == 'DbPassword'][0]
		host = [t[1] for t in filtered if t[0] == 'DbHost'][0]
		port = [t[1] for t in filtered if t[0] == 'DbPassword'][0]
		schema = [t[1] for t in filtered if t[0] == 'DbSchema'][0]
		return db.connect(host=host, port=3306, user=user, passwd=password, db=schema)

def save_predictions(data, instance = None):
	if instance is None:
		instance = "corporate"
		logging.debug("No instance specified.  Assuming %s", instance)
	conn = get_connection('analytics')
	insert = 'insert into analytics.opportunity_forecast values '
	for index, row in data.iterrows():
		insert += "('" + row['Id'] + "','" + instance + "', utc_timestamp(), " + str(row['predictions']) + '),'
	
	cur = conn.cursor()
	cur.execute(insert[:-1])
	conn.commit()

def get_to_be_forecasted_df(schema = None):
	if schema is None:
		schema = "training"
		logging.debug("No schema specified.  Assuming %s", schema)
	mysql_con = get_connection(schema)
	query = """
		(select 
			o.Id,
			o.CreatedDate as 'Date Created',
			o.LastModifiedDate as 'Date Updated',
			o.Type,
			a.Name as 'Client',
			oo.Name as 'Owner',
			ifnull(o.LeadSource,'') as 'Lead Source',
			ifnull(o.Contract_Term__c,'') as 'Contract Term',
			timestampdiff(day,o.createdDate,utc_timestamp()) as 'Aging Created',
			o.Amount/ct.ConversionRate as 'Amount AUD',
			o.Probability,
			ifnull(o.Region__c,'') as 'Region',
			BillingCountry, 
			BillingState, 
			a.Industry, 
			a.Industry_Vertical__c, 
			a.Industry_Sub_group__c,
			null as 'IsWon'
		from training.opportunity o
		left join salesforce.currencytype ct on o.CurrencyIsoCode = ct.IsoCode
		left join training.user oo on o.OwnerId = oo.Id
		left join training.account a on o.AccountId = a.Id
		where
			o.IsDeleted = 0
			and o.StageName not in ('Closed Won', 'Closed Lost')
			and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
		group by o.Id
		order by o.LastModifiedDate);"""
	return pd.read_sql(query, con=mysql_con)
	
def get_train_df(schema = None):
	if schema is None:
		schema = "training"
		logging.debug("No schema specified.  Assuming %s", schema)

	mysql_con = get_connection(schema)
	query = """
		(select 
			o.Id,
			o.CreatedDate as 'Date Created',
			oh.CreatedDate as 'Date Updated',
			o.Type,
			a.Name as 'Client',
			oo.Name as 'Owner',
			ifnull(o.LeadSource,'') as 'Lead Source',
			ifnull(o.Contract_Term__c,'') as 'Contract Term',
			timestampdiff(day,o.createdDate,oh.CreatedDate) as 'Aging Created',
			oh.Amount/ct.ConversionRate as 'Amount AUD',
			oh.Probability,
			ifnull(o.Region__c,'') as 'Region',
			#BillingCity, 
			BillingCountry, 
			#BillingPostalCode, 
			BillingState, 
			a.Industry, 
			a.Industry_Vertical__c, 
			a.Industry_Sub_group__c,
			o.IsWon
		from training.opportunity o
		inner join training.opportunityhistory oh on oh.OpportunityId = o.Id and oh.IsDeleted = 0
		#inner join training.recordtype rt on o.RecordTypeId = rt.Id
		left join salesforce.currencytype ct on oh.CurrencyIsoCode = ct.IsoCode
		left join training.user oo on o.OwnerId = oo.Id
		left join training.account a on o.AccountId = a.Id
	where
		o.IsDeleted = 0
		and o.StageName in ('Closed Won', 'Closed Lost')
		and oh.StageName not in ('Closed Won', 'Closed Lost')
		and o.Type in ('BV - GRC - Implementation Services','BV - EHS - Implementation Services')
		#and rt.Name in ('Compliance Asia Pacific Opportunity Record Type', 'CMPL - APAC - Opportunity Record Type')
	group by oh.Id
	order by oh.CreatedDate);"""
	return pd.read_sql(query, con=mysql_con)

def clean_data(data = None):
	if data is None:
		logging.debug("Importing train dataset")
		data = util.get_train_df()
		logging.debug("Size train:" + str(len(data)))

	logging.debug("Removing unused columns")
	columns = set(data.columns)
	columns.remove("Amount AUD")
	columns.remove("IsWon")
	columns.remove("Id")
	columns.remove("Date Created")
	columns.remove("Date Updated")
	columns.remove("Client")
	
	train_fea = pd.DataFrame({"Amount AUD": data["Amount AUD"].fillna(-1)})
	
	logging.debug("Converting data")
	for col in columns:
		if data[col].dtype == np.dtype('object'):
			s = np.unique(data[col].fillna('').values)
			mapping = pd.Series([x[0] for x in enumerate(s)], index = s)
			train_fea = train_fea.join(data[col].map(mapping).fillna(-1))
		else:
			train_fea = train_fea.join(data[col].fillna(0))
	return train_fea

def build_model(schema = None, train = None):
	if schema is None:
		logging.debug('Schema not provided.  Assuming training')
		schema = "training"
	if train is None:
		logging.debug('Train data not provided.  Pulling from database ' + schema)
		train = get_train_df(schema)
	train_fea = clean_data(train)
	logging.debug("Starting training")
	rf = RandomForestClassifier(n_estimators=300, n_jobs=1)
	rf.fit(train_fea, train["IsWon"])
	return rf

def write_submission(submission_name, test, submission_path=None):
    if submission_path is None:
        data_path, submission_path = get_paths()
    
    test.to_csv(os.path.join(submission_path,
        submission_name), index=False)
		
def get_date_dataframe(date_column):
    return pd.DataFrame({
        "DeliveryYear": [d.year for d in date_column],
        "DeliveryMonth": [d.month for d in date_column],
        "DeliveryDay": [d.day for d in date_column]
        }, index=date_column.index)