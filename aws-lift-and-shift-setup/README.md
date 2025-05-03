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

[ Users ]
↓
[ GoDaddy Domain (DNS) ]
↓
[ Route 53 (Private DNS) + ACM (SSL) ]
↓
[ Application Load Balancer (ALB) – HTTPS ]
↓
[ Auto Scaling Group – Tomcat EC2 Instances (Ubuntu AMI from Image) ]
↓
[ S3 – App Artifact Repository ]
↓
[ Private DNS: *.vprofile.internal ]
↓
[ Backend Services – EC2 Instances (Amazon Linux 2023):
- MySQL (3306)
- RabbitMQ (5672)
- Memcached (11211) ]
