#!/bin/bash
set -e
echo "=== AWS Personal Account Setup Script ==="
echo "This script creates ECR repositories"
# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"
# AWS Profile
AWS_PROFILE="aws-personal"
# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"
# Create ECR repositories
echo "Creating ECR repositories..."
for repo in ai-service data-service frontend; do
    echo " - Creating repository: $repo"
    aws ecr describe-repositories --profile $AWS_PROFILE --repository-names $repo 2>/dev/null || \
    aws ecr create-repository --profile $AWS_PROFILE --repository-name $repo \
        --tags Key=Project,Value=AI-Ops-Specialization Key=Environment,Value=Lab
done
