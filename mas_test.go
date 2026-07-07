package mas

import (
	"testing"
)

func TestDecodeBasic(t *testing.T) {
	p, err := Decode("https://api.anthropic.com#m=claude-sonnet-4-5&k=sk-ant-abc123")
	if err != nil {
		t.Fatal(err)
	}
	if p.M != "claude-sonnet-4-5" {
		t.Fatalf("expected claude-sonnet-4-5, got %s", p.M)
	}
	if p.K != "sk-ant-abc123" {
		t.Fatalf("expected sk-ant-abc123, got %s", p.K)
	}
}

func TestDecodeNoK(t *testing.T) {
	p, err := Decode("https://localhost:11434#m=mistral")
	if err != nil {
		t.Fatal(err)
	}
	if p.M != "mistral" {
		t.Fatalf("expected mistral, got %s", p.M)
	}
	if p.K != "" {
		t.Fatalf("expected empty k, got %s", p.K)
	}
}

func TestDecodeMissingM(t *testing.T) {
	_, err := Decode("https://example.com#k=foo")
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestDecodeNoFragment(t *testing.T) {
	_, err := Decode("https://example.com")
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestEncodeRoundtrip(t *testing.T) {
	orig := &Params{M: "gpt-4o", K: "sk-xyz"}
	s, err := Encode(orig)
	if err != nil {
		t.Fatal(err)
	}
	p, err := Decode("https://example.com" + s)
	if err != nil {
		t.Fatal(err)
	}
	if p.M != orig.M || p.K != orig.K {
		t.Fatalf("roundtrip failed: %+v -> %+v", orig, p)
	}
}
