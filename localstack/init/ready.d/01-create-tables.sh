#!/bin/bash
set -e

DDB_DIR="/opt/dynamodb"

echo "[LocalStack] Criando tabelas DynamoDB..."

for table_file in "$DDB_DIR"/*.json; do
  if [ -f "$table_file" ]; then
    echo "[LocalStack] Criando tabela $(basename "$table_file")"
    awslocal dynamodb create-table --cli-input-json file://"$table_file"
  fi
done
