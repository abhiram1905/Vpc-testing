pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'What do you want to do?')
    string(name: 'TF_DIR', defaultValue: '.', description: 'Path to Terraform code in the repo')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init & Validate') {
      steps {
        dir(params.TF_DIR) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                            credentialsId: '33c6efd0-8eb3-4530-8012-db1ef4147fc5', 
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            withEnv(["AWS_DEFAULT_REGION=${params.AWS_REGION}"]) {
              sh '''
                terraform --version
                terraform init -input=false -upgrade -reconfigure
                terraform validate
              '''
            }
          }
        }
      }
    }

    stage('Terraform Plan') {
      when { anyOf { expression { params.ACTION == 'plan' }; expression { params.ACTION == 'apply' } } }
      steps {
        dir(params.TF_DIR) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: '33c6efd0-8eb3-4530-8012-db1ef4147fc5',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            withEnv(["AWS_DEFAULT_REGION=${params.AWS_REGION}"]) {
              sh 'terraform plan -input=false -out=tfplan'
            }
          }
        }
      }
      post {
        success {
          archiveArtifacts artifacts: "tfplan", onlyIfSuccessful: true
        }
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        dir(params.TF_DIR) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: '33c6efd0-8eb3-4530-8012-db1ef4147fc5',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            withEnv(["AWS_DEFAULT_REGION=${params.AWS_REGION}"]) {
              sh '''
                if [ -f tfplan ]; then
                  terraform apply -input=false -auto-approve tfplan
                else
                  terraform apply -input=false -auto-approve
                fi
              '''
            }
          }
        }
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        dir(params.TF_DIR) {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: '33c6efd0-8eb3-4530-8012-db1ef4147fc5',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            withEnv(["AWS_DEFAULT_REGION=${params.AWS_REGION}"]) {
              sh '''
                terraform init -input=false -reconfigure
                terraform show || echo "State not found"
                terraform state list || echo "Nothing to destroy"
                terraform destroy -input=false -auto-approve
              '''
            }
          }
        }
      }
    }
  }

  post {
    always {
      dir(params.TF_DIR) {
        archiveArtifacts artifacts: 'terraform.tfstate*', allowEmptyArchive: true
      }
    }
  }
}
