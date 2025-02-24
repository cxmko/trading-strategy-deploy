# src/cost_checker.py
import boto3
import logging
import os
from datetime import datetime, timedelta

# Configure logging
os.makedirs('/app/logs', exist_ok=True)
logging.basicConfig(
    filename='/app/logs/output.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)


def check_cost():
    client = boto3.client('ce')
    end_date = datetime.utcnow().strftime('%Y-%m-%d')
    start_date = (datetime.utcnow() - timedelta(days=7)).strftime('%Y-%m-%d')
    
    response = client.get_cost_and_usage(
        TimePeriod={'Start': start_date, 'End': end_date},
        Granularity='DAILY',
        Metrics=['UnblendedCost']
    )
    
    logging.info("AWS Costs (Last 7 Days):")
    for day in response['ResultsByTime']:
        log_msg = f"{day['TimePeriod']['Start']}: ${day['Total']['UnblendedCost']['Amount']}"
        logging.info(log_msg)
        print(f"{day['TimePeriod']['Start']}: ${day['Total']['UnblendedCost']['Amount']}")

if __name__ == "__main__":
    check_cost()