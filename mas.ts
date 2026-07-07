/** Model Address Standard (MAS) parameters. */
export interface MASParams {
  /** Model identifier (required). */
  m: string;
  /** API key (optional). */
  k?: string;
}

/**
 * Extract MAS parameters (`m`, `k`) from an HTTP/HTTPS URI.
 *
 * @param uri - A valid MAS address
 * @returns An object with `m` and optionally `k`
 * @throws If the fragment is missing, `m` is absent, or `m` is empty
 *
 * @example
 * decode("https://api.example.com#m=gpt-4o&k=sk-xyz")
 * // => { m: "gpt-4o", k: "sk-xyz" }
 */
export function decode(uri: string): MASParams {
  const url = new URL(uri);
  const fragment = url.hash.slice(1);
  if (!fragment) {
    throw new Error("MAS: fragment is required");
  }

  const params: Record<string, string> = {};
  for (const part of fragment.split("&")) {
    const idx = part.indexOf("=");
    const key = decodeURIComponent(idx >= 0 ? part.slice(0, idx) : part);
    const value = idx >= 0 ? decodeURIComponent(part.slice(idx + 1)) : "";

    if (key === "m") {
      if (!value) {
        throw new Error("MAS: m must not be empty");
      }
      params["m"] = value;
    } else if (key === "k" && value) {
      params["k"] = value;
    }
  }

  if (!("m" in params)) {
    throw new Error("MAS: m is required");
  }

  return params as unknown as MASParams;
}

/**
 * Build a MAS fragment string from `MASParams`.
 *
 * @param obj - Object with a non-empty `m` and optionally `k`
 * @returns URI fragment of the form `#m=...&k=...`
 * @throws If `m` is missing or empty
 *
 * @example
 * encode({ m: "gpt-4o" })
 * // => "#m=gpt-4o"
 */
export function encode(obj: MASParams): string {
  if (!obj.m) {
    throw new Error("MAS: m is required and must be non-empty");
  }

  const parts = [`m=${encodeURIComponent(obj.m)}`];
  if (obj.k) {
    parts.push(`k=${encodeURIComponent(obj.k)}`);
  }

  return "#" + parts.join("&");
}
