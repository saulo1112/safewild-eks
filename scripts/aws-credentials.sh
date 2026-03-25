#!/bin/bash
echo "=== AWS Personal Account Profile Configuration ==="
echo ""
echo "This script will configure the profile 'aws-personal'"
echo ""

# Request credentials
read -p "AWS Access Key ID: " access_key
read -p "AWS Secret Access Key: " secret_key

# Configure profile without session token
aws configure set aws_access_key_id "$access_key" --profile aws-personal
aws configure set aws_secret_access_key "$secret_key" --profile aws-personal
aws configure set region us-east-1 --profile aws-personal

echo ""
echo "✅ Profile 'aws-personal' configured correctly"
echo ""

# Verify configuration
echo "Verifying credentials..."
if aws sts get-caller-identity --profile aws-personal > /dev/null 2>&1; then
    echo "✅ Valid credentials"
    echo ""
    aws sts get-caller-identity --profile aws-personal
    echo ""
    echo "To use this profile in all commands, run:"
    echo "export AWS_PROFILE=aws-personal"
else
    echo "❌ Error: Credentials are not valid"
    exit 1
fi
