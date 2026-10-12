pipeline {
  agent any
  environment {
    MK_IP = sh(script: 'minikube ip', returnStdout: true).trim()
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build') {
      steps {
        sh 'docker build --build-arg VERSION=v2 --build-arg COLOR=green -t myapp:v2 app/'
        sh 'minikube image load myapp:v2 --overwrite=true'
      }
    }
    stage('Deploy Green') {
      steps {
        sh 'kubectl apply -f k8s/deployment-green.yaml -f k8s/service-green-preview.yaml'
        sh 'kubectl rollout restart deployment/myapp-green'
        sh 'kubectl rollout status deployment/myapp-green --timeout=120s'
      }
    }
    stage('Test Green') {
      steps {
        sh 'curl -sf http://$MK_IP:30081 | grep "Version: v2"'
        sh 'echo "Live traffic still on: $(kubectl get svc myapp-service -o jsonpath={.spec.selector.color})"'
      }
    }
    stage('Switch Traffic') {
      steps {
        input "Switch to Green?"
        sh '''
        kubectl patch service myapp-service \
        -p '{"spec":{"selector":{"app":"myapp","color":"green"}}}'
        '''
      }
    }
    stage('Verify') {
      steps {
        sh 'kubectl get svc myapp-service -o jsonpath="{.spec.selector}"; echo'
        sh 'curl -sf http://$MK_IP:30080 | grep -o "Version: v2[^<]*"'
      }
    }
  }
}
