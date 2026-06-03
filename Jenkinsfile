pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        ECR_REGISTRY    = '915993062448.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO        = 'my-site'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        CONTAINER_NAME  = 'my-site'
        CONTAINER_PORT  = '8080'
    }

    stages {

        // ── 1. Checkout ───────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "Клонируем репозиторий..."
                checkout scm
            }
        }

        // ── 2. Build Docker image ─────────────────────────────
        stage('Build') {
            steps {
                echo "Собираем Docker образ с тегом ${IMAGE_TAG}..."
                sh """
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest
                """
            }
        }

        // ── 3. Push to ECR ────────────────────────────────────
        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',     variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    echo "Логинимся в ECR и пушим образ..."
                    sh """
                        aws configure set aws_access_key_id     $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region        ${AWS_REGION}

                        aws ecr get-login-password --region ${AWS_REGION} \
                            | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
                    """
                }
            }
        }

        // ── 4. Deploy ─────────────────────────────────────────
        stage('Deploy') {
            steps {
                echo "Деплоим новый контейнер..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm   ${CONTAINER_NAME} || true

                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        --restart unless-stopped \
                        -p ${CONTAINER_PORT}:80 \
                        ${ECR_REGISTRY}/${ECR_REPO}:latest
                """
            }
        }

        // ── 5. Health check ───────────────────────────────────
        stage('Health Check') {
            steps {
                echo "Проверяем что сайт отвечает..."
                sh """
                    sleep 5
                    curl -f http://localhost:${CONTAINER_PORT}/health || exit 1
                """
            }
        }
    }

    // ── Уведомления ───────────────────────────────────────────
    post {
        success {
            echo "✅ Деплой успешен! Сайт доступен на порту ${CONTAINER_PORT}"
        }
        failure {
            echo "❌ Pipeline упал. Смотри логи выше."
            // Откат на предыдущий образ
            sh """
                docker stop ${CONTAINER_NAME} || true
                docker rm   ${CONTAINER_NAME} || true
                docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    -p ${CONTAINER_PORT}:80 \
                    ${ECR_REGISTRY}/${ECR_REPO}:latest || true
            """
        }
        always {
            echo "Очищаем локальные образы..."
            sh "docker image prune -f || true"
        }
    }
}