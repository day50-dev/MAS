#[derive(Debug, Clone, PartialEq)]
pub struct Params {
    pub m: String,
    pub k: Option<String>,
}

pub fn decode(uri: &str) -> Result<Params, String> {
    let url = url::Url::parse(uri).map_err(|e| format!("MAS: invalid URI: {e}"))?;
    let fragment = url.fragment().ok_or("MAS: fragment is required")?;
    if fragment.is_empty() {
        return Err("MAS: fragment is required".into());
    }

    let mut m = None;
    let mut k = None;

    for part in fragment.split('&') {
        let (key, value) = match part.split_once('=') {
            Some((k, v)) => (k, v),
            None => (part, ""),
        };
        let key = urlencoding::decode(key)
            .map_err(|e| format!("MAS: failed to decode key: {e}"))?;
        let value = urlencoding::decode(value)
            .map_err(|e| format!("MAS: failed to decode value: {e}"))?;

        match key.as_ref() {
            "m" => {
                if value.is_empty() {
                    return Err("MAS: m must not be empty".into());
                }
                m = Some(value.into_owned());
            }
            "k" if !value.is_empty() => {
                k = Some(value.into_owned());
            }
            _ => {}
        }
    }

    let m = m.ok_or("MAS: m is required")?;

    Ok(Params { m, k })
}

pub fn encode(params: &Params) -> Result<String, String> {
    if params.m.is_empty() {
        return Err("MAS: m is required and must be non-empty".into());
    }

    let mut s = format!("#m={}", urlencoding::encode(&params.m));
    if let Some(k) = &params.k {
        if !k.is_empty() {
            s.push_str(&format!("&k={}", urlencoding::encode(k)));
        }
    }

    Ok(s)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decode_basic() {
        let p = decode("https://api.example.com#m=claude-sonnet-4-5&k=sk-ant-abc").unwrap();
        assert_eq!(p.m, "claude-sonnet-4-5");
        assert_eq!(p.k, Some("sk-ant-abc".into()));
    }

    #[test]
    fn test_decode_no_k() {
        let p = decode("https://localhost:11434#m=mistral").unwrap();
        assert_eq!(p.m, "mistral");
        assert_eq!(p.k, None);
    }

    #[test]
    fn test_decode_missing_m() {
        let r = decode("https://example.com#k=foo");
        assert!(r.is_err());
    }

    #[test]
    fn test_decode_no_fragment() {
        let r = decode("https://example.com");
        assert!(r.is_err());
    }

    #[test]
    fn test_encode_roundtrip() {
        let p = Params { m: "gpt-4o".into(), k: Some("sk-xyz".into()) };
        let s = encode(&p).unwrap();
        let p2 = decode(&format!("https://example.com{s}")).unwrap();
        assert_eq!(p, p2);
    }
}
