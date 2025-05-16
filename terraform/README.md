# Terraform Infrastructure Deployment

This project uses [Terraform](https://www.terraform.io/) to provision and manage infrastructure as code.

## 📁 Project Structure

```css
terraform/
├── backend.tf
├── instance.tf
├── instance_id.tf
├── provider.tf
├── keypair.tf
├── securitygrp.tf
├── vars.tf
└── README.md
```

## 🚀 Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- AWS CLI (if using AWS)
- AWS credentials configured (`~/.aws/credentials` or environment variables)

## 🔧 Usage

### 1. Initialize Terraform\*\*

```bash
terraform init
```

### 2. Format the Code

Ensures all Terraform files are properly formatted.

```bash
terraform fmt
```

### 3. Validate the Configuration

```bash
terraform validate
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Changes

```bash
terraform apply
```

### 6. Destroy the Infrastructure

```bash
terraform destroy
```
