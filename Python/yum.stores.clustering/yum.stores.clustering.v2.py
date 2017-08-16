import pymysql as db
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.cluster.vq import kmeans2
from geopy.distance import vincenty
import sys

reload(sys)
sys.setdefaultencoding("utf-8")

avg_speed = 50
avg_duration = 3.5
no_audits_per_site_per_year = 4
milk_run_size = 1

print("Input Variables:")
print("No Audits per site per year: " + str(no_audits_per_site_per_year))
print("Average Audit Duration: " + str(avg_duration) + " hours")
print("Average Travel Speed: " + str(avg_speed) + " km/h")
print("")
print("Connecting to DB");
print("")
conn = db.connect(host="analytics.assurance.saiglobal.com", port=3306, user="luca", passwd="s7nsh8n3", db="analytics", charset='utf8')
query = "select geo.Latitude, geo.Longitude from analytics.yum_store ys inner join salesforce.Saig_geocode_cache geo on geo.Address = concat(ifnull(concat(ys.Site_Address_Line_1,' '),''),ifnull(concat(ys.Site_Address_Line_2,' '),''),ifnull(concat(ys.Site_City,' '),''),ifnull(concat(ys.`Site_Province/State`,' '),''),ifnull(concat(ys.Site_Country,' '),''),ifnull(concat(ys.Site_Postal_Code,' '),''))"
print("Executing query");
print("")
coordinates = pd.read_sql(query, con=conn).values
clusters = pd.DataFrame(index=np.arange(10), columns = (
  "# clusters", 
  "max cluster size", 
  "min cluster size", 
  "total distance", 
  "average distance",
  "max cluster audit days",
  "min cluster audit days"));

print("Clustering")
range_from = 15
range_to = 15
K = range(range_from,range_to)
for k in K:
	print("Cluster size " + str(k));
	centroids, labels = kmeans2(coordinates, k, iter = 100)
	sites = pd.DataFrame(coordinates)
	sites.columns = ["lat","lon"]
	sites["cluster"] = labels
	sites["distance"] = sites.apply(lambda row: vincenty((row["lat"], row["lon"]),(centroids[row["cluster"]][0], centroids[row["cluster"]][1])).km, axis=1)
	sites["audit plus travel days"] = sites.apply(lambda row: (vincenty((row["lat"], row["lon"]),(centroids[row["cluster"]][0], centroids[row["cluster"]][1])).km*2/avg_speed/milk_run_size + avg_duration)*no_audits_per_site_per_year/8, axis=1)
	clusters["# clusters"][k-range_from] = k
	clusters["max cluster size"][k-range_from] = sites.groupby(["cluster"])["distance"].agg(['count']).max()[0]
	clusters["min cluster size"][k-range_from] = sites.groupby(["cluster"])["distance"].agg(['count']).min()[0]
	clusters["total distance"][k-range_from] = sites["distance"].sum()
	clusters["average distance"][k-range_from] = sites["distance"].mean()
	clusters["max cluster audit days"][k-range_from] = sites.groupby(["cluster"])["audit plus travel days"].agg(['sum']).max()[0]
	clusters["min cluster audit days"][k-range_from] = sites.groupby(["cluster"])["audit plus travel days"].agg(['sum']).min()[0]

print(clusters)
print("Plotting")
plt.plot(clusters["# clusters"], clusters["average distance"], color="blue", label="average distance")
#plt.plot(clusters["# clusters"], clusters["max cluster size"], color="green", label="max cluster size")
plt.plot(clusters["# clusters"], clusters["min cluster size"], color="green", label="min cluster size")
#plt.plot(clusters["# clusters"], clusters["max cluster audit days"], color="grey", label="max audit plus travel days/year")
#plt.plot(clusters["# clusters"], clusters["min cluster audit days"], color="black", label="min audit plus travel days/year")

plt.grid(True)
plt.legend()
plt.xlabel("Number of clusters")
plt.title("Elbow for K-Means clustering")
plt.show()