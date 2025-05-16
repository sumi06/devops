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

## 🏗️ Architecture Flow

```text

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

```

## ⚙️ Step-by-Step Deployment

### 🔐 Step 1: Create Security Groups via AWS Console
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

2️⃣ Create sg-tomcat – For Tomcat EC2 Instances
1. Go back to Security Groups → Create security group
2. Set:
- Name: sg-tomcat
- Description: Security group for Tomcat EC2 instances
3. Under Inbound rules, add:
- Custom TCP (port 8080) — Source: sg-elb (select existing security group)
- SSH (port 22) — Source: My IP (recommended)
4. Click Create security group

3️⃣ Create sg-backend – For MySQL, RabbitMQ, Memcached EC2
1. Go back to Security Groups → Create security group
2. Set:
- Name: sg-backend
- Description: Security group for backend services
3. Under Inbound rules, add:
- MySQL/Aurora (port 3306) — Source: sg-tomcat
- Custom TCP (port 5672 - RabbitMQ) — Source: sg-tomcat
- Memcached (port 11211) — Source: sg-tomcat
- All traffic — Source: sg-backend (for internal communication)
- SSH (port 22) — Source: My IP
4. Click Create security group

🔑 Step 2: Create a Key Pair in AWS Console
1. Go to EC2 Dashboard → Key Pairs
2. Click Create key pair
3. Set:
- Name: prod-env-key
- Type: RSA
- Format: .pem (for Linux/macOS) or .ppk (for Windows PuTTY)
4. Click Create key pair
5. Save the downloaded file (prod-env-key.pem) securely
6. On your terminal, set permissions:

    ```chmod 400 prod-env-key.pem```

💡 This key will be used when launching and SSHing into all EC2 instances (Tomcat, MySQL, etc.)

### 🖥️ Step 2: Launch EC2 Instances for Services
You will launch 4 EC2 instances, each with the appropriate base OS and user data.

🔧 Common Launch Settings
- Key Pair: prod-env-key
- Instance Type: t2.micro or t3.micro
- Storage: 8–20 GB (based on service)
- VPC/Subnet: Choose same VPC for all
- Auto-assign Public IP: Only if needed for external access
- IAM Role: Add if S3 access or Route 53 updates are needed
- Security Groups:
    - sg-backend: for MySQL, Memcached, RabbitMQ
    - sg-tomcat: for Tomcat

1️⃣ Tomcat (Ubuntu 22.04)
- AMI: Ubuntu Server 22.04 LTS
- Security Group: sg-tomcat
- User Data:

```#!/bin/bash sudo apt update sudo apt upgrade -y sudo apt install openjdk-17-jdk -y sudo apt install tomcat10 tomcat10-admin tomcat10-docs tomcat10-common git -y```

2️⃣ MySQL (Amazon Linux 2023)
- AMI: Amazon Linux 2023 AMI
- Security Group: sg-backend
- User Data:

```bash
#!/bin/bash
DATABASE_PASS='admin123'
sudo dnf update -y
sudo dnf install git zip unzip -y
sudo dnf install mariadb105-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
cd /tmp/
sudo mysqladmin -u root password "$DATABASE_PASS"
sudo mysql -u root -p"$DATABASE_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_PASS'"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
sudo mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'localhost' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.\* TO 'admin'@'%' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
```

3️⃣ Memcached (Amazon Linux 2023)
- AMI: Amazon Linux 2023 AMI
- Security Group: sg-backend
- User Data:

```bash
#!/bin/bash
sudo dnf install memcached -y
sudo systemctl start memcached
sudo systemctl enable memcached
sudo systemctl status memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached
sudo memcached -p 11211 -U 11111 -u memcached -d
```

4️⃣ RabbitMQ (Amazon Linux 2023)
- AMI: Amazon Linux 2023 AMI
- Security Group: sg-backend
- User Data:

```bash
#!/bin/bash
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc'
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key'
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key'
curl -o /etc/yum.repos.d/rabbitmq.repo https://raw.githubusercontent.com/hkhcoder/vprofile-project/refs/heads/awsliftandshift/al2023rmq.repo
dnf update -y
dnf install socat logrotate -y
dnf install -y
erlang rabbitmq-server
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
sudo sh -c 'echo "[{rabbit, [{loopback*users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator rabbitmqctl set_permissions -p / test ".*" ".\_" ".\*"
sudo systemctl restart rabbitmq-server
```

### 🌐 Step 3: Create Private DNS Records in Route 53
To allow your Tomcat app to resolve backend services like MySQL, Memcached, RabbitMQ by name instead of private IP, create a Route 53 Private Hosted Zone and add A records for each backend service.

🛠️ 1️⃣ Create Private Hosted Zone
1. Go to Route 53 Console → Hosted Zones
2. Click Create Hosted Zone
3. Set:
- Domain name: vprofile.internal (or any non-public domain)
- Type: Private Hosted Zone
- VPC: Select your VPC used for EC2 instances
4. Click Create Hosted Zone

🧭 2️⃣ Create A Records for Services
For each service, map the DNS name to the EC2 private IP address:
- You can get each EC2 private IP from the EC2 console → Instances

---

Record Name Type Value (Private IP) Purpose
mysql.vprofile.internal A 10.x.x.x MySQL host for JDBC
memcache.vprofile.internal A 10.x.x.x Memcached access
rabbitmq.vprofile.internal A 10.x.x.x RabbitMQ connection

---

🔧 How to add each record:
1. In your hosted zone (vprofile.internal), click Create Record
2. Name: e.g., mysql (this will resolve as mysql.vprofile.internal)
3. Record type: A – IPv4 address
4. Value: EC2 private IP of the service
5. TTL: 300 seconds (default is fine)
6. Click Create Record

Repeat for:

```memcache.vprofile.internal```
```rabbitmq.vprofile.internal```

✅ Test DNS Resolution
SSH into your Tomcat EC2 instance, then run:

```nslookup mysql.vprofile.internal nslookup memcache.vprofile.internal nslookup rabbitmq.vprofile.internal```
You should get the correct private IPs in the response.

### 📦 Step 4: Build and Deploy Artifacts to Tomcat via S3
This step involves building the WAR file, storing it in an S3 bucket, and then deploying it to the Tomcat EC2 instance.

1️⃣ Create an S3 Bucket
1. Go to S3 Console → Create bucket
2. Set:
- Bucket name: vprofile-app-artifacts (or any globally unique name)
- Region: Same region as EC2 instances
- Leave defaults (Block Public Access ON, versioning optional)
3. Click Create bucket

2️⃣ Create IAM Access for S3
🧑‍💼 Option A: IAM User with Access Key (for local CLI)
1. Go to IAM Console → Users → Add user
2. Name: artifact-uploader, select Programmatic access
3. Attach Policy: AmazonS3FullAccess (or scoped-down custom policy)
4. Download the Access Key ID and Secret Access Key

🧑‍💻 Option B: IAM Role for EC2 (Recommended for Tomcat EC2)
1. Go to IAM Console → Roles → Create Role
2. Select EC2
3. Attach policy: AmazonS3ReadOnlyAccess
4. Name: EC2S3ReadOnlyRole
5. Attach this role to the Tomcat EC2 instance (EC2 → Actions → Security → Modify IAM Role)

3️⃣ Configure AWS CLI (for Local Upload)

```aws configure #Enter Access Key, Secret Key, Region, and output format```

4️⃣ Build the WAR Artifact (Maven)
1. Clone the project and build:

```mvn clean install```

The WAR file will be generated in:

```target/vprofile-v2.war```

5️⃣ Upload WAR to S3

```aws s3 cp target/vprofile-v2.war s3://vprofile-app-artifacts/vprofile-v2.war```

6️⃣ SSH into Tomcat EC2 Instance

```ssh -i prod-env-key.pem ubuntu@<Tomcat-EC2-Public-IP>```

7️⃣ Install AWS CLI on Tomcat EC2

```sudo apt update sudo apt install awscli -y```

If using IAM role, no need to configure.
Otherwise run aws configure inside EC2 with IAM access keys.

8️⃣ Download WAR from S3

```aws s3 cp s3://vprofile-app-artifacts/vprofile-v2.war /tmp/vprofile.war```

9️⃣ Deploy WAR to Tomcat
```sudo systemctl stop tomcat10 sudo rm -rf /var/lib/tomcat10/webapps/ROOT sudo cp /tmp/vprofile.war /var/lib/tomcat10/webapps/ROOT.war sudo systemctl start tomcat10```

💡 You may also check logs:

```sudo tail -f /var/log/tomcat10/catalina.out```

### 🌐 Step 5: Create ALB and Connect to GoDaddy DNS
This step sets up:
- A public Application Load Balancer (ALB) for HTTPS routing
- ACM certificate for SSL/TLS
- DNS mapping from GoDaddy to ALB

🧱 1️⃣ Create Target Group for Tomcat EC2
1. Go to EC2 Console → Target Groups → Create target group
2. Choose:
- Target type: Instances
- Protocol: HTTP
- Port: 8080
- Name: tg-tomcat
3. Select VPC used by EC2
4. Register your Tomcat EC2 instance
5. Click Create target group

🛡️ 2️⃣ Create ACM Certificate for Your Domain
1. Go to ACM Console → Request a certificate
2. Choose Public certificate
3. Enter your domain name (e.g., www.yourdomain.com)
4. Choose DNS validation
5. ACM will show a CNAME record
6. Go to GoDaddy DNS Manager and add the CNAME record under DNS > Add Record
7. Wait until certificate status becomes “Issued”

🌍 3️⃣ Create Application Load Balancer
1. Go to EC2 Console → Load Balancers → Create Load Balancer
2. Choose Application Load Balancer
3. Set:
- Name: alb-vprofile
- Scheme: Internet-facing
- IP type: IPv4
- Listeners:
    - Add listener for HTTPS (443) only (we'll redirect HTTP if needed)
- VPC: Select the one your EC2s are in
- Subnets: Select at least 2 public subnets (for high availability)
4. Security Groups: Select sg-elb
5. Listener Configuration:
- Add HTTPS (443) listener
- Choose your ACM certificate
- Set forward to Target Group tg-tomcat
6. Click Create Load Balancer

🌐 4️⃣ Update DNS in GoDaddy to Point to ALB
1. After ALB is created, copy its DNS name (e.g., alb-vprofile-123456789.us-east-1.elb.amazonaws.com)
2. Log into your GoDaddy account
3. Go to My Products → DNS → Manage DNS for your domain
4. In the DNS records:
- Delete existing A or CNAME pointing to old IP
- Add CNAME record:
- Host: www (or blank for root)
- Points to: paste the ALB DNS name
- TTL: 600 seconds
Optional: Set A record with an ALIAS using Route 53 if you fully migrate DNS to AWS.

🔍 5️⃣ Test Application Access
Visit your domain in a browser:

```https://www.yourdomain.com```

✅ You should see your Tomcat-hosted app load via ALB with HTTPS!

### ⚙️ Step 6: Create Auto Scaling Group for Tomcat Using Custom AMI
To scale Tomcat automatically with consistent configuration, you'll first create an AMI from your pre-configured Tomcat EC2 instance.

🖼️ 1️⃣ Create AMI from Existing Tomcat EC2 Instance
1. Go to EC2 Console → Instances
2. Select your fully configured Tomcat EC2 instance
3. Click Actions → Image and templates → Create Image
4. Set:
- Name: ami-tomcat-configured
- Optionally add a description
- Enable No reboot if needed (default is safe)
5. Click Create Image
6. Wait for AMI to finish building (under AMIs tab)
📝 This image includes pre-installed Java, Tomcat, AWS CLI, and app deployment steps

🧰 2️⃣ Create Launch Template Using the AMI
1. Go to EC2 Console → Launch Templates → Create launch template
2. Set:
- Name: lt-tomcat
- AMI: Select ami-tomcat-configured created above
- Instance type: t2.micro or t3.micro
- Key pair: prod-env-key
- Security group: sg-tomcat
3. User Data: Leave empty (configuration already baked into AMI)
4. Click Create launch template

📈 3️⃣ Create Auto Scaling Group (ASG)
1. Go to EC2 Console → Auto Scaling Groups → Create Auto Scaling Group
2. Set:
- Name: asg-tomcat
- Launch template: Select lt-tomcat
3. Network:
- Select your VPC and at least 2 public or private subnets in different Availability Zones
4. Attach to ALB:
- Select existing Application Load Balancer
- Choose target group: tg-tomcat
5. Group Size:
- Desired capacity: 2
- Minimum: 1
- Maximum: 3
6. Health Checks:
- Enable ELB health check
7. Scaling Policies (optional):
- Set CPU-based scale-out/scale-in (e.g., add instance if CPU > 70%)

✅ 4️⃣ Verify Auto Scaling
1. Go to EC2 → Instances and check 2 Tomcat EC2s are running
2. Terminate one manually — ASG should replace it
3. Test app by accessing your domain via ALB

🧾 Final Summary

---

| Component                | AWS Resource Used                        |
| ------------------------ | ---------------------------------------- |
| Web Server Load Balancer | **Application Load Balancer (ALB)**      |
| App Server               | **Tomcat EC2 (in ASG, from AMI)**        |
| Database                 | **MySQL on EC2 (Amazon Linux 2023)**     |
| Caching Layer            | **Memcached on EC2**                     |
| Messaging Queue          | **RabbitMQ on EC2**                      |
| Shared App Storage       | **Amazon S3**                            |
| DNS Resolution (Private) | **Route 53 Private Hosted Zone**         |
| SSL/TLS Certs            | **AWS Certificate Manager (ACM)**        |
| Artifact Storage         | **Amazon S3 Bucket**                     |
| Infrastructure Scaling   | **Launch Template + Auto Scaling Group** |
| Access Key & SSH         | **Key Pair (`prod-env-key`)**            |

---

✅ Project Benefits
1. Highly Available: ASG ensures multiple app nodes
2. Secure: TLS via ACM, restricted SGs, and private DNS
3. Elastic: Scales based on traffic load
4. Modular: App and services can be upgraded independently
5. Efficient: S3-based artifact deployment decouples CI/CD
