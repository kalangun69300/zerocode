pipeline {
    agent { label 'slave01' }

    environment {
        IMAGE_NAME = "hubdc.dso.local/test-image/zerocode-scan"
        IMAGE_TAG = "${BUILD_NUMBER}"    
        DOCKER_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
    }

    stages {

                stage('Build JAR') {
            steps {
                script {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Docker Image') {
                    steps {
                        script {
                            sh "docker build -t ${DOCKER_IMAGE} ."
                        }
                    }
                }

        stage('Login to Harbor') {
            steps {
                script {
                    // ใช้ credentials เพื่อ login ไป Harbor
                    withCredentials([usernamePassword(credentialsId: 'harborhub', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        // Login to Harbor
                        sh "echo $DOCKER_PASS | docker login hubdc.dso.local -u $DOCKER_USER --password-stdin"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    sh "docker push ${DOCKER_IMAGE}"
                }
            }
        }
    }
}

