import numpy as np
from matplotlib import pyplot as plt

from sklearn.datasets import make_biclusters
from sklearn.datasets import samples_generator as sg
from sklearn.cluster.bicluster import SpectralCoclustering
from sklearn.metrics import consensus_score
import pandas as pd

df=pd.read_csv('c:\Users\conluc0\Downloads\data\\auditors.uk.2018.03.txt', sep=',',header=None)

df = df.loc[:, (df != 0).any(axis=0)]
df = df.loc[(df != 0).any(axis=1),:]
data = df.values

#data, rows, columns = make_biclusters(shape=(71, 158), n_clusters=2, noise=0,shuffle=False, random_state=0, minval=0, maxval=1)

plt.matshow(data, cmap=plt.cm.Blues)
plt.title("Original dataset")

#data, row_idx, col_idx = sg._shuffle(data, random_state=0)
#plt.matshow(data, cmap=plt.cm.Blues)
#plt.title("Shuffled dataset")

model = SpectralCoclustering(n_clusters=2, random_state=0, svd_method='arpack')
model.fit(data)
#print model.rows_[model.rows_==True]
#print model.columns_
#score = consensus_score(model.biclusters_,(rows[:, row_idx], columns[:, col_idx]))

#print("consensus score: {:.3f}".format(score))

fit_data = data[np.argsort(model.row_labels_)]
fit_data = fit_data[:, np.argsort(model.column_labels_)]

plt.matshow(fit_data, cmap=plt.cm.Blues)
plt.title("After biclustering; rearranged to show biclusters")

plt.show()