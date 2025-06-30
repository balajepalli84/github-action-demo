import os
import oci
import base64
import time

print("Starting test with TokenExchangeSigner...")

# Read the GitHub OIDC JWT token from file
jwt_path = ".oci/id-token.jwt"
if not os.path.exists(jwt_path):
    print(f"JWT token file not found at {jwt_path}")
    exit(1)

OCI_JWT = open(jwt_path).read().strip()

# Read other environment variables
OCI_DOMAIN_ID = os.environ["OCI_DOMAIN_ID"]
OCI_CLIENT_ID = os.environ["OCI_CLIENT_ID"]
OCI_CLIENT_SECRET = os.environ["OCI_CLIENT_SECRET"]
region = os.environ.get("OCI_REGION", "us-ashburn-1")
secret_id = os.environ["OCI_SECRET_ID"]

# Create signer using token exchange
signer = oci.auth.signers.TokenExchangeSigner(
    OCI_JWT,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)

# Create client for Secrets service
secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

print("Calling OCI Secrets API to fetch secret bundle...")

# Call the Secrets API
try:
    response = secrets_client.get_secret_bundle(secret_id)
    base64_content = response.data.secret_bundle_content.content
    decoded_content = base64.b64decode(base64_content).decode("utf-8")
    
    print("\n Secret fetched successfully:")
    print(f"Base64-Encoded: {base64_content}")
    print(f"Decoded Value : {decoded_content}\n")

except Exception as e:
    print(f"\n Failed to fetch secret: {e}")
    exit(2)
