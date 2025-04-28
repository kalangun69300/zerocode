pipeline {
    agent { label 'slave01' }

    environment {
        image_name = "hubdc.dso.local/test-image/zerocode-scan:latest"
    }

    stages {
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

        stage('Pull Docker Image') {
            steps {
                script {
                    sh "docker pull ${env.image_name}"
                }
            }
        }
    }
}

