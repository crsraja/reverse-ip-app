# Demo - AWS ECS Deployment with Secure CI/CD Pipeline

## 📌 Project Overview
This project deploys a **web application** that returns the **reversed public IP** of any request.  
It is deployed on **AWS ECS (Fargate)** using **Terraform** and a **CI/CD pipeline** built with **AWS CodePipeline & CodeBuild**.  

### ✅ Features:
- **Terraform Infrastructure as Code (IaC)**
- **ECS Fargate Deployment with AWS ECR**
- **CI/CD Pipeline using AWS CodePipeline**
- **Security Scans:**
  - ✅ **Checkov** → Terraform misconfiguration detection
  - ✅ **Trivy** → Docker image vulnerability scanning
- **IAM Roles for CI/CD & ECS**
- **YAML-based Terraform variables (`terraform.yaml`)**

---



