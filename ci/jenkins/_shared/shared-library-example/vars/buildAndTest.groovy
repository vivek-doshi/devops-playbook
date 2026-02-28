// vars/buildAndTest.groovy
// Jenkins Shared Library — call as: buildAndTest(tech: 'dotnet')

def call(Map config = [:]) {
    def tech = config.tech ?: 'node'

    pipeline {
        agent any

        stages {
            stage('Build & Test') {
                steps {
                    script {
                        if (tech == 'dotnet') {
                            sh 'dotnet build && dotnet test'
                        } else if (tech == 'python') {
                            sh 'pip install -r requirements.txt && pytest'
                        } else if (tech == 'node') {
                            sh 'npm ci && npm test'
                        }
                    }
                }
            }
        }
    }
}
