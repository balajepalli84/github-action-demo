import os
import oci
import base64
import time
import sys
import traceback

def getJWT():
    TOKEN = open(".oci/id-token.jwt").read().strip()
    return TOKEN

try:
    OCI_JWT = getJWT()
    print(f"UPST (JWT) token: {OCI_JWT}")

    OCI_DOMAIN_ID = os.getenv("OCI_DOMAIN_ID")
    OCI_CLIENT_ID = os.getenv("OCI_CLIENT_ID")
    OCI_CLIENT_SECRET = os.getenv("OCI_CLIENT_SECRET")
    region = os.getenv("OCI_REGION")
    secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"

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
            print("Sleeping for 45 minutes...")
            time.sleep(3700)
except Exception as e:
    print("An error occurred:")
    traceback.print_exc()
