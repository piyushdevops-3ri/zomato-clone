pipeline {
    agent any

    environment {
        DOCKER_IMAGE     = "zomato-clone"
        DOCKER_TAG       = "${BUILD_NUMBER}"
        DOCKER_HUB_REPO  = "piyushchopade/zomato-clone"
        SONAR_PROJECT    = "zomato-clone"
    }

    stages {

        stage('Git Checkout') {
            steps {
                echo "Cloning repository..."
                git branch: 'main', url: 'https://github.com/piyushdevops-3ri/zomato-clone.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing Node dependencies..."
                sh 'npm ci'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube code quality scan..."
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                        npx sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT} \
                          -Dsonar.sources=src \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Waiting for SonarQube Quality Gate result..."
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Trivy File System Scan') {
            steps {
                echo "Running Trivy vulnerability scan on source..."
                sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL --format table . | tee trivy-fs-report.txt'
            }
        }

        stage('Docker Build') {
            steps {
                echo "Building Docker image..."
                sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                echo "Running Trivy scan on Docker image..."
                sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL --format table ${DOCKER_IMAGE}:${DOCKER_TAG} | tee trivy-image-report.txt'
            }
        }

        stage('Docker Push to DockerHub') {
            steps {
                echo "Pushing image to DockerHub..."
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_REPO}:${DOCKER_TAG}
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_REPO}:latest
                        docker push ${DOCKER_HUB_REPO}:${DOCKER_TAG}
                        docker push ${DOCKER_HUB_REPO}:latest
                    '''
                }
            }
        }

        stage('Deploy Container') {
            steps {
                echo "Deploying container on Jenkins server..."
                sh '''
                    docker stop zomato-clone || true
                    docker rm zomato-clone   || true
                    docker run -d \
                        --name zomato-clone \
                        -p 3000:3000 \
                        ${DOCKER_HUB_REPO}:latest
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! App running on port 3000."
        }
        failure {
            echo "❌ Pipeline failed. Check stage logs above."
        }
        always {
            archiveArtifacts artifacts: 'trivy-*.txt', allowEmptyArchive: true
        }
    }
}
