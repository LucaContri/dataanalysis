import util
import pandas as pd
import logging
import logging.config
import inspect
import os

logging.config.fileConfig('/SAI/properties/python.log.conf')
name = inspect.getfile(inspect.currentframe())
logging = logging.getLogger(name)

logging.info('Starting %s', name)

schema = 'training'
data_path, submission_path = util.get_paths()

train = util.get_train_df(schema)
train = train.sort(['Date Updated'], ascending=True)
train, test = train[:int(len(train)*.9)], train[int(len(train)*.9):]

util.write_submission("risk.closed.opportunities.train.csv", train, data_path)
util.write_submission("risk.closed.opportunities.test.csv", test, data_path)

train_fea = util.clean_data(train)
test_fea = util.clean_data(test)
rf = util.build_model(schema, train)

logging.info("Starting predicting")
predictions = rf.predict(test_fea)

logging.info("Writing submissions")
pred_series = pd.Series(predictions, name="predictions", index=test.index)
test = test.join(pred_series)

util.write_submission("risk.closed.opportunities.forecast.csv", test, submission_path)

logging.info("Results")
imp = sorted(zip(train_fea.columns, rf.feature_importances_), key=lambda tup: tup[1], reverse=True)
for fea in imp:
    logging.info(fea)

guessed = test["IsWon"]==test["predictions"]
logging.info("Success Rate: " + "{:.2%}".format(guessed.mean()))
logging.info('Finished %s', name)