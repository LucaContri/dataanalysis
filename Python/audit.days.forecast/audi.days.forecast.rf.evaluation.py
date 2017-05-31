import util
import pandas as pd
import logging
import logging.config
import inspect
import os
import matplotlib.pyplot as plt

logging.config.fileConfig('/SAI/properties/python.log.conf')
name = inspect.getfile(inspect.currentframe())
logging = logging.getLogger(name)

logging.info('Starting %s', name)

data_path, submission_path = util.get_paths()

data = util.get_train_df(data_path)
train = data[(data['Country']=='Australia') & (data['Period'] != '2015 08')]
test = data[(data['Country']=='Australia') & (data['Period'] == '2015 08')]

util.write_submission("risk.closed.opportunities.train.csv", train, data_path)
util.write_submission("risk.closed.opportunities.test.csv", test, data_path)

train_fea = util.clean_data(train)
test_fea = util.clean_data(test)
rf = util.build_model(train_fea, train['Final Confirmed Days'])

logging.info("Starting predicting")
predictions = rf.predict(test_fea)
error = (predictions - test['Final Confirmed Days'])
error_perc = error/test['Final Confirmed Days']
pred_series = pd.Series(predictions, name="predictions", index=test.index)
error_series = pd.Series(error, name="error", index=test.index)
error_perc_series = pd.Series(error_perc, name="error_perc", index=test.index)
test = test.join(pred_series).join(error_series).join(error_perc_series)

logging.info("Writing submissions")
util.write_submission("audit.days.forecast.csv", test, submission_path)

logging.info("Results")
imp = sorted(zip(train_fea.columns, rf.feature_importances_), key=lambda tup: tup[1], reverse=True)
for fea in imp:
    logging.info(fea)

plt.plot(error_perc)
plt.ylabel('Error %')
plt.show()