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
	data_path = os.path.join(reportfolder, "AuditDays")
	submission_path = os.path.join(reportfolder, "AuditDays\\forecast")
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
	
	return pd.read_sql(query, con=mysql_con)
	
def get_train_df(data_path):
	return pd.read_csv(data_path + '/snapshots.csv')

def clean_data(data):

	logging.debug("Removing unused columns")
	columns = set(data.columns)
	columns.remove("Report Date")
	columns.remove("Region")
	columns.remove("Final Confirmed Days")
	columns.remove("Available/Final Confirmed")
	columns.remove("Country")
	columns.remove("Period")
	#columns.remove("Month")
	#columns.remove("Quarter")
	columns.remove("Year")
	columns.remove("Period End Date")
	columns.remove("Open")
	
	train_fea = pd.DataFrame({"Open": data["Open"].fillna(-1)})
	
	logging.debug("Converting data")
	for col in columns:
		if data[col].dtype == np.dtype('object'):
			s = np.unique(data[col].fillna('').values)
			mapping = pd.Series([x[0] for x in enumerate(s)], index = s)
			train_fea = train_fea.join(data[col].map(mapping).fillna(-1))
		else:
			train_fea = train_fea.join(data[col].fillna(0))
	return train_fea

def build_model(train_fea, train_res):
	rf = RandomForestClassifier(n_estimators=300, n_jobs=1)
	rf.fit(train_fea, train_res)
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