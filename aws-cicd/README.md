# AWS CI/CD Pipeline with Beanstalk, RDS, Bitbucket, CodeBuild, and CodePipeline

## Overview

This project sets up a complete CI/CD pipeline on AWS where:

- Code is hosted in **Bitbucket**
- AWS **CodePipeline** orchestrates the process
- **CodeBuild** builds the application
- Application is deployed to **Elastic Beanstalk**
- Backend database is managed by **Amazon RDS**

---

## Step 1: Create Elastic Beanstalk Environment

1. Go to AWS Elastic Beanstalk Console.
2. Create a new application.
3. Choose platform (e.g., Tomcat, Node.js, etc.).
4. Upload a sample app or placeholder WAR/ZIP for setup.
5. Note the EC2 instance's **Security Group ID**.

---

## Step 2: Create Amazon RDS

1. Create a new RDS (e.g., MySQL or PostgreSQL).
2. In the **Connectivity** section:
   - Choose the same VPC as Beanstalk.
   - Add a new or existing subnet group.
3. Modify the **RDS Security Group**:
   - Allow inbound traffic from Beanstalk's EC2 SG on port `3306`.

---

## Step 3: Verify RDS Connection

1. SSH into the Beanstalk EC2 instance:

```bash
ssh -i <key.pem> ec2-user@<instance-public-ip>
```

2. Install MySQL client:

```bash
sudo yum install mysql -y
```

3. Verify connection:

```bash
mysql -h <rds-endpoint> -u <user> -p
```

4. Upload and execute SQL file:

```bash
wget <sql-file-url>
mysql -h <rds-endpoint> -u <user> -p < db.sql

```

---

## Step 4: Setup Bitbucket Repo

1. Create a Bitbucket account and new repository.

2. Generate SSH keys:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

3. Add the public key to Bitbucket:

   - Bitbucket > Personal Settings > SSH Keys

4. Update ~/.ssh/config:

```bash
Host bitbucket.org
  HostName bitbucket.org
  User git
  IdentityFile ~/.ssh/id_rsa
```

---

## Step 5: Migrate from GitHub to Bitbucket

```bash
git clone https://github.com/user/repo.git
cd repo
git remote remove origin
git remote add origin git@bitbucket.org:user/repo.git
git push -u origin main
```

---

## Step 6: Create CodeBuild Project

1. Go to CodeBuild → Create a project

2. Source: Bitbucket

3. Add service role with access to:

   - S3 (artifacts)

   - Elastic Beanstalk (deployments)

4. Create a buildspec.yml in your repo root:

```yaml
version: 0.2

#env:
#variables:
# key: "value"
# key: "value"
#parameter-store:
# key: "value"
# key: "value"

phases:
  install:
    runtime-versions:
      java: corretto17
  pre_build:
    commands:
      - apt-get update
      - apt-get install -y jq
      - wget https://archive.apache.org/dist/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz
      - tar xzf apache-maven-3.9.8-bin.tar.gz
      - ln -s apache-maven-3.9.8 maven
      - sed -i 's/jdbc.password=admin123/jdbc.password=<rds_password>/' src/main/resources/application.properties
      - sed -i 's/jdbc.username=admin/jdbc.username=admin/' src/main/resources/application.properties
      - sed -i 's/db01:3306/<rds_endpoint>:3306/' src/main/resources/application.properties
  build:
    commands:
      - mvn install
  post_build:
    commands:
      - mvn package
artifacts:
  files:
    - "**/*"
  base-directory: "target/vprofile-v2"
```

5. Create an S3 bucket for artifacts.

---

## Step 7: Create CodePipeline

1. Go to CodePipeline → Create pipeline

2. Source:

   - Provider: Bitbucket

3. Build:

   - Provider: CodeBuild (select project)

4. Deploy:

   - Provider: Elastic Beanstalk (select app and environment)

---

## Step 8: Test CI/CD Pipeline

1. Make a code change in Bitbucket:

```bash
git add .
git commit -m "CI/CD test commit"
git push origin main
```

2. Verify that:

   - CodePipeline is triggered.

   - CodeBuild runs successfully.

   - New version is deployed in Beanstalk.
