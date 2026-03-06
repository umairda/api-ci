pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_REPO', defaultValue: 'localhost:5001/health-api', description: 'Docker image repository')
    string(name: 'K8S_CONTEXT', defaultValue: 'kind-jenkins-kube', description: 'kubectl context to deploy to')
  }

  environment {
    IMAGE_REPO = "${params.IMAGE_REPO}"
    IMAGE_TAG = "${BUILD_NUMBER}"
  }

  stages {
    stage('Alpha') {
      steps {
        script {
          runStage('alpha', 'k8s/alpha.yaml')
        }
      }
    }

    stage('Beta') {
      steps {
        script {
          runStage('beta', 'k8s/beta.yaml')
        }
      }
    }

    stage('Prod') {
      steps {
        script {
          runStage('prod', 'k8s/prod.yaml')
        }
      }
    }
  }
}

void runStage(String envName, String manifestPath) {
  echo "Running ${envName} stage"

  sh 'cp /root/.kube/config /tmp/kubeconfig'
  sh "sed -i 's#https://127.0.0.1:#https://host.docker.internal:#g' /tmp/kubeconfig"
  sh "kubectl --kubeconfig=/tmp/kubeconfig config use-context ${params.K8S_CONTEXT}"
  sh 'make clean'
  sh 'make all'
  sh 'make test'
  sh './scripts/run_coverage.sh'

  sh "docker build -t ${IMAGE_REPO}:${envName}-${IMAGE_TAG} ."
  sh "docker push ${IMAGE_REPO}:${envName}-${IMAGE_TAG}"

  sh "sed 's|REPLACE_IMAGE|${IMAGE_REPO}:${envName}-${IMAGE_TAG}|g' ${manifestPath} | kubectl --kubeconfig=/tmp/kubeconfig apply -f -"
  sh "kubectl --kubeconfig=/tmp/kubeconfig rollout status deployment/health-api -n health-${envName} --timeout=120s"
}
