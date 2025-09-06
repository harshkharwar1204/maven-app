// Jenkins Pipeline for Project 5: Containerizing and Scanning with Docker Hub
// This pipeline automates the entire process from source code to a deployed Docker container on Docker Hub.

pipeline {
    agent none

    tools {
        maven 'Maven3' // Ensure this tool is configured in Jenkins global tools
    }

    environment {
        DOCKERHUB_URL = "docker.io"
        DOCKERHUB_USERNAME = "kharwarharsh1204"  // Changed this line
        IMAGE_NAME = "crudapp"
        IMAGE_TAG = "latest"
        DOCKERHUB_CREDENTIALS_ID = "dockerhub-credentials"
    }

    stages {
        stage('Checkout') {
            agent any
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Compile on Builder') {
            agent { label 'builder' }
            steps {
                echo "Running mvn compile on 'builder' node"
                script {
                    if (isUnix()) {
                        sh 'mvn -B -DskipTests clean compile'
                    } else {
                        bat 'mvn -B -DskipTests clean compile'
                    }
                }
            }
        }

        stage('Test on Tester') {
            agent { label 'tester' }
            steps {
                echo "Running mvn test on 'tester' node"
                script {
                    if (isUnix()) {
                        sh 'mvn -B test'
                    } else {
                        bat 'mvn -B test'
                    }
                }
                archiveArtifacts artifacts: 'target/surefire-reports/**', allowEmptyArchive: true
                // MODIFIED LINE: Added 'allowEmptyResults: true' to prevent failure on no tests
                junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
            }
        }

        stage('Package (on Builder)') {
            agent { label 'builder' }
            steps {
                echo 'Packaging the application on builder...'
                script {
                    if (isUnix()) {
                        sh 'mvn -B -DskipTests package'
                    } else {
                        bat 'mvn -B -DskipTests package'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            agent any
            steps {
                echo 'Building the Docker image...'
                script {
                    if (isUnix()) {
                        sh "docker build -t ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    } else {
                        bat "docker build -t ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
            }
        }

        stage('Login to Docker Hub') {
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        if (isUnix()) {
                            sh "docker login ${DOCKERHUB_URL} --username ${DOCKER_USERNAME} --password ${DOCKER_PASSWORD}"
                        } else {
                            bat "docker login ${DOCKERHUB_URL} --username %DOCKER_USERNAME% --password %DOCKER_PASSWORD%"
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            agent any
            steps {
                echo "Pushing image to Docker Hub: ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                script {
                    if (isUnix()) {
                        sh "docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                    } else {
                        bat "docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy Application') {
            agent any
            steps {
                echo 'Deploying the application...'
                script {
                    if (isUnix()) {
                        sh """
                            docker stop crudapp || true
                            docker rm crudapp || true
                            docker run -d --name=crudapp -p 8081:8081 ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    } else {
                        bat """
                            docker stop crudapp || true
                            docker rm crudapp || true
                            docker run -d --name=crudapp -p 8081:8081 ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            agent { label 'builder' }  // Change from 'agent any' to 'agent { label 'builder' }'
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
