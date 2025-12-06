# Projeto LocalStack + DynamoDB + Streams + SQS + SNS + Lambda

Esse repositório contém um ambiente local completo usando LocalStack e AWS simulada, com:

* **DynamoDB**: criação automática de tabelas a partir de arquivos JSON
* **DynamoDB Streams**: captura de alterações nas tabelas
* **Lambda**: processa eventos dos Streams, converte dados e publica em SNS
* **SNS e SQS**: integração via arquivos JSON (tópicos, filas e subscriptions)
* **Scripts de inicialização**: automatizam a criação da infraestrutura no LocalStack

---

## Estrutura do Projeto

```plaintext
.
├── docker-compose.yml          # configuração do LocalStack
├── localstack/init/ready.d/    # scripts executados no startup do container
├── dynamodb/                   # JSONs com definições de tabelas DynamoDB
│     └── *.json
├── sqs/                        # JSONs com definições de filas SQS
│     └── *.json
├── sns/                        # configuração SNS
│     ├── topics/               # JSONs para criação de tópicos
│     │    └── *.json
│     └── subscriptions/        # JSONs para subscriptions SNS → SQS/Lambda
│          └── *.json
├── lambda/                     # código da Lambda + env.json
│     ├── handler.py
│     └── env.json              # variáveis de ambiente (ex: SNS_TOPIC_ARN, endpoint)
└── README.md                   # este arquivo
```

---

## Como usar

1. Clone o repositório:

```bash
git clone https://github.com/lscheiner/localstack.git
cd localstack
```

2. Execute o LocalStack com Docker Compose:

```bash
docker compose up
```

Isso irá:

* Criar tabelas DynamoDB definidas em `dynamodb/`
* Criar filas SQS definidas em `sqs/`
* Criar tópicos SNS e subscriptions definidas em `sns/`
* Criar a Lambda com variáveis definidas em `lambda/env.json`, empacotar o código e configurar DynamoDB Streams

3. Inserir dados de teste na tabela DynamoDB:

```bash
awslocal dynamodb put-item \
  --table-name Orders \
  --item '{"orderId":{"S":"ORD-001"}, "customerId":{"S":"CUST-99"}, "status":{"S":"CREATED"}, "amount":{"N":"45.70"}, "createdAt":{"S":"2025-12-05T21:00:00Z"}}'
```

Isso aciona a Lambda, que publica o item no SNS e na SQS inscrita.

---

## Exemplos de arquivos JSON

### DynamoDB (ex: `dynamodb/orders.json`)

```json
{
  "TableName": "Orders",
  "AttributeDefinitions": [
    { "AttributeName": "orderId", "AttributeType": "S" }
  ],
  "KeySchema": [
    { "AttributeName": "orderId", "KeyType": "HASH" }
  ],
  "BillingMode": "PAY_PER_REQUEST",
  "StreamSpecification": {
    "StreamEnabled": true,
    "StreamViewType": "NEW_AND_OLD_IMAGES"
  }
}
```

### SQS (ex: `sqs/filaStatus.json`)

```json
{
  "QueueName": "filaStatus",
  "Attributes": {
    "VisibilityTimeout": "30"
  }
}
```

### SNS Topic (ex: `sns/topics/pedidoAtualizado.json`)

```json
{
  "Name": "pedidoAtualizado"
}
```

### SNS Subscription (ex: `sns/subscriptions/pedidoAtualizado_to_filaStatus.json`)

```json
{
  "TopicArn": "arn:aws:sns:us-east-1:000000000000:pedidoAtualizado",
  "Protocol": "sqs",
  "Endpoint": "arn:aws:sqs:us-east-1:000000000000:filaStatus",
  "Attributes": {
    "FilterPolicy": "{\"customerId\":[\"CUST-99\"]}"
  }
}
```

---

## Lambda Handler (exemplo)

```python
import os
import json
import boto3
from decimal import Decimal
from boto3.dynamodb.types import TypeDeserializer

deserializer = TypeDeserializer()
sns_client = boto3.client("sns", endpoint_url=os.environ["AWS_ENDPOINT_URL"])

def _convert_decimals(obj):
    if isinstance(obj, list):
        return [_convert_decimals(i) for i in obj]
    if isinstance(obj, dict):
        return {k: _convert_decimals(v) for k, v in obj.items()}
    if isinstance(obj, Decimal):
        return float(obj) if obj % 1 else int(obj)
    return obj

def lambda_handler(event, context):
    topic = os.environ.get("SNS_TOPIC_ARN")
    for rec in event.get("Records", []):
       new_image = rec.get("dynamodb", {}).get("NewImage")
       if new_image:
         item = {k: deserializer.deserialize(v) for k, v in new_image.items()}
         item = _convert_decimals(item)
         payload = json.dumps(item, indent=2)
         print("Novo item:", payload)
         sns_client.publish(TopicArn=topic, Message=payload)
```

---

## Observações

* Use o nome do serviço Docker Compose (`localstack`) para conectar do container, não `localhost`.
* Timeout da Lambda no LocalStack é curto; ajuste se necessário.
* Decimal do DynamoDB deve ser convertido para JSON.
* SNS não armazena mensagens; utilize SQS ou Lambda para inspecionar payloads.

---

## Referências

* [LocalStack GitHub](https://github.com/localstack/localstack)
* [AWS CLI LocalStack](https://docs.localstack.cloud/aws/getting-started)
