import logging
import os
import pandas as pd
from sklearn.linear_model import LinearRegression

# Configure logging
os.makedirs('/app/logs', exist_ok=True)
logging.basicConfig(
    filename='/app/logs/output.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

def train_model(data):
    X = data[['feature']]
    y = data['spread']
    model = LinearRegression()
    model.fit(X, y)
    return model

def execute_trade(model, new_data):
    prediction = model.predict(new_data)
    return 'BUY' if prediction > 0 else 'SELL'

if __name__ == "__main__":
    logging.info("Strategy running in eu-west-3!")
    print("Strategy running in eu-west-3!")