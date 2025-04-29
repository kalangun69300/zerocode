pipeline {
    agent { label 'slave01' }

    environment {
        IMAGE_NAME = "hubdc.dso.local/test-image/zerocode-scan"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        COVERITY_PATH = "/apps/devsecops/coverity/cov-analysis-linux64-2024.12.0/bin"
        COVERITY_DIR = "/home/dsoadm01/gun/zerocode/zerocode-maven-archetype/target"
        COVERITY_STREAM = "zerocode-scan"
    }

    stages {
        stage('Build JAR') {
            steps {
                script {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Configure Coverity') {
            steps {
                script {
                    sh "${COVERITY_PATH}/cov-configure --java"
                }
            }
        }

        stage('Build with Cov-Build') {
            steps {
                script {
                    sh "${COVERITY_PATH}/cov-build --dir ${COVERITY_DIR} mvn clean install -DskipTests"
                }
            }
        }

        stage('Analyze with Cov-Analyze') {
            steps {
                script {
                    sh "${COVERITY_PATH}/cov-analyze --dir ${COVERITY_DIR} --all --webapp-security --distrust-all --jobs max4"
                }
            }
        }

        stage('Commit Defects to Coverity Server') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'coverity-secret', passwordVariable: 'COVERITY_PASS', usernameVariable: 'COVERITY_USER')]) {
                    sh "echo $COVERITY_PASS | cov-commit --dir ${COVERITY_DIR} --host 192.168.172.101 --user ${COVERITY_USER} --password-stdin --stream ${COVERITY_STREAM} --https-port=8443 --ssl --on-new-cert trust"
                    }
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
