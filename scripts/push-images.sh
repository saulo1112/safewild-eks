#!/bin/bash
set -e
echo "=== Push Docker Images to ECR ==="
# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"
# AWS Profile
AWS_PROFILE="aws-personal"
# Get AWS Account ID and Region
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
REGION="us-east-1"
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
echo "Account ID: $ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --profile $AWS_PROFILE --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
# Build and push each service
services=("ai-service" "data-service" "frontend")
for service in "${services[@]}"; do
    echo ""
    docker tag $service:v1 $ECR_REGISTRY/$service:v1
    echo "Pushing $service to ECR..."
    docker push $ECR_REGISTRY/$service:v1
    cd "$PROJECT_ROOT"
done
echo ""
echo "=== All images pushed successfully ==="
echo "You can now deploy to EKS: kubectl apply -f k8s/"
