#!/bin/bash
set -e

echo ""
echo "===================================================="
echo "[LocalStack] Criando filas SQS a partir de arquivos JSON..."
echo "===================================================="

SQS_DIR="/opt/custom/sqs"

if [ ! -d "$SQS_DIR" ]; then
  echo "[LocalStack] Pasta /opt/sqs não encontrada — nenhuma fila será criada."
  exit 0
fi

CREATED_QUEUES=()

for file in "$SQS_DIR"/*.json; do
  [ -e "$file" ] || continue

  echo ""
  echo "[LocalStack] Processando arquivo: $file"

  # Criar fila direto via JSON
  QUEUE_URL=$(awslocal sqs create-queue \
      --cli-input-json file://"$file" \
      --query QueueUrl \
      --output text)

  # Extrair apenas o nome da fila
  QUEUE_NAME=$(basename "$QUEUE_URL")

  CREATED_QUEUES+=("$QUEUE_NAME")

  echo "[LocalStack] Fila criada: $QUEUE_NAME"
done

echo ""
echo "===================================================="
echo "[LocalStack] FILAS SQS CRIADAS:"
echo "===================================================="

for q in "${CREATED_QUEUES[@]}"; do
  echo " - $q"
done

echo ""
echo "===================================================="
echo "[LocalStack] Listagem de filas via API:"
echo "===================================================="

awslocal sqs list-queues

echo ""
echo "[LocalStack] Fim!"
echo "===================================================="
