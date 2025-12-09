# Projeto LocalStack — DynamoDB, Lambda, SNS e SQS

Este repositório contém um ambiente local para desenvolvimento e testes que simula serviços AWS usando LocalStack. O objetivo é permitir validar integrações entre DynamoDB (com Streams), AWS Lambda, SNS e SQS sem necessidade de uma conta AWS.

Componentes principais:

- DynamoDB (com Streams habilitado)
- Lambda (função que processa eventos do Stream)
- SNS (tópicos para distribuição de mensagens)
- SQS (filas para persistência/consumo das mensagens)
- Wiremock (stubs HTTP para testes de chamadas externas)
- Redis (cache)

Estrutura principal do repositório:

```
. 
├── docker-compose.yml              # configuração dos serviços (LocalStack, Wiremock, Redis)
├── localstack/                     # scripts executados pelo LocalStack no bootstrap
│   └── init/ready.d/
├── localstack-config/              # definições de recursos (dynamodb, lambda, sns, sqs)
├── wiremock/                       # stubs e mapeamentos HTTP
├── redis/                          
└── README.md
```

Como o bootstrap funciona

- Ao subir `docker compose up`, o serviço `localstack` monta `localstack-config` em `/opt/custom` e executa os scripts em `localstack/init/ready.d/`.
- Os scripts criam tabelas DynamoDB, empacotam e criam a função Lambda, configuram o Event Source Mapping para o Stream da tabela, criam filas SQS e tópicos SNS, e aplicam subscriptions.

Arquivos e scripts relevantes

- `docker-compose.yml`: define serviços `localstack`, `wiremock` e `redis`.
- `localstack/init/ready.d/01-create-tables.sh`: cria tabelas DynamoDB a partir dos JSONs em `localstack-config/dynamodb/`.
- `localstack/init/ready.d/02-create-lambda.sh`: empacota `localstack-config/lambda/handler.py` e cria a função a partir de `localstack-config/lambda/lambda.json`.
- `localstack/init/ready.d/03-create-event-source.sh`: cria o Event Source Mapping entre o Stream da tabela `Orders` e a Lambda `lambda-processor`.
- `localstack/init/ready.d/04-create-sqs.sh`: cria filas SQS a partir de `localstack-config/sqs/`.
- `localstack/init/ready.d/05-create-sns.sh`: cria tópicos SNS a partir de `localstack-config/sns/topic/` e subscriptions a partir de `localstack-config/sns/subscription/`.

Requisitos

- Docker (Desktop) com Compose
- (Opcional) `awslocal` para executar comandos AWS apontando para o LocalStack

Instruções rápidas

1) Subir o ambiente

```powershell
docker compose up
```

2) Confirmar recursos criados (exemplos com `awslocal`)

```powershell
awslocal dynamodb list-tables
awslocal sqs list-queues
awslocal sns list-topics
```

**Alternativa:** se não tiver `awslocal`, use `aws` com `--endpoint-url`:

```powershell
aws dynamodb list-tables --endpoint-url http://localhost:4566 --region us-east-1
aws sqs list-queues --endpoint-url http://localhost:4566 --region us-east-1
aws sns list-topics --endpoint-url http://localhost:4566 --region us-east-1
```

3) Inserir um item de teste na tabela `Orders`

```powershell
awslocal dynamodb put-item --table-name Orders --item '{"orderId":{"S":"ORD-001"}, "customerId":{"S":"CUST-99"}, "status":{"S":"CREATED"}, "amount":{"N":"45.70"}, "createdAt":{"S":"2025-12-05T21:00:00Z"}}'
```

**Ou com `aws --endpoint-url`:**

```powershell
aws dynamodb put-item --endpoint-url http://localhost:4566 --region us-east-1 --table-name Orders --item '{"orderId":{"S":"ORD-001"}, "customerId":{"S":"CUST-99"}, "status":{"S":"CREATED"}, "amount":{"N":"45.70"}, "createdAt":{"S":"2025-12-05T21:00:00Z"}}'
```

4) Ler mensagens na fila SQS (ex.: `fila-pedidos`)

```powershell
awslocal sqs receive-message --queue-url http://localhost:4566/000000000000/fila-pedidos --max-number-of-messages 10
```

Detalhes do processamento

- A função Lambda (`lambda-processor`) está definida em `localstack-config/lambda/lambda.json` e implementada em `localstack-config/lambda/handler.py`.
- Fluxo da Lambda:
  1. Recebe eventos do DynamoDB Stream (campo `NewImage`).
  2. Desserializa os atributos do DynamoDB usando `TypeDeserializer` do `boto3`.
  3. Converte valores `Decimal` para `int`/`float` para permitir serialização JSON.
  4. Publica o payload JSON no tópico SNS configurado (`SNS_TOPIC_ARN`) com atributos de mensagem (ex.: `customerId`).

Observações operacionais

- Verifique se a tabela DynamoDB possui `StreamSpecification` habilitada (ex.: `NEW_AND_OLD_IMAGES`).
- O Event Source Mapping é criado com `starting-position` = `LATEST` e `batch-size` = `1`.
- Subscriptions SNS podem usar `FilterPolicy` e `FilterPolicyScope` para filtrar mensagens antes de chegarem às filas.

Wiremock

- O serviço Wiremock fornece stubs HTTP definidos em `wiremock/mappings` e respostas em `wiremock/files`.

Redis

- O Redis é iniciado pelo container `redis` definido em `docker-compose.yml` e expõe a porta `6379`.
- O entrypoint `redis/redis-entrypoint.sh` inicia o servidor e executa um seed inicial:

  - Chave: `teste_ff0ddb1f-f91e-4d4a-9555-ccabd86e8da6`
  - Valor: `10000`

- Arquivo de entrypoint: `redis/redis-entrypoint.sh` (inicia servidor e popula seed).
- Diretório de configuração: `redis/redis.conf/` (pode conter arquivo `redis.conf` de customização).

- Para acessar o Redis localmente (do host):

```powershell
redis-cli -h localhost -p 6379
```

- Para verificar o valor seed direto no host:

```powershell
redis-cli GET teste_ff0ddb1f-f91e-4d4a-9555-ccabd86e8da6
```

- Alternativa: via container:

```powershell
docker exec -it redis redis-cli GET teste_ff0ddb1f-f91e-4d4a-9555-ccabd86e8da6
```

- Se precisar de outros valores iniciais, adicione comandos `redis-cli` no `redis/redis-entrypoint.sh`.

- **Verificação automática**: execute o script `scripts/check-redis.sh` para validar se o Redis está rodando e se o seed está correto:

```powershell
bash scripts/check-redis.sh
```

Debugging e comandos úteis

- Ver logs do LocalStack:
```powershell
docker compose logs -f localstack
```

- Listar event source mappings:
```powershell
awslocal lambda list-event-source-mappings
```

- Verificar subscriptions de um tópico:
```powershell
awslocal sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:pedidoAtualizado
```

Como estender o projeto

- Para adicionar uma nova tabela: adicionar JSON em `localstack-config/dynamodb/`.
- Para adicionar uma nova fila SQS: adicionar JSON em `localstack-config/sqs/`.
- Para adicionar tópico SNS ou subscription: adicionar JSON em `localstack-config/sns/topic/` ou `localstack-config/sns/subscription/`.

