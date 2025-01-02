# Vitech CI/CD Pipeline and IaC for AWS

## Overview

This project sets up a CI/CD pipeline with four stages (Dev, QA, UAT, Prod) using GitHub Actions or Jenkins. Terraform scripts provision AWS resources.

## Prerequisites

- AWS CLI configured with admin access
- Terraform installed
- Docker installed
- SonarQube setup (optional)

## Infrastructure

![alt text](/assets/image.png)

- CodePipeline
- CodeBuild
- ECR
- Fargate
- S3 Buckets
- CloudWatch for logging

## Deployment Steps

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd <repository>

    Initialize Terraform:
   ```

terraform init

Plan and Apply Terraform scripts:

    terraform plan
    terraform apply -auto-approve

    Trigger the CI/CD pipeline by pushing code to the repository.

    Approve changes in each stage (QA, UAT, Prod) manually in the pipeline UI.

CI/CD Pipeline

    GitHub Actions is used for automation.
    Docker images are built and pushed to ECR.
    Fargate runs the batch jobs.
