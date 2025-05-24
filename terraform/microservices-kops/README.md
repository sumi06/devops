# Microservices on Kubernetes using Kops (AWS EC2)

## 🏗️ Architecture Overview

```pgsql
          [ Internet / Browser ]
                  |
                  v
          +----------------------+
          |  NGINX Ingress       |  <== Route53: vprofile.sdstudy.xyz
          | (vpro-ingress)       |
          +----------------------+
                  |
                  v
         +-----------------------+
         | vproapp-service (8080)| <== ClusterIP
         +-----------------------+
                  |
                  v
        +--------------------------+
        |      vproapp Pod         |
        | (sumi27/vprofileapp)     |
        +--------------------------+
                  |
    +-------------+--------------+--------------+
    |                            |              |
    v                            v              v
+-----------+          +----------------+   +------------------+
| vprodb    |          | vpromq         |   | vpromc           |
| MySQL     |          | RabbitMQ       |   | Memcached        |
| (3306)    |          | (5672)         |   | (11211)          |
+-----+-----+          +--------+-------+   +--------+---------+
      |                         |
      |                         |
      v                         v
+-------------+        +----------------+
| PVC:        |        | Secret:        |
| db-pv-claim |        | rmq-pass (b64) |
+-------------+        +----------------+
      |
      v
+-------------------------+
| Secret: db-pass (b64)   |
| Used by: vprodb         |
+-------------------------+
```

## 🔧 Cluster Setup — Using Kops on AWS

🧱 Prerequisites

- AWS CLI configured with IAM permissions

- S3 bucket for state storage

- Route53 public or private hosted zone

- kops, kubectl installed

## 📌 Step-by-Step Setup

### 1. ✅ Create S3 bucket for cluster state

```bash
aws s3api create-bucket --bucket <your-kops-state-store> --region us-east-1
export KOPS_STATE_STORE=s3://<your-kops-state-store>
```

### 2. ✅ Create a Route53 Hosted Zone

Ensure your domain (e.g., sdstudy.xyz) is registered and managed via Route53.

### 3. ✅ Create the Cluster

```bash
kops create cluster \
  --name vprofile.sdstudy.xyz \
  --zones us-east-1a \
  --node-count 2 \
  --node-size t3.medium \
  --master-size t3.medium \
  --dns-zone sdstudy.xyz \
  --state $KOPS_STATE_STORE \
  --yes
```

### 4. ✅ Validate the Cluster

```bash
kops validate cluster
```

## 🚀 Deploy Application Stack

```bash
kubectl apply -f app-secret.yaml
kubectl apply -f db-pvc.yaml

# Deploy infrastructure services
kubectl apply -f vprodb-deployment.yaml
kubectl apply -f vpromq-deployment.yaml
kubectl apply -f vpromc-deployment.yaml

# Create Services
kubectl apply -f vprodb-service.yaml
kubectl apply -f vpromq-service.yaml
kubectl apply -f vprocache01-service.yaml

# Deploy main application
kubectl apply -f vproapp-deployment.yaml
kubectl apply -f vproapp-service.yaml

# Deploy ingress resource
kubectl apply -f vpro-ingress.yaml
```

## 🌐 Ingress & DNS Setup

### 1. Install NGINX Ingress Controller (if not already installed):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

### 2. Get External LoadBalancer DNS:

```bash
kubectl get svc -n ingress-nginx
```

### Update Route53 DNS A record:

Point vprofile.sdstudy.xyz to the external DNS of the LoadBalancer (use CNAME record).

## 🧪 Verify Deployment

- Open browser: http://vprofile.sdstudy.xyz

- Check Pod logs:

```bash
kubectl logs -l app=vproapp
```

- Verify services:

```bash
kubectl get svc
kubectl get ingress
```

## 🔒 Security Notes

Secrets in app-secret.yaml are base64-encoded for demo purposes only.

⚠️ Do not store sensitive credentials in plain base64 in production.

Instead, use:

- KMS encryption (e.g., AWS KMS with Kubernetes Secrets EncryptionConfig)

- External secret managers
