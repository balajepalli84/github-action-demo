import os
import oci
import base64
import time
import sys
import requests

OCI_DOMAIN_ID = "idcs-8dd307747946491cbfe1b7a3f063db0d"
OCI_CLIENT_ID = "8aa264f421d646e98699b716b2e9b72e"
OCI_CLIENT_SECRET = "idcscs-59183ab6-657c-4a24-ad24-ffae6c8bc061"

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

    # Print the token for debugging
    print("DEBUG: Generated OIDC JWT:", jwt, flush=True)

    if not jwt:
        raise ValueError("JWT token not found in the response")
    return jwt



'''
These are the values for your custom code
in this example, we are reading a secret from OCI Vault in us-ashburn-1 region
change the code here as per your requirement
'''
region = "us-ashburn-1"
secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

'''
Here, i am passing the JWT value directly but you can use the getJWT() function to read from Github
same will is true for any OIDC identity provider.
'''


'''
Here we are using the TokenExchangeSigner from the custom signers code
'''
signer = oci.auth.signers.TokenExchangeSigner(
    get_jwt,
    OCI_DOMAIN_ID,
    OCI_CLIENT_ID,
    OCI_CLIENT_SECRET
)

secrets_client = oci.secrets.SecretsClient(
    config={"region": region},
    signer=signer
)

'''
Here we are reading the secret 10 times with a sleep of 45 minutes in between
This is to demonstrate the token refresh capability of the TokenExchangeSigner
'''

for i in range(10):
    try:
        response = secrets_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        print(f"Iteration {i+1}: Secret content (base64): {base64_content}", flush=True)
    except Exception as e:
        print(f"Iteration {i+1} failed: {str(e)}", flush=True)
    if i < 9:
        print("Sleeping for 61 minutes...", flush=True)
        time.sleep(3700)  # 61 minutes

