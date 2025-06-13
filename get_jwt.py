import os
import requests

# Get environment variables provided by GitHub Actions runner
oidc_url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL")
oidc_token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN")

if not oidc_url or not oidc_token:
    raise EnvironmentError("OIDC environment variables not set.")

# Optionally, append audience if needed:
# oidc_url += "&audience=YOUR_AUDIENCE"

headers = {
    "Authorization": f"Bearer {oidc_token}",
    "Accept": "application/json; api-version=2.0"
}

response = requests.get(oidc_url, headers=headers)
response.raise_for_status()

jwt = response.json().get("value")
print("OIDC JWT:", jwt)
