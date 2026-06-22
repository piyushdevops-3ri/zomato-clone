#!/bin/bash
set -e
exec > /var/log/userdata.log 2>&1

echo "====== ZOMATO DEVSECOPS SETUP STARTED: $(date) ======"

# ─── System Update ─────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget unzip gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# ─── Install Java 17 (Jenkins dependency) ─────────────────────────────────────
apt-get install -y openjdk-17-jdk
java -version
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment

# ─── Install Jenkins ──────────────────────────────────────────────────────────
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins
echo "Jenkins installed and started."

# ─── Install Docker ───────────────────────────────────────────────────────────
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

# Add ubuntu and jenkins users to docker group
usermod -aG docker ubuntu
usermod -aG docker jenkins
echo "Docker installed."

# ─── Install Node.js 18 ───────────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
node -v
npm -v
echo "Node.js installed."

# ─── Install Trivy ────────────────────────────────────────────────────────────
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
apt-get update -y
apt-get install -y trivy
trivy --version
echo "Trivy installed."

# ─── Run SonarQube as Docker Container ────────────────────────────────────────
# Wait for Docker to be fully ready
sleep 10
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community
echo "SonarQube container started."

# ─── Install sonar-scanner CLI ────────────────────────────────────────────────
SONAR_SCANNER_VERSION="5.0.1.3006"
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -O /tmp/sonar-scanner.zip
unzip /tmp/sonar-scanner.zip -d /opt/
mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' >> /etc/profile.d/sonar.sh
chmod +x /etc/profile.d/sonar.sh
ln -sf /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
sonar-scanner --version || true
echo "SonarQube Scanner installed."

echo "====== SETUP COMPLETE: $(date) ======"
echo "Jenkins  : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "SonarQube: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
