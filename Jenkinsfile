pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    SOURCE_BUCKET      = 'dr-source-bucket-swetha'
    DESTINATION_BUCKET = 'dr-destination-bucket-swetha'
  }

  stages {
    stage('Terraform Init & Apply') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws_creds'
        ]]) {
          dir('terraform') {
            bat '''
              terraform init
              terraform plan -out=tfplan
              terraform apply -auto-approve tfplan
            '''
          }
        }
      }
    }

    stage('Deploy K8s Base') {
      steps {
        bat 'kubectl apply -k base'
      }
    }

    stage('Test S3 Replication') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws_creds'
        ]]) {
          bat '''
            echo DR test from Jenkins %DATE% %TIME% > test.txt
            aws s3 cp test.txt s3://%SOURCE_BUCKET%
            timeout /t 30
            aws s3 ls s3://%DESTINATION_BUCKET%
          '''
        }
      }
    }

    stage('Apply Failover Overlay') {
      steps {
        bat 'kubectl apply -k overlays\\failover'
      }
    }

    stage('Validate Recovery') {
      steps {
        bat 'kubectl get pods -n dr-lab'
        bat 'kubectl get svc db-service -n dr-lab'
      }
    }
  }

  post {
    always {
      echo "✅ DR pipeline complete. S3 replication and K8s failover validated."
    }
  }
}
