using System;
using System.Collections.Generic;
using System.Net;
using System.Text;

/// <summary>
/// Model Address Standard (MAS) — decode/encode MAS URIs.
/// </summary>
public static class Mas
{
    /// <summary>MAS parameters extracted from a URI.</summary>
    public class Params
    {
        /// <summary>Model identifier (required).</summary>
        public string M { get; }
        /// <summary>API key (optional).</summary>
        public string? K { get; }

        public Params(string m, string? k)
        {
            M = m ?? throw new ArgumentNullException(nameof(m));
            K = k;
        }
    }

    /// <summary>
    /// Extract MAS parameters (m, k) from an HTTP/HTTPS URI.
    /// </summary>
    /// <param name="uri">A valid MAS address.</param>
    /// <returns>The extracted parameters.</returns>
    /// <exception cref="ArgumentException">
    /// Thrown if the fragment is missing, m is absent, or m is empty.
    /// </exception>
    public static Params Decode(string uri)
    {
        int hash = uri.IndexOf('#');
        if (hash < 0)
            throw new ArgumentException("MAS: fragment is required");

        string fragment = uri.Substring(hash + 1);
        if (string.IsNullOrEmpty(fragment))
            throw new ArgumentException("MAS: fragment is required");

        string? m = null;
        string? k = null;

        foreach (string part in fragment.Split('&'))
        {
            int eq = part.IndexOf('=');
            string key = eq >= 0 ? part.Substring(0, eq) : part;
            string val = eq >= 0 ? part.Substring(eq + 1) : "";

            key = WebUtility.UrlDecode(key) ?? key;
            val = WebUtility.UrlDecode(val) ?? val;

            if (key == "m")
            {
                if (string.IsNullOrEmpty(val))
                    throw new ArgumentException("MAS: m must not be empty");
                m = val;
            }
            else if (key == "k" && !string.IsNullOrEmpty(val))
            {
                k = val;
            }
        }

        if (m == null)
            throw new ArgumentException("MAS: m is required");

        return new Params(m, k);
    }

    /// <summary>
    /// Build a MAS fragment string from parameters.
    /// </summary>
    /// <param name="p">The parameters (must have a non-empty M).</param>
    /// <returns>URI fragment of the form <c>#m=...&amp;k=...</c>.</returns>
    /// <exception cref="ArgumentException">
    /// Thrown if M is missing or empty.
    /// </exception>
    public static string Encode(Params p)
    {
        if (string.IsNullOrEmpty(p.M))
            throw new ArgumentException("MAS: m is required and must be non-empty");

        var sb = new StringBuilder("#m=");
        sb.Append(WebUtility.UrlEncode(p.M));

        if (!string.IsNullOrEmpty(p.K))
        {
            sb.Append("&k=");
            sb.Append(WebUtility.UrlEncode(p.K));
        }

        return sb.ToString();
    }
}
