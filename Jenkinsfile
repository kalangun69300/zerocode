pipeline {
  agent { label 'slave01' }

  environment {
    COVERITY_HOME   = '/apps/devsecops/coverity/cov-analysis-linux64-2024.12.0/bin'
    COVERITY_REPORT = '/apps/devsecops/coverity/cov-reports-2024.12.0/bin'
    reportDir       = "${env.WORKSPACE}/scan-reports"
    project         = 'zerocode-scan'
    stream          = 'zerocode-scan'
  }

  stages {
    stage('Checkout') {
      steps {
        // ดึงโค้ดจาก SCM (Git) มาไว้ใน workspace
        checkout scm
      }
    }
    
    stage('Prepare report folder') {
      steps {
        sh "mkdir -p ${reportDir}"
      }
    }

    stage('Build JAR') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('creat project & stream') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'coverity-secret', usernameVariable: 'user', passwordVariable: 'pass')]) {
          script {
            // 1) ตรวจสอบ/สร้าง Project
            def projCount = sh(
              script: """\
${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --mode projects --show --fields project \
  --name "${project}" -nh --on-new-cert trust \
| grep -v DEBUG | wc -l
""", returnStdout: true
            ).trim()

            if (projCount == '0') {
              sh """
${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --mode projects --add --set name:"${project}" \
  --on-new-cert trust
"""
            }

            // 2) ตรวจสอบ/สร้าง Stream
            def streamCount = sh(
              script: """\
${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --mode streams --show --fields stream \
  --name "${stream}" -nh --on-new-cert trust \
| grep -v DEBUG | wc -l
""", returnStdout: true
            ).trim()

            if (streamCount == '0') {
              sh """
${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --mode streams --add --set name:"${stream}" \
  --on-new-cert trust

${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --mode projects --name "${project}" \
  --update --insert stream:"${stream}" \
  --on-new-cert trust
"""
            }
          }
        }
      }
    }
  }
}
