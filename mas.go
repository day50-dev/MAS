// Package mas implements the Model Address Standard (MAS).
//
// MAS defines a minimal client-side convention for identifying an AI
// model using a URI fragment parameter.  See the specification in
// MAS.md for details.
//
// Usage:
//
//	p, err := mas.Decode("https://api.example.com#m=gpt-4o&k=sk-xyz")
//	s, err := mas.Encode(&mas.Params{M: "gpt-4o"})
package mas

import (
	"fmt"
	"net/url"
	"strings"
)

// Params holds the MAS parameters extracted from a URI.
type Params struct {
	M string // Model identifier (required)
	K string // API key (optional)
}

// Decode extracts MAS parameters (m, k) from an HTTP/HTTPS URI.
//
// It returns an error if the fragment is missing, m is absent, or m
// is empty.  Unknown fragment parameters are silently ignored.
func Decode(uri string) (*Params, error) {
	u, err := url.Parse(uri)
	if err != nil {
		return nil, fmt.Errorf("MAS: invalid URI: %w", err)
	}
	if u.Fragment == "" {
		return nil, fmt.Errorf("MAS: fragment is required")
	}

	var m, k string
	for _, part := range strings.Split(u.Fragment, "&") {
		var key, value string
		if idx := strings.IndexByte(part, '='); idx >= 0 {
			key = part[:idx]
			value = part[idx+1:]
		} else {
			key = part
		}

		key, err = url.QueryUnescape(key)
		if err != nil {
			return nil, fmt.Errorf("MAS: failed to decode key: %w", err)
		}
		value, err = url.QueryUnescape(value)
		if err != nil {
			return nil, fmt.Errorf("MAS: failed to decode value: %w", err)
		}

		switch key {
		case "m":
			if value == "" {
				return nil, fmt.Errorf("MAS: m must not be empty")
			}
			m = value
		case "k":
			k = value
		}
	}

	if m == "" {
		return nil, fmt.Errorf("MAS: m is required")
	}

	return &Params{M: m, K: k}, nil
}

// Encode builds a MAS fragment string from Params.
//
// It returns an error if m is empty.
func Encode(p *Params) (string, error) {
	if p.M == "" {
		return "", fmt.Errorf("MAS: m is required and must be non-empty")
	}

	var b strings.Builder
	b.WriteString("#m=")
	b.WriteString(url.QueryEscape(p.M))

	if p.K != "" {
		b.WriteString("&k=")
		b.WriteString(url.QueryEscape(p.K))
	}

	return b.String(), nil
}
