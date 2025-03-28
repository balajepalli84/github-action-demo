#!/bin/bash
set -euo pipefail

# Required environment variables
CLIENT_ID="${CLIENT_ID:-}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
DOMAIN_BASE_URL="${DOMAIN_BASE_URL:-}"

# Input paths
JWT_FILE="${JWT_FILE:-.oci/id-token.json}"
PUBLIC_KEY_PATH="${PUBLIC_KEY_PATH:-.oci/temp_public.pem}"
UPST_OUTPUT_PATH="${UPST_OUTPUT_PATH:-.oci/upst.token}"

# Validate required files
if [ ! -f "$JWT_FILE" ]; then
  echo "Missing JWT file at $JWT_FILE"
  exit 1
fi

if [ ! -f "$PUBLIC_KEY_PATH" ]; then
  echo "Missing public key file at $PUBLIC_KEY_PATH"
  exit 1
fi

refresh_token() {
  echo "Refreshing UPST token at $(date)"

  JWT=$(jq -r '.value' "$JWT_FILE")
  if [ -z "$JWT" ]; then
    echo "Failed to extract JWT from $JWT_FILE"
    return 1
  fi

  PUBKEY=$(awk '/BEGIN PUBLIC KEY/ {skip=1; next} /END PUBLIC KEY/ {skip=0; next} skip {printf "%s", $0;}' "$PUBLIC_KEY_PATH")

  AUTH_HEADER=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

  RESPONSE=$(curl -sSL \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "Authorization: Basic $AUTH_HEADER" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
    --data-urlencode "requested_token_type=urn:oci:token-type:oci-upst" \
    --data-urlencode "subject_token=$JWT" \
    --data-urlencode "subject_token_type=jwt" \
    --data-urlencode "public_key=$PUBKEY" \
    "${DOMAIN_BASE_URL}/oauth2/v1/token")

  echo "$RESPONSE" | jq -r '.token' > "$UPST_OUTPUT_PATH"

  if [ -s "$UPST_OUTPUT_PATH" ]; then
    echo "UPST token refreshed successfully"
    return 0
  else
    echo "Failed to refresh UPST token"
    return 1
  fi
}

# Loop every 45 minutes
while true; do
  refresh_token
  sleep 2700  # 45 minutes
done
