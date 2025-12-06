#!/bin/bash
set -e

echo "[LocalStack] Empacotando lambda..."

mkdir -p /tmp

zip -j /tmp/lambda.zip /opt/lambda/handler.py

NAME="lambda-processor"
ENV_FILE="/opt/lambda/env.json"
LAMBDA_ENV=""

if [ -f "$ENV_FILE" ]; then
  echo "[LocalStack] Carregando variáveis de ambiente do env.json..."

  ENV_VARS=$(python3 - <<EOF
import json
with open("$ENV_FILE") as f:
    print(json.dumps({"Variables": json.load(f)}))
EOF
  )

  LAMBDA_ENV="--environment '$ENV_VARS'"
else
  echo "[LocalStack] Nenhum env.json encontrado. Lambda será criada sem environment."
fi

echo "[LocalStack] Criando Lambda..."

eval awslocal lambda create-function \
  --function-name $NAME \
  --runtime python3.12 \
  --handler handler.lambda_handler \
  --zip-file fileb:///tmp/lambda.zip \
  --role arn:aws:iam::000000000000:role/lambda-role \
  $LAMBDA_ENV

echo "[LocalStack] Lambda criada com sucesso!"
