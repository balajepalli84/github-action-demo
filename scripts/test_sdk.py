import os
import oci
import base64
import time
import sys
import requests
import datetime

# OCI IAM details for token exchange
OCI_DOMAIN_ID = "idcs-8dd307747946491cbfe1b7a3f063db0d"
OCI_CLIENT_ID = "8aa264f421d646e98699b716b2e9b72e"
OCI_CLIENT_SECRET = "idcscs-59183ab6-657c-4a24-ad24-ffae6c8bc061"

# Function to fetch GitHub OIDC JWT
def get_jwt():
    token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN")
    url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL")
    audience = os.environ.get("CLIENT_ID", "github-actions")

    if not token or not url or not audience:
        raise ValueError("Missing required environment variables.")

    full_url = f"{url}&audience={audience}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(full_url, headers=headers)
    response.raise_for_status()
    jwt = response.json().get("value")

    print(f"[{datetime.datetime.now()}] DEBUG: Generated OIDC JWT: {jwt}", flush=True)

    if not jwt:
        raise ValueError("JWT token not found in the response")
    return jwt

# Function to sleep with periodic heartbeat logs
def sleep_with_heartbeat(total_minutes=61, heartbeat_minutes=5):
    print(f"[{datetime.datetime.now()}] Sleep start: {total_minutes} minutes", flush=True)
    for minute in range(1, total_minutes + 1):
        try:
            time.sleep(60)
        except Exception as e:
            print(f"[{datetime.datetime.now()}] Sleep interrupted at minute {minute}: {str(e)}", flush=True)
            break
        if minute % heartbeat_minutes == 0:
            print(f"[{datetime.datetime.now()}] Heartbeat: Slept {minute} minutes...", flush=True)
    print(f"[{datetime.datetime.now()}] Sleep finished.", flush=True)

# OCI region and Vault Secret OCID
region = "us-ashburn-1"
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

# Token Exchange signer setup
signer = oci.auth.signers.TokenExchangeSigner(
    get_jwt,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)

# Initialize OCI secrets client
secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

# Loop 10 times, read the secret, and sleep 61 minutes between
for i in range(10):
    print(f"[{datetime.datetime.now()}] ===== Iteration {i+1} =====", flush=True)
    try:
        response = secrets_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        print(f"[{datetime.datetime.now()}] Secret content (base64): {base64_content}", flush=True)
    except Exception as e:
        print(f"[{datetime.datetime.now()}] Iteration {i+1} failed: {str(e)}", flush=True)

    if i < 9:
        print(f"[{datetime.datetime.now()}] Sleeping for 61 minutes with heartbeat logs every 5 minutes...", flush=True)
        sleep_with_heartbeat()
