import os
import oci
import base64

print("Starting test with TokenExchangeSigner...")

# Read JWT token
jwt_path = "oidc_token.txt"
if not os.path.exists(jwt_path):
    print(f"JWT token file not found: {jwt_path}")
    exit(1)

OCI_JWT = open(jwt_path).read().strip()
OCI_DOMAIN_ID = os.environ["OCI_DOMAIN_ID"]
OCI_CLIENT_ID = os.environ["OCI_CLIENT_ID"]
OCI_CLIENT_SECRET = os.environ["OCI_CLIENT_SECRET"]
region = os.environ.get("OCI_REGION", "us-ashburn-1")
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

# Debug output
print(" Input Parameters:")
print(f"  OCI_DOMAIN_ID  = {OCI_DOMAIN_ID}")
print(f"  OCI_CLIENT_ID  = {OCI_CLIENT_ID}")
print(f"  Region         = {region}")
print(f"  Secret OCID    = {secret_id}")

# Token exchange signer
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

    print("\n Secret fetched successfully:")
    print(f" Base64-Encoded: {base64_content}")
    print(f" Decoded Value : {decoded_content}\n")

except Exception as e:
    print(f"\n Error fetching secret: {e}")
    exit(2)
