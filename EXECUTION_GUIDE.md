# 🚀 Zomato Clone — DevSecOps Complete Execution Guide
## Jenkins + Docker + Trivy + SonarQube on AWS EC2 via Terraform

---

## 📁 Repository Structure (What to Push to GitHub)

```
zomato-clone/                    ← root of your GitHub repo
├── src/                         ← React app source (from original project)
├── public/
├── package.json
├── Dockerfile                   ← use the FIXED Dockerfile
├── Jenkinsfile                  ← use the FIXED Jenkinsfile
├── .gitignore                   ← rename from _gitignore
└── terraform-infra/             ← Terraform folder (all .tf + userdata.sh)
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tf
    └── userdata.sh
```

---

## PHASE 1 — Prepare Your Local Machine (Windows PowerShell)

### Step 1.1 — Confirm Prerequisites

```powershell
terraform --version     # Must be >= 1.3.0
aws --version           # AWS CLI v2
git --version
```

### Step 1.2 — Configure AWS CLI

```powershell
aws configure
```

Enter:
- AWS Access Key ID     → from IAM user
- AWS Secret Access Key → from IAM user
- Default region        → ap-south-1
- Default output format → json

Verify:
```powershell
aws sts get-caller-identity
```

---

## PHASE 2 — Terraform: Provision AWS Infrastructure

### Step 2.1 — Go to Terraform folder

```powershell
cd "D:\DevOps\Zomato-Clone\terraform-infra"
```

### Step 2.2 — Initialize Terraform

```powershell
terraform init
```

✅ Expected: "Terraform has been successfully initialized!"

### Step 2.3 — Validate

```powershell
terraform validate
```

✅ Expected: "Success! The configuration is valid."

### Step 2.4 — Plan

```powershell
terraform plan
```

Review what will be created: 1 EC2 (t2.large), 1 SG, 1 Key Pair, 1 PEM file.

### Step 2.5 — Apply

```powershell
terraform apply --auto-approve
```

⏳ Takes ~3-4 minutes.

### Step 2.6 — Note the Outputs

After apply completes, you'll see:

```
jenkins_server_public_ip = "x.x.x.x"
jenkins_url              = "http://x.x.x.x:8080"
sonarqube_url            = "http://x.x.x.x:9000"
zomato_app_url           = "http://x.x.x.x:3000"
ssh_command              = "ssh -i zomato-jenkins-key.pem ubuntu@x.x.x.x"
```

📌 **Save these IPs — you'll need them throughout.**

### Step 2.7 — Fix PEM permissions (Windows)

```powershell
icacls "D:\DevOps\Zomato-Clone\terraform-infra\zomato-jenkins-key.pem" /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

---

## PHASE 3 — Wait for EC2 Setup to Complete

The userdata.sh script installs Jenkins, Docker, Trivy, SonarQube, and Node.js automatically.
It takes **8-12 minutes** after EC2 launches.

### Step 3.1 — SSH into EC2

```powershell
ssh -i "D:\DevOps\Zomato-Clone\terraform-infra\zomato-jenkins-key.pem" ubuntu@<YOUR_EC2_IP>
```

### Step 3.2 — Watch the setup log live

```bash
tail -f /var/log/userdata.log
```

Wait until you see:
```
====== SETUP COMPLETE: <timestamp> ======
```

### Step 3.3 — Verify all services

```bash
# Jenkins running?
sudo systemctl status jenkins

# Docker running?
sudo systemctl status docker

# SonarQube container running?
docker ps

# Trivy installed?
trivy --version

# Node installed?
node -v
```

---

## PHASE 4 — Configure Jenkins

### Step 4.1 — Get Jenkins Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy this password.

### Step 4.2 — Open Jenkins in Browser

```
http://<YOUR_EC2_IP>:8080
```

- Paste the initial admin password
- Click **Install suggested plugins** → wait ~3 minutes
- Create your admin user (e.g. admin / admin123)
- Click **Save and Finish**

### Step 4.3 — Install Required Jenkins Plugins

Go to: **Manage Jenkins → Plugins → Available plugins**

Search and install these (check all, then click Install):

| Plugin Name |
|---|
| NodeJS Plugin |
| SonarQube Scanner |
| Docker Pipeline |
| Docker Commons Plugin |
| Pipeline: Stage View |
| Eclipse Temurin Installer (JDK) |

Click **Restart Jenkins after install** checkbox.

### Step 4.4 — Configure NodeJS in Jenkins

**Manage Jenkins → Tools → NodeJS installations → Add NodeJS**

- Name: `NodeJS-18`
- Version: `NodeJS 18.x`
- ✅ Install automatically

Click **Save**.

### Step 4.5 — Configure SonarQube Scanner in Jenkins

**Manage Jenkins → Tools → SonarQube Scanner installations → Add SonarQube Scanner**

- Name: `SonarQube-Scanner`
- ✅ Install automatically (latest version)

Click **Save**.

---

## PHASE 5 — Configure SonarQube

### Step 5.1 — Open SonarQube in Browser

```
http://<YOUR_EC2_IP>:9000
```

⚠️ SonarQube takes **3-5 minutes** to start. If you see a loading screen, wait.

- Login: `admin` / `admin`
- Change password when prompted (e.g. `Admin@123`)

### Step 5.2 — Create SonarQube Project

- Click **Create Project** → **Manually**
- Project Key: `zomato-clone`
- Project Name: `zomato-clone`
- Click **Set Up**
- Select: **With Jenkins**
- Select: **GitHub**
- Click **Configure Analysis**

### Step 5.3 — Generate SonarQube Token

**My Account (top right) → Security → Generate Tokens**

- Name: `jenkins-token`
- Type: `Global Analysis Token`
- Expiry: `No expiration`
- Click **Generate** → **Copy the token** (you won't see it again!)

---

## PHASE 6 — Connect SonarQube to Jenkins

### Step 6.1 — Add SonarQube Token to Jenkins Credentials

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

- Kind: **Secret text**
- Secret: `<paste your SonarQube token>`
- ID: `sonar-token`
- Description: `SonarQube Token`
- Click **Create**

### Step 6.2 — Configure SonarQube Server in Jenkins

**Manage Jenkins → Configure System → SonarQube servers → Add SonarQube**

- Name: `SonarQube-Server`
- Server URL: `http://<YOUR_EC2_IP>:9000`
- Server authentication token: select `sonar-token`

Click **Save**.

---

## PHASE 7 — Add DockerHub Credentials to Jenkins

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

- Kind: **Username with password**
- Username: `<your DockerHub username>`
- Password: `<your DockerHub password or access token>`
- ID: `dockerhub-credentials`
- Description: `DockerHub Credentials`
- Click **Create**

---

## PHASE 8 — Push Code to GitHub

### Step 8.1 — On your local machine

```powershell
cd "D:\DevOps\Zomato-Clone"

# Rename _gitignore to .gitignore
Rename-Item "_gitignore" ".gitignore"

# Replace Dockerfile and Jenkinsfile with the fixed versions
# (copy from the output files provided)

git init
git add .
git commit -m "Initial commit - Zomato Clone DevSecOps"
git branch -M main
git remote add origin https://github.com/piyushdevops-3ri/zomato-clone.git
git push -u origin main
```

### Step 8.2 — Update Jenkinsfile placeholders

In your Jenkinsfile, replace:
```
<YOUR_DOCKERHUB_USERNAME>  →  your actual DockerHub username
<YOUR_GITHUB_USERNAME>     →  piyushdevops-3ri
```

---

## PHASE 9 — Create & Run Jenkins Pipeline

### Step 9.1 — Create New Pipeline Job

- Jenkins Dashboard → **New Item**
- Name: `Zomato-Clone-Pipeline`
- Type: **Pipeline**
- Click **OK**

### Step 9.2 — Configure Pipeline

Under **Pipeline** section:
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/piyushdevops-3ri/zomato-clone.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`

Click **Save**.

### Step 9.3 — Run the Pipeline

Click **Build Now**.

Watch the pipeline run through these stages:
```
✅ Git Checkout
✅ Install Dependencies
✅ SonarQube Analysis
✅ Quality Gate
✅ Trivy File System Scan
✅ Docker Build
✅ Trivy Docker Image Scan
✅ Docker Push to DockerHub
✅ Deploy Container
```

---

## PHASE 10 — Verify the Deployment

### Check app is running:

```bash
# SSH into EC2
ssh -i "zomato-jenkins-key.pem" ubuntu@<YOUR_EC2_IP>

# Check container running
docker ps

# Test app locally on EC2
curl http://localhost:3000
```

### Open app in browser:

```
http://<YOUR_EC2_IP>:3000
```

🎉 **You should see the Zomato Clone app!**

---

## 🧹 CLEANUP — Destroy Everything When Done

```powershell
cd "D:\DevOps\Zomato-Clone\terraform-infra"
terraform destroy --auto-approve
```

⚠️ This stops all billing. Run this when you're done practicing.

---

## 🔴 Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `Permission denied (publickey)` on SSH | Wrong PEM permissions | Run `icacls` command from Step 2.7 |
| Jenkins page not loading after 5 min | userdata still running | Wait and re-check `tail -f /var/log/userdata.log` |
| SonarQube shows blank page | Container still starting | Wait 5 min, refresh |
| `docker: permission denied` in Jenkins | jenkins user not in docker group | `sudo usermod -aG docker jenkins` then restart Jenkins |
| Quality Gate fails | SonarQube found bugs/issues | Check SonarQube dashboard, fix code issues or set gate to "warn" |
| `npm ci` fails in pipeline | node_modules cache issue | Add `rm -rf node_modules` before `npm ci` in Jenkinsfile |

---

## 📊 Architecture Summary

```
Your PC (Windows)
    │
    ├── Terraform apply
    │       │
    │       ▼
    │   AWS EC2 (t2.large, Ubuntu 22.04, ap-south-1)
    │       ├── Jenkins       :8080
    │       ├── SonarQube     :9000  (Docker container)
    │       ├── Docker Engine
    │       ├── Trivy
    │       └── Zomato App    :3000  (Docker container after pipeline)
    │
    ├── GitHub (source code + Jenkinsfile + Dockerfile)
    │
    └── DockerHub (built image pushed here)
```

