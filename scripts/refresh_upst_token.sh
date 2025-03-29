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
UPST_LATEST="$HOME/.oci/upst.token"
TOKEN_DIR="$GITHUB_WORKSPACE/.oci/tokens"
LOG_FILE="$GITHUB_WORKSPACE/upst_refresh.log"

mkdir -p .oci "$TOKEN_DIR"

# Validate public key presence
if [ ! -f "$PUBLIC_KEY_PATH" ]; then
  echo "Missing public key: $PUBLIC_KEY_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Starting UPST token refresher loop..." | tee -a "$LOG_FILE"

while true; do
  echo "Refreshing UPST at $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >> "$LOG_FILE"

  # Load GitHub OIDC JWT
  JWT=$(jq -r '.value // empty' "$JWT_FILE")
  if [ -z "$JWT" ]; then
    echo "❌ Failed to extract JWT from $JWT_FILE" >> "$LOG_FILE"
    sleep 60
    continue
  fi

  # Extract public key and auth header
  PUBKEY=$(awk '/BEGIN PUBLIC KEY/ {skip=1; next} /END PUBLIC KEY/ {skip=0; next} skip {printf "%s", $0;}' "$PUBLIC_KEY_PATH")
  AUTH_HEADER=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

  echo "🔍 Token exchange request to ${DOMAIN_BASE_URL}/oauth2/v1/token" >> "$LOG_FILE"

  RESPONSE=$(curl -sSL \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "Authorization: Basic $AUTH_HEADER" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
    --data-urlencode "requested_token_type=urn:oci:token-type:oci-upst" \
    --data-urlencode "subject_token=$JWT" \
    --data-urlencode "subject_token_type=jwt" \
    --data-urlencode "public_key=$PUBKEY" \
    "${DOMAIN_BASE_URL}/oauth2/v1/token")

  TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty' | tr -d '\n\r')
  if [ -z "$TOKEN" ]; then
    echo "❌ Failed to extract UPST token" >> "$LOG_FILE"
    sleep 60
    continue
  fi

  echo -n "$TOKEN" > "$UPST_LATEST"
  chmod 600 "$UPST_LATEST"

  # Save snapshot
  SNAP_FILE="$TOKEN_DIR/upst_$(date -u +'%Y%m%dT%H%M%SZ').token"
  echo -n "$TOKEN" > "$SNAP_FILE"
  # Save snapshot in timestamped file
  TOKEN_TIMESTAMP=$(date -u +'%Y%m%dT%H%M%SZ')
  SNAP_PATH="$GITHUB_WORKSPACE/.oci/tokens/upst_$TOKEN_TIMESTAMP.token"
  echo -n "$TOKEN" > "$SNAP_PATH"
  chmod 600 "$SNAP_PATH"
  echo "📝 Saved UPST token to: $SNAP_PATH" >> "$LOG_FILE"

  # Decode token payload for exp/sess_exp
  PAYLOAD_ENC=$(echo "$TOKEN" | cut -d '.' -f2)
  PAYLOAD_ENC=$(echo "$PAYLOAD_ENC" | tr '_-' '/+')
  PADDING=$((4 - ${#PAYLOAD_ENC} % 4))
  if [ $PADDING -ne 4 ]; then
    PAYLOAD_ENC="${PAYLOAD_ENC}$(printf '=%.0s' $(seq 1 $PADDING))"
  fi

  PAYLOAD=$(echo "$PAYLOAD_ENC" | base64 -d 2>/dev/null || echo "")
  EXP=$(echo "$PAYLOAD" | jq -r '.exp // empty')
  SESS_EXP=$(echo "$PAYLOAD" | jq -r '.sess_exp // empty')

  if [[ "$EXP" =~ ^[0-9]+$ ]]; then
    EXP_HUMAN=$(date -u -d "@$EXP" +'%Y-%m-%d %H:%M:%S UTC')
    echo "✅ Token exp:      $EXP_HUMAN" >> "$LOG_FILE"
  fi

  if [[ "$SESS_EXP" =~ ^[0-9]+$ ]]; then
    SESS_HUMAN=$(date -u -d "@$SESS_EXP" +'%Y-%m-%d %H:%M:%S UTC')
    echo "✅ Token sess_exp: $SESS_HUMAN" >> "$LOG_FILE"
  else
    echo "⚠️  sess_exp not found in token." >> "$LOG_FILE"
  fi

  sleep 240
done
