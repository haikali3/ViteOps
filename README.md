# ViteOps Deployment with AWS Fargate and GitHub Actions

This repository automates the deployment of a Vite app using AWS ECS Fargate and GitHub Actions for CI/CD. The app is built with Vite, served using Nginx, and utilizes Amazon S3 and ECR.

## Infrastructure

![alt text](/assets/image.png)

## Prerequisites

- AWS CLI configured with admin access
- Terraform installed
- Docker installed
- SonarQube setup (optional)

### AWS Setup

- Ensure you have an AWS account with access to:
  - ECR repository: `haikali3/viteops`
  - S3 buckets: `s3-viteops-input` and `s3-viteops-output`
  - Necessary permissions to create ECS, IAM, and CloudWatch resources
- AWS CLI installed and configured

### Docker

- Ensure Docker is installed and running

### Node.js

- Install Node.js (v18)

### GitHub Secrets

Add the following secrets to your repository for GitHub Actions:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## How to Run Locally

1. Install Dependencies:

```bash
npm install
```

2. Build the App:

```bash
npm run build
```

3. Run Locally with Docker:

```bash
docker build -t vite-app .
docker run -p 80:80 vite-app
```

Access the app at http://localhost

## Deployment Steps

### 1. Deploy Infrastructure

Ensure you have Terraform installed. Run the following commands:

```bash
terraform init
terraform apply
```

Confirm the resource creation prompts.

### 2. CI/CD Pipeline

- Push changes to the main or develop branch to trigger the pipeline
- The pipeline will:
  - Build the Vite app
  - Build and push the Docker image to Amazon ECR
  - Deploy the task to AWS Fargate upon ECR image push

### 3. Trigger ECS Task

CloudWatch Event Rule automatically triggers the ECS task when a new image is pushed to ECR.

## Configuration

### S3 Buckets

- Input: `s3-viteops-input`
- Output: `s3-viteops-output`

### ECS Cluster

- Cluster Name: `fargate-cluster`
- Service Name: `fargate-service`

### IAM Roles

- `fargate_task_execution_role`: Grants ECS task access to S3 and ECR
- `cloudwatch_events_role`: Allows CloudWatch to trigger ECS tasks

### GitHub Actions Workflow

- Located in `.github/workflows/deploy.yml`

## Useful Commands

### Docker Login to ECR:

```bash
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

### Push Docker Image to ECR:

```bash
docker tag vite-app:latest <account_id>.dkr.ecr.ap-southeast-1.amazonaws.com/haikali3/viteops:latest
docker push <account_id>.dkr.ecr.ap-southeast-1.amazonaws.com/haikali3/viteops:latest
```

### Destroy Infrastructure with Terraform

Run Terraform destroy to delete all remaining resources:

```bash
terraform destroy
```


## Notes

- Ensure subnets and security groups in `main.tf` are correctly configured for your environment
- Replace `<account_id>` with your AWS account ID
