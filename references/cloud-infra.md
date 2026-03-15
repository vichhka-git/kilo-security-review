# Cloud & Infrastructure Security Reference

## Container Security

### Dockerfile Hardening
```dockerfile
# FLAG — running as root
FROM ubuntu:20.04
CMD ["node", "server.js"]  # runs as root by default

# SAFE — non-root user, minimal base, pinned version
FROM node:20.11-alpine3.19
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    addgroup -S appgroup && adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /app
USER appuser
COPY --chown=appuser:appgroup . .
CMD ["node", "server.js"]
```

```dockerfile
# FLAG — secrets baked into image layers
RUN aws configure set aws_access_key_id AKIA...
ENV DATABASE_PASSWORD=secret123
COPY .env .  # .env persists in all layers even if later deleted

# SAFE — pass secrets at runtime
# docker run -e DATABASE_URL="..." myimage
# OR use Docker secrets / mounted secret files
```

### Container Scanning
```bash
# Scan image for CVEs
trivy image myapp:latest

# Scan for misconfigurations in Dockerfile
trivy config Dockerfile

# Scan running container for secrets
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  trufflesecurity/trufflehog docker --image myapp:latest
```

## Kubernetes

### Common Misconfigurations
```yaml
# FLAG — privileged pod
spec:
  containers:
    - securityContext:
        privileged: true   # full host access

# FLAG — secret in env var from literal (not Secret object)
env:
  - name: DB_PASSWORD
    value: "hardcoded_password"

# FLAG — no resource limits (DoS possible)
resources: {}

# SAFE
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
      resources:
        requests: { cpu: "100m", memory: "128Mi" }
        limits:   { cpu: "500m", memory: "512Mi" }
```

```bash
# Scan k8s manifests
checkov -d k8s/
trivy config k8s/
kubesec scan deployment.yaml
```

## AWS IAM — Principle of Least Privilege

```json
// FLAG — wildcard permissions (overly permissive)
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}

// FLAG — wildcard on sensitive actions
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "arn:aws:s3:::*"
}

// SAFE — scoped to what's needed
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::my-specific-bucket/*"
}
```

### EC2 Instance Metadata Service (IMDS)
```bash
# Check if IMDSv2 is enforced (prevents SSRF → metadata exfil)
aws ec2 describe-instances --query \
  "Reservations[].Instances[].MetadataOptions.HttpTokens"
# Should return "required" (IMDSv2) not "optional" (IMDSv1 vulnerable)

# Exploit IMDSv1 via SSRF
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

## S3 Bucket Misconfiguration

```bash
# Check for public buckets
aws s3api get-bucket-acl --bucket BUCKET_NAME
aws s3api get-bucket-policy --bucket BUCKET_NAME

# List objects (if ACL is public)
aws s3 ls s3://BUCKET_NAME --no-sign-request

# Common flags:
# - ACL: "public-read" or "public-read-write"
# - Policy: "Principal": "*" with s3:GetObject
# - No server-side encryption
# - No versioning (ransomware risk)
# - No access logging
```

## CI/CD Security

```yaml
# FLAG — secrets in workflow env vars visible in logs
- name: Deploy
  env:
    AWS_SECRET: ${{ secrets.AWS_SECRET }}  # OK if from GitHub Secrets
    HARDCODED: "sk_live_abc123"           # FLAG — plaintext in YAML

# FLAG — overly permissive workflow token
permissions: write-all

# SAFE — minimal permissions
permissions:
  contents: read
  id-token: write  # for OIDC auth only if needed

# FLAG — unpinned action (supply chain risk)
- uses: actions/checkout@main  # uses moving ref

# SAFE — pinned by SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

```bash
# Scan GitHub Actions for secrets
trufflehog github --repo https://github.com/org/repo --only-verified

# Scan workflow files for misconfigs
actionlint .github/workflows/*.yml
```

## Terraform Security Scan

```bash
# Check for misconfigs across all providers
checkov -d . --framework terraform

# AWS-specific
tfsec .

# Snyk IaC
snyk iac test .
```

Common Terraform findings:
- S3 bucket without `server_side_encryption_configuration`
- Security group with `cidr_blocks = ["0.0.0.0/0"]` on sensitive ports
- RDS without `storage_encrypted = true`
- CloudTrail disabled or not multi-region
- IAM policies with wildcard actions
- `.tfstate` not stored in encrypted backend (local state = plaintext on disk)

## NGINX / Apache Misconfiguration

```nginx
# FLAG — server version exposed
server_tokens on;  # leaks nginx version in headers

# FLAG — directory listing enabled
autoindex on;

# FLAG — missing security headers
# (no add_header directives)

# SAFE
server_tokens off;
add_header X-Frame-Options "DENY";
add_header X-Content-Type-Options "nosniff";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self';";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```
