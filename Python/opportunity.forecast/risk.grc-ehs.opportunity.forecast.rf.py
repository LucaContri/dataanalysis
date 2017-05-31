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
logging.debug('Init schema = %s', schema)
test = util.get_to_be_forecasted_df(schema)
logging.debug('Loaded open opportunities from schema %s', schema)
test_fea = util.clean_data(test)
logging.debug('Cleaned open opportunities for processing')
rf = util.build_model(schema)
logging.debug('Built model from schema %s', schema)

logging.debug("Start predicting")
predictions = rf.predict(test_fea)
logging.debug("Finished predicting")

logging.info("Saving predictions to database")
pred_series = pd.Series(predictions, name="predictions", index=test.index)
test = test.join(pred_series)

util.save_predictions(test, 'corporate')
logging.info('Finished %s', name)