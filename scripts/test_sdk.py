import os
import sys
import oci
import base64
import json

print("Starting test with TokenExchangeSigner...")

# Read JWT token from file
jwt_path = ".oci/id-token.jwt"
with open(jwt_path, "r") as f:
    OCI_JWT = f.read().strip()

# Environment variables
OCI_DOMAIN_ID = os.environ["OCI_DOMAIN_ID"]
OCI_CLIENT_ID = os.environ["OCI_CLIENT_ID"]
OCI_CLIENT_SECRET = os.environ["OCI_CLIENT_SECRET"]
region = os.environ.get("OCI_REGION", "us-ashburn-1")

# For test: replace with your actual OCID
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

# Create token exchange signer
signer = oci.auth.signers.TokenExchangeSigner(
    OCI_JWT,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)
for i in range(10):
    try:
        response = secrets_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        print(f"Iteration {i+1}: Secret content (base64): {base64_content}")
        decoded_content = base64.b64decode(base64_content).decode("utf-8")
        print("\nSecret fetched successfully:")
        print(f"  Base64-Encoded: {base64_content}")
        print(f"  Decoded Value : {decoded_content}")
        
    except Exception as e:
        print(f"Iteration {i+1} failed: {str(e)}")
    if i < 9:
        print("Sleeping for 61 minutes...")
        time.sleep(3700)  # 61 minutes
