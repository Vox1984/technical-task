pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: docker
            image: docker:latest
            command:
            - cat
            tty: true
            volumeMounts:
             - mountPath: /var/run/docker.sock
               name: docker-sock
          volumes:
          - name: docker-sock
            hostPath:
              path: /var/run/docker.sock    
        '''
    }
  }
    
    environment {
        APP_NAME = "fastapi-app"
        IMAGE_NAME = "${APP_NAME}:${BUILD_NUMBER}"
        NAMESPACE = "default"
    }
    
    stages {
        stage('Build') {
            steps {
                container('docker') {
                    script {
                        // Build Docker image
                        sh 'docker build -t ${IMAGE_NAME} .'
                        // Save image digest for deployment
                        sh 'echo ${IMAGE_NAME} > image-tag.txt'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                container('docker') {
                    script {
                        // Create test container
                        sh '''
                            docker run --rm -d --name test-container ${IMAGE_NAME} tail -f /dev/null
                        
                            # Copy test files into container
                            docker cp ./test.py test-container:/app/
                            
                            # Run pytest
                            docker exec test-container pytest /app/test.py
                            
                            # Collect test results
                            docker cp test-container:/app/results .
                            
                            # Clean up
                            docker rm -f test-container
                        '''
                        
                        // Archive test results for Jenkins
                        junit '**/results/*.xml'
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                expression {
                    return currentBuild.result == null || currentBuild.result.isSuccess()
                }
            }
            
            steps {
                script {
                    // Load image tag
                    def imageTag = readFile 'image-tag.txt'
                    
                    // Apply Kubernetes deployment
                    sh '''
                        kubectl apply -f deployment.yaml
                        kubectl patch deployment ${APP_NAME} \
                            -p=\'{"spec":{"template":{"spec":{"containers":[{"name":"${APP_NAME}","image":"'"${imageTag}"'"}]}}}'}'
                    '''
                }
            }
        }
        
        stage('Validate') {
            when {
                expression {
                    return currentBuild.result == null || currentBuild.result.isSuccess()
                }
            }
            
            steps {
                script {
                    // Wait for deployment to become available
                    sh 'kubectl rollout status deployment/${APP_NAME}'
                    
                    // Verify health endpoint
                    sh '''
                        HEALTH_STATUS=$(kubectl get pod -l app=${APP_NAME} \
                            -o jsonpath='{.items[0].status.containerStatuses[0].ready}')
                        
                        if [ "$HEALTH_STATUS" != "true" ]; then
                            exit 1
                        fi
                        
                        echo "Deployment validated successfully"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        failure {
            // Send notification on failure
            mail to: 'team@example.com',
                 subject: 'FastAPI App Pipeline Failed',
                 body: 'Pipeline failed - check Jenkins console for details'
        }
    }
 }                   

    
