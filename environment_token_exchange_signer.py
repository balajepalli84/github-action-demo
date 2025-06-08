import threading
import base64
import json
import logging

from oci._vendor import requests
from oci.auth.session_key_supplier import SessionKeySupplier
from oci.auth.security_token_container import SecurityTokenContainer
from oci.auth.signers.security_token_signer import SecurityTokenSigner, SECURITY_TOKEN_FORMAT_STRING
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat,PrivateFormat, NoEncryption
from datetime import datetime

# === Logging Setup ===
logger = logging.getLogger("token_exchange_logger")
if not logger.hasHandlers():
    handler = logging.FileHandler("token_exchange.log", mode='a', encoding='utf-8')
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

class EnvironmentTokenExchangeSigner(SecurityTokenSigner):
    def __init__(self, jwt, client_id, client_secret, token_endpoint, region=None, **kwargs):
        self.jwt = jwt
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_endpoint = token_endpoint
        self.region = region
        self._reset_signers_lock = threading.Lock()
        self.requests_session = requests.Session()

        self.session_key_supplier = SessionKeySupplier()
        token = self._exchange_jwt_for_upst()
        self.security_token_container = SecurityTokenContainer(self.session_key_supplier, token)


        if 'generic_headers' in kwargs:
            generic_headers = kwargs['generic_headers']
            super().__init__(
                self.security_token_container.security_token,
                self.session_key_supplier.get_key_pair()['private'],
                generic_headers=generic_headers
            )
        else:
            super().__init__(
                self.security_token_container.security_token,
                self.session_key_supplier.get_key_pair()['private']
            )
    def get_security_token(self):
        if self.security_token_container.valid_with_half_expiration_time():
            logger.info("Using cached UPST token.")
            return self.security_token_container.security_token
        logger.info("Token expired — refreshing.")
        return self._refresh_security_token_inner()


    def refresh_security_token(self):
        return self._refresh_security_token_inner()

    def _refresh_security_token_inner(self):
        with self._reset_signers_lock:
            self.session_key_supplier.refresh()
            token = self._exchange_jwt_for_upst()

            # Save UPST to file
            with open(r"C:\Security\Blogs\TokenExchange\current_upst.token", "w", encoding="utf-8") as f:
                f.write(token)

            # Save private key to file (unencrypted PEM)
            private_key = self.session_key_supplier.private_key
            private_pem = private_key.private_bytes(
                encoding=Encoding.PEM,
                format=PrivateFormat.PKCS8,
                encryption_algorithm=NoEncryption()
            ).decode("utf-8")

            with open(r"C:\Security\Blogs\TokenExchange\current_private_key.pem", "w", encoding="utf-8") as f:
                f.write(private_pem)

            # Optional: log rotation or append a timestamp
            with open("refresh.log", "a") as log:
                log.write(f"[{datetime.utcnow().isoformat()}Z] Token refreshed.\n")

            self.security_token_container = SecurityTokenContainer(self.session_key_supplier, token)
            self._reset_signers()
            return self.security_token_container.security_token


    def _reset_signers(self):
        self.api_key = SECURITY_TOKEN_FORMAT_STRING.format(self.security_token_container.security_token)
        self.private_key = self.session_key_supplier.get_key_pair()['private']

        if hasattr(self, '_basic_signer'):
            self._basic_signer.reset_signer(self.api_key, self.private_key)
        if hasattr(self, '_body_signer'):
            self._body_signer.reset_signer(self.api_key, self.private_key)

    def _exchange_jwt_for_upst(self):
        try:
            private_key = self.session_key_supplier.private_key
            public_key = private_key.public_key()
            public_key_pem = public_key.public_bytes(
                encoding=Encoding.PEM,
                format=PublicFormat.SubjectPublicKeyInfo
            ).decode("utf-8").replace("\n", "").replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "")

            auth_string = f"{self.client_id}:{self.client_secret}"
            encoded_auth = base64.b64encode(auth_string.encode("utf-8")).decode("utf-8")

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

            logger.info("[_exchange_jwt_for_upst] Sending request to token endpoint: %s", self.token_endpoint)
            logger.debug("Headers: %s", {k: ("<hidden>" if k.lower() == "authorization" else v) for k, v in headers.items()})
            logger.debug("Body: %s", json.dumps(data, indent=2))

            response = self.requests_session.post(self.token_endpoint, headers=headers, data=data)

            try:
                response.raise_for_status()
            except Exception as e:
                logger.error("Request failed: %s", str(e))
                logger.error("Status Code: %s", response.status_code)
                logger.error("Response Body: %s", response.text)
                raise

            response_json = response.json()
            logger.debug("Response JSON: %s", json.dumps(response_json, indent=2))

            if "token" not in response_json:
                raise RuntimeError("'token' not found in token exchange response")

            logger.info("Token successfully obtained.")
            return response_json["token"]

        except Exception as e:
            logger.exception("Unhandled exception during token exchange.")
            raise
