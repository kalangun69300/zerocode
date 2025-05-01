pipeline {
  agent { label 'slave01' }

  environment {
    COVERITY_HOME   = '/apps/devsecops/coverity/cov-analysis-linux64-2024.12.0/bin'
    COVERITY_REPORT = '/apps/devsecops/coverity/cov-reports-2024.12.0/bin'
    reportDir       = "${env.WORKSPACE}/scan-reports"
    project         = "zerocode-scan"
    stream          = "zerocode-scan"
  }

  stages {
    stage('Prepare report folder') {
      steps {
        sh "mkdir -p ${reportDir}/Coverity-scan-result"
      }
    }

    stage('Build JAR') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Coverity scan & report') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'coverity-secret',
          usernameVariable: 'user',
          passwordVariable: 'pass'
        )]) {
          script {
            // … (ขั้นตอนเช็ค/สร้าง project-stream, capture/analyze, commit defectsฯลฯ) …

            // 4) Copy template → report-configuration.yaml
            sh """
               cp report-configuration-template.yaml report-configuration.yaml
            """

            // 5) ดึง snapshotId
            snapshotId = sh(
              script: "jq -r .analysisInfo.comparisonSnapshotId \"${reportDir}/Coverity-scan-result/preview-report.json\"",
              returnStdout: true
            ).trim()

            // 6) แทนค่าใน report-configuration.yaml ด้วย sed
            sh """
               sed -i 's/Project_Name/${project}/g'                         report-configuration.yaml
               sed -i 's/Project_Stream/${stream}/g'                        report-configuration.yaml
               sed -i 's/Project_Version/1.0/g'                             report-configuration.yaml
               sed -i "s/Create_Date/$(date '+%m')\\/$(date '+%d')\\/$(date '+%Y')/g" report-configuration.yaml
               sed -i 's/snapshotId/${snapshotId}/g'                        report-configuration.yaml
               sed -i 's/User_Name/${user}/g'                               report-configuration.yaml
               sed -i 's/Owasp_version/2021/g'                              report-configuration.yaml
            """

            // 7) Generate PDF report
            sh """
               echo "$pass" > password.txt
               ${COVERITY_REPORT}/cov-generate-security-report report-configuration.yaml \\
                 --output "${reportDir}/Coverity-scan-result/Coverity-${project}.pdf" \\
                 --on-new-cert trust --password file:password.txt --project "${project}"
               rm -f password.txt
            """
          }
        }
      }
    }
  }
}

