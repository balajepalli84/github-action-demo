import os
import oci
import base64
import time
import sys, requests


'''
OCI_JWT
This is the JWT token from Github OIDC. Either rdirectly pass the value or use the getJWT() function to read from Github
The same will is true for any OIDC identity provider.

def get_jwt():
    return open(r"C:\Users\Ramesh\.oci\jwt_token.txt").read().strip()
'''
'''
These values are from the OCI Identity Domain created for the OIDC identity provider
Ideally, they should be stored in a secure location like Github secrets
'''
OCI_DOMAIN_ID = "idcs-8dd307747946491cbfe1b7a3f063db0d"
OCI_CLIENT_ID = "8aa264f421d646e98699b716b2e9b72e"
OCI_CLIENT_SECRET = "idcscs-59183ab6-657c-4a24-ad24-ffae6c8bc061"

def get_jwt():
    # Fetch required environment variables
    token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN")
    url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL")
    audience = "github-actions"

    if not token or not url or not audience:
        raise ValueError(
            "Missing environment variables: "
            "ACTIONS_ID_TOKEN_REQUEST_TOKEN, ACTIONS_ID_TOKEN_REQUEST_URL"
        )

    # Construct the full URL with the audience parameter
    full_url = f"{url}&audience={audience}"

    # Make the HTTP GET request with Authorization header
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(full_url, headers=headers)
    response.raise_for_status()  # Raises an error for non-200 responses

    # Extract the JWT from the JSON response
    jwt = response.json().get("value")
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
        print(f"Iteration {i+1}: Secret content (base64): {base64_content}")
    except Exception as e:
        print(f"Iteration {i+1} failed: {str(e)}")
    if i < 9:
        print("Sleeping for 61 minutes...")
        time.sleep(3700)  # 61 minutes

