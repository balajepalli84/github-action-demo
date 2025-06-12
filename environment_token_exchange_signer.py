import os
import threading
import base64
import json
import logging
from datetime import datetime

from oci._vendor import requests
from oci.auth.session_key_supplier import SessionKeySupplier
from oci.auth.security_token_container import SecurityTokenContainer
from oci.auth.signers.security_token_signer import SecurityTokenSigner, SECURITY_TOKEN_FORMAT_STRING
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat, PrivateFormat, NoEncryption

# === Logging Setup ===
LOG_DIR = r"C:\Security\Blogs\TokenExchange"
LOG_FILE = os.path.join(LOG_DIR, "token_exchange.log")

# Ensure log directory exists
os.makedirs(LOG_DIR, exist_ok=True)

logger = logging.getLogger("token_exchange_logger")
logger.setLevel(logging.DEBUG)  # Set level before adding handlers

# Avoid duplicate handlers if re-imported
if not any(isinstance(h, logging.FileHandler) and h.baseFilename == LOG_FILE for h in logger.handlers):
    handler = logging.FileHandler(LOG_FILE, mode='a', encoding='utf-8')
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

class EnvironmentTokenExchangeSigner(SecurityTokenSigner):
    """
    OCI Python SDK signer for OAuth2 Token Exchange (UPST) authentication.
    Automatically refreshes tokens as needed, suitable for use with OCI SDK clients.
    """

    def __init__(self, jwt, client_id, client_secret, token_endpoint, region=None, **kwargs):
        logger.info("Initializing EnvironmentTokenExchangeSigner")
        self.jwt = jwt
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_endpoint = token_endpoint
        self.region = region
        self._reset_signers_lock = threading.Lock()
        self.requests_session = requests.Session()
        self._last_refresh = datetime.utcnow()

        self.session_key_supplier = SessionKeySupplier()
        token = self._get_new_token()
        self.security_token_container = SecurityTokenContainer(self.session_key_supplier, token)

        generic_headers = kwargs.get("generic_headers", ["date", "(request-target)", "host"])
        super().__init__(
            self.security_token_container.security_token,
            self.session_key_supplier.get_key_pair()['private'],
            generic_headers=generic_headers
        )
        logger.info("EnvironmentTokenExchangeSigner initialized")

    def close(self):
        logger.info("Signer closed.")

    def __call__(self, request, enforce_content_headers=True):
        if not self.security_token_container.valid():
            logger.info("Security token expired or invalid, refreshing...")
            self._refresh_security_token_inner()
        else:
            logger.debug("Security token valid, proceeding with request.")
        return super().__call__(request, enforce_content_headers)

    def get_security_token(self):
        # Proactively refresh if token is past half its lifetime
        if self.security_token_container.valid_with_half_expiration_time():
            return self.security_token_container.security_token
        else:
            self._refresh_security_token_inner()
            return self.security_token_container.security_token

    def _refresh_security_token_inner(self):
        self._last_refresh = datetime.utcnow()
        with self._reset_signers_lock:
            logger.info("Refreshing security token...")
            self.session_key_supplier.refresh()
            token = self._get_new_token()

            # Optional: Write token and key for debugging/auditing
            try:
                with open(os.path.join(LOG_DIR, "current_upst.token"), "w", encoding="utf-8") as f:
                    f.write(token)

                private_key = self.session_key_supplier.private_key
                private_pem = private_key.private_bytes(
                    encoding=Encoding.PEM,
                    format=PrivateFormat.PKCS8,
                    encryption_algorithm=NoEncryption()
                ).decode("utf-8")

                with open(os.path.join(LOG_DIR, "current_private_key.pem"), "w", encoding="utf-8") as f:
                    f.write(private_pem)

                with open(os.path.join(LOG_DIR, "refresh.log"), "a", encoding="utf-8") as log:
                    log.write(f"[{datetime.utcnow().isoformat()}Z] Token refreshed.\n")
                    log.write(f"[{datetime.utcnow().isoformat()}Z] Token: {token[:2800]}...\n")
            except Exception as file_exc:
                logger.warning("Failed to write token/key files: %s", file_exc)

            self.security_token_container = SecurityTokenContainer(self.session_key_supplier, token)
            logger.info("Refreshed UPST token: %s", token)
            self._reset_signers()
            logger.info("Security token refreshed successfully.")

    def _reset_signers(self):
        self.api_key = SECURITY_TOKEN_FORMAT_STRING.format(self.security_token_container.security_token)
        self.private_key = self.session_key_supplier.get_key_pair()['private']

        if hasattr(self, '_basic_signer'):
            self._basic_signer.reset_signer(self.api_key, self.private_key)
        if hasattr(self, '_body_signer'):
            self._body_signer.reset_signer(self.api_key, self.private_key)

    def _get_new_token(self):
        """
        Requests a new UPST token from the token exchange endpoint.
        """
        try:
            private_key = self.session_key_supplier.private_key
            public_key = private_key.public_key()
            public_key_pem = public_key.public_bytes(
                encoding=Encoding.PEM,
                format=PublicFormat.SubjectPublicKeyInfo
            ).decode("utf-8").replace("\n", "").replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "")

            encoded_auth = base64.b64encode(f"{self.client_id}:{self.client_secret}".encode("utf-8")).decode("utf-8")

            headers = {
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": f"Basic {encoded_auth}"
            }

            data = {
                "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
                "requested_token_type": "urn:oci:token-type:oci-upst",
                "subject_token": self.jwt,
                "subject_token_type": "jwt",
                "public_key": public_key_pem
            }

            logger.info("Requesting new token from endpoint: %s", self.token_endpoint)
            logger.debug("Headers: %s", {k: ("<hidden>" if k.lower() == "authorization" else v) for k, v in headers.items()})
            logger.debug("Body: %s", json.dumps(data, indent=2))

            response = self.requests_session.post(self.token_endpoint, headers=headers, data=data)
            response.raise_for_status()

            response_json = response.json()
            if "token" not in response_json:
                logger.error("'token' not found in token exchange response")
                raise RuntimeError("'token' not found in token exchange response")

            logger.info("Token successfully obtained.")
            logger.info("Full UPST token: %s", response_json["token"])
            return response_json["token"]

        except Exception as e:
            logger.exception("Unhandled exception during token exchange.")
            raise
