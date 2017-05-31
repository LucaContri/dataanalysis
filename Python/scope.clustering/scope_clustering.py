#http://brandonrose.org/clustering

from __future__ import print_function
from sklearn import feature_extraction
from sklearn.feature_extraction.text import TfidfVectorizer
import util
import csv
import numpy as np
import pandas as pd
import os
import codecs
import sys
import nltk

#import mpld3

reload(sys)
sys.setdefaultencoding("utf-8")

stopwords = nltk.corpus.stopwords.words('english')
stopwords.append('provision')
stopwords.append('includes')
stopwords.sort()

data = util.get_scopes()

totalvocab_stemmed = []
totalvocab_tokenized = []
for i in data['scope']:
    allwords_stemmed = util.tokenize_and_stem(i) #for each scope, tokenize/stem
    totalvocab_stemmed.extend(allwords_stemmed) #extend the 'totalvocab_stemmed' list
    
    allwords_tokenized = util.tokenize_only(i)
    totalvocab_tokenized.extend(allwords_tokenized)

vocab_frame = pd.DataFrame({'words': totalvocab_tokenized}, index = totalvocab_stemmed)
print ('there are ' + str(vocab_frame.shape[0]) + ' items in vocab_frame')

#define vectorizer parameters
tfidf_vectorizer = TfidfVectorizer(max_df=0.8, max_features=200000, min_df=0.0, stop_words=stopwords, use_idf=True, tokenizer=util.tokenize_and_stem, ngram_range=(1,3))

tfidf_matrix = tfidf_vectorizer.fit_transform(data['scope']) #fit the vectorizer to scopes
print(tfidf_matrix.shape)

terms = tfidf_vectorizer.get_feature_names()

from sklearn.metrics.pairwise import cosine_similarity
dist = 1 - cosine_similarity(tfidf_matrix)
print
print

from sklearn.cluster import KMeans

num_clusters = 5

km = KMeans(n_clusters=num_clusters)

km.fit(tfidf_matrix)

clusters = km.labels_.tolist()

companies = { 'name': data['client'], 'scope': data['scope'], 'cluster': clusters }

#frame = pd.DataFrame(companies, index = ['clusters'] , columns = ['name', 'scope', 'cluster'])
frame = pd.DataFrame(companies)
frame['cluster'].value_counts() #number of films per cluster (clusters from 0 to 4)


print("Top terms per cluster:")
print()
#sort cluster centers by proximity to centroid
order_centroids = km.cluster_centers_.argsort()[:, ::-1] 

for i in range(num_clusters):
    print("Cluster %d words:" % i, end='')
    
    for ind in order_centroids[i, :6]: # 6 with n words per cluster
        print(' %s' % vocab_frame.ix[terms[ind].split(' ')].values.tolist()[0][0].encode('utf-8', 'ignore'), end=',')
    print() #add whitespace
    print() #add whitespace
    
    print("Cluster %d companies:" % i, end='')
    for company in frame[frame['cluster']==i]['name'][:10].values.tolist():
        print(' %s,' % company, end='')
    print() #add whitespace
    print() #add whitespace
    
print()
print()
