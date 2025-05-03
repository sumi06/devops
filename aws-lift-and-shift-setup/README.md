# 🚀 AWS Lift-and-Shift Architecture: Legacy App Modernization

This project re-architects a legacy on-premise infrastructure setup to AWS using EC2 instances, Load Balancer (ALB), Auto Scaling, Amazon S3, Route 53, and Amazon Certificate Manager (ACM).

## 🧱 Original On-Premise Setup

- **Nginx** – Front-end Load Balancer
- **Apache Tomcat** – Application Server
- **MySQL** – Database
- **RabbitMQ** – Messaging Queue
- **Memcached** – Caching
- **Shared Storage**
- **Private DNS**

---

## ☁️ AWS Re-Architected Infrastructure

### AWS Services Used:

| On-Prem Component | AWS Equivalent                  |
| ----------------- | ------------------------------- |
| Nginx LB          | Application Load Balancer (ALB) |
| Tomcat VM         | EC2 Instances (Auto Scaled)     |
| MySQL             | EC2 (or optional RDS)           |
| RabbitMQ          | EC2 Instance                    |
| Memcached         | EC2 Instance (or ElastiCache)   |
| Shared Storage    | Amazon S3                       |
| Private DNS       | Route 53 Private Hosted Zone    |
| SSL Certificates  | AWS Certificate Manager (ACM)   |

---

🗺️ Architecture Overview

```text
Users
  ↓
[Godaddy DNS (Public)]
  ↓
[Route 53 + ACM Certificate]
  ↓
[HTTPS]
  ↓
[ALB (Application Load Balancer)]
  ↓
[EC2 Auto Scaling Group (Tomcat)]
  ↓
[Backend Services: MySQL, RabbitMQ, Memcached on EC2]
  ↓
[Amazon S3 for Artifact & File Storage]
  ↓
[Route 53 Private Hosted Zone]
```

⚙️ Step-by-Step Deployment

🔐 Step 1: Create Security Groups via AWS Console

1️⃣ Create sg-elb – For Application Load Balancer (ALB)
1. Go to EC2 Dashboard → Network & Security → Security Groups
2. Click Create security group
3. Set:
    - Name: sg-elb
    - Description: Security group for ELB
    - VPC: Select your default or custom VPC
4. Under Inbound rules, add:
    - HTTP (port 80) — Source: Anywhere (0.0.0.0/0)
    - HTTPS (port 443) — Source: Anywhere (0.0.0.0/0)
5. Click Create security group

