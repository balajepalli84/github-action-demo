import os
import oci
import base64
import time

OCI_JWT = os.environ["OCI_JWT"]
OCI_DOMAIN_ID = os.environ["OCI_DOMAIN_ID"]
OCI_CLIENT_ID = os.environ["OCI_CLIENT_ID"]
OCI_CLIENT_SECRET = os.environ["OCI_CLIENT_SECRET"]
region = os.environ.get("OCI_REGION", "us-ashburn-1")
secret_id = os.environ["OCI_SECRET_ID"]

signer = oci.auth.signers.TokenExchangeSigner(
    OCI_JWT,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)

secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

for i in range(10):
    try:
        response = secrets_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        print(f"Iteration {i+1}: Secret content (base64): {base64_content}")
    except Exception as e:
        print(f"Iteration {i+1} failed: {str(e)}")
    if i < 9:
        print("Sleeping for 61 minutes...")
        time.sleep(3700)
