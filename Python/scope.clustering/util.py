import pymysql as db
import pandas as pd
import nltk
import re

def get_scopes():
	conn = db.connect(host="analytics.assurance.saiglobal.com", port=3306, user="luca", passwd="s7nsh8n3", db="analytics", charset='utf8')
	#query = "select aco.CompanyName as 'client', aco.Scope as 'scope' from analytics.accredia_certified_organisations aco where aco.Scope is not null limit 100000;"
	query = """select client.Name as 'client', csp.Scope__c as 'scope'
	from salesforce.certification_standard_program__c csp 
	inner join salesforce.administration_group__c ag on csp.Administration_Ownership__c = ag.Id
	inner join salesforce.certification__c c on csp.Certification__c = c.Id
	inner join salesforce.account client on c.Primary_client__c = client.Id
	where ag.Name = 'AUS-Management Systems' 
	and csp.Status__c in ('Registered', 'Customised')
	and csp.Scope__c is not null
	group by `client`
	;"""
	return pd.read_sql(query, con=conn)

def tokenize_and_stem(text):
	stemmer = nltk.stem.snowball.SnowballStemmer("english")
	filtered_tokens = tokenize_only(text)
	stems = [stemmer.stem(t) for t in filtered_tokens]
	return stems

def tokenize_only(text):
	# first tokenize by sentence, then by word to ensure that punctuation is caught as it's own token
	tokens = [word.lower() for sent in nltk.sent_tokenize(text) for word in nltk.word_tokenize(sent)]
	filtered_tokens = []
	# filter out any tokens not containing letters (e.g., numeric tokens, raw punctuation)
	for token in tokens:
		if re.search('[a-zA-Z]', token):
			filtered_tokens.append(token)
	return filtered_tokens