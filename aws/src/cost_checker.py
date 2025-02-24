# src/cost_checker.py
import boto3
from datetime import datetime, timedelta

def check_cost():
    # Initialize AWS Cost Explorer client
    client = boto3.client('ce')
    
    # Set time range (last 7 days)
    end_date = datetime.utcnow().strftime('%Y-%m-%d')
    start_date = (datetime.utcnow() - timedelta(days=7)).strftime('%Y-%m-%d')
    
    # Query AWS costs
    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date,
            'End': end_date
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost']
    )
    
    print("AWS Costs (Last 7 Days):")
    for day in response['ResultsByTime']:
        print(f"{day['TimePeriod']['Start']}: ${day['Total']['UnblendedCost']['Amount']}")

if __name__ == "__main__":
    check_cost()