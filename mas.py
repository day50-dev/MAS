from urllib.parse import urlparse, unquote, quote


def decode(uri: str) -> dict:
    parsed = urlparse(uri)
    fragment = parsed.fragment
    if not fragment:
        raise ValueError("MAS: fragment is required")

    params = {}
    for part in fragment.split("&"):
        key, _, value = part.partition("=")
        key = unquote(key)
        value = unquote(value)

        if key == "m":
            if not value:
                raise ValueError("MAS: m must not be empty")
            params["m"] = value
        elif key == "k" and value:
            params["k"] = value

    if "m" not in params:
        raise ValueError("MAS: m is required")

    return params


def encode(obj: dict) -> str:
    m = obj.get("m")
    if not m:
        raise ValueError("MAS: m is required and must be non-empty")

    parts = [f"m={quote(m, safe='')}"]
    k = obj.get("k")
    if k:
        parts.append(f"k={quote(k, safe='')}")

    return "#" + "&".join(parts)
