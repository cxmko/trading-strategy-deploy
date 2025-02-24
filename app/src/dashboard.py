import streamlit as st
import sqlite3
import pandas as pd
import numpy as np
import time
import plotly.graph_objects as go
from datetime import datetime, timedelta

# ========== Configuration ========== #
st.set_page_config(
    page_title="🚀 Dogecoin Pro Trader",
    page_icon="🐶",
    layout="wide"
)

# Custom CSS
st.markdown("""
    <style>
    .header { font-size:32px !important; color: #FFD700 !important; border-bottom: 2px solid #FFD700; padding-bottom: 10px; }
    .metric-box { padding:20px; border-radius:15px; background: #1a1a1a; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    .positive { color: #00FF00; } .negative { color: #FF0000; }
    </style>
""", unsafe_allow_html=True)

# ========== Enhanced GBM Model ========== #
def generate_gbm_price(previous_price, mu, sigma):
    """More frequent price updates"""
    dt = 1/(24*60*12)  # 5-second intervals
    drift = (mu - 0.5 * sigma**2) * dt
    shock = sigma * np.random.normal() * np.sqrt(dt)
    new_price = previous_price * np.exp(drift + shock)
    return max(0.01, min(100.0, new_price))

# ========== Database Setup ========== #
@st.cache_resource
def init_db():
    conn = sqlite3.connect('trades.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS trades
                (timestamp TEXT, symbol TEXT, price REAL)''')
    
    # Initialize with 30-second interval history
    if c.execute("SELECT COUNT(*) FROM trades").fetchone()[0] == 0:
        base_time = datetime.utcnow().replace(second=0, microsecond=0) - timedelta(minutes=30)
        price = 0.08
        for i in range(360):  # 30 minutes of history
            timestamp = (base_time + timedelta(seconds=5*i)).isoformat() + 'Z'
            price = generate_gbm_price(price, 0.002, 0.25)  # Increased volatility
            c.execute("INSERT INTO trades VALUES (?, 'DOGE-USD', ?)", (timestamp, price))
        conn.commit()
    
    return conn

conn = init_db()

# ========== UI Components ========== #
def calculate_metrics(df):
    latest = df.iloc[-1]
    return {
        'price': latest['price'],
        'change_pct': (latest['price'] - df.iloc[-2]['price'])/df.iloc[-2]['price']*100,
        '12_ma': df['price'].rolling(12).mean().iloc[-1],  # 1-minute MA (12*5s)
        'upper_band': df['price'].rolling(12).mean().iloc[-1] + 2*df['price'].rolling(12).std().iloc[-1],
        'lower_band': df['price'].rolling(12).mean().iloc[-1] - 2*df['price'].rolling(12).std().iloc[-1]
    }

def create_candlestick(df):
    df = df.copy()
    df['timestamp'] = pd.to_datetime(df['timestamp'], utc=True)
    df = df.set_index('timestamp').sort_index()
    
    # Resample to 30-second candles
    ohlc = df['price'].resample('30S').agg({
        'Open': 'first',
        'High': 'max',
        'Low': 'min',
        'Close': 'last'
    }).ffill()
    
    # Limit to last 30 minutes
    ohlc = ohlc.last('30T')
    
    fig = go.Figure(data=[go.Candlestick(
        x=ohlc.index,
        open=ohlc['Open'],
        high=ohlc['High'],
        low=ohlc['Low'],
        close=ohlc['Close'],
        increasing_line_color='#00FF00',
        decreasing_line_color='#FF0000'
    )])
    fig.update_layout(xaxis_range=[ohlc.index[-1] - timedelta(minutes=30), ohlc.index[-1]])
    return fig

# ========== Main Loop ========== #
placeholder = st.empty()
current_price = 0.08
mu = 0.002    # Higher drift for visible changes
sigma = 0.25  # 25% daily volatility

while True:
    current_price = generate_gbm_price(current_price, mu, sigma)
    timestamp = datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'
    
    c = conn.cursor()
    c.execute("INSERT INTO trades VALUES (?, 'DOGE-USD', ?)", (timestamp, current_price))
    conn.commit()
    
    df = pd.read_sql(f"""
        SELECT * FROM trades 
        WHERE timestamp >= datetime('now', '-30 minutes', 'utc')
        ORDER BY timestamp ASC
    """, conn)
    
    with placeholder.container():
        if len(df) < 12:
            st.progress(len(df)/12)
            st.info(f"📈 Initializing... ({len(df)}/12 samples)")
            time.sleep(1)
            continue
            
        metrics = calculate_metrics(df)
        fig = create_candlestick(df)
        
        # Header
        st.markdown("<div class='header'>🐶 Dogecoin Pro Trading Suite</div>", unsafe_allow_html=True)
        
        # Metrics
        cols = st.columns(4)
        metrics_data = [
            ("PRICE", f"${metrics['price']:.4f}", f"{metrics['change_pct']:+.2f}%"),
            ("12-MA", f"${metrics['12_ma']:.4f}", "Bollinger Bands"),
            ("VOLATILITY", f"25.0%", "Daily σ"),
            ("TREND", "Bullish" if metrics['price'] > metrics['12_ma'] else "Bearish", "vs MA")
        ]
        
        for col, (title, value, sub) in zip(cols, metrics_data):
            with col:
                st.markdown(f"""
                    <div class='metric-box'>
                        <div style="font-size:18px">{title}</div>
                        <h2>{value}</h2>
                        <div>{sub}</div>
                    </div>
                """, unsafe_allow_html=True)
        
        # Chart
        st.subheader("📊 30-Second Candlestick Chart")
        fig.update_layout(
            height=500,
            xaxis_rangeslider_visible=False,
            template="plotly_dark",
            margin=dict(l=20, r=20, t=20, b=20)
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Order Book
        st.subheader("📈 Depth Chart")
        spread = abs(current_price * 0.01)  # 1% spread
        bids = [(current_price * (1 - i*0.002), 1000 - i*100) for i in range(1, 6)]
        asks = [(current_price * (1 + i*0.002), 1000 - i*100) for i in range(1, 6)]
        
        col1, col2 = st.columns(2)
        with col1:
            st.markdown("**Bids**")
            for price, qty in reversed(bids):
                st.markdown(f"<div class='positive'>${price:.4f} × {qty}</div>", unsafe_allow_html=True)
        with col2:
            st.markdown("**Asks**")
            for price, qty in asks:
                st.markdown(f"<div class='negative'>${price:.4f} × {qty}</div>", unsafe_allow_html=True)

    time.sleep(5)  # Update every 5 seconds