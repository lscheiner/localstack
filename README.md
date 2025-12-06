# Projeto LocalStack + DynamoDB + Streams + SQS + SNS + Lambda + Wiremock + Redis

Este projeto cria um ambiente local completo simulando serviços AWS usando **LocalStack**, junto com integração de filas, tópicos, lambda, cache e APIs externas. Ele serve para desenvolvimento e testes locais de aplicações que dependem de AWS sem precisar de uma conta real.

## Funcionalidades

* **LocalStack**: ambiente AWS simulado localmente.
* **DynamoDB**: criação automática de tabelas a partir de arquivos JSON.
* **DynamoDB Streams**: captura de alterações nas tabelas.
* **Lambda**: processa eventos dos Streams, converte dados e publica em SNS.
* **SNS e SQS**: integração via arquivos JSON (tópicos, filas e subscriptions).
* **Wiremock**: simula APIs externas com stubs.
* **Redis**: cache com valores iniciais carregados automaticamente.
* **Scripts de inicialização**: automatizam a criação da infraestrutura no LocalStack.

## Estrutura do Projeto

```
.
├── docker-compose.yml        # Configuração do LocalStack, Wiremock e Redis
├── localstack/
│   ├── init/ready.d/         # Scripts executados no startup do container
│   ├── lambda/               # Código da Lambda + env.json
│   ├── dynamodb/             # Arquivos JSON de definição das tabelas
│   ├── sqs/                  # Arquivos JSON de definição das filas
│   └── sns/                  # topic/ e subscription/ com JSON de configuração
├── wiremock/
│   ├── mappings/             # Arquivos JSON de mapeamento de endpoints
│   └── __files/              # Responses dos endpoints
```

## Como Usar

1. **Subir o ambiente**

```bash
docker compose up
```

Isso iniciará:

* LocalStack com Lambda, DynamoDB, SQS, SNS, IAM e Logs.
* Wiremock na porta 8080.
* Redis na porta 6379 com valor inicial carregado.

2. **Criar tabelas DynamoDB**

* Coloque arquivos JSON em `localstack/dynamodb/` e os scripts de init criarão automaticamente as tabelas.

3. **Criar filas SQS**

* Coloque arquivos JSON em `localstack/sqs/` e o script criará as filas.

4. **Criar tópicos SNS e subscriptions**

* Configure tópicos em `localstack/sns/topic/` e subscriptions em `localstack/sns/subscription/`.

5. **Lambda**

* A Lambda processa eventos do DynamoDB Streams e publica em SNS.
* Variáveis de ambiente podem ser configuradas em `localstack/lambda/env.json`.

6. **Wiremock**

* Adicione endpoints em `wiremock/mappings/` e respostas em `wiremock/__files/`.
* Acesse em `http://localhost:8080`.

7. **Redis**

* Valor inicial carregado automaticamente via `redis-init-data`.
* Acesse via `redis-cli -h localhost -p 6379`.

