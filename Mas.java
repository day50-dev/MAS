import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Model Address Standard (MAS) — decode/encode MAS URIs.
 */
public class Mas {

    /** MAS parameters extracted from a URI. */
    public static final class Params {
        public final String m;
        public final String k;

        public Params(String m, String k) {
            this.m = Objects.requireNonNull(m, "m is required");
            this.k = k;
        }

        @Override
        public String toString() {
            return "Params{m='" + m + "', k='" + k + "'}";
        }
    }

    /**
     * Extract MAS parameters (m, k) from an HTTP/HTTPS URI.
     *
     * @param uri a valid MAS address
     * @return the extracted parameters
     * @throws IllegalArgumentException if the fragment is missing,
     *         m is absent, or m is empty
     */
    public static Params decode(String uri) {
        int hash = uri.indexOf('#');
        if (hash < 0) {
            throw new IllegalArgumentException("MAS: fragment is required");
        }
        String fragment = uri.substring(hash + 1);
        if (fragment.isEmpty()) {
            throw new IllegalArgumentException("MAS: fragment is required");
        }

        String m = null;
        String k = null;

        for (String part : fragment.split("&")) {
            int eq = part.indexOf('=');
            String key = eq >= 0 ? part.substring(0, eq) : part;
            String val = eq >= 0 ? part.substring(eq + 1) : "";

            key = URLDecoder.decode(key, StandardCharsets.UTF_8);
            val = URLDecoder.decode(val, StandardCharsets.UTF_8);

            if (key.equals("m")) {
                if (val.isEmpty()) {
                    throw new IllegalArgumentException("MAS: m must not be empty");
                }
                m = val;
            } else if (key.equals("k") && !val.isEmpty()) {
                k = val;
            }
        }

        if (m == null) {
            throw new IllegalArgumentException("MAS: m is required");
        }

        return new Params(m, k);
    }

    /**
     * Build a MAS fragment string from parameters.
     *
     * @param p the parameters (must have a non-empty m)
     * @return URI fragment of the form {@code #m=...&k=...}
     * @throws IllegalArgumentException if m is missing or empty
     */
    public static String encode(Params p) {
        if (p.m == null || p.m.isEmpty()) {
            throw new IllegalArgumentException("MAS: m is required and must be non-empty");
        }

        StringBuilder sb = new StringBuilder("#m=");
        sb.append(URLEncoder.encode(p.m, StandardCharsets.UTF_8));

        if (p.k != null && !p.k.isEmpty()) {
            sb.append("&k=");
            sb.append(URLEncoder.encode(p.k, StandardCharsets.UTF_8));
        }

        return sb.toString();
    }
}
