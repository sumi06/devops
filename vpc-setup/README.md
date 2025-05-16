# 📘 VPC Setup and Secure Web Deployment on AWS

## 🔧 Overview

This guide sets up a secure AWS VPC with public/private subnets across two Availability Zones, deploys a private web application accessible via a bastion host, configures VPC peering, and enables centralized logging to S3 and CloudWatch.

## 📍 Architecture Summary

| Component        | Description                                                        |
| ---------------- | ------------------------------------------------------------------ |
| **VPC**          | `172.20.0.0/16`                                                    |
| **Subnets**      | 2 Public (`/24`), 2 Private (`/24`) in `us-west-1a` & `us-west-1b` |
| **IGW**          | 1 Internet Gateway                                                 |
| **NGW**          | 2 NAT Gateways                                                     |
| **EIP**          | 2 Elastic IPs for NAT                                              |
| **Route Tables** | 1 for Public, 1 for Private                                        |
| **Bastion Host** | In public subnet                                                   |
| **Website EC2**  | In private subnet                                                  |
| **VPC Peering**  | Peer with another VPC                                              |
| **Logs**         | Sent to S3 & CloudWatch                                            |

## 🧱 Step-by-Step Setup

### 1. Create VPC

- CIDR: 172.20.0.0/16

- Enable DNS resolution & hostnames

### 2. Create Subnets

| Type    | AZ         | CIDR             |
| ------- | ---------- | ---------------- |
| Public  | us-west-1a | `172.20.1.0/24`  |
| Public  | us-west-1b | `172.20.2.0/24`  |
| Private | us-west-1a | `172.20.10.0/24` |
| Private | us-west-1b | `172.20.20.0/24` |

### 3. Create and Attach IGW

- Create Internet Gateway

- Attach to VPC

### 4. Create 2 NAT Gateways

- Allocate 2 Elastic IPs

- Place NAT GW1 in us-west-1a Public Subnet

- Place NAT GW2 in us-west-1b Public Subnet

### 5. Create Route Tables

- Public Route Table

  - Route: 0.0.0.0/0 → IGW

  - Associate with both public subnets

- Private Route Table

  - Route: 0.0.0.0/0 → NAT GW (one per AZ)

  - Associate with corresponding private subnets

### 6. Create NACLs (Optional Advanced Step)

- Create custom NACLs for public/private subnets

- Allow SSH (22), HTTP (80), HTTPS (443), and ephemeral ports for outbound

### 7. Launch EC2 Instances

- Bastion Host (Public Subnet)

  - Amazon Linux 2

  - Key pair for SSH access

  - Security Group: Allow 22 from your IP

- Web Server (Private Subnet)

  - Amazon Linux 2

  - User-data to install and run HTTPD

  - Security Group: Allow 80 from Bastion SG only

### 8. SSH via Bastion to Private EC2

```bash
# SSH to bastion
ssh -i bastion.pem ec2-user@<Bastion_Public_IP>

# From bastion, SSH to private instance
ssh -i web.pem ec2-user@<Private_IP>
```

### 🌐 VPC Peering

- Create a VPC peering connection with another VPC

- Accept the peering request

- Update route tables in both VPCs to route traffic through the peering link

### 📦 Logging EC2 Logs to S3

- Create S3 Bucket for logs.

- Attach IAM Role to EC2 with AmazonS3FullAccess (or scoped policy).

- Configure cloud-init or cron job:

```bash
aws s3 cp /var/log/messages s3://your-bucket-name/logs/ --region us-west-1
```

### 📊 Stream EC2 Logs to CloudWatch

- Attach IAM role with CloudWatchAgentServerPolicy

- Install CloudWatch Agent:

```bash
sudo yum install amazon-cloudwatch-agent -y
```

- Create config file:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/app",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

- Start the agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/config.json -s
```

## 🧱 Terraform VPC Setup Code

### vpc-terraform/

```css
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
```

### 🔧 provider.tf

```hcl
provider "aws" {
  region = "us-west-1"
}
```

### 🔧 variables.tf

```hcl
variable "vpc_cidr" {
  default = "172.20.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["172.20.1.0/24", "172.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["172.20.10.0/24", "172.20.20.0/24"]
}

variable "azs" {
  default = ["us-west-1a", "us-west-1b"]
}
```

### 🔧 main.tf

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_eip" "nat_eip" {
  count = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[count.index].id
  }
  tags = {
    Name = "private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

### 📤 outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```
