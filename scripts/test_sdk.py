import os
import sys
import oci
import base64
import json

# Force stdout to flush in CI logs
sys.stdout.reconfigure(line_buffering=True)

print("Starting test with TokenExchangeSigner...")

# Read JWT token from file
jwt_path = ".oci/id-token.jwt"
if not os.path.exists(jwt_path):
    print(f"JWT token file not found: {jwt_path}")
    exit(1)

with open(jwt_path, "r") as f:
    OCI_JWT = f.read().strip()

print(f"OCI_JWT Token length: {len(OCI_JWT)}")
print(f"OCI_JWT Token starts with: {OCI_JWT[:20]}")
print(f"OCI_JWT Token ends with  : {OCI_JWT[-20:]}")

# Decode JWT for inspection
def decode_jwt(token):
    parts = token.split('.')
    if len(parts) != 3:
        print("Invalid JWT format")
        return

    def decode_part(part):
        padding = '=' * (4 - len(part) % 4)
        return base64.urlsafe_b64decode(part + padding).decode("utf-8")

    header = decode_part(parts[0])
    payload = decode_part(parts[1])

    print("\nDecoded JWT Header:")
    print(json.dumps(json.loads(header), indent=2))

    print("\nDecoded JWT Payload:")
    print(json.dumps(json.loads(payload), indent=2))

decode_jwt(OCI_JWT)

# Environment variables
OCI_DOMAIN_ID = os.environ["OCI_DOMAIN_ID"]
OCI_CLIENT_ID = os.environ["OCI_CLIENT_ID"]
OCI_CLIENT_SECRET = os.environ["OCI_CLIENT_SECRET"]
region = os.environ.get("OCI_REGION", "us-ashburn-1")

# For test: replace with your actual OCID
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

# Debug output
print("\nInput Parameters:")
print(f"  OCI_DOMAIN_ID  = {OCI_DOMAIN_ID}")
print(f"  OCI_CLIENT_ID  = {OCI_CLIENT_ID}")
print(f"  Region         = {region}")
print(f"  Secret OCID    = {secret_id}")

# Create token exchange signer
signer = oci.auth.signers.TokenExchangeSigner(
    OCI_JWT,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)

# Call Secrets API
try:
    secrets_client = oci.secrets.SecretsClient(
        config={"region": region},
        signer=signer
    )
    response = secrets_client.get_secret_bundle(secret_id)
    base64_content = response.data.secret_bundle_content.content
    decoded_content = base64.b64decode(base64_content).decode("utf-8")

    print("\nSecret fetched successfully:")
    print(f"  Base64-Encoded: {base64_content}")
    print(f"  Decoded Value : {decoded_content}")

except Exception as e:
    print(f"\nError fetching secret: {e}")
    exit(2)
