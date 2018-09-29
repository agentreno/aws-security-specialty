import base64

import boto3
from Crypto.Cipher import AES

session = boto3.Session(profile_name='development')
kms_client = session.client('kms')
s3_client = session.client('s3')

# Encrypt the file contents locally with a DEK from KMS
# In production, use a proper padding lib :/
data_key = kms_client.generate_data_key(
    KeyId='<insert cse kms key ID from terraform output>',
    KeySpec='AES_256'
)
plaintext = open('test_file.txt').read().ljust(16)
encryption_suite = AES.new(data_key['Plaintext'], AES.MODE_CBC, 'thisismyiv123456')
cipher_text = encryption_suite.encrypt(plaintext)

# Upload and download from S3 with wrapped DEK in metadata
s3_client.put_object(
    Bucket='karl-cse-kms-example',
    Key='test_file.txt',
    Body=cipher_text,
    Metadata={
        'x-amz-meta-wrapped-dek': base64.b64encode(data_key['CiphertextBlob']).decode('utf-8')
    }
)

response = s3_client.get_object(
    Bucket='karl-cse-kms-example',
    Key='test_file.txt'
)

# Decrypt the file contents
ciphertext_message = response['Body'].read()
ciphertext_data_key = base64.b64decode(response['Metadata']['x-amz-meta-wrapped-dek'])

plaintext_data_key = kms_client.decrypt(
    CiphertextBlob=ciphertext_data_key
)['Plaintext']
decryption_suite = AES.new(plaintext_data_key, AES.MODE_CBC, 'thisismyiv123456')
plaintext_message = decryption_suite.decrypt(ciphertext_message).rstrip()

print(plaintext_message)
