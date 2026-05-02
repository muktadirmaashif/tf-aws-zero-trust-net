bucket_name="remote-state-$(aws sts get-caller-identity --query "Account" --output text)"
echo $bucket_name

# 1. Create S3 Bucket (Replace with unique name)
aws s3api create-bucket \
    --bucket $bucket_name \
    --region us-east-1

# 2. Enable Versioning (Critical for rollback)
aws s3api put-bucket-versioning \
    --bucket $bucket_name \
    --versioning-configuration Status=Enabled

# 3. Enable Default Encryption (SSE-S3)
aws s3api put-bucket-encryption \
    --bucket $bucket_name \
    --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# 4. Block Public Access
aws s3api put-public-access-block \
    --bucket $bucket_name \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
