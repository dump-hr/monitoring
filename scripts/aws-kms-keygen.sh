#!/bin/sh

PROJECT=$1

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project>"
  exit 1
fi

KEY_ID=$(AWS_PROFILE="$PROJECT" AWS_REGION=us-east-1 aws kms create-key | jq -r .KeyMetadata.KeyId)

AWS_PROFILE="$PROJECT" AWS_REGION=us-east-1 aws kms create-alias --alias-name "alias/$PROJECT" --target-key-id "$KEY_ID"

AWS_PROFILE="$PROJECT" AWS_REGION=us-east-1 aws kms describe-key --key-id "$KEY_ID" | jq -r .KeyMetadata.Arn
