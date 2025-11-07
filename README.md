# Terraform CDK – Automated Next.js Deployment on AWS

## 📘 Project Summary

This project automates the deployment of a **Next.js web application** on two AWS EC2 instances using **Terraform CDK (CDKTF)**.

Each EC2 instance is configured to:
- Install **Node.js, PM2, and Nginx**
- Clone the application code from GitHub using a **Personal Access Token (PAT)**
- Build and serve the Next.js app with PM2
- Configure **Nginx reverse proxy** and enable **SSL** via Certbot

Terraform handles all AWS infrastructure provisioning, while a custom **bash script (`deploy.sh`)** automates app setup and deployment.

**Deployed Instances:**
- EC2-1 → `node3.divyanshutiwari.site`
- EC2-2 → `node4.divyanshutiwari.site`

---

## 📂 Folder Structure

```
terraform-cdk/
│
├── main.ts
├── stacks/
│   └── ec2-stack.ts    # NOTE: Uncomment line 39 to enable GitHub clone command
├── scripts/
│   └── deploy.sh
├── cdktf.json
├── package.json
└── README.md
```

---

## ⚙️ Setup Instructions

### 1️⃣ Install CDKTF CLI
```bash
npm install -g cdktf-cli
cdktf --version
```

### 2️⃣ Initialize Project
```bash
mkdir terraform-cdk
cd terraform-cdk
cdktf init --template=typescript --local
```

### 3️⃣ Install Dependencies
```bash
npm install cdktf constructs @cdktf/provider-aws
```

### 4️⃣ Synthesize Terraform JSON
```bash
cdktf synth
```

### 5️⃣ Deploy Infrastructure
```bash
cdktf deploy
```

### 6️⃣ Check Deployment Logs (on EC2)
```bash
cat /home/ubuntu/deploy.log
```

### 7️⃣ Destroy Resources
```bash
cdktf destroy
```

---

## 🛡️ Security Notes
- `.env` file I have not pushed due to security concerns
- Always add `.env` to `.gitignore`.


