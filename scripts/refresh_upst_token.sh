#!/bin/bash
set -euo pipefail

# Required environment variables
CLIENT_ID="${CLIENT_ID:-}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
DOMAIN_BASE_URL="${DOMAIN_BASE_URL:-}"
ACTIONS_ID_TOKEN_REQUEST_TOKEN="${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}"
ACTIONS_ID_TOKEN_REQUEST_URL="${ACTIONS_ID_TOKEN_REQUEST_URL:-}"
AUDIENCE="${AUDIENCE:-$CLIENT_ID}"

# File paths
JWT_FILE=".oci/id-token.json"
PUBLIC_KEY_PATH=".oci/temp_public.pem"
UPST_OUTPUT_PATH="$HOME/.oci/upst.token"
LOG_FILE=".oci/token-refresh.log"

mkdir -p .oci

# Validate required files
if [ ! -f "$PUBLIC_KEY_PATH" ]; then
  echo "Missing public key file: $PUBLIC_KEY_PATH"
  exit 1
fi

echo "Starting UPST token refresher every 10 seconds..."

while true; do
  echo "Refreshing UPST at $(date)" >> "$LOG_FILE"

  # Step 1: Get a fresh GitHub OIDC token
  curl -sSL -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
    "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=${AUDIENCE}" > "$JWT_FILE"

  JWT=$(jq -r '.value' "$JWT_FILE")
  if [ -z "$JWT" ]; then
    echo "Failed to extract JWT from $JWT_FILE"
    sleep 10
    continue
  fi

  # Step 2: Prepare public key (strip headers)
  PUBKEY=$(awk '/BEGIN PUBLIC KEY/ {skip=1; next} /END PUBLIC KEY/ {skip=0; next} skip {printf "%s", $0;}' "$PUBLIC_KEY_PATH")
  AUTH_HEADER=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

  # Step 3: Exchange for UPST token
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

  if [[ -z "$TOKEN" ]]; then
    echo "Failed to extract UPST token" >> "$LOG_FILE"
  else
    echo -n "$TOKEN" > "$UPST_OUTPUT_PATH"
    chmod 600 "$UPST_OUTPUT_PATH"

    TOKEN_HEAD=$(echo "$TOKEN" | cut -c1-10)
    EXP=$(echo "$TOKEN" | jq -R 'split(".")[1] | @base64d | fromjson | .exp')
    EXP_HUMAN=$(date -d "@$EXP")

    echo "Token refreshed: head=$TOKEN_HEAD, exp=$EXP_HUMAN" >> "$LOG_FILE"
  fi

  sleep 5  # Refresh interval (short for testing)
done
