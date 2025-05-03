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

