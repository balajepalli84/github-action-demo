import os
import sys
import oci
import base64
import time
import requests

# -----------------------------------------------------------------------------
# Script usage:
#   python workload_identity_federation_signer_example.py <region> <resource_ocid> <oci_domain_id> <oci_client_id> <oci_client_secret>
#
# Example:
#   python workload_identity_federation_signer_example.py us-ashburn-1 ocid1.vaultsecret.oc1.iad.xxxxx domain_id client_id client_secret
#
# Notes:
# - The second argument (<resource_ocid>) is shown as a secret OCID in the example,
#   but it can be any client resource OCID (Vault secret, Object Storage, etc.)
#   depending on your use case and the service client you initialize.
# -----------------------------------------------------------------------------

region = "us-ashburn-1"
resource_ocid = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"
oci_domain_id = os.environ.get("OCI_DOMAIN_ID")
oci_client_id = os.environ.get("OCI_CLIENT_ID")
oci_client_secret = os.environ.get("OCI_CLIENT_SECRET")

def get_jwt():
    """
    Workload Identity Federation:
    This function is used to exchange an OIDC token for an OCI short-lived token.
    """
    token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN")
    url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL")
    audience = "github-actions"

    if not token or not url or not audience:
        raise ValueError("Missing required environment variables for JWT retrieval.")

    params = {"audience": audience}
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()

    jwt = response.json().get("value")
    if not jwt:
        raise ValueError("JWT token not found in the response")

    return jwt


# -----------------------------------------------------------------------------
# TokenExchangeSigner
# -----------------------------------------------------------------------------
signer = oci.auth.signers.TokenExchangeSigner(
    get_jwt,       
    oci_domain_id,  
    oci_client_id,  
    oci_client_secret
)

# -----------------------------------------------------------------------------
# Example: Use the resource OCID with SecretsClient
# -----------------------------------------------------------------------------
secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

# -----------------------------------------------------------------------------
# Example: Read a secret multiple times to demonstrate token refresh
# -----------------------------------------------------------------------------
for i in range(10):
    try:
        response = secrets_client.get_secret_bundle(resource_ocid)
        base64_content = response.data.secret_bundle_content.content

        decoded_content = base64.b64decode(base64_content).decode("utf-8")
        print(f"Resource value (decoded): {decoded_content}", flush=True)

    except Exception as e:
        print(f"Error reading resource {resource_ocid}: {e}", flush=True)

    if i < 9:
        time.sleep(3700)  # 61 minutes
