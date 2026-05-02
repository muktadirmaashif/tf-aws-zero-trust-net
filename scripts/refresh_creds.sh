#!/bin/bash

# USAGE: source refresh.sh <ACCESS_KEY> <SECRET_KEY>
# NOTE: Must use 'source' to affect the current shell environment.

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Error: Missing credentials."
    echo "Usage: source refresh.sh AKIA... wJalrXUtnFEMI..."
    return 1
fi

# 1. Set Credentials for Current Session
export AWS_ACCESS_KEY_ID="$1"
export AWS_SECRET_ACCESS_KEY="$2"
export AWS_DEFAULT_REGION="us-east-1"

# 2. Clear Conflicting Configs
unset AWS_PROFILE
unset AWS_SHARED_CREDENTIALS_FILE

# 3. Verify Immediately
echo "🔄 Verifying credentials..."
CALLER=$(aws sts get-caller-identity --query Account --output text 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Success! Account ID: $CALLER"
    echo "🚀 Ready for Terraform."
else
    echo "❌ Failed: $CALLER"
    echo "Check your keys or IAM permissions."
    return 1
fi
