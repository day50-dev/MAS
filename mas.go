package mas

import (
	"fmt"
	"net/url"
	"strings"
)



type Params struct {
	M string
	K string
}

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
