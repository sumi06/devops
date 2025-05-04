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

```text

Users 
  ↓
GoDaddy (Domain Registrar) 
  ↓
Amazon Route 53 (DNS Resolution)
  ↓
Elastic Beanstalk (includes ALB + ASG + Tomcat app servers)
  ↓
CloudWatch (Monitoring & Logs)
  ↓
Amazon S3 (Static assets / storage)
  ↓
Amazon MQ (RabbitMQ for messaging)
  ↓
Amazon ElastiCache (Memcached for caching)
  ↓
Amazon RDS (MySQL Database)

```

## 🚀 Deployment Steps

### 🔐 Step 1: Create Security Group and Key Pair (via AWS Console)

✅ 1.1 Create a Security Group for Backend Services
1. Go to the EC2 Dashboard in AWS Console.
2. In the left sidebar, click "Security Groups" under Network & Security.
3. Click "Create security group".
4. Fill in:
  - Security group name: backend-services-sg
  - Description: Security group for backend services that route to themselves
  - VPC: Select the appropriate VPC for your deployment.
5. Under Inbound rules:
  - Click "Add Rule"
  - Type: All traffic
  - Protocol: All
  - Port range: All
  - Source: Custom → Select the same security group (backend-services-sg)
6. Leave Outbound rules as default (allows all).
7. Click Create security group.

✅ 1.2 Create a Key Pair
1. In the EC2 Dashboard, go to the left sidebar.
2. Click "Key Pairs" under Network & Security.
3. Click "Create key pair".
4. Fill in:
  - Name: app-prod-key
  - Key pair type: RSA (or ED25519)
  - Private key format: .pem (for Linux/Unix) or .ppk (for Windows PuTTY)
  5. Click "Create key pair".
6. The .pem file will automatically download to your machine.
💡 Store this .pem file securely. You’ll use it to SSH into Beanstalk EC2 instances if needed.

### 🛠️ Step 2: Set Up RDS (MySQL) via AWS Console

✅ 2.1 Create a DB Parameter Group
1. Open the RDS Console.
2. In the left menu, click “Parameter groups”.
3. Click “Create parameter group”.
4. Choose:
  - Parameter group family: mysql8.0 (or your desired version)
  - Type: DB Parameter Group
  - Group name: mysql8-prod-params
  - Description: Custom parameter group for MySQL production
5. Click Create.
6. (Optional) Select the group and click Edit parameters to customize any database settings (e.g., slow_query_log, max_connections).

✅ 2.2 Create a DB Subnet Group
1. In the RDS console, click “Subnet groups” under Network & Security.
2. Click “Create DB Subnet Group”.
3. Enter:
  - Name: mysql8-prod-subnet-group
  - Description: Subnet group for RDS MySQL
  - VPC: Choose your application’s VPC.
4. Under Add subnets, select at least two subnets in different Availability Zones.
5. Click Create.
☁️ RDS needs subnets in multiple AZs for high availability.

✅ 2.3 Create a MySQL RDS Instance
1. In the RDS Console, click "Databases", then "Create database".
2. Choose Standard create.
3. Engine options:
  - Engine type: MySQL
  - Version: Choose 8.0.x or your preferred version
4. Templates: Choose Production (for Multi-AZ) or Dev/Test for single AZ (cheaper).
5. Settings:
  - DB instance identifier: app-mysql-db
  - Master username: e.g., admin
  - Password: Choose or auto-generate
6. DB instance class:
  - Choose e.g., db.t3.medium (scale as needed)
7. Storage:
  - Recommended: General Purpose (SSD) with autoscaling enabled
8. Connectivity:
  - Virtual Private Cloud (VPC): Choose your app’s VPC
  - Subnet group: Select mysql8-prod-subnet-group
  - Public access: No
  - VPC security group: Select your previously created backend-services-sg
9. Database authentication: Use password authentication.
10. Additional configuration:
  - Initial DB name: appdb
  - DB parameter group: mysql8-prod-params
11. Click Create database.

### 🧠 Step 3: Create ElastiCache (Memcached)

✅ 3.1 Create a Parameter Group
1. Go to the ElastiCache Console.
2. In the left sidebar, click “Parameter groups”.
3. Click “Create parameter group”.
4. Enter:
  - Parameter group family: memcached1.6 (or latest)
  - Group type: Memcached
  - Group name: memcache-prod-params
  - Description: Parameter group for production Memcached
5. Click Create.
6. (Optional) Select the group → Click "Edit parameters" to modify settings like max_item_size, conn_limit, etc.

✅ 3.2 Create a Subnet Group
1. In the ElastiCache Console, click "Subnet groups" from the left menu.
2. Click “Create subnet group”.
3. Fill in:
  - Name: memcache-subnet-group
  - Description: Subnet group for Memcached
  - VPC: Select your app’s VPC
4. Under Subnets, choose at least two subnets in different Availability Zones.
5. Click Create.

✅ 3.3 Launch a Memcached Cluster
1. In the ElastiCache Console, go to "Redis/Memcached", then choose "Create".
2. Select Memcached engine.
3. Under Cluster settings:
  - Name: app-memcache
  - Engine version: Use default or latest stable
  - Port: Default 11211
4. Under Node type:
  - Choose e.g., cache.t3.micro (scale later)
  - Number of nodes: Start with 2+ for high availability
5. Subnet group: Select memcache-subnet-group
6. Parameter group: Choose memcache-prod-params
7. Security groups: Select backend-services-sg
8. Click Create.

### 📨 Step 4: Create Amazon MQ (RabbitMQ)

✅ 4.1 Launch an Amazon MQ Broker (RabbitMQ)
1. In the Amazon MQ Console, click “Create a broker”.
2. Select broker engine:
  - Engine: RabbitMQ
  - Version: Use default or latest stable (e.g., 3.11.x)

📌 Broker settings:
  - Broker name: app-rabbitmq-broker
  - Deployment mode:
    - Single-instance for development or non-critical workloads
    - Cluster deployment (active/standby) for production HA
  - Broker instance type: Choose mq.t3.micro (scale later as needed)

📌 User access:
  - Username: admin (or custom)
  - Password: Enter a strong, secure password (store securely)

📌 Networking:
  - VPC: Select your existing application VPC
  - Subnet IDs: Choose 2 private subnets in different Availability Zones
  - Security group: Select backend-services-sg
  🔒 This ensures internal-only access to the broker by backend services like Beanstalk.

📌 Additional configuration (optional):
  - Encryption: Enabled by default (managed by AWS)
  - CloudWatch logs: Enable if audit or performance logging is required
  - Maintenance window: Accept default or customize
3. Click “Create broker”.

### ✅ Step 5: Initialize the RDS Database (Using Ubuntu EC2 Client)

✅ 5.1 Create an EC2 Instance (RDS Client)
1. In the EC2 Console, click “Launch instance”.
2. Configure:
  - Name: rds-client-ec2
  - AMI: Ubuntu Server 22.04 LTS
  - Instance type: t3.micro (or equivalent)
  - Key pair: Use app-prod-key
  - Network settings:
    - VPC: Same as RDS
    - Subnet: Public (for SSH) or private with a bastion
    - Security group: Create a new group called rds-client-sg

✅ 5.2 SSH and Install MySQL Client (Ubuntu)
1. SSH into your EC2 instance:

``` ssh -i app-prod-key.pem ubuntu@<EC2_PUBLIC_IP> Update and install the MySQL client: ```

``` sudo apt update sudo apt install -y mysql-client git ```

✅ 5.3 Update Backend Security Group to Allow RDS Client Access
1. Go to EC2 → Security Groups.
2. Select backend-services-sg, then click “Edit inbound rules”.
3. Add a rule:
  - Type: MySQL/Aurora
  - Port: 3306
  - Source: rds-client-sg

🔐 This ensures only the client EC2 can access the RDS database securely.

✅ 5.4 Connect to the RDS Database
Use the MySQL CLI:

``` mysql -h <RDS_ENDPOINT> -u admin -p ```

- Enter the RDS master password you configured earlier
- Confirm you can connect and view databases:

``` SHOW DATABASES; ```

✅ 5.5 Clone Git Repo and Run SQL Initialization
1. Clone your repository:

``` git clone https://github.com/your-org/your-repo.git cd your-repo/db ```

2. Run SQL script to initialize DB:

``` mysql -h <RDS_ENDPOINT> -u admin -p < init.sql ```
📄 Replace init.sql with your actual SQL filename or script path.

### ✅ Step 6: Create Elastic Beanstalk Environment (Tomcat)

✅ 6.1 Create an IAM Role for Elastic Beanstalk
1. Go to the IAM Console → Roles → Create role
2. Trusted entity type: Select AWS service
3.  Use case: Choose Elastic Beanstalk
4. Click Next.
5. Attach permissions policies:
  - AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy
  - AWSElasticBeanstalkWebTier
  - AWSElasticBeanstalkMulticontainerDocker
  - AmazonS3ReadOnlyAccess (if your app fetches from S3)
  - Any custom policies if needed (e.g., to access MQ or ElastiCache)
6. Role name: aws-elasticbeanstalk-ec2-role
7. Click Create role
🔐 This role will be attached to EC2 instances launched by Beanstalk to allow them access to other AWS resources.

✅ 6.2 Create the Beanstalk Environment
1. Go to the Elastic Beanstalk Console
2. Click Create application

📌 Application Settings:
  - Application name: my-app
  - Platform: Tomcat (choose version compatible with your Java app)
  - Application code:
    - Upload a .war file manually, or
    - Point to your S3 bucket if hosted externally
3. Click Configure more options (don’t use “default”)

📌 Environment Configuration:
  - Environment type: Load balanced (enables ALB + ASG)
  - Instance type: t3.medium or similar
  - EC2 key pair: Select app-prod-key
  - IAM instance profile: Choose aws-elasticbeanstalk-ec2-role
  - VPC settings:
    - VPC: Choose your application VPC
    - Subnets: Select private subnets for EC2 instances and public for load balancer
  - Security group: Use a group that allows access to backend services (backend-services-sg or similar)
4. Monitoring and Logs:
  - Enable CloudWatch Logs integration if needed
  - Enable Health Reporting: Enhanced
5. Click Create environment
📦 Beanstalk will launch EC2 instances, provision an ALB, create Auto Scaling Groups, and deploy your application automatically.

### ✅ Step 7: Allow Beanstalk to Access Backend Services

✅ 7.1 Identify the Beanstalk EC2 Instance Security Group
1. Go to the EC2 Console.
2. In the left sidebar, click “Instances”.
3. Find an instance launched by Elastic Beanstalk.
4. Click the instance ID to view details.
5. Under Security, note the EC2 security group name (e.g., awseb-e-xxxx-stack-AWSEBAutoScalingGroup-xxxxxx).
💡 This is the security group attached to the EC2 instances in your Beanstalk environment.

✅ 7.2 Update the Backend Services Security Group
1. Go to EC2 → Security Groups.
2. Find and select the backend-services-sg.
3. Click “Edit inbound rules”.
4. Add new rules for required services:
 
| Type         | Protocol | Port                 | Source                  |
| ------------ | -------- | -------------------- | ----------------------- |
| MySQL/Aurora | TCP      | 3306                 | `Beanstalk instance SG` |
| Memcached    | TCP      | 11211                | `Beanstalk instance SG` |
| Custom TCP   | TCP      | 5671/5672 (RabbitMQ) | `Beanstalk instance SG` |

📌 Replace "Beanstalk instance SG" with the security group ID or name you noted in step 7.1.

5. Click Save rules.

### ✅ Step 8: Build & Deploy Application Artifacts

✅ 8.1 Update Configuration File
1. Before building, update environment-specific config files with the correct values for:
  - Database connection
  - RabbitMQ
  - Memcached

✅ 8.2 Build the Application
1. Use Maven to generate the .war file:

  ``` mvn clean package ```

- Output: target/app.war

✅ 8.3 Deploy to Elastic Beanstalk
1. Go to the Elastic Beanstalk Console
2. Select your application → Upload and deploy
3. Choose the new .war file
4. Click Deploy
📦 Beanstalk will update the running environment with your latest application build.

✅ 8.4 Enable HTTPS on Beanstalk (via ALB)
1. Go to EC2 → Load Balancers
2. Select the ALB created by Beanstalk
3. In Listeners, click Add listener → Choose HTTPS: 443
4. Attach an SSL certificate (use:
  - ACM certificate if already provisioned
  - Or request a new ACM certificate for your domain)
5. Set up forwarding to the same target group as HTTP (port 80)
🔒 You can then redirect HTTP to HTTPS inside your app or via ALB rules.

✅ 8.5 Add a DNS Entry in GoDaddy
1. Log in to your GoDaddy account
2. Navigate to DNS Management for your domain
3. Add or update a CNAME or A record:
  - Type: CNAME
  - Name: e.g., app
  - Value: ALB DNS name (e.g., my-app-env.eba-xyz.us-east-1.elb.amazonaws.com)
4. Save the DNS record
🌐 Your app will now be accessible via https://app.yourdomain.com

### ✅ Step 9: Create CloudFront Distribution & Update DNS

✅ 9.1 Create a CloudFront Distribution
1. Go to the CloudFront Console
2. Click “Create Distribution”

📌 Origin Settings:
  - Origin domain: Use the ALB DNS name from your Elastic Beanstalk environment
  (e.g., my-app-env.eba-xyz.us-east-1.elb.amazonaws.com)
  - Protocol: HTTPS only
  - Origin ID: Auto-generated (you can rename)

📌 Default Cache Behavior Settings:
  - Viewer protocol policy: Redirect HTTP to HTTPS
  - Allowed HTTP methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE (if needed)
  - Cache policy: Use CachingDisabled (for dynamic app) or custom if caching static content
  - Origin request policy: Choose one that forwards all headers/cookies if needed by your app

📌 SSL:
  - Choose Custom SSL certificate (ACM) if using your domain (e.g., app.yourdomain.com)
  - Otherwise use default CloudFront SSL for *.cloudfront.net

📌 Alternate domain name (CNAME):
  - Add your app’s subdomain (e.g., app.yourdomain.com)
  - Attach an ACM certificate that matches this domain (must be in us-east-1)
  
3. Click Create Distribution

⏳ It may take ~15–30 minutes for the CloudFront distribution to deploy

✅ 9.2 Update GoDaddy DNS to Point to CloudFront
1. In the GoDaddy DNS Management Console:
2. Find the existing record for app.yourdomain.com
3. Change it to point to the CloudFront domain:

| Type  | Name  | Value                       |
| ----- | ----- | --------------------------- |
| CNAME | `app` | `d1234abcde.cloudfront.net` |

4. Save the DNS changes

🌍 Once propagated, traffic to https://app.yourdomain.com will go through CloudFront, improving latency and edge caching.




















































































































































































