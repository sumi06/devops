# CI/CD Pipeline with Jenkins, Docker, and Amazon ECR

This repository demonstrates a complete CI/CD pipeline using **Jenkins**, **Maven**, **SonarQube**, **Docker**, and **Amazon ECR**, triggered by changes in a **GitHub** repository.

---

## 🔁 CI/CD Flow

```text
Developer → GitHub → Jenkins (Fetch Code)
         → Unit Test (Maven)
         → Code Style Check (Checkstyle)
         → Static Code Analysis (SonarQube)
         → Quality Gate Evaluation
         → Docker Build
         → Push to Amazon ECR
         → Deploy to ECS

```

## 🧰 Tools Used

GitHub – Version Control

Jenkins – CI/CD Orchestration

Maven – Build & Dependency Management

SonarQube – Static Code Analysis

Docker – Containerization

Amazon ECR – Container Registry

Amazon ECS - Container Deployment

## 📋 Prerequisites

Jenkins installed with required plugins:

Git

Maven Integration

Docker

SonarQube Scanner

SonarQube server configured and accessible

Amazon ECR repository created

IAM credentials configured in Jenkins (AWS access keys)

Docker installed and running on the Jenkins node

Amazon ECS cluster created

## Setup Steps

### ✅ Step 1: Install AWS CLI, Docker, and Add Jenkins User to Docker Group

#### 🔹 1.1 Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

✅ Verify installation:

`aws --version`

#### 🔹 1.2 Install Docker

```bash
sudo apt update
sudo apt install docker.io -y
```

✅ Enable Docker on startup:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

✅ Verify installation:

```bash
docker --version
```

#### 🔹 1.3 Add jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

🔁 After this, restart the Jenkins service and log out and back in or reboot the system to apply group changes.

```bash
sudo systemctl restart jenkins
```

✅ Verify jenkins can run Docker (optional, via sudo su - jenkins):

```bash
sudo su - jenkins
docker info
```

### ✅ Step 2: AWS IAM Setup and Jenkins Plugin Installation

#### 🔹 2.1 Create IAM User with Required Policies

1. Go to AWS Console > IAM > Users > Add User

2. Username: jenkins-ecr-user

3. Access Type: ✅ Programmatic Access

4. Attach the following managed policies:

```bash
AmazonEC2ContainerRegistryFullAccess
AmazonECSFullAccess
```

🔒 Optional: Use a custom policy for tighter security, e.g.:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:*", "ecs:*"],
      "Resource": "*"
    }
  ]
}
```

5. Complete user creation and download the Access Key ID and Secret Access Key.

#### 🔹 2.2 Store AWS Credentials in Jenkins

In Jenkins:

1. Go to: Manage Jenkins > Credentials > (Global or specific domain) > Add Credentials

2. Kind: AWS Credentials

3. Fill in:

   - Access Key ID

   - Secret Access Key

   - ID (e.g., aws-jenkins-ecr)

4. Save.

#### 🔹 2.3 Create ECR Repository

Use AWS CLI or Console:

```bash
aws ecr create-repository --repository-name my-app --region us-east-1
```

Output will show the ECR URI like:

```bash
123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app
```

#### 🔹 2.4 Install Required Jenkins Plugins

Go to Manage Jenkins > Plugin Manager > Available and install:

✅ Docker Pipeline

✅ Docker Commons Plugin

✅ Amazon ECR Plugin

✅ AWS SDK Plugin

🔄 After installing, restart Jenkins to ensure plugins are loaded.

### ✅ Step 3: Set Up Amazon ECS (Elastic Container Service)

#### 🔹 3.1 Create ECS Cluster

1. Go to ECS Console > Clusters > Create Cluster

2. Select "Networking only" (Fargate) → Click Next step

3. Set:

   - Cluster name: my-app-cluster

   - VPC: Use existing or create new

4. Click Create

#### 🔹 3.2 Create ECS Task Definition

1. Go to Task Definitions > Create new Task Definition

2. Launch type: ✅ Fargate

3. Fill in:

   - Task Definition Name: my-app-task

   - Task Role: create or select ecsTaskExecutionRole

   - Network Mode: awsvpc

   - Task size: e.g., 0.5 vCPU, 1 GB RAM

4. Add Container:

   - Container name: my-app

   - Image URI: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

   - Port mapping: 8080 (or your app port)

#### 🔹 3.3 Attach Inline Policy to Task Role (for CloudWatch Logs)

1. Go to IAM > Roles > ecsTaskExecutionRole

2. Add the following inline policy to allow CloudWatch logging:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 🔹 3.4 Create ECS Service

1. Go to ECS > Clusters > my-app-cluster > Services > Create

2. Launch type: Fargate

3. Task Definition: Select your task and revision

4. Service name: my-app-service

5. Number of tasks: 1 (scale as needed)

6. Cluster VPC and subnets: choose the ones used earlier

7. Security group: allow HTTP/HTTPS (e.g., port 80 or 8080)

8. Load balancer (optional): attach ALB if needed

### ✅ Step 4: Create Jenkins Pipeline to Deploy

#### 📄 Jenkinsfile

```groovy
pipeline {
    agent any

    tools {
        maven "MAVEN3.9"
        jdk "JDK17"
    }

    environment {
        registryCredential = 'ecr:us-east-2:awscreds'
        appRegistry = "951401132355.dkr.ecr.us-east-2.amazonaws.com/vprofileappimg"
        vprofileRegistry = "https://951401132355.dkr.ecr.us-east-2.amazonaws.com"
        cluster = "vprofile"
        service = "vprofileappsvc"
    }

    stages {

        stage('Fetch Code') {
            steps {
                git branch: 'docker', url: 'https://github.com/hkhcoder/vprofile-project.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn install -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Checkstyle Analysis') {
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
        }

        stage('Sonar Code Analysis') {
            environment {
                scannerHome = tool 'sonar6.2'
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh '''${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=vprofile \
                        -Dsonar.projectName=vprofile \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                        -Dsonar.junit.reportsPath=target/surefire-reports/ \
                        -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                        -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build App Image') {
            steps {
                script {
                    dockerImage = docker.build("${appRegistry}:${BUILD_NUMBER}", "./Docker-files/app/multistage/")
                }
            }
        }

        stage('Upload App Image') {
            steps {
                script {
                    docker.withRegistry(vprofileRegistry, registryCredential) {
                        dockerImage.push("${BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage('Remove Container Images') {
            steps {
                script {
                    def imageId = sh(script: "docker images -q ${appRegistry}:${BUILD_NUMBER}", returnStdout: true).trim()
                    if (imageId) {
                        sh "docker rmi -f ${imageId} || true"
                    }
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withAWS(credentials: 'awscreds', region: 'us-east-2') {
                    sh '''
                        aws ecs update-service \
                        --cluster ${cluster} \
                        --service ${service} \
                        --force-new-deployment
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
    }
}
```

###

✅ Step 5: Verify Results

After pipeline execution, confirm that deployment was successful:

🔍 Jenkins Console Output

✅ All stages pass (green ticks)

✅ SonarQube Quality Gate = Passed

✅ Docker image pushed to ECR

✅ ECS service updated (check logs for update-service success)

🧪 Verify ECS Deployment

1. Go to ECS > Clusters > vprofile > Services

2. Confirm vprofileappsvc has:

   - Latest task definition revision

   - Running desired task count

3. Click service → Tasks > Logs → Confirm app logs in CloudWatch

🌐 Verify Application URL (if using ALB)

Access your ECS service via ALB DNS or exposed public IP

Confirm your app UI or API is running as expected
