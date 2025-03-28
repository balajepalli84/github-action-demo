#!/bin/bash
set -euo pipefail

# Required environment variables
CLIENT_ID="${CLIENT_ID:-}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
DOMAIN_BASE_URL="${DOMAIN_BASE_URL:-}"
OCI_TENANCY="${OCI_TENANCY:-}"
OCI_REGION="${OCI_REGION:-}"
ACTIONS_ID_TOKEN_REQUEST_TOKEN="${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}"
ACTIONS_ID_TOKEN_REQUEST_URL="${ACTIONS_ID_TOKEN_REQUEST_URL:-}"
AUDIENCE="${AUDIENCE:-$CLIENT_ID}"

# Validate required parameters
for var in CLIENT_ID CLIENT_SECRET DOMAIN_BASE_URL OCI_TENANCY OCI_REGION ACTIONS_ID_TOKEN_REQUEST_TOKEN ACTIONS_ID_TOKEN_REQUEST_URL; do
  if [ -z "${!var}" ]; then
    echo "Missing required environment variable: $var"
    exit 1
  fi
done

mkdir -p .oci $HOME/.oci

echo "Generating RSA key pair..."
openssl genrsa -out .oci/temp_private.pem 2048
openssl rsa -in .oci/temp_private.pem -pubout -out .oci/temp_public.pem
chmod 600 .oci/temp_private.pem .oci/temp_public.pem

echo "Fetching GitHub OIDC token..."
curl -sSL -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=${AUDIENCE}" > .oci/id-token.json

JWT=$(jq -r '.value' .oci/id-token.json)

if [ -z "$JWT" ]; then
  echo "Failed to retrieve GitHub OIDC token"
  exit 1
fi

echo "Exchanging OIDC token for OCI UPST token..."
AUTH_HEADER=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')
PUBKEY=$(awk '/BEGIN PUBLIC KEY/ {skip=1; next} /END PUBLIC KEY/ {skip=0; next} skip {printf "%s", $0;}' .oci/temp_public.pem)

RESPONSE=$(curl -sSL \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "Authorization: Basic $AUTH_HEADER" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "requested_token_type=urn:oci:token-type:oci-upst" \
  --data-urlencode "subject_token=$JWT" \
  --data-urlencode "subject_token_type=jwt" \
  --data-urlencode "public_key=$PUBKEY" \
  "${DOMAIN_BASE_URL}/oauth2/v1/token")

TOKEN=$(echo "$RESPONSE" | jq -r '.token' | tr -d '\n\r')


if [ ! -s .oci/upst.token ]; then
  echo "Failed to extract UPST token"
  exit 1
fi

echo "Configuring OCI CLI..."
cp .oci/temp_private.pem $HOME/.oci/temp_private.pem
cp .oci/upst.token $HOME/.oci/upst.token
chmod 600 $HOME/.oci/temp_private.pem $HOME/.oci/upst.token

FINGERPRINT=$(openssl rsa -pubout -outform DER -in $HOME/.oci/temp_private.pem 2>/dev/null | openssl md5 -c | awk '{print $2}')

cat <<EOF > $HOME/.oci/config
[upst]
region=${OCI_REGION}
tenancy=${OCI_TENANCY}
fingerprint=${FINGERPRINT}
key_file=$HOME/.oci/temp_private.pem
security_token_file=$HOME/.oci/upst.token
EOF

echo "UPST token setup complete. You can now run: terraform apply -auto-approve"
