import random
import sqlite3
from datetime import datetime
import time

def generate_data():
    conn = sqlite3.connect('/app/db/trades.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS trades
                (timestamp TEXT, symbol TEXT, price REAL)''')
    
    while True:
        timestamp = datetime.now().isoformat()
        price = round(random.uniform(45000, 50000), 2)
        c.execute("INSERT INTO trades VALUES (?, 'BTC-USD', ?)", (timestamp, price))
        conn.commit()
        time.sleep(30)  # Update every 30 seconds

if __name__ == "__main__":
    generate_data()