import secrets

import boto3

session = boto3.Session(profile_name='development')
client = session.client('s3')

# Generate a key (not a great keymat source but its an example)
key = secrets.token_bytes(32)

client.put_object(
    Bucket='karl-sse-c-example',
    Key='test_file.txt',
    Body=open('test_file.txt').read(),
    SSECustomerAlgorithm='AES256',
    SSECustomerKey=key  # library does the base64 encoding
    # SSECustomerKeyMD5 is optional and calculated for us, excellent
)

response = client.get_object(
    Bucket='karl-sse-c-example',
    Key='test_file.txt',
    SSECustomerAlgorithm='AES256',
    SSECustomerKey=key
)

print(response['Body'].read())
