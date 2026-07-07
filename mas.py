"""Model Address Standard (MAS) — decode/encode MAS URIs.

Usage:
    >>> import mas
    >>> mas.decode("https://api.example.com#m=gpt-4o&k=sk-xyz")
    {'m': 'gpt-4o', 'k': 'sk-xyz'}
    >>> mas.encode({"m": "gpt-4o"})
    '#m=gpt-4o'
"""

from urllib.parse import urlparse, unquote, quote


def decode(uri: str) -> dict:
    """Extract MAS parameters (m, k) from an HTTP/HTTPS URI.

    Args:
        uri: A valid MAS address (any HTTP(S) URI with a fragment
            containing at least an ``m`` parameter).

    Returns:
        A dict with key ``m`` (the model identifier) and optionally
        ``k`` (the API key) if present.

    Raises:
        ValueError: If the fragment is missing, ``m`` is absent,
            or ``m`` is empty.
    """
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
    """Build a MAS fragment string from a dict with ``m`` and optional ``k``.

    Args:
        obj: A dict with a non-empty ``m`` key and optionally a ``k`` key.

    Returns:
        A URI fragment string of the form ``#m=...&k=...``.

    Raises:
        ValueError: If ``m`` is missing or empty.
    """
    m = obj.get("m")
    if not m:
        raise ValueError("MAS: m is required and must be non-empty")

    parts = [f"m={quote(m, safe='')}"]
    k = obj.get("k")
    if k:
        parts.append(f"k={quote(k, safe='')}")

    return "#" + "&".join(parts)
