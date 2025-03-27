import os
import subprocess
import base64
import json
import requests
from pathlib import Path

# Load env vars from GitHub Actions
CLIENT_ID = os.environ["CLIENT_ID"]
CLIENT_SECRET = os.environ["CLIENT_SECRET"]
DOMAIN_BASE_URL = os.environ["DOMAIN_BASE_URL"]
OCI_REGION = os.environ["OCI_REGION"]
OCI_TENANCY = os.environ["OCI_TENANCY"]
ID_TOKEN = os.environ["ACTIONS_ID_TOKEN_REQUEST_TOKEN"]
ID_TOKEN_URL = os.environ["ACTIONS_ID_TOKEN_REQUEST_URL"]

oci_dir = Path.home() / ".oci"
oci_dir.mkdir(parents=True, exist_ok=True)

# Step 1: Generate private key
private_key = oci_dir / "temp_private.pem"
public_key = oci_dir / "temp_public.pem"

subprocess.run(["openssl", "genrsa", "-out", str(private_key), "2048"], check=True)
subprocess.run(["openssl", "rsa", "-in", str(private_key), "-pubout", "-out", str(public_key)], check=True)

# Step 2: Convert public key to single-line without headers
def strip_pem_headers(pem_path):
    with open(pem_path, "r") as f:
        lines = f.readlines()
    return "".join(line.strip() for line in lines if "BEGIN" not in line and "END" not in line)

pubkey_clean = strip_pem_headers(public_key)

# Step 3: Get GitHub OIDC Token
resp = requests.get(f"{ID_TOKEN_URL}&audience={CLIENT_ID}", headers={
    "Authorization": f"Bearer {ID_TOKEN}"
})
oidc_token = resp.json()["value"]

# Step 4: Exchange for UPST token
auth_header = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()
token_url = f"{DOMAIN_BASE_URL}/oauth2/v1/token"
payload = {
    "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
    "requested_token_type": "urn:oci:token-type:oci-upst",
    "subject_token": oidc_token,
    "subject_token_type": "jwt",
    "public_key": pubkey_clean
}
#test
headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    "Authorization": f"Basic {auth_header}"
}

res = requests.post(token_url, data=payload, headers=headers)
res.raise_for_status()
upst_token = res.json()["token"]

# Step 5: Save UPST token to file
with open(oci_dir / "upst.token", "w") as f:
    f.write(upst_token.strip())

# Step 6: Generate fingerprint
fingerprint = subprocess.check_output([
    "openssl", "rsa", "-pubout", "-outform", "DER", "-in", str(private_key)
], stderr=subprocess.DEVNULL)
fingerprint = subprocess.check_output(["openssl", "md5", "-c"], input=fingerprint).decode().split()[-1]

# Step 7: Write config
with open(oci_dir / "config", "w") as f:
    f.write("[upst]\n")
    f.write(f"region={OCI_REGION}\n")
    f.write(f"tenancy={OCI_TENANCY}\n")
    f.write(f"fingerprint={fingerprint}\n")
    f.write(f"key_file={private_key}\n")
    f.write(f"security_token_file={oci_dir}/upst.token\n")

print("✅ UPST config generated.")
