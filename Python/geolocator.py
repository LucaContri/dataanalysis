from geopy.geocoders import Bing
import pymysql as db
import pandas as pd
import sys

reload(sys)
sys.setdefaultencoding("utf-8")

def SQLEsc(s):
	if s == None:
		return "NULL"
	else:
		print(s)
		return "'"+str.replace(str(s), "'", "''")+"'"

conn = db.connect(host="analytics.assurance.saiglobal.com", port=3306, user="luca", passwd="s7nsh8n3", db="analytics", charset='utf8')
query = """select aco.Address as 'Address' from analytics.aerospace_certified_organisations aco left join analytics.accredia_addresses aa on aa.Address = aco.Address where aa.Address is null limit 10000;"""
data = pd.read_sql(query, con=conn)
cur = conn.cursor()
geocoder = Bing('AqjA9KVwwFhOONfU8dDe1fZnnlJpu0cu3J5J4cjtsm4C5R9XB-3mvWKLdHbnna8k', format_string='%s', scheme='https', timeout=1, proxies=None, user_agent=None)

for address in data['Address']:
	try:
		location = geocoder.geocode(address)
		if location is not None:
			formattedAddress = str(location.address)
			countryRegion, adminDistrict, adminDistrict2, locality, postalCode = None, None, None, None, None
			if 'address' in location.raw:
				if 'countryRegion' in location.raw['address']:
					countryRegion = str(location.raw['address']['countryRegion'])
				if 'adminDistrict' in location.raw['address']:
					adminDistrict = str(location.raw['address']['adminDistrict'])
				if 'adminDistrict2' in location.raw['address']:
					adminDistrict2 = str(location.raw['address']['adminDistrict2'])
				if 'locality' in location.raw['address']:
					locality = str(location.raw['address']['locality'])
				if 'postalCode' in location.raw['address']:
					postalCode = str(location.raw['address']['postalCode'])
			
			insert = "insert into analytics.accredia_addresses (Address, FormattedAddress, locality, administrative_area_level_2, administrative_area_level_1, Country, PostCode, Latitude, Longitude) values(" + SQLEsc(address) + ", " + SQLEsc(str(location.address)) + ", " + SQLEsc(locality) + ", " + SQLEsc(adminDistrict2) + ", " + SQLEsc(adminDistrict) + ", " + SQLEsc(countryRegion) + ", " + SQLEsc(postalCode) + ", " + str(location.latitude) + ", " + str(location.longitude) + ")"
			print(insert)
			cur.execute(insert)
			conn.commit();
		else:
			print('Location not found: %s' % (address))
			insert = "insert into analytics.accredia_addresses (Address) values(" + SQLEsc(address) + ")"
			cur.execute(insert)
			conn.commit();
	except:
		pass

