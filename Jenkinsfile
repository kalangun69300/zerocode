pipeline {
  agent { label 'slave01' }

//   parameters {
//     string(name: 'project',   defaultValue: 'zerocode-scan', description: 'ชื่อ Coverity project')
//     string(name: 'stream',    defaultValue: 'zerocode-scan', description: 'ชื่อ Coverity stream')
//   }

  environment {
    IMAGE_NAME = "hubdc.dso.local/test-image/zerocode-scan"
    IMAGE_TAG = "${BUILD_NUMBER}"
    DOCKER_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
    COVERITY_HOME   = '/apps/devsecops/coverity/cov-analysis-linux64-2024.12.0/bin'
    COVERITY_REPORT = '/apps/devsecops/coverity/cov-reports-2024.12.0/bin'
    reportDir       = "${WORKSPACE}/scan-reports"
    project = "zerocode-scan"
    stream = "zerocode-scan"

  }

  stages {
    stage('Prepare report folder') {
      steps {
        sh "mkdir -p ${reportDir}/Coverity-scan-result"
      }
    }

    stage('Build JAR') {
            steps {
                script {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }


    stage('Coverity scan & report') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'coverity-secret', usernameVariable: 'user', passwordVariable: 'pass')]) {
          script {
            // 1) ตรวจสอบ/สร้าง project & stream
            PROJECT = sh(
              script: """\
            ${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
            --user "$user" --password "$pass" \
            --mode projects --show --fields project \
            --name "${project}" -nh --on-new-cert trust \
            | grep -v DEBUG | wc -l
            """, returnStdout: true
                        ).trim()

                        STREAM = sh(
                        script: """\
            ${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
            --user "$user" --password "$pass" \
            --mode streams --show --fields stream \
            --name "${stream}" -nh --on-new-cert trust \
            | grep -v DEBUG | wc -l
            """, returnStdout: true
                        ).trim()

                        if (PROJECT == '0') {
                        sh """\
            ${COVERITY_HOME}/cov-manage-im --url https://192.168.172.101:8443 \
            --user "$user" --password "$pass" \
            --mode projects --add --set name:"${project}" \
            --on-new-cert trust
            """
                        }

                        if (STREAM == '0') {
                        sh """\
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

            // 2) Capture → Analyze → HTML format-errors
            sh """\
${COVERITY_HOME}/cov-capture --project-dir "${WORKSPACE}" --dir idir
${COVERITY_HOME}/cov-capture --source-dir  "${WORKSPACE}" --dir idir
${COVERITY_HOME}/cov-build --dir idir mvn clean install -DskipTests
${COVERITY_HOME}/cov-analyze --dir idir --all --webapp-security --distrust-all --strip-path=`pwd`
${COVERITY_HOME}/cov-format-errors -dir idir --html-output "${reportDir}/Coverity-scan-result/"
"""

            // 3) Commit defects & สร้าง preview-report.json
            sh """\
${COVERITY_HOME}/cov-commit-defects \
  --dir idir --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --stream "${stream}"

${COVERITY_HOME}/cov-commit-defects \
  --dir idir --url https://192.168.172.101:8443 \
  --user "$user" --password "$pass" \
  --stream "${stream}" \
  --on-new-cert trust \
  --preview-report-v2 "${reportDir}/Coverity-scan-result/preview-report.json"
"""

            // 4) Copy HTML/JSON และเท็มเพลต config
            sh """\
cp "${reportDir}/Coverity-scan-result/preview-report.json" "${WORKSPACE}/preview-report.json"
cp "${reportDir}/Coverity-scan-result/index.html"        "${WORKSPACE}/index.html"
cp report-configuration-template.yaml report-configuration.yaml
"""

            // 5) ดึง snapshotId
            snapshotId = sh(
              script: "jq -r .analysisInfo.comparisonSnapshotId \"${reportDir}/Coverity-scan-result/preview-report.json\"",
              returnStdout: true
            ).trim()

            // 6) แทนค่าใน report-configuration.yaml
            sh """\
sed -i s/Project_Name/"${project}"/g report-configuration.yaml
sed -i s/Project_Stream/"${stream}"/g report-configuration.yaml
sed -i s/Project_Version/1.0/g report-configuration.yaml
sed -i "s/Create_Date/$(date '+%m')\/$(date '+%d')\/$(date '+%Y')/g" report-configuration.yaml
sed -i s/snapshotId/"${snapshotId}"/g report-configuration.yaml
sed -i s/User_Name/"${user}"/g report-configuration.yaml
sed -i s/Owasp_version/2021/g report-configuration.yaml
"""

            // 7) สร้าง PDF report จาก config
            sh """\
echo "$pass" > password.txt
${COVERITY_REPORT}/cov-generate-security-report report-configuration.yaml \
  --output "${reportDir}/Coverity-scan-result/Coverity-${project}.pdf" \
  --on-new-cert trust --password file:password.txt --project "${project}"
rm -f password.txt
"""
          }
        }
      }
    }
  }
}

