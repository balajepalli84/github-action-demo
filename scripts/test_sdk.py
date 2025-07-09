import os
import oci
import base64
import time
import requests

# -----------------------------------------------------------------------------
# GitHub Actions: Passing Values as Environment Variables
# -----------------------------------------------------------------------------
# In your GitHub Actions workflow YAML, you can pass secrets or other values to
# your script using environment variables. Example:
#
# jobs:
#   my-job:
#     runs-on: ubuntu-latest
#     env:
#       OCI_DOMAIN_ID: ${{ secrets.OCI_DOMAIN_ID }}
#       OCI_CLIENT_ID: ${{ secrets.OCI_CLIENT_ID }}
#       OCI_CLIENT_SECRET: ${{ secrets.OCI_CLIENT_SECRET }}
#     steps:
#       - name: Run script
#         run: python my_script.py
#
# In your Python code, you can then access these values using os.environ.get().
# -----------------------------------------------------------------------------

OCI_DOMAIN_ID = os.environ.get("OCI_DOMAIN_ID")
OCI_CLIENT_ID = os.environ.get("OCI_CLIENT_ID")
OCI_CLIENT_SECRET = os.environ.get("OCI_CLIENT_SECRET")

# Validate that all required environment variables are set
if not OCI_DOMAIN_ID or not OCI_CLIENT_ID or not OCI_CLIENT_SECRET:
    raise ValueError("Missing required OCI environment variables.")

def get_jwt():
    """
    Obtain a JWT token from the environment for OIDC authentication.
    """
    token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN") # Bearer token for GitHub OIDC
    url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL") # Github OIDC endpoint URL
    audience = "github-actions" # Audience for the token, typically "github-actions"
    if not token or not url or not audience:
        raise ValueError("Missing required environment variables for JWT retrieval.")

    # Construct the full URL safely to avoid issues with special characters    
    params = {"audience": audience}
    headers = {"Authorization": f"Bearer {token}"}

    # Make the request to retrieve the JWT
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    jwt = response.json().get("value")
    if not jwt:
        raise ValueError("JWT token not found in the response")
    return jwt

#example to retrieve secret from OCI Vault using the TokenExchangeSigner
# Set the OCI region and secret OCID (update these as needed for your use case)
region = "us-ashburn-1"
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

# -----------------------------------------------------------------------------
# TokenExchangeSigner: Accepts Function or String
# -----------------------------------------------------------------------------
# The TokenExchangeSigner can be initialized in two ways:
# 1. By passing a function (such as get_jwt) that returns a JWT token.
#    This is useful if you want the signer to fetch or refresh the token dynamically.
#
#    signer = oci.auth.signers.TokenExchangeSigner(get_jwt, OCI_DOMAIN_ID, OCI_CLIENT_ID, OCI_CLIENT_SECRET)
#
# 2. By passing a string containing a JWT token directly.
#    This is useful if you already have a static token.
#
#    jwt_token = get_jwt()
#    signer = oci.auth.signers.TokenExchangeSigner(jwt_token, OCI_DOMAIN_ID, OCI_CLIENT_ID, OCI_CLIENT_SECRET)
# -----------------------------------------------------------------------------

# Here, we pass the function so the signer can refresh the token as needed
signer = oci.auth.signers.TokenExchangeSigner(
    get_jwt,        # Function to get JWT token
    OCI_DOMAIN_ID,  # OCI domain ID from environment
    OCI_CLIENT_ID,  # OCI client ID from environment
    OCI_CLIENT_SECRET, 
    log_requests=True 
)

# Initialize the OCI SecretsClient with the signer and region
secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

# UPST token is valid for 60 minutes, so we will read the secret multiple times to demonstrate token refresh
# Read the secret 10 times, sleeping 61 minutes between each read to demonstrate token refresh
for i in range(10):
    try:
        response = secrets_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        print(f"secret value : {base64_content}",flush=True)  # Print the base64 encoded secret content
        # Use the secret content as needed in your application here
        # For example, decode with: decoded_content = base64.b64decode(base64_content).decode()
    except Exception as e:
        # Handle exceptions as needed (e.g., logging, error handling)
        pass
    if i < 9:
        # Sleep for 61 minutes before the next iteration to test token refresh
        time.sleep(3700)  # 61 minutes
