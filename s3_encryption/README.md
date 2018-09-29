# S3 Encryption

## S3 Server-side Encryption

S3 encrypts objects before writing them to disk and decrypts them before
reading them. It is about protecting the data at rest on AWS storage.

### SSE-S3

S3 manages the keys and encryption internally. A different key is used per
object, wrapped with a master key that regularly rotates. AES-256 is used.

This type of encryption is activated by adding the
`x-amz-server-side-encryption` header on PUT, multipart uploads and COPY
requests. You can also just set bucket configuration to encrypt everything with
SSE-S3 by default so headers are not required on every request.

A bucket policy can be added to deny any requests to a bucket that don't turn
on SSE-S3.

Rejected request and accepted request with encryption header:
```
http PUT https://karl-sse-s3-example.s3.amazonaws.com/test_file.txt < test_file.txt
http PUT https://karl-sse-s3-example.s3.amazonaws.com/test_file.txt 'x-amz-server-side-encryption:AES256' < test_file.txt
```

```diff
+ Very simple to implement (bucket policy or header)
+ No key management or encryption code to worry about
+ Good security properties (dek per object, rotated master key)
- You need to trust that AWS have taken enough steps to secure the keys it is
  using to encrypt your data for you (physical security, personnel security,
  datacentre security etc.)
- You need to trust that AWS won't hand over the keys to someone e.g. if
  compelled to do so
```

### SSE-KMS

AWS KMS manages the keys and S3 uses it to perform the encryption. This allows
for specific requirements around key management, type, algorithms, auditing etc.
while still allowing AWS to manage all of the keys and encryption.

This type of encryption is activated by:
- Adding the `x-amz-server-side-encryption` header with a value of `aws:kms`.
  This creates and uses a default key in KMS.
- If a particular key is needed, accompanying it with a
  `x-amz-server-side-encryption-aws-kms-key-id` header will use that key
  instead.

```diff
+ Still fairly simple to implement (KMS default key, or KMS key creation)
+ No encryption code, limited key management effort
+ Provides all the benefits of KMS: custom key rotation schedules, key usage
  auditing, disabling keys, importing key material, access control on key
  usage etc.
+ This allows you to meet specific compliance requirements
- Requires the same level of trust in broader AWS security as SSE-S3
```

### SSE-C

The customer manages the keys and S3 uses it to perform the encryption. This
gives direct control over the key material and key storage client-side.

This type of encryption is activated by:
- Adding the `x-amz-server-side-encryption-customer-algorithm` header with a
  value of `AES256`
- Adding the `x-amz-server-side-encryption-customer-key` header with a 256-bit
  base 64 encoded key to use
- Adding the `x-amz-server-side-encryption-customer-key-MD5` header with a
  128-bit MD5 hash of the encryption key, as an extra check on message
  integrity to avoid unrecoverable data

```diff
+ Harder to implement, involves key generation and storage outside of AWS
- It's a strange mix of creating your own keys but then providing them to AWS
  anyway, something which is possible using KMS if key generation is the issue
```

## S3 Client-side Encryption

### CSE-KMS (KMS Managed CMK)

KMS manages the master key, the customer uses KMS to generate data encryption
keys and encrypts client-side before uploading to S3.

This type of encryption is activated by:
- Calling KMS `GenerateDataKey` operation for an existing KMS master key, which
  provides a plaintext version and ciphered version of the data key
- Using the resulting key to encrypt the data locally
- Uploading the encrypted file to S3 with a metadata header of
  `x-amz-meta-wrapped-dek` containing the ciphered data key, so it can be
  unwrapped for decryption using KMS later

```diff
+ Useful if you want to use AWS for key management, but you want to encrypt
  data outside of AWS
- Again, like SSE-C, slightly odd in that involves trusting some AWS components
  but not others
```

### CSE-CM (Customer Managed CMK)

AWS doesn't see keys or plaintext data in any form. A data key is generated
locally and used to encrypt the data. As with CSE-KMS, the data key is wrapped
with a master key and stored alongside the data in S3 as metadata, under the
name `x-amz-meta-wrapped-dek`.

```diff
+ At least logically consistent with an approach of preferring not to rely on
  AWS broader security controls - no trust in AWS required
- You have to run a key management infrastructure, and encrypt data yourself
  before sending it to S3
```
