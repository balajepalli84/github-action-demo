import os
import oci
import base64
import time
import logging
from datetime import datetime
from oci.auth.signers.environment_token_exchange_signer import EnvironmentTokenExchangeSigner

# Set environment variables (for demo/testing; in production, set these externally)
os.environ["OCI_JWT"] = open(".oci/jwt_token.txt").read().strip()
os.environ["OCI_TOKEN_EXCHANGE_ENDPOINT"] = "https://idcs-8dd307747946491cbfe1b7a3f063db0d.identity.oraclecloud.com/oauth2/v1/token"
os.environ["OCI_CLIENT_ID"] = "8aa264f421d646e98699b716b2e9b72e"
os.environ["OCI_CLIENT_SECRET"] = "idcscs-59183ab6-657c-4a24-ad24-ffae6c8bc061"

# === Logging Setup ===
logger = logging.getLogger("test_logger")
if not logger.hasHandlers():
    handler = logging.FileHandler(
        r"C:\Security\Blogs\TokenExchange\secret_test_output.log",
        mode='a',
        encoding='utf-8'
    )
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

def load_env_vars():
    """Load and validate required environment variables with correct mapping."""
    mapping = {
        "OCI_JWT": "jwt",
        "OCI_CLIENT_ID": "client_id",
        "OCI_CLIENT_SECRET": "client_secret",
        "OCI_TOKEN_EXCHANGE_ENDPOINT": "token_endpoint"
    }
    env_vars = {}
    for env_var, arg_name in mapping.items():
        value = os.environ.get(env_var)
        if not value:
            logger.error(f"Missing environment variable: {env_var}")
            raise ValueError(f"Missing environment variable: {env_var}")
        env_vars[arg_name] = value.strip()
    env_vars["region"] = os.environ.get("OCI_REGION", "us-ashburn-1")
    return env_vars

def read_secret_value(secret_client, secret_id):
    """Fetch and decode a secret from OCI Vault."""
    try:
        response = secret_client.get_secret_bundle(secret_id)
        base64_content = response.data.secret_bundle_content.content
        return base64.b64decode(base64_content.encode()).decode()
    except Exception as e:
        logger.error(f"Failed to retrieve secret: {e}")
        raise

def main():
    # Load environment variables and configure test parameters
    env_vars = load_env_vars()
    secret_id = "ocid1.vaultsecret.oc1.iad.amaaaaaac3adhhqacfyyvmkejvczkklmmex7xirxyc3hyynboi72xzok4ica"
    output_file = os.path.join(os.environ.get("OCI_OUTPUT_DIR", "."), "secret_test_output.log")
    sleep_interval = int(os.environ.get("OCI_TEST_SLEEP", 30))

    logger.info("Initializing EnvironmentTokenExchangeSigner")
    signer = EnvironmentTokenExchangeSigner(**env_vars)
    logger.info("Signer initialized")
    logger.info(f"Current UPST token: {signer.security_token_container.security_token}")

    logger.info("Creating OCI SecretsClient")
    secrets_client = oci.secrets.SecretsClient(
        config={"region": env_vars["region"]},
        signer=signer
    )

    logger.info("Starting test loop")
    for i in range(10):
        logger.info(f"--- Iteration {i+1}/10 ---")
        try:
            secret_content = read_secret_value(secrets_client, secret_id)
            timestamp = datetime.utcnow().isoformat()
            logger.info(f"secret_content: {secret_content}")
        except Exception as e:
            logger.error(f"Iteration {i+1} failed: {e}")
        if i < 10 - 1:
            logger.info(f"Sleeping for 2700 seconds")
            time.sleep(2700)


    signer.close()
    logger.info("Test session complete")


if __name__ == "__main__":
    main()
