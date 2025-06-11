---
id: potential-secrets-test
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'manual review'
version: '0.1.0'
# Fields that look like they might contain secrets
api_key: 'sk-1234567890abcdef'
password: 'super-secret-password'
token: 'ghp_xxxxxxxxxxxxxxxxxxxx'
secret: 'my-secret-value'
auth_token: 'bearer-token-value'
---

# Potential Secrets Test

This file contains fields with names that suggest they might contain secrets:
- api_key
- password
- token
- secret
- auth_token

These should be flagged by security validation.
