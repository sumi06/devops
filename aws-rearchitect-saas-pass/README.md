# ☁️ AWS Rearchitected Application - PaaS/SaaS Migration

This project documents the rearchitecture of a traditional on-premise application stack to a modern, scalable, and fully managed AWS PaaS/SaaS-based architecture.

---

## 🧱 Original On-Premise Stack

- **Nginx** – Load Balancer
- **Apache Tomcat** – Java Application Server
- **MySQL** – Relational Database
- **RabbitMQ** – Messaging Queue
- **Memcached** – In-memory Caching
- **Shared Storage** – Network file system
- **Private DNS** – Internal name resolution

---

## ☁️ AWS Rearchitected Stack

| On-Prem Component | AWS Service                                 | Description                                                   |
| ----------------- | ------------------------------------------- | ------------------------------------------------------------- |
| Nginx             | **Application Load Balancer (ALB)**         | Layer 7 load balancer managed by AWS                          |
| Apache Tomcat     | **AWS Elastic Beanstalk (Tomcat Platform)** | Fully managed Java PaaS                                       |
| MySQL             | **Amazon RDS (MySQL)**                      | Managed relational database service                           |
| RabbitMQ          | **Amazon MQ (RabbitMQ)**                    | Managed message broker with native RabbitMQ support           |
| Memcached         | **Amazon ElastiCache (Memcached)**          | Scalable in-memory caching service                            |
| Shared Storage    | **Amazon S3 / Amazon EFS**                  | Use S3 for static assets, EFS for shared file system          |
| Private DNS       | **Amazon Route 53**                         | Scalable DNS service supporting internal and external routing |
| Deployment + CDN  | **AWS CloudFormation + CloudFront**         | Infrastructure as Code and content delivery                   |

---

## 📊 Architecture Diagram

The diagram below illustrates the end-to-end request flow of the rearchitected system on AWS:

graph TD
A[Users] --> B[GoDaddy (DNS)]
B --> C[Route 53 (DNS Resolution)]
C --> D[Elastic Beanstalk]
D --> E[CloudWatch]
D --> F[S3]
D --> G[Amazon MQ (RabbitMQ)]
G --> H[ElastiCache (Memcached)]
H --> I[RDS (MySQL)]
