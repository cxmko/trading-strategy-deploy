import pandas as pd
from sklearn.linear_model import LinearRegression

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
    print("Strategy running in eu-west-3!")