import os
import json
import boto3
from decimal import Decimal
from boto3.dynamodb.types import TypeDeserializer

deserializer = TypeDeserializer()

endpoint_url = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
sns_client = boto3.client("sns", endpoint_url=endpoint_url)

def convert_decimals(obj):
    if isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    else:
        return obj

def lambda_handler(event, context):
    topic_arn = os.environ.get("SNS_TOPIC_ARN")
    if not topic_arn:
        print("Variável de ambiente SNS_TOPIC_ARN não definida!")
        return {"status": "error", "message": "SNS_TOPIC_ARN missing"}

    for record in event.get("Records", []):
        new_image = record.get("dynamodb", {}).get("NewImage")
        if new_image:

            item = {k: deserializer.deserialize(v) for k, v in new_image.items()}
            item = convert_decimals(item)

            json_payload = json.dumps(item, indent=2)
            print("Novo pedido do DynamoDB Stream:")
            print(json_payload)

            response = sns_client.publish(
                TopicArn=topic_arn,
                Message=json_payload,
                MessageAttributes={
                    "customerId": {
                        "DataType": "Number",
                        "StringValue": str(item.get("customerId", "0").replace("CUST-", ""))
                    }
                }
            )
            print(f"Publicado no SNS: {response['MessageId']}")

    return {"status": "ok"}
