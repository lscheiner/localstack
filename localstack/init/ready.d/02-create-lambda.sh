#!/bin/bash
set -e

LAMBDA_DIR="/opt/custom/lambda"
LAMBDA_JSON="$LAMBDA_DIR/lambda.json"
ZIP_FILE="/tmp/lambda.zip"

echo "[Lambda] Empacotando handler..."
zip -j "$ZIP_FILE" "$LAMBDA_DIR/handler.py"

echo "[Lambda] Criando função usando JSON + zip-file..."

awslocal lambda create-function \
  --cli-input-json file://"$LAMBDA_JSON" \
  --zip-file fileb://"$ZIP_FILE"

echo "[Lambda] Função criada com sucesso!"
