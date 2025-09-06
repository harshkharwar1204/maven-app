// Jenkins Pipeline for Project 5: Containerizing and Scanning with Docker Hub
// This pipeline automates the entire process from source code to a deployed Docker container on Docker Hub.

pipeline {
    // Agent configuration for the pipeline
    agent any

    // Define tools required for the build process
    tools {
        maven 'Maven3' // Must match your Jenkins Maven installation name
    }

    // Environment variables for Docker Hub and image details.
    // Replace the placeholders with your actual values.
    environment {
        // You'll need to set up a Docker Hub account and credentials in Jenkins
        DOCKERHUB_URL = "docker.io"
        DOCKERHUB_USERNAME = "kharwarharsh1204" // Your Docker Hub username
        IMAGE_NAME = "crudapp"
        IMAGE_TAG = "latest" // Or use a dynamic tag like "${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS_ID = "dockerhub-credentials" // Jenkins Credential ID for Docker Hub username/password
    }

    // The core stages of the pipeline
    stages {
        // Stage 1: Checkout the source code from SCM
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        // Stage 2: Compile the Java project
        stage('Build') {
            steps {
                echo 'Building the project...'
                bat 'mvn clean compile'
            }
        }

        // Stage 3: Run unit tests
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                bat 'mvn test'
            }
        }

        // Stage 4: Package the application into an executable JAR
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                // The 'package' goal will produce the JAR file in the target directory
                bat 'mvn package'
            }
        }

        // Stage 5: Build a Docker image for the application
        stage('Build Docker Image') {
            steps {
                echo 'Building the Docker image...'
                // The 'docker build' command uses the Dockerfile in the current directory.
                // It tags the image with the full repository name for Docker Hub.
                bat "docker build -t ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // Stage 6: Authenticate with Docker Hub
        stage('Login to Docker Hub') {
            steps {
                echo 'Logging in to Docker Hub...'
                // Use Jenkins withCredentials to securely inject Docker Hub username/password
                // The DOCKERHUB_CREDENTIALS_ID must be a 'Username with password' type credential in Jenkins.
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    bat "docker login ${DOCKERHUB_URL} --username %DOCKER_USERNAME% --password %DOCKER_PASSWORD%"
                }
            }
        }

        // Stage 7: Push the Docker image to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                echo "Pushing image to Docker Hub: ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                bat "docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // The DTR Security Scan stage is removed as Docker Hub does not have this specific feature.
        // You would integrate a separate security scanner tool here if needed.

        // Stage 8: Deploy the application on a target host
        stage('Deploy Application') {
            steps {
                echo 'Deploying the application...'
                bat """
                docker stop crudapp || true
                docker rm crudapp || true
                docker run -d --name=crudapp -p 8081:8081 crudapp:latest
                """
            }
        }

        // Stage 9: Archive the packaged JAR file
        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    // Post-build actions to run after all stages
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
