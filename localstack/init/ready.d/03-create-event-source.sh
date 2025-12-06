#!/bin/bash
set -e

echo "[LocalStack] Criando vínculo DynamoDB Stream → Lambda..."

#CONFIGURA O NOME DA TABELA
TABLE="Orders"
NAME="lambda-processor"


STREAM_ARN=$(awslocal dynamodb describe-table \
  --table-name $TABLE \
  --query "Table.LatestStreamArn" \
  --output text)

# Aguarda a Lambda ficar disponível
until awslocal lambda get-function --function-name $NAME > /dev/null 2>&1; do
  echo "Aguardando Lambda ficar pronta..."
  sleep 1
done

awslocal lambda create-event-source-mapping \
  --function-name $NAME \
  --event-source-arn "$STREAM_ARN" \
  --starting-position LATEST \
  --batch-size 1

echo "[LocalStack] Event Source Mapping criado!"
