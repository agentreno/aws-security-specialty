import boto3

session = boto3.Session(profile_name='development')
client = session.client('s3')

# Using boto3 for S3 PUT using SSE-KMS since algv4 is hard to calculate on the
# command line
client.put_object(
    Bucket='karl-sse-kms-example',
    Key='test_file.txt',
    Body=open('test_file.txt').read(),
    ServerSideEncryption='aws:kms',
    SSEKMSKeyId='<insert sse kms key ID from terraform output>'
)
