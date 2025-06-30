import json
import base64

def decode_jwt(token):
    parts = token.split('.')
    if len(parts) != 3:
        print(" Invalid JWT format")
        return

    def decode_part(part):
        # Pad base64 if needed
        padding = '=' * (4 - len(part) % 4)
        return base64.urlsafe_b64decode(part + padding).decode("utf-8")

    header = decode_part(parts[0])
    payload = decode_part(parts[1])

    print("\n Decoded JWT Header:")
    print(json.dumps(json.loads(header), indent=2))
    print("\n Decoded JWT Payload:")
    print(json.dumps(json.loads(payload), indent=2))

decode_jwt(OCI_JWT)
