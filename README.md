# terraform-cdk

🧩 Project Summary

This project automates the deployment of a Next.js web application on two AWS EC2 instances using Terraform CDK (CDKTF).
Each EC2 instance automatically:

Installs Node.js, PM2, and Nginx

Clones code from GitHub using a Personal Access Token (PAT)

Builds and serves the Next.js app

Configures Nginx reverse proxy and enables SSL (Certbot)
Terraform handles all AWS infrastructure provisioning, while a custom bash script automates app setup and deployment.

EC2-1: node3.divyanshutiwari.site

Ec2-2: node4.divyanshutiwari.site

---------------------------------------------------------------

### Folder Structure
terraform-cdk/
│
├── main.ts
├── stacks/
│   └── ec2-stack.ts  note: on this line no 39 uncomment the code 
├── scripts/
│   └── deploy.sh
├── cdktf.json
├── package.json
└── README.md


# ==== INSTALL CDKTF CLI ====
npm install -g cdktf-cli
cdktf --version

# ==== INITIALIZE PROJECT ====
mkdir terraform-cdk
cd terraform-cdk
cdktf init --template=typescript --local

# ==== INSTALL DEPENDENCIES ====
npm install cdktf constructs @cdktf/provider-aws

# ==== SYNTHESIZE TERRAFORM JSON ====
cdktf synth

# ==== DEPLOY INFRASTRUCTURE ====
cdktf deploy

# ==== CHECK DEPLOYMENT LOGS (on EC2) ====
cat /home/ubuntu/deploy.log

# ==== DESTROY ALL RESOURCES ====
cdktf destroy