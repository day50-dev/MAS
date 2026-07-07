<?php
/**
 * Model Address Standard (MAS) — decode/encode MAS URIs.
 *
 * Usage:
 *   $params = mas_decode("https://api.example.com#m=gpt-4o&k=sk-xyz");
 *   $frag   = mas_encode(["m" => "gpt-4o"]);
 */

if (!function_exists('mas_decode')) {

    /**
     * Extract MAS parameters (m, k) from an HTTP/HTTPS URI.
     *
     * @param string $uri A valid MAS address.
     * @return array{0: string, 1?: string} [m, k?]
     * @throws \InvalidArgumentException If the fragment is missing,
     *         m is absent, or m is empty.
     */
    function mas_decode(string $uri): array {
        $hash = strpos($uri, '#');
        if ($hash === false) {
            throw new \InvalidArgumentException('MAS: fragment is required');
        }
        $fragment = substr($uri, $hash + 1);
        if ($fragment === '' || $fragment === false) {
            throw new \InvalidArgumentException('MAS: fragment is required');
        }

        $m = null;
        $k = null;

        foreach (explode('&', $fragment) as $part) {
            $eq = strpos($part, '=');
            $key = $eq !== false ? substr($part, 0, $eq) : $part;
            $val = $eq !== false ? substr($part, $eq + 1) : '';

            $key = rawurldecode($key);
            $val = rawurldecode($val);

            if ($key === 'm') {
                if ($val === '') {
                    throw new \InvalidArgumentException('MAS: m must not be empty');
                }
                $m = $val;
            } elseif ($key === 'k' && $val !== '') {
                $k = $val;
            }
        }

        if ($m === null) {
            throw new \InvalidArgumentException('MAS: m is required');
        }

        return $k !== null ? [$m, $k] : [$m];
    }
}

if (!function_exists('mas_encode')) {

    /**
     * Build a MAS fragment string from parameters.
     *
     * @param array{0: string, 1?: string}|array{m: string, k?: string} $params
     *        Must contain a non-empty "m" key or first element.
     * @return string URI fragment of the form "#m=...&k=...".
     * @throws \InvalidArgumentException If m is missing or empty.
     */
    function mas_encode(array $params): string {
        $m = $params['m'] ?? $params[0] ?? null;
        if ($m === null || $m === '') {
            throw new \InvalidArgumentException('MAS: m is required and must be non-empty');
        }

        $parts = ['m=' . rawurlencode($m)];
        $k = $params['k'] ?? $params[1] ?? null;
        if ($k !== null && $k !== '') {
            $parts[] = 'k=' . rawurlencode($k);
        }

        return '#' . implode('&', $parts);
    }
}
