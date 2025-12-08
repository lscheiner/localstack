#!/bin/bash
set -e

SNS_DIR="/opt/custom/sns"
TOPIC_DIR="$SNS_DIR/topic"
SUB_DIR="$SNS_DIR/subscription"

echo "[SNS] Criando SNS Topics..."

declare -A TOPIC_ARNS

for file in "$TOPIC_DIR"/*.json; do
  [ -e "$file" ] || continue

  NAME=$(python3 - <<EOF
import json
with open("$file") as f:
    print(json.load(f)["Name"])
EOF
)

  ARN=$(awslocal sns create-topic --cli-input-json file://"$file" --query TopicArn --output text)

  TOPIC_ARNS["$NAME"]=$ARN

  echo "[SNS] Topic criado: $NAME -> $ARN"
done

echo "[SNS] Criando Subscriptions..."

for file in "$SUB_DIR"/*.json; do
  [ -e "$file" ] || continue

  echo "[SNS] Processando subscription: $(basename "$file")"

  awslocal sns subscribe --cli-input-json file://"$file" >/dev/null

  echo "[SNS] Subscription criada: $(basename "$file")"
done

echo ""
echo "============================"
echo " SNS - TÓPICOS CRIADOS"
echo "============================"

awslocal sns list-topics --output json

echo ""
echo "============================"
echo " SNS - SUBSCRIÇÕES POR TÓPICO"
echo "============================"

for topic_name in "${!TOPIC_ARNS[@]}"; do
  topic_arn="${TOPIC_ARNS[$topic_name]}"

  echo ""
  echo "Tópico: $topic_name"
  echo "ARN: $topic_arn"
  echo "Subscriptions:"
  
  awslocal sns list-subscriptions-by-topic \
      --topic-arn "$topic_arn" \
      --output json
done

echo ""
echo "[SNS] Finalizado!"
