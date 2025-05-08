# Jenkins CI Pipeline with GitHub, Maven, SonarQube, Nexus, and AWS EC2

This project implements a Continuous Integration (CI) pipeline using Jenkins deployed on an AWS EC2 instance. It integrates with GitHub, builds and tests code using Maven, performs code quality analysis with SonarQube, and uploads artifacts to Nexus Repository Manager.

## 🔁 CI Pipeline Flow

→ Developer
→ GitHub
→ Jenkins (Git)
→ Build (Maven)
→ Unit Test (Maven)
→ Code Analysis (SonarQube)
→ Quality Gate Check (SonarQube)
→ Artifact Upload (Nexus)

## 🛠️ Prerequisites

1. AWS EC2 Instance with:

- Jenkins installed and running

- Java (JDK 11+)

- Maven

- Git

2. Tools Setup:

- Jenkins

- SonarQube Server

- Nexus Repository Manager

- itHub Repository (your code)

- Maven project structure

## CI Pipilene Steps

### 🔧 Step 1: Jenkins Installation on AWS EC2 (Ubuntu)

#### 🖥️ 1. Launch AWS EC2 Instance

1. Choose Ubuntu Server 22.04 LTS (or compatible).

2. Instance type: t2.micro (for testing) or higher.

3. Open the following ports in Security Group:

   - 22 (SSH)

   - 8080 (Jenkins)

   - 80 (optional, for Nginx/Apache reverse proxy)

#### 🔐 2. SSH into the EC2 Instance

`ssh -i "your-key.pem" ubuntu@<your-ec2-public-ip>`

☕ 3. Install OpenJDK 21

```bash
sudo apt update
sudo apt install openjdk-21-jdk -y
java -version
```

#### 🔑 4. Add Jenkins Repository Key

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```

#### 📦 5. Add Jenkins APT Repository

```bash
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
```

#### 🛠️ 6. Install Jenkins

```bash
sudo apt update
sudo apt install jenkins -y
```

### 🚀 7. Start and Enable Jenkins

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

#### 🌐 8. Access Jenkins Web UI

Go to `http://<your-ec2-public-ip>:8080`

#### 🔓 9. Unlock Jenkins

`sudo cat /var/lib/jenkins/secrets/initialAdminPassword`

Copy and paste the password into the browser setup wizard.

#### 🔌 10. Install Suggested Plugins

Let Jenkins install recommended plugins.

#### 👤 11. Create First Admin User

Set your admin username, password, and email.

### 📦 Step 2: Nexus Repository Manager Installation

#### 🖥️ 1. Launch AWS EC2 Instance

OS: Amazon Linux 2023

1. Instance Type: t2.medium or higher

2. Storage: Minimum 10 GB

3. ecurity Group Configuration:

   - SSH (22): My IP

   - 8081: My IP, Jenkins SG (to allow Jenkins to upload artifacts)

#### ⚙️ 2. Add the following User Data during EC2 launch:

```bash
#!/bin/bash

# Install Amazon Corretto JDK 17
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-17-amazon-corretto-devel wget -y

# Create directories for Nexus
mkdir -p /opt/nexus/
mkdir -p /tmp/nexus/
cd /tmp/nexus/

# Download and extract Nexus
NEXUSURL="https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.78.0-14.tar.gz"
wget $NEXUSURL -O nexus.tar.gz
sleep 10
EXTOUT=`tar xzvf nexus.tar.gz`
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`
rm -rf /tmp/nexus/nexus.tar.gz
cp -r /tmp/nexus/* /opt/nexus/

# Create nexus user and set permissions
useradd nexus
chown -R nexus:nexus /opt/nexus

# Create Nexus systemd service
cat <<EOT>> /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Configure run_as_user
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Enable and start service
systemctl daemon-reload
systemctl start nexus
systemctl enable nexus
```

#### 🌐 3. Access Nexus from Your Browser

1. URL: http://<EC2_PUBLIC_IP>:8081

2. Default login:

   - Username: admin

   - Password: Get from:

     `sudo cat /opt/nexus/sonatype-work/nexus3/admin.password `

### 🔍 Step 3: SonarQube Installation on Ubuntu (with PostgreSQL and NGINX)

#### 🖥️ 1. Launch AWS EC2 Instance

1. OS: Ubuntu 22.04 LTS

2. Instance Type: t2.medium or higher

3. Storage: Minimum 20 GB

4. Security Group Configuration:

   - SSH (22): My IP

   - HTTP (80): My IP

   - Custom TCP (9000): Jenkins SG (SonarQube API access for Jenkins)

#### 🧾 2. Add the following User Data during EC2 launch:

```bash
#!/bin/bash

# Kernel and limit config
cp /etc/sysctl.conf /root/sysctl.conf_backup
cat <<EOT> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
EOT

cp /etc/security/limits.conf /root/sec_limit.conf_backup
cat <<EOT> /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOT

# Java
sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
sudo update-alternatives --config java
java -version

# PostgreSQL setup
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql.service
sudo systemctl start  postgresql.service

# Create SonarQube DB and user
echo "postgres:admin123" | sudo chpasswd
runuser -l postgres -c "createuser sonar"
sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"
systemctl restart  postgresql

# Download and configure SonarQube
sudo mkdir -p /sonarqube/
cd /sonarqube/
sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.8.100196.zip
sudo apt-get install zip -y
sudo unzip -o sonarqube-9.9.8.100196.zip -d /opt/
sudo mv /opt/sonarqube-9.9.8.100196/ /opt/sonarqube

# Create sonar user and assign permissions
sudo groupadd sonar
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar
sudo chown -R sonar:sonar /opt/sonarqube/

# Configure sonar.properties
cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup
cat <<EOT> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

# Create systemd service
cat <<EOT> /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable sonarqube.service

# Install and configure NGINX
apt-get install nginx -y
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default
cat <<EOT> /etc/nginx/sites-available/sonarqube
server {
    listen      80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header    Host            \$host;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
EOT

ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
systemctl enable nginx.service
ufw allow 80,9000,9001/tcp

echo "System reboot in 30 sec"
sleep 30
reboot
```

#### 🌐 3. Access SonarQube via Browser

1. URL: http://<EC2_PUBLIC_IP>

2. Default credentials:

   - Username: admin

   - Password: admin

3. Set new admin password on first login.

#### 🔁 4. Jenkins Integration

1. Update Jenkins SG to allow outbound access to SonarQube's security group on port 9000.

2. In Jenkins:

   - Go to Manage Jenkins → Configure System

   - Add SonarQube Server under SonarQube section

   - Provide server URL and token

### 🔌 Step 4: Install Required Jenkins Plugins

To enable full CI functionality with GitHub, Maven, SonarQube, and Nexus integration, install the following Jenkins plugins:

#### ✅ Required Plugins

| Plugin Name                    | Purpose                                       |
| ------------------------------ | --------------------------------------------- |
| **Git Plugin**                 | Enables Jenkins to pull code from GitHub      |
| **SonarQube Scanner**          | Integrates SonarQube for code analysis        |
| **Nexus Artifact Uploader**    | Uploads artifacts to Nexus Repository Manager |
| **Pipeline Maven Integration** | Enables use of Maven in Jenkins Pipelines     |
| **Build Timestamp Plugin**     | Adds timestamp metadata to builds             |

#### 🔧 Installation Steps

1. Go to Jenkins Dashboard → Manage Jenkins

2. Click on Manage Plugins

3. Under the Available tab, search and check these plugins:

   - Git plugin

   - SonarQube Scanner

   - Nexus Artifact Uploader

   - Pipeline Maven Integration Plugin

   - Build Timestamp

4. Click Install without restart

5. Wait for the installation to complete

#### ⚙️ Post-Installation Configuration

1. SonarQube:

   - Go to Manage Jenkins → Configure System

   - Scroll to SonarQube Servers

   - Add your SonarQube name, URL, and authentication token

2. Maven:

   - Go to Manage Jenkins → Global Tool Configuration

   - Add Maven (e.g., name it Maven 3.8.7) with install automatically or manual path

### 🧪 Step 5: Write Jenkins Pipeline as Code

#### 📄 Jenkinsfile

```groovy
def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
]

pipeline {
    agent any

    tools {
        maven "MAVEN3.9"
        jdk "JDK17"
    }

    environment {
        BUILD_TIMESTAMP = new Date().format("yyyyMMddHHmmss")
    }

    stages {

        stage('Slack Test') {
            steps {
                sh 'NotARealCommand' // Intentional error to test Slack
            }
        }

        stage('Fetch Code') {
            steps {
                git branch: 'atom', url: 'https://github.com/hkhcoder/vprofile-project.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn install -DskipTests'
            }
            post {
                success {
                    echo 'Now Archiving it...'
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

        stage("SonarQube Analysis") {
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

        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Upload Artifact to Nexus") {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: '172.31.25.14:8081',
                    groupId: 'QA',
                    version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                    repository: 'vprofile-repo',
                    credentialsId: 'nexuslogin',
                    artifacts: [[
                        artifactId: 'vproapp',
                        classifier: '',
                        file: 'target/vprofile-v2.war',
                        type: 'war'
                    ]]
                )
            }
        }
    }

    post {
        always {
            echo 'Sending Slack Notification...'
            slackSend channel: '#devopscicd',
                color: COLOR_MAP[currentBuild.currentResult],
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \nMore info: ${env.BUILD_URL}"
        }
    }
}
```

#### 🧩 1. Create a New Pipeline Job in Jenkins

1. Go to Jenkins Dashboard

2. Click New Item

3. Enter a name (e.g., vprofile-ci-pipeline)

4. Choose Pipeline, then click OK

#### 🔧 2. Configure the Pipeline

1. In the job configuration page:

   - Scroll to Pipeline section

   - Set Definition to: Pipeline script from SCM

   - Set SCM to: Git

   - Enter Repository URL (e.g., https://github.com/hkhcoder/vprofile-project.git)

   - Set Branch: \*/atom or your branch name

   - Script Path: Jenkinsfile (if it's in the repo root)

#### 🧰 3. Ensure Tool Configuration

1. Before running, make sure:

   - MAVEN3.9 and JDK17 are configured in Global Tool Configuration

   - sonar6.2 is defined in SonarQube installation

   - sonarserver is defined in SonarQube servers

   - nexuslogin credentials are added under Manage Jenkins → Credentials

   - Slack integration is configured in Manage Jenkins → Configure System

#### 🚀 4. Trigger the Build

1. Click Build Now to run the pipeline

2. Monitor output in Console Output

#### 📈 5. View Results

1. Build Stage Logs: See each step execution

2. Test Reports: Check Maven Surefire output (if configured)

3. SonarQube: Review analysis on http://<sonarqube-host>

4. Nexus: Verify artifact in http://<nexus-host>:8081 under your repository

5. Slack: Confirm notification in #devopscicd channel
