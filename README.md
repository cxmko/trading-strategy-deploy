# Algorithmic Trading Strategy Deployment Platform

![AWS](https://img.shields.io/badge/AWS-EC2-orange)
![Terraform](https://img.shields.io/badge/Infra-Terraform-purple)
![Docker](https://img.shields.io/badge/Container-Docker-blue)
![Conda](https://img.shields.io/badge/Environment-Conda-green)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub_Actions-blue)

A cloud-agnostic platform for deploying algorithmic trading strategies with automated infrastructure management.

## Current Features
- **Multi-Cloud Ready**: AWS infrastructure (with future Oracle Cloud compatibility)
- **Streamlit Dashboard**: Real-time trading visualization
- **Infrastructure-as-Code**: Terraform-managed cloud resources
- **Containerized Services**: Docker-based microservices architecture
- **Cost Monitoring**: AWS Cost Explorer integration

## Installation Guide

### Prerequisites
- Python 3.9+
- Conda/Miniconda
- Docker Engine 20.10+
- AWS Account
- Terraform 1.7+

### Setup
1. **Clone Repository**
   ```bash
   git clone https://github.com/cxmko/trading-strategy-deploy.git
   cd trading-strategy-deploy
   ```

2. **Configure Environments**
   ```bash
   # AWS Trading Environment
   conda env create -f aws/environment.yml
   
   # Local Dashboard
   conda env create -f app/environment.yml
   ```

3. **AWS Credentials**
   ```bash
   mkdir -p ~/.aws
   echo "[default]
   aws_access_key_id = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   region = us-east-1" > ~/.aws/credentials
   ```

4. **Docker Setup**
   ```bash
   docker-compose build
   ```

### Deployment
**Local Development**
```bash
docker-compose up local-app
# Access dashboard at http://localhost:8501
```

**AWS Deployment**
```bash
cd aws/infra
terraform init
terraform apply -auto-approve
```

**Cleanup**
```bash
terraform destroy -auto-approve
```

## AWS Cost Monitoring System

### Python Cost Checker Script
The `aws/src/cost_checker.py` provides real-time cost tracking:


### Usage
**Local Execution:**
```bash
conda activate aws-trading
python aws/src/cost_checker.py

# Expected output:
AWS Costs (Last 7 Days):
2025-02-01: $12.34
2025-02-02: $15.67
...
```

**Docker Execution:**
```bash
docker-compose run aws-services python src/cost_checker.py
```

## GitHub Actions Deployment

1. **Repository Secrets**  
   Add these in GitHub Settings → Secrets → Actions:
   - `AWS_ACCESS_KEY_ID`: Your IAM access key
   - `AWS_SECRET_ACCESS_KEY`: Associated secret key

2. **Workflow Configuration**  
   The deployment workflow (`.github/workflows/deploy-aws.yml`) triggers on:
   ```yaml
   on:
     push:
       paths:
         - 'aws/**'           # AWS infrastructure changes
         - '.github/workflows/deploy-aws.yml'  # Workflow updates
   ```

3. **Monitoring Deployments**  
   Check execution in GitHub → Actions → "Deploy to AWS":
   - Successful deployments show green checkmarks
   - Destroy phase always runs post-deployment
   - View Terraform output in workflow logs

## Project Structure
```
.
├── app/                   # Local trading components
│   ├── src/              # Dashboard and data generation
│   ├── environment.yml   # Conda dependencies
│   └── Dockerfile        # Local service container
│
├── aws/                  # AWS infrastructure
│   ├── infra/            # Terraform configurations
│   ├── src/              # Trading strategy logic
│   ├── environment.yml   # AWS dependencies
│   └── Dockerfile        # AWS service container
│
├── oracle/               # Future Oracle Cloud integration
│
└── docker-compose.yml    # Multi-service orchestration
```



## License
MIT License - See [LICENSE](LICENSE) for details









**GitHub Actions Integration:**
The deployment workflow automatically runs cost checks:
```yaml
- name: Run Cost Check
  run: python aws/src/cost_checker.py
  env:
    AWS_DEFAULT_REGION: us-east-1
```


