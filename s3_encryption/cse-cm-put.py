import base64
import secrets

import boto3
from Crypto.Cipher import AES, PKCS1_v1_5
from Crypto.PublicKey import RSA

session = boto3.Session(profile_name='development')
s3_client = session.client('s3')

# Set up a asymmetric master key
key = RSA.generate(2048)
master_cipher = PKCS1_v1_5.new(key)

# Encrypt the file contents locally with a locally generated DEK
# In production, use a proper padding lib :/
data_key = secrets.token_bytes(32)
wrapped_data_key = master_cipher.encrypt(data_key)
plaintext = open('test_file.txt').read().ljust(16)
encryption_suite = AES.new(data_key, AES.MODE_CBC, 'thisismyiv123456')
cipher_text = encryption_suite.encrypt(plaintext)

# Upload and download from S3 with wrapped DEK in metadata
s3_client.put_object(
    Bucket='karl-cse-cm-example',
    Key='test_file.txt',
    Body=cipher_text,
    Metadata={
        'x-amz-meta-wrapped-dek': base64.b64encode(wrapped_data_key).decode('utf-8')
    }
)

response = s3_client.get_object(
    Bucket='karl-cse-cm-example',
    Key='test_file.txt'
)

# Decrypt the file contents
# In production, use a better sentinel value
ciphertext_message = response['Body'].read()
ciphertext_data_key = base64.b64decode(response['Metadata']['x-amz-meta-wrapped-dek'])

plaintext_data_key = master_cipher.decrypt(ciphertext_data_key, 'sentinel')
decryption_suite = AES.new(plaintext_data_key, AES.MODE_CBC, 'thisismyiv123456')
plaintext_message = decryption_suite.decrypt(ciphertext_message).rstrip()

print(plaintext_message)
